from modules.websocket_handler import WebSocketHandler
from modules.command_mapper import CommandMapper
from modules.utils.logger import Logger

def main():
    logger = Logger()

    # Log application start
    logger.log("INFO", "Application started", "Main")

    # Initialize WebSocketHandler
    url = "wss://smartender-432708816033.europe-west3.run.app/smartender/socket"
    headers = {
        "x-api-key": "b0ec1aa3-98bd-434d-b6b6-f72b99383859",
        "Hardware-Auth-Key": "TODO: Add Hardware-Auth-Key",
    }
    websocket_handler = WebSocketHandler(url, headers)

    # Initialize CommandMapper
    command_mapper = CommandMapper()

    # Subscribe to WebSocket messages
    websocket_handler.message_subject.subscribe(
        on_next=lambda message: process_message(message, command_mapper, logger),
        on_error=lambda e: logger.log("ERROR", f"WebSocket stream error: {e}", "Main"),
        on_completed=lambda: logger.log("INFO", "WebSocket stream completed", "Main"),
    )

    # Start WebSocket handler
    websocket_handler.start()

    try:
        # Keep the main thread running
        while True:
            pass  # Main thread remains active; add application logic here if needed
    except KeyboardInterrupt:
        logger.log("INFO", "Application is shutting down", "Main")
        websocket_handler.stop()

def process_message(message, command_mapper, logger):
    """
    Process a single WebSocket message.

    Args:
        message (str): The WebSocket message received.
        command_mapper (CommandMapper): The CommandMapper instance.
        logger (Logger): The Logger instance.
    """
    logger.log("INFO", f"Processing message: {message}", "Main")
    commands = command_mapper.map_command(message)
    if commands:
        logger.log("INFO", f"Commands processed: {commands}", "Main")
        # Additional processing can go here

if __name__ == "__main__":
    main()
