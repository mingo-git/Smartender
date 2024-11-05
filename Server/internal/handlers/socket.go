package handlers

import (
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true }, // Akzeptiert alle Ursprünge, für Tests ok
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
	hardwareID := r.URL.Query().Get("hardware_id")
	if hardwareID == "" {
		http.Error(w, "Missing hardware_id", http.StatusBadRequest)
		return
	}

	conn, exists := hardwareConnections[hardwareID]
	if !exists {
		http.Error(w, "Hardware not connected", http.StatusNotFound)
		return
	}

	command := r.URL.Query().Get("command")
	if command == "" {
		http.Error(w, "Missing command", http.StatusBadRequest)
		return
	}

	err := conn.WriteMessage(websocket.TextMessage, []byte(command))
	if err != nil {
		log.Println("Failed to send command:", err)
		http.Error(w, "Failed to send command", http.StatusInternalServerError)
		return
	}

	w.Write([]byte("Command sent successfully"))
}
