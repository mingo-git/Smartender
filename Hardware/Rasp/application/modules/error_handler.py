from enum import Enum
import asyncio
import websocket
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
    def __init__(self, websocket_instance):
        self._websocket_instance = websocket_instance
        self.logger = Logger()
    
    async def send_error(self, error_code, message=None):
        """Send an error code and optional message via WebSocket."""
        if not self._websocket_instance:
            print("No WebSocket connection available.")
            self.logger.log("ERROR", "No WebSocket connection", "ErrorHandler")
            return
        
        payload = {
            "type": "ERROR",
            "message": message or "No additional information."
        }

        self. logger.log("ERROR", f"Error reported: {payload}", "ErrorHandler") 

        try:
            await self._websocket_instance.send(str(payload))
            self.logger.log("ERROR", f"Error reported: {payload}", "ErrorHandler")
        except Exception as e:
            print(f"Failed to send error: {e}")
            self.logger.log("ERROR", f"Failed to send error: {e}", "ErrorHandler")