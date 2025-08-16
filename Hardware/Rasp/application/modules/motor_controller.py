import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger
from modules.error_handler import ErrorHandler
from rx import create
from rx.subject import Subject
import pigpio

class MotorController:
    def __init__(self, dir_pin=16, pull_pin=12, error_handler=None):
        """
        Initialize the stepper motor controller.
        :param dir_pin: GPIO pin for direction control.
        :param pull_pin: GPIO pin for pulsing steps.
        """
        self.logger = Logger()
        self.message_subject = Subject()
        self.dir_pin = dir_pin
        self.pull_pin = pull_pin

        self.pi = pigpio.pi()
        self.pi.set_mode(self.pull_pin, pigpio.OUTPUT)
        self.pi.set_mode(self.dir_pin, pigpio.OUTPUT)

    def subscribe(self):
        """
        Subscribe to limit switch events.
        :return: Subscription object.
        """
        return self.message_subject.subscribe()


    def rotate_stepper_pigpio(self, steps, direction, frequency):
            self.pi.write(self.dir_pin, direction)
            self.pi.hardware_PWM(self.pull_pin, frequency, 500000)  # 50% duty cycle
            time.sleep(steps / frequency)
            self.pi.hardware_PWM(self.pull_pin, 0, 0)  # Stop PWM

    def rotate_until_limit(self, target_slot, position_handler, direction, frequency=2000):
        """
        Rotate the stepper motor until the specified limit switch is triggered.
        :param target_slot: The target slot number (limit switch index).
        :param position_handler: PositionHandler instance for limit switch states.
        :param frequency: Frequency of the pulse signal in Hz.
        :param direction: Direction (1 for clockwise, 0 for counterclockwise).
        """
        self.pi.write(self.dir_pin, direction)
        self.pi.hardware_PWM(self.pull_pin, frequency, 500000)  # 50% duty cycle

        try:
            while position_handler.get_position() != target_slot:
                time.sleep(0.0001)  # Check the limit switch state periodically
        finally:
            self.pi.hardware_PWM(self.pull_pin, 0, 0)  # Stop PWM once the limit switch is pressed
            self.logger.log("INFO", f"Limit switch {target_slot} triggered. Motor stopped.", "MotorController")


    def cleanup(self):
        """Stop all signals and close the pigpio connection."""
        self.pi.hardware_PWM(self.pull_pin, 0, 0)  # Stop PWM on the PUL pin
        self.pi.stop()  # Disconnect from pigpio daemon