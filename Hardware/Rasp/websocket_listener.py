import websocket
import threading
import json
import time

# WebSocket URL
url = "wss://smartender-432708816033.europe-west3.run.app/smartender/socket"

# Headers required for connection
headers = {
    "x-api-key": "b0ec1aa3-98bd-434d-b6b6-f72b99383859",
    "Hardware-Auth-Key": "TODO: Add Hardware-Auth-Key",
}

# Define the on_message function to handle received messages
def on_message(ws, message):
    print("Received:", message)

# Define the on_error function to handle errors
def on_error(ws, error):
    print("Error:", error)

# Define the on_close function to handle connection closures
def on_close(ws, close_status_code, close_msg):
    print("Connection closed:", close_status_code, close_msg)

# Define the on_open function to handle the connection opening
def on_open(ws):
    print("Connected to WebSocket server")

# Create and run the WebSocket connection
if __name__ == "__main__":
    websocket.enableTrace(True)  # Enable debugging messages
    ws = websocket.WebSocketApp(
        url,
        header=headers,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close,
        on_open=on_open,
    )

    try:
        while True:
            try:
                # Run the WebSocket connection forever
                ws.run_forever()
            except Exception as e:
                print("Reconnecting after error:", e)
                time.sleep(5)  # Wait before retrying
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received. Exiting...")

# TODO:
# Add endpoint for WLAN oconfig transmission
# Add functionality to persist Configs [config.json]
# Add Bash scripte for WLAN config
# Execute Bash scrpt on incomming [POST] /config 
# Add Launch Demon to auto start python script
# share a tmux session
