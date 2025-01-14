import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger

class MotorController:
    def __init__(self, dir_pin=16, pull_pin=12, min_delay=0.0001, max_delay=0.01, steps_per_second=1000, error_handler = None):
        """
        Initialize the stepper motor controller.
        :param dir_pin: GPIO pin for direction control.
        :param pull_pin: GPIO pin for pulsing steps.
        :param min_delay: Minimum delay between steps (for maximum speed).
        :param max_delay: Maximum delay between steps (for starting speed).
        :param steps_per_second: Target number of steps per second.
        """
        self.logger = Logger()
        self.dir_pin = dir_pin
        self.pull_pin = pull_pin
        self.min_delay = min_delay
        self.max_delay = max_delay
        self.steps_per_second = steps_per_second

        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.dir_pin, GPIO.OUT)
        GPIO.setup(self.pull_pin, GPIO.OUT)

    def set_direction(self, direction):
        """Set the direction of the stepper motor."""
        GPIO.output(self.dir_pin, direction)
        self.logger.log("INFO", f"Direction set to {direction}", "MotorController")

    def accelerate_motor(self, steps):
        """
        Gradually accelerate the motor by decreasing the delay between steps.
        :param steps: Total number of steps to move.
        """
        delay = self.max_delay
        acceleration_rate = (self.max_delay - self.min_delay) / steps

        for step in range(steps):
            GPIO.output(self.pull_pin, GPIO.HIGH)
            time.sleep(delay)
            GPIO.output(self.pull_pin, GPIO.LOW)
            time.sleep(delay)

            # Gradually decrease the delay
            delay = max(self.min_delay, delay - acceleration_rate)

        self.logger.log("INFO", f"Accelerated motor for {steps} steps", "MotorController")

    def step_motor(self, steps):
        """Run the motor at constant speed for the specified number of steps."""
        delay = self.min_delay
        for _ in range(steps):
            GPIO.output(self.pull_pin, GPIO.HIGH)
            time.sleep(delay)
            GPIO.output(self.pull_pin, GPIO.LOW)
            time.sleep(delay)
        self.logger.log("INFO", f"Stepped motor {steps} steps at constant speed", "MotorController")

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
        self.logger.log("INFO", "GPIO cleanup complete", "MotorController")
