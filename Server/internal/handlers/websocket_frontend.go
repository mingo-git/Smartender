// internal/handlers/websocket_frontend.go
package handlers

import (
	auth "app/internal/auth"
	models "app/internal/models"
	query "app/internal/query"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// Frontend-spezifische WebSocket-Strukturen
type FrontendClient struct {
	UserID       int
	Conn         *websocket.Conn
	Send         chan []byte
	LastActivity time.Time
}

type ClientManager struct {
	clients    map[int]*FrontendClient // UserID -> Client
	register   chan *FrontendClient
	unregister chan *FrontendClient
	broadcast  chan []byte
	mutex      sync.RWMutex
}

type WebSocketMessage struct {
	Type      string      `json:"type"`
	Data      interface{} `json:"data"`
	Timestamp time.Time   `json:"timestamp"`
}

// Verschiedene Message-Typen
const (
	MessageTypeDrinkUpdate      = "drink_update"
	MessageTypeRecipeUpdate     = "recipe_update"
	MessageTypeSlotUpdate       = "slot_update"
	MessageTypeHardwareUpdate   = "hardware_update"
	MessageTypeFavoriteUpdate   = "favorite_update"
	MessageTypeIngredientUpdate = "ingredient_update"
	MessageTypePing             = "ping"
	MessageTypePong             = "pong"
	MessageTypeClientConnected  = "client_connected"
	MessageTypeWelcome          = "welcome"
)

var frontendClientManager = &ClientManager{
	clients:    make(map[int]*FrontendClient),
	register:   make(chan *FrontendClient),
	unregister: make(chan *FrontendClient),
	broadcast:  make(chan []byte),
}

// In Server/internal/handlers/websocket_frontend.go - Sichere CORS-Policy
var frontendUpgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		origin := r.Header.Get("Origin")
		log.Printf("🌐 WebSocket Origin: %s", origin)
		
		// 🔒 SICHERHEIT: Nur erlaubte Origins in Production
		env := os.Getenv("ENVIRONMENT")
		if env == "prod" || env == "production" {
			allowedOrigins := []string{
				"https://smartender.lextron.dev",
				// Fügen Sie Ihre erlaubten Domains hinzu
			}
			
			for _, allowedOrigin := range allowedOrigins {
				if origin == allowedOrigin {
					return true
				}
			}
			
			log.Printf("❌ WebSocket Origin nicht erlaubt: %s", origin)
			return false
		}
		
		// In Development: erlaube localhost
		if strings.Contains(origin, "localhost") || strings.Contains(origin, "127.0.0.1") {
			return true
		}
		
		return false
	},
}

// Initialisiere den Client Manager
func init() {
	log.Printf("🚀 Initialisiere Frontend WebSocket Client Manager...")
	go frontendClientManager.run()
}

// Client Manager Loop
func (manager *ClientManager) run() {
	log.Printf("📡 Frontend WebSocket Client Manager gestartet")
	for {
		select {
		case client := <-manager.register:
			manager.mutex.Lock()
			manager.clients[client.UserID] = client
			manager.mutex.Unlock()
			log.Printf("✅ Frontend Client registriert für User %d (Total: %d)", client.UserID, len(manager.clients))
			
			// Sende Welcome Message
			welcomeMsg := WebSocketMessage{
				Type: MessageTypeWelcome,
				Data: map[string]interface{}{
					"message":    "Willkommen bei Smartender V2",
					"user_id":    client.UserID,
					"features":   []string{"real_time_updates", "ping_pong", "auto_reconnect", "full_data_sync"},
					"version":    "2.0",
					"server_time": time.Now().Format(time.RFC3339),
				},
				Timestamp: time.Now(),
			}
			if msgBytes, err := json.Marshal(welcomeMsg); err == nil {
				select {
				case client.Send <- msgBytes:
				default:
					manager.mutex.Lock()
					delete(manager.clients, client.UserID)
					close(client.Send)
					manager.mutex.Unlock()
				}
			}

		case client := <-manager.unregister:
			manager.mutex.Lock()
			if _, ok := manager.clients[client.UserID]; ok {
				delete(manager.clients, client.UserID)
				close(client.Send)
				log.Printf("❌ Frontend Client abgemeldet für User %d (Verbleibend: %d)", client.UserID, len(manager.clients))
			}
			manager.mutex.Unlock()

		case message := <-manager.broadcast:
			manager.mutex.RLock()
			for userID, client := range manager.clients {
				select {
				case client.Send <- message:
				default:
					delete(manager.clients, userID)
					close(client.Send)
				}
			}
			manager.mutex.RUnlock()
		}
	}
}

// Frontend WebSocket Handler
func FrontendWebSocket(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📱 [WS] Frontend WebSocket Verbindungsversuch um %s", time.Now().Format("15:04:05"))

	// JWT aus Query Parameter oder Header extrahieren
	token := r.URL.Query().Get("token")
	if token == "" {
		token = r.Header.Get("Authorization")
		if token != "" {
			if len(token) > 7 && token[:7] == "Bearer " {
				token = token[7:]
			}
		}
	}

	if token == "" {
		log.Default().Printf("❌ [WS] Kein Authentication Token gefunden")
		http.Error(w, "Missing authentication token", http.StatusUnauthorized)
		return
	}

	// JWT validieren und UserID extrahieren
	userID, err := auth.ValidateJWT(token)
	if err != nil {
		log.Default().Printf("❌ [WS] Invalid JWT token: %v", err)
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	log.Default().Printf("✅ [WS] JWT validiert für User ID: %d", userID)

	// WebSocket-Verbindung upgraden
	conn, err := frontendUpgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Default().Printf("❌ [WS] WebSocket upgrade fehlgeschlagen: %v", err)
		return
	}

	log.Default().Printf("🔌 [WS] WebSocket Verbindung erfolgreich für User %d", userID)

	// Client erstellen
	client := &FrontendClient{
		UserID:       userID,
		Conn:         conn,
		Send:         make(chan []byte, 256),
		LastActivity: time.Now(),
	}

	// Client registrieren
	frontendClientManager.register <- client

	// Goroutinen für Lesen und Schreiben starten
	go client.writePump()
	go client.readPump(db)
}

// Lese-Loop für Frontend-Client
func (c *FrontendClient) readPump(db *sql.DB) {
	defer func() {
		log.Printf("🔌 [WS] ReadPump beendet für User %d", c.UserID)
		frontendClientManager.unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(512)
	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		log.Printf("🏓 [WS] Pong erhalten von User %d", c.UserID)
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		c.LastActivity = time.Now()
		return nil
	})

	for {
		_, messageBytes, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("❌ [WS] Unerwarteter WebSocket Fehler für User %d: %v", c.UserID, err)
			} else {
				log.Printf("🔌 [WS] WebSocket Verbindung geschlossen für User %d: %v", c.UserID, err)
			}
			break
		}

		c.LastActivity = time.Now()

		var message WebSocketMessage
		if err := json.Unmarshal(messageBytes, &message); err != nil {
			log.Printf("❌ [WS] Ungültiges Message Format von User %d: %v", c.UserID, err)
			continue
		}

		log.Printf("📨 [WS] Nachricht erhalten von User %d: %s", c.UserID, message.Type)

		switch message.Type {
		case MessageTypePing:
			pongMsg := WebSocketMessage{
				Type: MessageTypePong,
				Data: map[string]interface{}{
					"server_time": time.Now().Format(time.RFC3339),
					"user_id":     c.UserID,
				},
				Timestamp: time.Now(),
			}
			if msgBytes, err := json.Marshal(pongMsg); err == nil {
				select {
				case c.Send <- msgBytes:
					log.Printf("🏓 [WS] Pong gesendet an User %d", c.UserID)
				default:
					log.Printf("❌ [WS] Pong konnte nicht gesendet werden an User %d", c.UserID)
					close(c.Send)
					return
				}
			}

		case MessageTypeClientConnected:
			log.Printf("👋 [WS] Client Connected Message von User %d", c.UserID)

		default:
			log.Printf("❓ [WS] Unbekannter Message Type von User %d: %s", c.UserID, message.Type)
		}
	}
}

// Schreibe-Loop für Frontend-Client
func (c *FrontendClient) writePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		log.Printf("✍️ [WS] WritePump beendet für User %d", c.UserID)
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				log.Printf("❌ [WS] NextWriter Fehler für User %d: %v", c.UserID, err)
				return
			}
			w.Write(message)

			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				log.Printf("❌ [WS] Writer Close Fehler für User %d: %v", c.UserID, err)
				return
			}

		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("❌ [WS] Ping senden fehlgeschlagen für User %d: %v", c.UserID, err)
				return
			}
			log.Printf("🏓 [WS] Ping gesendet an User %d", c.UserID)
		}
	}
}

// ==============================================================================================
// ERWEITERTE BROADCAST-FUNKTIONEN MIT KOMPLETTEN DATEN
// ==============================================================================================

// BroadcastDrinkUpdate sendet komplette Drink-Daten via WebSocket
func BroadcastDrinkUpdate(db *sql.DB, drinkID int, hardwareID int, action string) {
	var drink *models.Drink = nil
	
	// Bei DELETE-Aktionen senden wir nur die IDs
	if action != "deleted" {
		// Hole komplette Drink-Daten aus der Datenbank
		var drinkData models.Drink
		err := db.QueryRow(query.GetDrinkByID(), drinkID, hardwareID).Scan(
			&drinkData.DrinkID, 
			&drinkData.HardwareID, 
			&drinkData.Name, 
			&drinkData.Alcoholic,
		)
		if err != nil {
			log.Printf("❌ [WS] Fehler beim Laden der Drink-Daten (ID: %d): %v", drinkID, err)
			// Fallback: sende nur IDs
		} else {
			drink = &drinkData
			log.Printf("✅ [WS] Drink-Daten geladen für ID %d: %s", drinkID, drink.Name)
		}
	}
	
	// Erstelle WebSocket Message
	messageData := map[string]interface{}{
		"action": action,
	}
	
	if drink != nil {
		messageData["drink"] = drink
	} else {
		// Fallback für DELETE oder wenn Datenbankabfrage fehlschlägt
		messageData["drink_id"] = drinkID
		messageData["hardware_id"] = hardwareID
	}
	
	message := WebSocketMessage{
		Type: MessageTypeDrinkUpdate,
		Data: messageData,
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Drink Update: %s (ID: %d, Hardware: %d)", action, drinkID, hardwareID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Drink Update: %v", err)
	}
}

// BroadcastRecipeUpdate sendet komplette Recipe-Daten via WebSocket
func BroadcastRecipeUpdate(db *sql.DB, recipeID int, hardwareID int, action string) {
	var recipe *models.Recipe_Response = nil
	
	// Bei DELETE-Aktionen senden wir nur die IDs
	if action != "deleted" {
		// Hole komplette Recipe-Daten aus der Datenbank
		var recipeData models.Recipe
		var drinkIDsJSON []byte
		err := db.QueryRow(query.GetRecipeByID(), recipeID, hardwareID).Scan(
			&recipeData.ID, 
			&recipeData.HardwareID, 
			&recipeData.Name, 
			&recipeData.Picture, 
			&drinkIDsJSON,
		)
		if err != nil {
			log.Printf("❌ [WS] Fehler beim Laden der Recipe-Daten (ID: %d): %v", recipeID, err)
		} else {
			// Hole Ingredients für das Recipe
			var ingredientsAll []models.IngredientResponse
			rows, err := db.Query(query.GetIngredientsForRecipe(), recipeData.ID)
			if err != nil {
				log.Printf("❌ [WS] Fehler beim Laden der Ingredients für Recipe %d: %v", recipeID, err)
			} else {
				defer rows.Close()
				
				for rows.Next() {
					var ingredient models.Ingredient
					if err := rows.Scan(&ingredient.RecipeID, &ingredient.DrinkID, &ingredient.Quantity_ml); err != nil {
						log.Printf("❌ [WS] Fehler beim Scannen des Ingredients: %v", err)
						continue
					}

					// Hole Drink-Details für das Ingredient
					var drink models.Drink
					if err := db.QueryRow(query.GetDrinkByID(), ingredient.DrinkID, recipeData.HardwareID).Scan(&drink.DrinkID, &drink.HardwareID, &drink.Name, &drink.Alcoholic); err != nil {
						log.Printf("❌ [WS] Fehler beim Laden der Drink-Details für Ingredient: %v", err)
						continue
					}

					ingredientsAll = append(ingredientsAll, models.IngredientResponse{
						Quantity_ml: ingredient.Quantity_ml,
						Drink:       drink,
					})
				}
				
				if len(ingredientsAll) == 0 {
					ingredientsAll = []models.IngredientResponse{}
				}
			}
			
			recipe = &models.Recipe_Response{
				ID:          recipeData.ID,
				HardwareID:  recipeData.HardwareID,
				Name:        recipeData.Name,
				Picture:     recipeData.Picture,
				Ingredients: ingredientsAll,
			}
			log.Printf("✅ [WS] Recipe-Daten geladen für ID %d: %s", recipeID, recipe.Name)
		}
	}
	
	// Erstelle WebSocket Message
	messageData := map[string]interface{}{
		"action": action,
	}
	
	if recipe != nil {
		messageData["recipe"] = recipe
	} else {
		// Fallback für DELETE oder wenn Datenbankabfrage fehlschlägt
		messageData["recipe_id"] = recipeID
		messageData["hardware_id"] = hardwareID
	}
	
	message := WebSocketMessage{
		Type: MessageTypeRecipeUpdate,
		Data: messageData,
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Recipe Update: %s (ID: %d, Hardware: %d)", action, recipeID, hardwareID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Recipe Update: %v", err)
	}
}

// BroadcastSlotUpdate sendet komplette Slot-Daten via WebSocket
func BroadcastSlotUpdate(db *sql.DB, slotNumber int, hardwareID int, drinkID *int) {
	var slot models.Slot
	slot.HardwareID = hardwareID
	slot.SlotNumber = slotNumber
	
	// Wenn drinkID gesetzt ist, lade die kompletten Drink-Daten
	if drinkID != nil && *drinkID > 0 {
		var drink models.Drink
		err := db.QueryRow(query.GetDrinkByID(), *drinkID, hardwareID).Scan(
			&drink.DrinkID, 
			&drink.HardwareID, 
			&drink.Name, 
			&drink.Alcoholic,
		)
		if err != nil {
			log.Printf("❌ [WS] Fehler beim Laden der Drink-Daten für Slot %d: %v", slotNumber, err)
			slot.Drink = nil
		} else {
			slot.Drink = &drink
			log.Printf("✅ [WS] Slot-Daten geladen: Slot %d hat Drink %s", slotNumber, drink.Name)
		}
	} else {
		// Slot ist leer
		slot.Drink = nil
		log.Printf("✅ [WS] Slot %d wurde geleert", slotNumber)
	}
	
	// Bestimme die Action basierend auf dem drinkID-Wert
	action := "cleared"
	if drinkID != nil && *drinkID > 0 {
		action = "updated"
	}
	
	message := WebSocketMessage{
		Type: MessageTypeSlotUpdate,
		Data: map[string]interface{}{
			"action": action,
			"slot":   slot,
		},
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Slot Update: %s (Slot: %d, Hardware: %d)", action, slotNumber, hardwareID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Slot Update: %v", err)
	}
}

// BroadcastFavoriteUpdate sendet Favorite-Updates via WebSocket
func BroadcastFavoriteUpdate(db *sql.DB, userID int, recipeID int, action string) {
	var recipe *models.Recipe_Response = nil
	
	// Bei CREATE-Aktionen senden wir die kompletten Recipe-Daten
	if action == "created" {
		// Hole Hardware-ID für das Recipe
		var hardwareID int
		err := db.QueryRow("SELECT hardware_id FROM recipes WHERE recipe_id = $1", recipeID).Scan(&hardwareID)
		if err != nil {
			log.Printf("❌ [WS] Fehler beim Laden der Hardware-ID für Recipe %d: %v", recipeID, err)
		} else {
			// Verwende die bestehende Recipe-Loading-Logik
			var recipeData models.Recipe
			var drinkIDsJSON []byte
			err := db.QueryRow(query.GetRecipeByID(), recipeID, hardwareID).Scan(
				&recipeData.ID, 
				&recipeData.HardwareID, 
				&recipeData.Name, 
				&recipeData.Picture, 
				&drinkIDsJSON,
			)
			if err == nil {
				// Hole Ingredients (vereinfachte Version)
				ingredientsAll := []models.IngredientResponse{}
				recipe = &models.Recipe_Response{
					ID:          recipeData.ID,
					HardwareID:  recipeData.HardwareID,
					Name:        recipeData.Name,
					Picture:     recipeData.Picture,
					Ingredients: ingredientsAll,
				}
			}
		}
	}
	
	messageData := map[string]interface{}{
		"action":    action,
		"user_id":   userID,
		"recipe_id": recipeID,
	}
	
	if recipe != nil {
		messageData["recipe"] = recipe
	}
	
	message := WebSocketMessage{
		Type: MessageTypeFavoriteUpdate,
		Data: messageData,
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Favorite Update: %s (User: %d, Recipe: %d)", action, userID, recipeID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Favorite Update: %v", err)
	}
}

// BroadcastIngredientUpdate sendet Ingredient-Updates via WebSocket
func BroadcastIngredientUpdate(db *sql.DB, recipeID int, drinkID int, action string) {
	var ingredient *models.IngredientResponse = nil
	
	// Bei CREATE und UPDATE-Aktionen senden wir die kompletten Ingredient-Daten
	if action != "deleted" {
		// Hole Hardware-ID für das Recipe
		var hardwareID int
		err := db.QueryRow("SELECT hardware_id FROM recipes WHERE recipe_id = $1", recipeID).Scan(&hardwareID)
		if err != nil {
			log.Printf("❌ [WS] Fehler beim Laden der Hardware-ID für Recipe %d: %v", recipeID, err)
		} else {
			// Hole Ingredient-Daten
			var ingredientData models.Ingredient
			err := db.QueryRow("SELECT recipe_id, drink_id, quantity_ml FROM recipe_ingredients WHERE recipe_id = $1 AND drink_id = $2", recipeID, drinkID).Scan(
				&ingredientData.RecipeID, 
				&ingredientData.DrinkID, 
				&ingredientData.Quantity_ml,
			)
			if err != nil {
				log.Printf("❌ [WS] Fehler beim Laden der Ingredient-Daten: %v", err)
			} else {
				// Hole Drink-Details
				var drink models.Drink
				err := db.QueryRow(query.GetDrinkByID(), drinkID, hardwareID).Scan(
					&drink.DrinkID, 
					&drink.HardwareID, 
					&drink.Name, 
					&drink.Alcoholic,
				)
				if err != nil {
					log.Printf("❌ [WS] Fehler beim Laden der Drink-Details für Ingredient: %v", err)
				} else {
					ingredient = &models.IngredientResponse{
						Quantity_ml: ingredientData.Quantity_ml,
						Drink:       drink,
					}
					log.Printf("✅ [WS] Ingredient-Daten geladen: Recipe %d, Drink %s", recipeID, drink.Name)
				}
			}
		}
	}
	
	messageData := map[string]interface{}{
		"action":    action,
		"recipe_id": recipeID,
		"drink_id":  drinkID,
	}
	
	if ingredient != nil {
		messageData["ingredient"] = ingredient
	}
	
	message := WebSocketMessage{
		Type: MessageTypeIngredientUpdate,
		Data: messageData,
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Ingredient Update: %s (Recipe: %d, Drink: %d)", action, recipeID, drinkID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Ingredient Update: %v", err)
	}
}

// ==============================================================================================
// STATUS- UND UTILITY-FUNKTIONEN (unverändert)
// ==============================================================================================

func IsUserOnline(userID int) bool {
	frontendClientManager.mutex.RLock()
	defer frontendClientManager.mutex.RUnlock()
	_, exists := frontendClientManager.clients[userID]
	return exists
}

func GetConnectedClientsCount() int {
	frontendClientManager.mutex.RLock()
	defer frontendClientManager.mutex.RUnlock()
	return len(frontendClientManager.clients)
}

func GetConnectedClientsInfo() []map[string]interface{} {
	frontendClientManager.mutex.RLock()
	defer frontendClientManager.mutex.RUnlock()
	
	var clients []map[string]interface{}
	for userID, client := range frontendClientManager.clients {
		clients = append(clients, map[string]interface{}{
			"user_id":         userID,
			"last_activity":   client.LastActivity.Format(time.RFC3339),
			"send_queue_size": len(client.Send),
		})
	}
	return clients
}

func GetWebSocketStatus(w http.ResponseWriter, r *http.Request) {
	status := map[string]interface{}{
		"connected_clients": GetConnectedClientsCount(),
		"clients_info":      GetConnectedClientsInfo(),
		"timestamp":         time.Now().Format(time.RFC3339),
		"websocket_config": map[string]interface{}{
			"read_buffer_size":  1024,
			"write_buffer_size": 1024,
			"ping_interval":     "54s",
			"read_timeout":      "60s",
		},
		"features": []string{
			"real_time_updates",
			"full_data_sync",
			"ping_pong",
			"auto_reconnect",
			"complete_entity_data",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
	log.Printf("📊 [WS] Status abgerufen: %d Clients verbunden", GetConnectedClientsCount())
}