package main

import (
    "encoding/json"
    "log"
    "os/exec"
    "time"
    "github.com/gorilla/websocket"
    "net/http"
)

// Define the message structure
type Message struct {
    Action string `json:"action"`
    Data   string `json:"data"`
}

// Backend WebSocket URL
const backendURL = "ws://10.27.1.2:8080/smartender/socket"

func main() {
    // Create headers to include in the WebSocket request
    headers := http.Header{}
    headers.Add("x-api-key", "b0ec1aa3-98bd-434d-b6b6-f72b99383859")
    headers.Add("Hardware-Auth-Key", "TODO: Add Hardware-Auth-Key")

    // Connect to the WebSocket server with headers
    conn, _, err := websocket.DefaultDialer.Dial(backendURL, headers)
    if err != nil {
        log.Fatal("Error connecting to WebSocket server:", err)
    }
    defer conn.Close()

    log.Println("Connected to WebSocket server")

    // Create a message to send
    message := Message{
        Action: "send_data",
        Data:   "Hello from Raspberry Pi!",
    }

    // Marshal the message to JSON
    jsonMessage, err := json.Marshal(message)
    if err != nil {
        log.Println("Error marshalling message:", err)
        return
    }

    // Send the message over the WebSocket connection
    err = conn.WriteMessage(websocket.TextMessage, jsonMessage)
    if err != nil {
        log.Println("Error sending message:", err)
        return
    }

    log.Println("Message sent:", string(jsonMessage))

    // Infinite loop to listen for messages from the backend
    for {
        _, message, err := conn.ReadMessage()
        if err != nil {
            log.Println("Error reading message:", err)
            time.Sleep(2 * time.Second) // Attempt reconnection if connection is lost
            conn, _, err = websocket.DefaultDialer.Dial(backendURL, headers) // Retry with headers
            if err != nil {
                log.Println("Reconnection failed:", err)
                continue
            }
            log.Println("Reconnected to WebSocket server")
        }
        log.Printf("Received command: %s\n", message)
        handleCommand(string(message))
    }
}

// Handle incoming commands (e.g., send data to Arduino)
func handleCommand(command string) {
    switch command {
    case "send_data":
        executeArduinoCommand("data_to_send") // Replace with actual data
    case "other_command":
        // Handle other commands as needed
    default:
        log.Println("Unknown command received:", command)
    }
}

// Execute a command to interact with the Arduino
func executeArduinoCommand(data string) {
    // Replace with actual interaction (e.g., Python script call)
    cmd := exec.Command("python3", "send_to_arduino.py", data)
    if err := cmd.Run(); err != nil {
        log.Println("Failed to execute command:", err)
    } else {
        log.Println("Command executed successfully")
    }
}

