import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger
from modules.error_handler import ErrorHandler
from rx import create
from rx.subject import Subject

class MotorController:
    def __init__(self, dir_pin=16, pull_pin=12, min_delay=0.0005, max_delay=0.001, error_handler=None):
        """
        Initialize the stepper motor controller.
        :param dir_pin: GPIO pin for direction control.
        :param pull_pin: GPIO pin for pulsing steps.
        :param min_delay: Minimum delay between steps (for maximum speed).
        :param max_delay: Maximum delay between steps (for starting speed).
        """
        self.logger = Logger()
        self.message_subject = Subject()
        self.dir_pin = dir_pin
        self.pull_pin = pull_pin
        self.min_delay = min_delay
        self.max_delay = max_delay
        self.current_delay = max_delay

        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.dir_pin, GPIO.OUT)
        GPIO.setup(self.pull_pin, GPIO.OUT)

    def subscribe(self):
        """
        Subscribe to limit switch events.
        :return: Subscription object.
        """
        return self.message_subject.subscribe()

    def set_direction(self, direction):
        """Set the direction of the stepper motor."""
        GPIO.output(self.dir_pin, direction)
        self.logger.log("INFO", f"Direction set to {direction}", "MotorController")

    def accelerate_motor(self, steps, acceleration_steps):
        """
        Gradually accelerate the motor by decreasing the delay between steps.
        :param steps: Total number of steps to move during acceleration.
        :param acceleration_steps: Number of steps over which to accelerate.
        """
        delay = self.max_delay
        delay_decrement = (self.max_delay - self.min_delay) / acceleration_steps
        for step in range(steps):
            GPIO.output(self.pull_pin, GPIO.HIGH)
            time.sleep(delay)
            GPIO.output(self.pull_pin, GPIO.LOW)
            time.sleep(delay)
            delay -= delay_decrement
        self.current_delay = delay
        self.logger.log("INFO", f"Accelerated motor for {steps} steps", "MotorController")

    def decelerate_motor(self, steps, deceleration_steps):
        """
        Gradually decelerate the motor by increasing the delay between steps.
        :param steps: Total number of steps to move during deceleration.
        :param deceleration_steps: Number of steps over which to decelerate.
        """
        delay = self.current_delay
        delay_increment = (self.max_delay - self.min_delay) / deceleration_steps
        for step in range(steps):
            GPIO.output(self.pull_pin, GPIO.HIGH)
            time.sleep(delay)
            GPIO.output(self.pull_pin, GPIO.LOW)
            time.sleep(delay)
            delay = min(delay_increment, self.max_delay)
        self.current_delay = delay
        self.logger.log("INFO", f"Decelerated motor for {steps} steps", "MotorController")

    def step_motor(self, total_steps, direction, acceleration_over_steps=200, deceleration_over_steps=200):
        """Run the motor with acceleration, constant speed, and deceleration."""
        self.set_direction(direction)

        self.logger.log("INFO", f"ACC: {acceleration_over_steps}, DEC: {deceleration_over_steps}", "MotorController")
        constant_steps = total_steps - acceleration_over_steps - deceleration_over_steps
        if constant_steps < 0:
            constant_steps = 0
        non_constant_steps = total_steps - constant_steps
        acceleration_steps = int(non_constant_steps * acceleration_over_steps / (acceleration_over_steps + deceleration_over_steps))
        deceleration_steps = non_constant_steps - acceleration_steps

        self.accelerate_motor(acceleration_steps, acceleration_over_steps)
        for _ in range(constant_steps):
            GPIO.output(self.pull_pin, GPIO.HIGH)
            time.sleep(self.current_delay)
            GPIO.output(self.pull_pin, GPIO.LOW)
            time.sleep(self.current_delay)
        self.decelerate_motor(deceleration_steps, deceleration_over_steps)

        self.logger.log("INFO", f"Stepped motor {total_steps} steps with acceleration and deceleration", "MotorController")

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
        self.logger.log("INFO", "GPIO cleanup complete", "MotorController")
