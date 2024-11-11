package handlers

import (
	models "app/internal/models"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// TODO: Add origin check for 'Hardware-Auth-Key' header
	CheckOrigin: func(r *http.Request) bool {
		return r.Header.Get("Hardware-Auth-Key") == "TODO: Add Hardware-Auth-Key"
	}, // Akzeptiert alle Ursprünge, für Tests ok
}

var hardwareConnections = make(map[string]*websocket.Conn) // Speichert Verbindungen nach Hardware-ID

func Socket(w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /socket at %s", time.Now())

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade failed:", err)
		return
	}
	defer conn.Close()

	hardwareID := "1" //r.URL.Query().Get("id") // Hardware-ID zur Identifikation
	if hardwareID == "" {
		log.Println("Hardware ID missing")
		return
	}

	hardwareConnections[hardwareID] = conn // Verbindung speichern
	log.Printf("Hardware %s connected", hardwareID)

	// Hält die Verbindung aktiv, liest Nachrichten (optional)
	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			log.Println("Error reading from WebSocket:", err)
			delete(hardwareConnections, hardwareID)
			break
		}
		log.Printf("Message from hardware %s: %s", hardwareID, string(msg))
	}
}

func SendCommandToHardware(w http.ResponseWriter, r *http.Request) {
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
		log.Default().Printf("Hardware %s not connected", hardwareID)
		http.Error(w, "Hardware not connected", http.StatusNotFound)
		return
	}

	command := instruction.Recipe_id
	if command == nil {
		log.Default().Printf("Missing RecipeID: %s", err)
		http.Error(w, "Missing command", http.StatusBadRequest)
		return
	}

	commandStr := strconv.Itoa(*command)

	err = conn.WriteMessage(websocket.TextMessage, []byte(commandStr))
	if err != nil {
		log.Println("Failed to send command:", err)
		http.Error(w, "Failed to send command", http.StatusInternalServerError)
		return
	}

	w.Write([]byte("Command sent successfully"))
}
