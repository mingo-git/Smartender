from modules.websocket_handler import WebSocketHandler
from modules.command_mapper import CommandMapper
from modules.motor_controller import MotorController
from modules.position_handler import PositionHandler
from modules.pump_controller import PumpController
from modules.weight_sensor import WeightSensor
from modules.actuator_controller import ActuatorController
# --------------------------------------------------------------------------------------------------
from modules.utils.logger import Logger
from modules.error_handler import ErrorHandler


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
    error_handler = ErrorHandler(websocket_instance=websocket_handler.ws)
    # TODO: pass error_handler to controllers and handlers
    # 
    #  - [ ] command_mapper
    #  - [?] motor_controller
    #  - [?] position_handler
    #  - [?] pump_controller
    #  - [?] weight_sensor
    #  - [?] actuator_controller
    #  - [ ] led_controller

    # Initialize CommandMapper
    command_mapper = CommandMapper()

    # Initialize Hardware Components
    motor_controller = MotorController(dir_pin=16, pull_pin=12, error_handler=error_handler)
    position_handler = PositionHandler(limit_switch_pins=[4, 17, 27, 22, 10, 9])  # Limit switches 0-5
    pump_controller = PumpController(pump_pins=[0, 5, 6, 13, 19, 26])  # Pumps for slots 6-11
    weight_sensor = WeightSensor(dt_pin=20, sck_pin=21)
    actuator_controller = ActuatorController(in_pins=[25, 8, 7, 1])

    logger.log("INFO", "Hardware components initialized", "Main")

    # Subscribe to WebSocket messages
    websocket_handler.message_subject.subscribe(
        on_next=lambda message: process_message(
            message, command_mapper, motor_controller, pump_controller, actuator_controller, position_handler, weight_sensor, logger
        ),
        on_error=lambda e: logger.log("ERROR", f"WebSocket stream error: {e}", "Main"),
        on_completed=lambda: logger.log("INFO", "WebSocket stream completed", "Main"),
    )

    # Start WebSocket handler
    websocket_handler.start()

    try:
        # Keep the main thread running
        while True:
            pass  # Main thread remains active
    except KeyboardInterrupt:
        logger.log("INFO", "Application is shutting down", "Main")
        websocket_handler.stop()
    finally:
        # Cleanup hardware components
        motor_controller.cleanup()
        position_handler.cleanup()
        pump_controller.cleanup()
        actuator_controller.cleanup()
        logger.log("INFO", "Hardware components cleaned up", "Main")


def process_message(message, command_mapper, motor_controller, pump_controller, actuator_controller, position_handler, weight_sensor, logger):
    """
    Process a single WebSocket message.

    Args:
        message (str): The WebSocket message received.
        command_mapper (CommandMapper): The CommandMapper instance.
        motor_controller (MotorController): The MotorController instance.
        pump_controller (PumpController): The PumpController instance.
        actuator_controller (ActuatorController): The ActuatorController instance.
        position_handler (PositionHandler): The PositionHandler instance.
        weight_sensor (WeightSensor): The WeightSensor instance.
        logger (Logger): The Logger instance.
    """
    logger.log("INFO", f"Processing message: {message}", "Main")
    commands = command_mapper.map_command(message)

    if commands:
        logger.log("INFO", f"Commands processed: {commands}", "Main")
        for command in commands:
            try:
                # Determine if the drink is alcoholic or non-alcoholic
                if 1 <= command.slot_number <= 5:  # Alcoholic (limit switches 1-5)
                    logger.log("INFO", f"Alcoholic drink: Slot {command.slot_number}", "Main")

                    # Move to the correct slot
                    logger.log("INFO", f"Moving to slot {command.slot_number}", "MotorController")
                    motor_controller.set_direction(1)
                    motor_controller.step_motor(200 * (command.slot_number - 1))

                    # Wait for the correct limit switch to be pressed
                    while position_handler.get_position() != command.slot_number:
                        pass

                    logger.log("INFO", f"Reached slot {command.slot_number}", "PositionHandler")

                    # Pour using the actuator
                    logger.log("INFO", f"Pouring from slot {command.slot_number}", "ActuatorController")
                    actuator_controller.activate(2)  # Duration placeholder

                elif 6 <= command.slot_number <= 11:  # Non-alcoholic (limit switch 0)
                    logger.log("INFO", f"Non-alcoholic drink: Slot {command.slot_number}", "Main")

                    # Ensure belt is at the home position (limit switch 0)
                    while position_handler.get_position() != 0:
                        motor_controller.set_direction(0)  # Move back to home
                        motor_controller.step_motor(200)

                    # Pump the drink
                    pump_index = command.slot_number - 6
                    logger.log("INFO", f"Activating pump {pump_index}", "PumpController")
                    pump_controller.activate_pump(pump_index, command.quantity_ml / 10)  # Placeholder logic

                # Check weight sensor for errors
                current_weight = weight_sensor.read_weight()
                logger.log("INFO", f"Current weight: {current_weight} g", "WeightSensor")

            except Exception as e:
                logger.log("ERROR", f"Error processing command: {e}", "Main")


if __name__ == "__main__":
    main()
