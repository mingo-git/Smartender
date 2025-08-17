// internal/handlers/websocket_frontend.go
package handlers

import (
	auth "app/internal/auth"
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
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

// WebSocket Upgrader für Frontend (andere Konfiguration als für Hardware)
var frontendUpgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Für Entwicklung: Erlaube alle Origins
		// In Produktion: Spezifische Origins prüfen
		origin := r.Header.Get("Origin")
		log.Printf("🌐 WebSocket Origin: %s", origin)
		return true // Für Development - in Production einschränken
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
					"features":   []string{"real_time_updates", "ping_pong", "auto_reconnect"},
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
	log.Default().Printf("📱 [WS] Headers: %v", r.Header)

	// JWT aus Query Parameter oder Header extrahieren
	token := r.URL.Query().Get("token")
	if token == "" {
		token = r.Header.Get("Authorization")
		if token != "" {
			// "Bearer " prefix entfernen
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

	// Timeout-Konfiguration
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

		// Nachricht verarbeiten
		var message WebSocketMessage
		if err := json.Unmarshal(messageBytes, &message); err != nil {
			log.Printf("❌ [WS] Ungültiges Message Format von User %d: %v", c.UserID, err)
			continue
		}

		log.Printf("📨 [WS] Nachricht erhalten von User %d: %s", c.UserID, message.Type)

		// Handle verschiedene Message-Typen
		switch message.Type {
		case MessageTypePing:
			// Pong zurücksenden
			pongMsg := WebSocketMessage{
				Type:      MessageTypePong,
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
			// Optional: Bestätigung senden oder Client-Info verarbeiten

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

			// Mehrere Nachrichten in einem Write zusammenfassen
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

// Broadcast-Funktionen für verschiedene Datentypen

// Broadcast Drink Update an alle verbundenen Clients
func BroadcastDrinkUpdate(drinkID int, hardwareID int, action string) {
	message := WebSocketMessage{
		Type: MessageTypeDrinkUpdate,
		Data: map[string]interface{}{
			"drink_id":    drinkID,
			"hardware_id": hardwareID,
			"action":      action, // "created", "updated", "deleted"
		},
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Drink Update: %s (ID: %d, Hardware: %d)", action, drinkID, hardwareID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Drink Update: %v", err)
	}
}

// Broadcast Recipe Update
func BroadcastRecipeUpdate(recipeID int, hardwareID int, action string) {
	message := WebSocketMessage{
		Type: MessageTypeRecipeUpdate,
		Data: map[string]interface{}{
			"recipe_id":   recipeID,
			"hardware_id": hardwareID,
			"action":      action,
		},
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Recipe Update: %s (ID: %d, Hardware: %d)", action, recipeID, hardwareID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Recipe Update: %v", err)
	}
}

// Broadcast Slot Update
func BroadcastSlotUpdate(slotNumber int, hardwareID int, drinkID *int) {
	message := WebSocketMessage{
		Type: MessageTypeSlotUpdate,
		Data: map[string]interface{}{
			"slot_number": slotNumber,
			"hardware_id": hardwareID,
			"drink_id":    drinkID,
		},
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Slot Update: Slot %d, Hardware %d, Drink %v", slotNumber, hardwareID, drinkID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Slot Update: %v", err)
	}
}

// Broadcast Favorite Update
func BroadcastFavoriteUpdate(userID int, recipeID int, action string) {
	message := WebSocketMessage{
		Type: MessageTypeFavoriteUpdate,
		Data: map[string]interface{}{
			"user_id":   userID,
			"recipe_id": recipeID,
			"action":    action, // "added", "removed"
		},
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		log.Printf("📢 [WS] Broadcasting Favorite Update: %s (User: %d, Recipe: %d)", action, userID, recipeID)
		frontendClientManager.broadcast <- messageBytes
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast Favorite Update: %v", err)
	}
}

// Broadcast an spezifischen User
func BroadcastToUser(userID int, messageType string, data interface{}) {
	frontendClientManager.mutex.RLock()
	client, exists := frontendClientManager.clients[userID]
	frontendClientManager.mutex.RUnlock()

	if !exists {
		log.Printf("❌ [WS] User %d nicht verbunden für Broadcast %s", userID, messageType)
		return
	}

	message := WebSocketMessage{
		Type:      messageType,
		Data:      data,
		Timestamp: time.Now(),
	}

	if messageBytes, err := json.Marshal(message); err == nil {
		select {
		case client.Send <- messageBytes:
			log.Printf("📤 [WS] Nachricht an User %d gesendet: %s", userID, messageType)
		default:
			// Client Channel ist voll, Client entfernen
			log.Printf("⚠️ [WS] Client Channel voll für User %d, entferne Client", userID)
			frontendClientManager.unregister <- client
		}
	} else {
		log.Printf("❌ [WS] Fehler beim Broadcast an User %d: %v", userID, err)
	}
}

// Hilfsfunktion um zu prüfen ob ein User online ist
func IsUserOnline(userID int) bool {
	frontendClientManager.mutex.RLock()
	defer frontendClientManager.mutex.RUnlock()
	_, exists := frontendClientManager.clients[userID]
	return exists
}

// Anzahl der verbundenen Clients
func GetConnectedClientsCount() int {
	frontendClientManager.mutex.RLock()
	defer frontendClientManager.mutex.RUnlock()
	return len(frontendClientManager.clients)
}

// Detaillierte Client-Informationen für Debugging
func GetConnectedClientsInfo() []map[string]interface{} {
	frontendClientManager.mutex.RLock()
	defer frontendClientManager.mutex.RUnlock()
	
	var clients []map[string]interface{}
	for userID, client := range frontendClientManager.clients {
		clients = append(clients, map[string]interface{}{
			"user_id":       userID,
			"last_activity": client.LastActivity.Format(time.RFC3339),
			"connected_since": client.LastActivity.Format(time.RFC3339),
			"send_queue_size": len(client.Send),
		})
	}
	return clients
}

// WebSocket Status Handler (für Debugging)
func GetWebSocketStatus(w http.ResponseWriter, r *http.Request) {
	status := map[string]interface{}{
		"connected_clients": GetConnectedClientsCount(),
		"clients_info":      GetConnectedClientsInfo(),
		"timestamp":         time.Now().Format(time.RFC3339),
		"server_uptime":     time.Since(time.Now().Add(-time.Hour)).String(), // Placeholder
		"websocket_config": map[string]interface{}{
			"read_buffer_size":  1024,
			"write_buffer_size": 1024,
			"ping_interval":     "54s",
			"read_timeout":      "60s",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
	log.Printf("📊 [WS] Status abgerufen: %d Clients verbunden", GetConnectedClientsCount())
}