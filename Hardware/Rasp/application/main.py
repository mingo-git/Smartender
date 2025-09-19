from modules.websocket_handler import WebSocketHandler
from modules.command_mapper import CommandMapper
from modules.utils.logger import Logger
from modules.motor_controller import MotorController
from modules.position_handler import PositionHandler
from modules.pump_controller import PumpController
from modules.weight_sensor import WeightSensor
from modules.actuator_controller_bts7960 import ActuatorControllerBTS7960
from modules.led_controller import LEDController
# --------------------------------------------------------------------------------------------------
from modules.utils.logger import Logger
from modules.error_handler import ErrorHandler
# --------------------------------------------------------------------------------------------------
from rx import create
from rx.subject import Subject
import time
import json
from dotenv import load_dotenv
import os
import sys
import traceback
import uuid
import math
# --------------------------------------------------------------------------------------------------

def main():
    print("[HW] Starting Smartender hardware...", flush=True)
    logger = Logger()
    logger.log("INFO", "Application started", "Main")
    try:
        with open("boot_marker.txt", "a") as f:
            f.write(f"Boot at {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
    except Exception as e:
        logger.log("WARNING", f"Could not write boot_marker: {e}", "Main")

    # Load environment variables from .env file EARLY
    load_dotenv()

    # Initialize WebSocketHandler (.env-driven with safe fallback)
    url = os.getenv("SMARTENDER_WS_URL", "wss://smartender.lextron.dev/smartender/socket")
    print(f"[HW] WS URL: {url}", flush=True)
    
    # Allow overriding MAC for single-device mode via env STATIC_MAC
    static_mac = os.getenv("STATIC_MAC")
    if static_mac and isinstance(static_mac, str) and len(static_mac) >= 11:
        mac_address = static_mac
    else:
        mac = uuid.getnode()
        mac_address = ':'.join(f'{(mac >> i) & 0xFF:02x}' for i in range(40, -1, -8))
    
    headers = {
        "x-api-key": os.getenv("X_API_KEY"),
        "Hardware-Auth-Key": os.getenv("HARDWARE_AUTH_KEY"),
        "Identifier": mac_address,
    }

    logger.log("INFO", headers, "Main")
    print(f"[HW] Headers prepared: {headers}", flush=True)

    websocket_handler = WebSocketHandler(url, headers)
    # Initialize CommandMapper
    command_mapper = CommandMapper()

    # Initialize Hardware Components
    print("[HW] Initializing hardware components...", flush=True)
    position_handler = PositionHandler(limit_switch_pins=[4, 17, 27, 22, 10, 9])
    weight_sensor = WeightSensor(dt_pin=20, sck_pin=21)
    motor_controller = MotorController(dir_pin=16, pull_pin=12)
    # Free a PWM-capable pin for LEDs: move pump (index 3) from GPIO13 -> GPIO7
    pump_controller = PumpController(pump_pins=[0, 5, 6, 7, 19, 26], weight_sensor=weight_sensor, position_handler=position_handler)
    # Actuator via BTS7960 driver (replaces relay-based controller)
    actuator_controller = ActuatorControllerBTS7960(
        pins={"r_en": 23, "l_en": 24, "r_pwm": 18, "l_pwm": 25},
        weight_sensor=weight_sensor,
        position_handler=position_handler,
        pwm_freq_hz=1000,
        invert=False,  # set True if your OUT/IN orientation is reversed
    )
    # LED Controller hardcoded (no ENV). Start OFF; only App may enable later.
    led_controller = None
    try:
        LED_PIN = 13          # WS281x DIN on GPIO13 (PWM Channel 1)
        LED_COUNT = 41        # number of LEDs
        LED_BRIGHTNESS = 160  # 0..255
        led_controller = LEDController(LV1_pin=LED_PIN, led_count=LED_COUNT, brightness=LED_BRIGHTNESS)
        # Ensure LEDs are OFF at boot
        led_controller.set_off()
    except Exception as e:
        logger.log("ERROR", f"LED init failed: {e}", "Main")

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
    print("[HW] Hardware components initialized", flush=True)

    # Subscribe to WebSocket messages
    websocket_handler.message_subject.subscribe(
        on_next=lambda message: process_message(
            message, command_mapper, motor_controller, pump_controller, actuator_controller, position_handler, weight_sensor, logger, led_controller
        ),
        on_error=lambda e: logger.log("ERROR", f"WebSocket stream error: {e}", "Main"),
        on_completed=lambda: logger.log("INFO", "WebSocket stream completed", "Main"),
    )

    # Start WebSocket handler
    websocket_handler.start()
    print("[HW] WebSocket handler started (background thread)", flush=True)
    #actuator_controller._move_down(3)
    #time.sleep(2)

    logger.log("INFO", "Initial actuator move down (1s)", "Main")
    print("[HW] Actuator: move down 1s", flush=True)
    actuator_controller._move_down(1)

    # Move stepper motor to position 0
    logger.log("INFO", "Checking home position (slot 0)", "Main")
    print("[HW] Checking home position (slot 0)", flush=True)
    if not position_handler.is_home_position():
        logger.log("INFO", "Not at home; nudging and homing", "Main")
        try:
            print("[HW] Nudge 500 steps dir=0 @2kHz", flush=True)
            motor_controller.rotate_stepper_pigpio(500, 0, 2000)
            motor_controller.rotate_until_limit(0, position_handler, 1, 1000)
            logger.log("INFO", "Homing complete (slot 0)", "Main")
            print("[HW] Homing complete (slot 0)", flush=True)
        except Exception as e:
            logger.log("ERROR", f"Homing error: {e}", "Main")
            print(f"[HW] Homing error: {e}", flush=True)
    else:
        logger.log("INFO", "Already at home position", "Main")
        print("[HW] Already at home position", flush=True)


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
        #led_controller.cleanup()
        #weight_sensor.cleanup()
        logger.log("INFO", "Hardware components cleaned up", "Main")


def process_message(message, command_mapper, motor_controller, pump_controller, actuator_controller, position_handler, weight_sensor, logger, led_controller=None):
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

    # First try maintenance pipeline: expects a JSON with top-level key "maintenance"
    try:
        parsed = json.loads(message)
        if isinstance(parsed, dict) and "maintenance" in parsed:
            maintenance = parsed.get("maintenance", {}) or {}
            process_maintenance(
                maintenance=maintenance,
                motor_controller=motor_controller,
                pump_controller=pump_controller,
                actuator_controller=actuator_controller,
                position_handler=position_handler,
                logger=logger,
                led_controller=led_controller,
            )
            return
    except Exception as e:
        # Not a maintenance message or invalid JSON; fall back to cocktail command mapping
        logger.log("DEBUG", f"Maintenance parse skipped: {e}", "Main")

    # Cocktail commands (legacy mapping)
    commands = command_mapper.map_command(message)

    if commands:
        sorted_commands = sorted(commands, key=lambda item: item.slot_number)

        #motor_controller.rotate_until_limit(1, position_handler, 0, 1000)
        #time.sleep(3)

        #actuator_controller._move_up(2.7)
        #time.sleep(10)
        #actuator_controller._move_down(3.5)
        #led_controller.progress_bar()
        #motor_controller.rotate_stepper_pigpio(4000, 0, 10000)
        #motor_controller.rotate_until_limit(0, position_handler, 1, 1000)
        #pump_controller.activate_pump(0, 4)
        #return 
        #time.sleep(1000)

        logger.log("INFO", f"Commands processed: {sorted_commands}", "Main")
        for idx, command in enumerate(sorted_commands):
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

                    pump_amount = math.ceil(command.quantity_ml/40)
                    # Progress visualization (if LEDs enabled)
                    if led_controller:
                        total_steps = max(1, pump_amount)
                        led_controller.set_progress(0.0)

                    for i in range(pump_amount):
                        # Pour using the actuator
                        logger.log("INFO", f"Pouring from slot {command.slot_number}", "Main")
                        actuator_controller._move_up(2.7)
                        time.sleep(6)
                        actuator_controller._move_down(3)
                        if led_controller:
                            led_controller.set_progress((i + 1) / float(pump_amount))

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
                    pump_controller.activate_pump(pump_index, command.quantity_ml/32.5)
                    actuator_controller._move_down(6)
                    if led_controller:
                        led_controller.set_progress(1.0)
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
            logger.log("INFO", "Returning to home (slot 0)", "Main")
            # Remove unintended pre-move in opposite direction; go straight to home
            motor_controller.rotate_until_limit(0, position_handler, 1)
        else:
            logger.log("ERROR", "No Commands received", "Main")


def process_maintenance(maintenance, motor_controller, pump_controller, actuator_controller, position_handler, logger, led_controller=None):
    """
    Handle maintenance commands sent from the backend.

    Expected structure: { "type": "...", other fields }
    Supported types (initial):
      - manual_move: fields x (-100..100), z (-100..100)
      - emergency_stop
      - light, flush_* (ignored/logged for now)
    """
    try:
        mtype = maintenance.get("type")
        logger.log("INFO", f"Maintenance command type: {mtype}", "Maintenance")

        if mtype == "manual_move":
            # Horizontal axis (stepper)
            x = maintenance.get("x")
            if isinstance(x, (int, float)) and abs(x) > 1:
                direction = 1 if x > 0 else 0
                steps = int(max(0, min(1000, abs(x) * 10)))  # scale: 0..1000 steps
                freq = 2000
                logger.log("INFO", f"Manual X move: dir={direction} steps={steps} freq={freq}", "Maintenance")
                if steps > 0:
                    motor_controller.rotate_stepper_pigpio(steps, direction, freq)

            # Vertical axis (linear actuator via driver)
            z = maintenance.get("z")
            if isinstance(z, (int, float)) and abs(z) > 1:
                duration = 0.05 + (min(100.0, abs(float(z))) * 0.01)  # 0.05..1.05s
                if z > 0:
                    logger.log("INFO", f"Manual Z move: up {duration:.2f}s", "Maintenance")
                    actuator_controller._move_up(duration)
                else:
                    logger.log("INFO", f"Manual Z move: down {duration:.2f}s", "Maintenance")
                    actuator_controller._move_down(duration)

            return

        if mtype == "emergency_stop":
            try:
                # Stop PWM on stepper and stop actuator
                motor_controller.pi.hardware_PWM(motor_controller.pull_pin, 0, 0)
            except Exception:
                pass
            try:
                actuator_controller._emergency_stop()
            except Exception:
                pass
            logger.log("ALERT", "Emergency stop executed", "Maintenance")
            return

        if mtype == "pump":
            try:
                idx = maintenance.get("index")
                action = maintenance.get("action")
                if not isinstance(idx, int):
                    logger.log("ERROR", f"Invalid pump index: {idx}", "Maintenance")
                    return
                logger.log("INFO", f"Pump hold: idx={idx} action={action}", "Maintenance")

                # Ensure home position for safety
                if position_handler.get_position() != 0:
                    logger.log("INFO", "Moving to home before pump activation", "Maintenance")
                    try:
                        motor_controller.rotate_until_limit(0, position_handler, 1, 1000)
                    except Exception as e:
                        logger.log("ERROR", f"Failed to move home: {e}", "Maintenance")
                        return

                if action == "start":
                    pump_controller.start_pump(idx)
                elif action == "stop":
                    pump_controller.stop_pump(idx)
                else:
                    logger.log("WARNING", f"Unknown pump action: {action}", "Maintenance")
                return
            except Exception as e:
                logger.log("ERROR", f"Pump maintenance error: {e}", "Maintenance")
                return

        # Light control
        if mtype == "light":
            if not led_controller:
                logger.log("INFO", "LED controller not enabled (ignored)", "Maintenance")
                return
            mode = maintenance.get("mode") or maintenance.get("light_mode") or "solid"
            color = maintenance.get("color") or "#FFFFFF"
            brightness = maintenance.get("brightness")
            speed_hz = maintenance.get("speed_hz") or 8.0

            # parse color strings like #RRGGBB
            def parse_hex(c):
                try:
                    c = str(c).lstrip('#')
                    if len(c) == 6:
                        return int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)
                except Exception:
                    pass
                return 255, 255, 255

            r, g, b = parse_hex(color)
            if isinstance(brightness, (int, float)):
                try:
                    led_controller.set_brightness(int(brightness))
                except Exception:
                    pass

            if mode.lower() in ("off", "none"):
                led_controller.stop_strobe()
                led_controller.set_off()
            elif mode.lower() in ("solid", "color"):
                led_controller.stop_strobe()
                led_controller.set_color(r, g, b)
            elif mode.lower() in ("strobe", "disco"):
                led_controller.start_strobe(r, g, b, float(speed_hz))
            elif mode.lower() in ("progress",):
                # progress mode is handled by main pour loops via set_progress
                led_controller.stop_strobe()
                led_controller.set_progress(0.0)
            else:
                logger.log("WARNING", f"Unknown light mode: {mode}", "Maintenance")
            return

        # Known but not yet implemented on hardware side
        if mtype in ("flush_all", "flush_slot"):
            logger.log("INFO", f"Maintenance '{mtype}' received (no-op on hardware)", "Maintenance")
            return

        # Unknown type: be defensive
        logger.log("WARNING", f"Unknown maintenance type: {mtype}", "Maintenance")
    except Exception as e:
        logger.log("ERROR", f"Maintenance handling error: {e}", "Maintenance")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("[HW] Interrupted by user", flush=True)
        raise
    except Exception as e:
        tb = traceback.format_exc()
        try:
            Logger().log("FATAL", f"Unhandled exception: {e}\n{tb}", "Main")
        except Exception:
            pass
        print(f"[HW] FATAL: {e}\n{tb}", file=sys.stderr, flush=True)
        raise
