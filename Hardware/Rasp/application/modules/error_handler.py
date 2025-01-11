from enum import Enum
import asyncio
import websockets
from rx import create
from rx.subject import Subject
from modules.utils.logger import Logger



class ErrorCode(Enum):
    UNKNOWN_ERROR = 1
    NETWORK_DISCONNECTED = 2
    SCALE_EXCEPTION = 3
    UNKNOWN_POSITION = 4
    BUSY = 5
    INVALID_COMMAND = 6
    INVALID_PARAMETER = 7
    INVALID_STATE = 8
    ABORTION = 9

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
            self.logger.log("ERROR", "No WebSocket connection", "ErrorHandler")
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
        
        Possible error codes:
            - ErrorCode.UNKNOWN_ERROR
            - ErrorCode.NETWORK_DISCONNECTED
            - ErrorCode.SCALE_EXCEPTION
            - ErrorCode.UNKNOWN_POSITION
            - ErrorCode.BUSY
            - ErrorCode.INVALID_COMMAND
            - ErrorCode.INVALID_PARAMETER
            - ErrorCode.INVALID_STATE
            - ErrorCode.ABORTION

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