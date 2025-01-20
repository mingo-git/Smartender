from modules.websocket_handler import WebSocketHandler
from modules.command_mapper import CommandMapper
from modules.utils.logger import Logger
from modules.motor_controller import MotorController
from modules.position_handler import PositionHandler
from modules.pump_controller import PumpController
from modules.weight_sensor import WeightSensor
from modules.actuator_controller import ActuatorController
from modules.led_controller import LEDController
# --------------------------------------------------------------------------------------------------
from modules.utils.logger import Logger
from modules.error_handler import ErrorHandler
# --------------------------------------------------------------------------------------------------
from rx import create
from rx.subject import Subject
import time
from dotenv import load_dotenv
import os
import uuid
# --------------------------------------------------------------------------------------------------

def main():
    logger = Logger()
    logger.log("INFO", "Application started", "Main")

    # Initialize WebSocketHandler
    url = "wss://smartender-432708816033.europe-west3.run.app/smartender/socket"
    # Load environment variables from .env file
    load_dotenv()
    
    mac = uuid.getnode()
    mac_address = ':'.join(f'{(mac >> i) & 0xFF:02x}' for i in range(40, -1, -8))
    
    headers = {
        "x-api-key": os.getenv("X_API_KEY"),
        "Hardware-Auth-Key": os.getenv("HARDWARE_AUTH_KEY"),
        "Identifier": mac_address,
    }

    logger.log("INFO", headers, "Main")

    websocket_handler = WebSocketHandler(url, headers)
    # Initialize CommandMapper
    command_mapper = CommandMapper()

    # Initialize Hardware Components
    position_handler = PositionHandler(limit_switch_pins=[4, 17, 27, 22, 10, 9])
    weight_sensor = WeightSensor(dt_pin=20, sck_pin=21)
    motor_controller = MotorController(dir_pin=16, pull_pin=12)
    pump_controller = PumpController(pump_pins=[0, 5, 6, 13, 19, 26], weight_sensor=weight_sensor, position_handler=position_handler)
    actuator_controller = ActuatorController(
        in_pins={"in3": 7, "in4": 1},
        weight_sensor=weight_sensor,
        position_handler=position_handler,
    )
    led_controller = LEDController(LV1_pin=18)

    # Extract subscriptions to subjects from the hardware components
    motor_controller_subject = motor_controller.subscribe()
    position_handler_subject = position_handler.subscribe()
    pump_controller_subject = pump_controller.subscribe()
    weight_sensor_subject = weight_sensor.subscribe()
    # actuator_controller_subject = actuator_controller.subscribe()

    error_handler = ErrorHandler(websocket_instance=websocket_handler.ws)
    # TODO: pass error_handler to controllers and handlers
    # 
    #  - [ ] command_mapper
    #  - [x] motor_controller
    #  - [x] position_handler
    #  - [x] pump_controller
    #  - [x] weight_sensor
    #  - [x] actuator_controller
    #  - [ ] led_controller

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
    #actuator_controller._move_down(3)
    led_controller.progress_bar()
    #time.sleep(2)

    actuator_controller._move_down(1)

    # Move stepper motor to position 0
    if not position_handler.is_home_position():
        motor_controller.rotate_stepper_pigpio(500, 0, 2000)
        motor_controller.rotate_until_limit(0, position_handler, 1, 1000)


    try:
        # Keep the main thread running
        while True:
            pass
    except KeyboardInterrupt:
        logger.log("INFO", "Application is shutting down", "Main")
        websocket_handler.stop()
    finally:
        # Cleanup hardware components
        motor_controller.cleanup()
        position_handler.cleanup()
        pump_controller.cleanup()
        actuator_controller.cleanup()
        led_controller.cleanup()
        #weight_sensor.cleanup()
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
        sorted_commands = sorted(commands, key=lambda item: item.slot_number)

        motor_controller.rotate_until_limit(2, position_handler, 0, 1000)
        time.sleep(3)

        actuator_controller._move_up(2.7)
        time.sleep(10)
        actuator_controller._move_down(3.5)
        #led_controller.progress_bar()
        #motor_controller.rotate_stepper_pigpio(1000, 0, 1000)
        motor_controller.rotate_until_limit(0, position_handler, 1, 1000)
        return 
        #time.sleep(1000)

        logger.log("INFO", f"Commands processed: {sorted_commands}", "Main")
        for command in sorted_commands:
            try:
                # pump_controller.activate_pump(5, 3)  # Placeholder logic
                # Determine if the drink is alcoholic or non-alcoholic
                if 1 <= command.slot_number <= 5:  # Alcoholic
                    logger.log("INFO", f"Alcoholic drink: Slot {command.slot_number}", "Main")

                    # Move to the correct slot with acceleration
                    logger.log("INFO", f"Moving to slot {command.slot_number} with acceleration", "MotorController")

                    # Rotate the stepper motor and stop when the limit switch is pressed
                    motor_controller.rotate_until_limit(command.slot_number, position_handler, 0)
                    logger.log("INFO", f"Moved to slot {command.slot_number}", "MotorController")
                    time.sleep(2)

                    if position_handler.get_position() != command.slot_number:
                        logger.log("ERROR", "Failed to reach the correct slot", "Main")
                        break

                    logger.log("INFO", f"Reached slot {command.slot_number}", "Main")

                    # Pour using the actuator
                    logger.log("INFO", f"Pouring from slot {command.slot_number}", "Main")
                    actuator_controller._move_up(2.7)
                    time.sleep(10)
                    actuator_controller._move_down(3)

                elif 6 <= command.slot_number <= 11:  # Non-alcoholic
                    logger.log("INFO", f"Non-alcoholic drink: Slot {command.slot_number}", "Main")

                    # Ensure belt is at the home position (limit switch 0)
                    if position_handler.get_position() != 0:
                        motor_controller.rotate_until_limit(0, position_handler, 1, 1000)

                    if position_handler.get_position() != 0:
                        logger.log("ERROR", "Failed to return to home position", "Main")
                        break

                    time.sleep(0.5)
                    # Pump the drink
                    pump_index = command.slot_number - 6
                    logger.log("INFO", f"Activating pump {pump_index}", "Main")
                    actuator_controller._move_up(5)
                    pump_controller.activate_pump(pump_index, command.quantity_ml/100)
                    actuator_controller._move_down(6)
                else:
                    logger.log("ERROR", "Invalid slot number", "Main")
                    break

                # # Check weight sensor for errors
                # current_weight = weight_sensor.read_weight()
                # logger.log("INFO", f"Current weight: {current_weight} g", "Main")
                
                # if current_weight > 395:
                #     logger.log("ERROR", "Weight to high, potential physical Overflow", "Main")
                #     break


            except Exception as e:
                logger.log("ERROR", f"Error processing command: {e}", "Main")
        if position_handler.get_position() != 0:
            logger.log("INFO", "Moving to slot 0", "Main")
            motor_controller.rotate_stepper_pigpio(500, 0, 2000)
            motor_controller.rotate_until_limit(0, position_handler, 1)
    else:
        logger.log("ERROR", "No Commands received", "Main")


if __name__ == "__main__":
    main()
