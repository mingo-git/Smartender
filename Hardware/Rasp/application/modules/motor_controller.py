import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger
from modules.error_handler import ErrorHandler


class MotorController:
    def __init__(self, dir_pin=16, pull_pin=12, step_delay=0.0001, error_handler=None):
        """
        Initialize the stepper motor controller.
        :param dir_pin: GPIO pin for direction control.
        :param pull_pin: GPIO pin for pulsing steps.
        :param step_delay: Delay between steps in seconds (adjust for speed).
        """
        self.logger = Logger()
        self.dir_pin = dir_pin
        self.pull_pin = pull_pin
        self.step_delay = step_delay
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.dir_pin, GPIO.OUT)
        GPIO.setup(self.pull_pin, GPIO.OUT)

    def set_direction(self, direction):
        """Set the direction of the stepper motor."""
        GPIO.output(self.dir_pin, direction)
        self.logger.log("INFO", f"Direction set to {direction}", "MotorController")

    def step_motor(self, steps):
        """Pulse the pull pin to step the motor."""
        for _ in range(steps):
            GPIO.output(self.pull_pin, GPIO.HIGH)
            time.sleep(self.step_delay)
            GPIO.output(self.pull_pin, GPIO.LOW)
            time.sleep(self.step_delay)
        self.logger.log("INFO", f"Stepped motor {steps} steps", "MotorController")

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
        self.logger.log("INFO", "GPIO cleanup complete", "MotorController")
