package handlers

import (
	models "app/internal/models"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"
	"os"

	utils "app/internal/utils"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return r.Header.Get("Hardware-Auth-Key") == os.Getenv("HARDWARE_AUTH_KEY")
	},
}

var hardwareConnections = make(map[string]*websocket.Conn) // Speichert Verbindungen nach Hardware-ID

func Socket(w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /socket at %s", time.Now())

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Default().Println("WebSocket upgrade failed:", err)
		return
	}
	defer conn.Close()

	hardwareID := "2" //r.URL.Query().Get("id") // Hardware-ID zur Identifikation
	if hardwareID == "" {
		log.Default().Println("Hardware ID missing")
		return
	}

	hardwareConnections[hardwareID] = conn // Verbindung speichern
	log.Default().Printf("Hardware %s connected", hardwareID)

	// Hält die Verbindung aktiv, liest Nachrichten (optional)
	for {
		_, resMsgRaw, err := conn.ReadMessage()
		if err != nil {
			log.Default().Println("Error reading from WebSocket:", err)
			delete(hardwareConnections, hardwareID)
			break
		}
		// TODO: Fehlermeldungen verarbeiten und an User zurückgeben  
		var resMsg models.ResponseMsg
		err = json.Unmarshal(resMsgRaw, &resMsg)
		if err != nil {
			http.Error(w, "Invalid request payload", http.StatusBadRequest)
			return
		}

		switch resMsg.Type {
		case models.Info:
			log.Default().Printf("Info: %s", resMsg.Message)
		case models.Warn:
			log.Default().Printf("Warn: %s", resMsg.Message)
		case models.Error:
			log.Default().Printf("Error: %s", resMsg.Message)
		case models.Fatal:
			log.Default().Printf("Fatal: %s", resMsg.Message)
		case models.Success:
			log.Default().Printf("Success: %s", resMsg.Message)
		}

	}
}

func SendCommandToHardware(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /action at %s", time.Now())

	// Deserialise the request body
	var instruction models.Instruction
	err := json.NewDecoder(r.Body).Decode(&instruction)
	if err != nil {
		log.Default().Printf("Failed to decode request body: %s", err)
		http.Error(w, "Failed to decode request body", http.StatusBadRequest)
		return
	}

	hardwareID := instruction.Hardware_id
	if hardwareID == nil {
		log.Default().Printf("Missing hardware_id: %s", err)
		http.Error(w, "Missing hardware_id", http.StatusBadRequest)
		return
	}

	conn, exists := hardwareConnections[strconv.Itoa(*hardwareID)]
	if !exists {
		log.Default().Printf("Hardware %d not connected", hardwareID)
		http.Error(w, "Hardware not connected", http.StatusNotFound)
		return
	}

	command := instruction.Recipe_id
	if command == nil {
		log.Default().Printf("Missing RecipeID: %s", err)
		http.Error(w, "Missing command", http.StatusBadRequest)
		return
	}

	log.Default().Printf("BEFORE THE CONVERSION IT WORKS")
	recipeIdInt := strconv.Itoa(*command)

	log.Default().Printf("BEFORE THE MAPPER IT WORKS")

	result, protokollMapperError := utils.CocktailProtokollMapper(db, *hardwareID, recipeIdInt, r)

	log.Default().Printf("AFTER MAPPER IT WORKS (GUESS NOt, but maybeee)")
	if protokollMapperError != nil {
		if protokollMapperError.Error() == "failed to get hardware from Database" {
			http.Error(w, "Not authorized for this hardware", http.StatusUnauthorized)
			return
		}
		log.Default().Println("Failed to map recipe to protocol:", protokollMapperError)
		http.Error(w, "Failed to map recipe to protocol", http.StatusInternalServerError)
		return
	}

	err = conn.WriteMessage(websocket.TextMessage, []byte(result))

	if err != nil {
		log.Default().Println("Failed to send command:", err)
		http.Error(w, "Failed to send command", http.StatusInternalServerError)
		return
	}

	w.Write([]byte("Command sent successfully"))
}
