import websocket
import threading
import json
import time
from rx.subject import Subject
from modules.utils.logger import Logger


class WebSocketHandler:
    def __init__(self, url, headers):
        """
        Initialize the WebSocket client.

        :param url: WebSocket URL to connect to.
        :param headers: Headers required for WebSocket connection.
        """
        self.logger = Logger()
        self.url = url
        self.headers = headers
        self.ws = None
        self.running = False
        self.message_subject = Subject()  # RxPy Subject for emitting messages

    def on_message(self, ws, message):
        """
        Handle incoming WebSocket messages.

        :param ws: WebSocket instance.
        :param message: Received message.
        """
        self.logger.log("INFO", f"Received WebSocket message: {message}", "WebSocketHandler")
        self.message_subject.on_next(message)  # Emit message to subscribers

    def on_error(self, ws, error):
        """
        Handle WebSocket errors.

        :param ws: WebSocket instance.
        :param error: Error message.
        """
        self.logger.log("ERROR", f"WebSocket error: {error}", "WebSocketHandler")

    def on_close(self, ws, close_status_code, close_msg):
        """
        Handle WebSocket connection closures.

        :param ws: WebSocket instance.
        :param close_status_code: Close status code.
        :param close_msg: Close message.
        """
        self.logger.log("INFO", f"Connection closed: {close_status_code} {close_msg}", "WebSocketHandler")
        self.running = False

    def on_open(self, ws):
        """
        Handle WebSocket connection opening.

        :param ws: WebSocket instance.
        """
        self.logger.log("INFO", "Connected to WebSocket server", "WebSocketHandler")

    def connect(self):
        """
        Establish and maintain the WebSocket connection.
        """
        websocket.enableTrace(True)
        self.ws = websocket.WebSocketApp(
            self.url,
            header=self.headers,
            on_message=self.on_message,
            on_error=self.on_error,
            on_close=self.on_close,
            on_open=self.on_open,
        )
        self.running = True

        while self.running:
            try:
                self.ws.run_forever()
            except Exception as e:
                self.logger.log("ERROR", f"Reconnecting after error: {e}", "WebSocketHandler")
                time.sleep(5)  # Wait before retrying

        self.connect()

    def start(self):
        """
        Start the WebSocket client in a separate thread.
        """
        thread = threading.Thread(target=self.connect, daemon=True)
        thread.start()

    def stop(self):
        """
        Stop the WebSocket client.
        """
        self.running = False
        if self.ws:
            self.ws.close()
        self.logger.log("INFO", "WebSocket client stopped", "WebSocketHandler")
