from enum import Enum
import asyncio
import websockets
from rx import create
from rx.subject import Subject
from modules.utils.logger import Logger



class ErrorCode(Enum):
    SENSOR_FAILURE = 1001
    NETWORK_DISCONNECTED = 1002
    HIGH_TEMPERATURE = 1003
    LOW_BATTERY = 1004
    UNKNOWN_ERROR = 1005

class ErrorHandler:
    def __init__(self, websocket_url, websocket_instance):
        self._websocket_url = websocket_url
        self._websocket_instance = websocket_instance
        self._subscriptions = []
        self.logger = Logger()
    
    async def send_error(self, error_code, message=None):
        """Send an error code and optional message via WebSocket."""
        if not self._websocket_instance:
            print("No WebSocket connection available.")
            self.logger.log("ERROR", "No WebSocket connection available.", "ErrorHandler")
            return
        
        payload = {
            "error_code": error_code.value,
            "error_name": error_code.name,
            "message": message or "No additional information."
        }
        try:
            await self._websocket_instance.send(str(payload))
            print(f"Error reported: {payload}")
            self.logger.log("ERROR", f"Error reported: {payload}", "ErrorHandler")
        except Exception as e:
            print(f"Failed to send error: {e}")
            self.logger.log("ERROR", f"Failed to send error: {e}", "ErrorHandler")
    
    def subscribe_to_stream(self, observable, error_code, message_resolver=None):
        """
        Subscribe to an observable stream and react to errors.

        Args:
            observable: The rxpy observable stream.
            error_code: The ErrorCode to send when the stream emits an event.
            message_resolver: Optional function to create a message based on the emitted value.
        """
        def on_next(value):
            message = message_resolver(value) if message_resolver else None
            asyncio.create_task(self.send_error(error_code, message))
        
        subscription = observable.subscribe(on_next)
        self._subscriptions.append(subscription)
    
    def unsubscribe_all(self):
        """Unsubscribe from all streams."""
        for subscription in self._subscriptions:
            subscription.dispose()
        self._subscriptions = []