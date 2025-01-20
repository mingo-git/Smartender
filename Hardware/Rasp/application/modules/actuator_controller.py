import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger
from rx import create
from rx.subject import Subject

class ActuatorController:
    def __init__(self, in_pins, weight_sensor, position_handler):
        """
        Initialize the actuator controller.
        :param in_pins: Dictionary with keys 'in3' and 'in4' for actuator control pins.
        :param weight_sensor: Weight sensor instance.
        :param position_handler: Position handler instance.
        """
        self.logger = Logger()
        self.message_subject = Subject()
        self.weight_sensor = weight_sensor
        self.position_handler = position_handler
        self.in3 = in_pins["in3"]
        self.in4 = in_pins["in4"]

        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.in3, GPIO.OUT)
        GPIO.setup(self.in4, GPIO.OUT)
        GPIO.output(self.in3, GPIO.LOW)
        GPIO.output(self.in4, GPIO.LOW)

    def activate(self, amount: int):
        """
        Activate the actuator to pour a specific amount.
        :param amount: Target weight of liquid to pour (grams).
        """
        if self.position_handler.current_position is None:
            self.logger.log("ERROR", "Actuator can only be activated in valid positions", "ActuatorController")
            raise ValueError("Actuator can only be activated in valid positions")

        weight_before_pour = self.weight_sensor.get_weight()

        self._move_up()
        while self.weight_sensor.get_weight() - weight_before_pour < amount:
            # Emergency stop on overflow
            if self.weight_sensor.get_weight() > 400:
                self._emergency_stop()
                self.logger.log("ERROR", "Weight sensor detected liquid overflow", "ActuatorController")
                break

        self._move_down()

    def _move_up(self, duration):
        """Move the actuator down."""
        GPIO.output(self.in3, GPIO.LOW)
        GPIO.output(self.in4, GPIO.HIGH)
        time.sleep(duration)  # Duration for moving down (adjust as needed)
        GPIO.output(self.in4, GPIO.LOW)
        self.logger.log("INFO", "Actuator moving up", "ActuatorController")

    def _move_down(self, duration):
        """Move the actuator up."""
        GPIO.output(self.in3, GPIO.HIGH)
        GPIO.output(self.in4, GPIO.LOW)
        self.logger.log("INFO", "Actuator moving down", "ActuatorController")
        time.sleep(duration)
        GPIO.output(self.in3, GPIO.LOW)

    def _emergency_stop(self):
        """Stop the actuator in an emergency."""
        GPIO.output(self.in3, GPIO.LOW)
        GPIO.output(self.in4, GPIO.LOW)
        self.logger.log("ALERT", "Actuator emergency stop triggered", "ActuatorController")

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup([self.in3, self.in4])
        self.logger.log("INFO", "GPIO cleanup complete for actuator", "ActuatorController")
