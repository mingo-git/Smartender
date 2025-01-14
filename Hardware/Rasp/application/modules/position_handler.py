import RPi.GPIO as GPIO
from modules.utils.logger import Logger


class PositionHandler:
    def __init__(self, limit_switch_pins):
        """
        Initialize the position handler for limit switches.
        :param limit_switch_pins: List of GPIO pins for the limit switches.
        """
        self.limit_switch_pins = limit_switch_pins
        self.logger = Logger()
        GPIO.setmode(GPIO.BCM)
        for pin in self.limit_switch_pins:
            GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    def get_position(self):
        """
        Check which limit switch is pressed.
        :return: Index of the active limit switch (0-based), or None if none are active.
        """
        for idx, pin in enumerate(self.limit_switch_pins):
            if GPIO.input(pin) == GPIO.LOW:  # Switch pressed
                self.logger.log("INFO", f"Limit switch {idx} pressed", "PositionHandler")
                return idx
        return None

    def is_home_position(self):
        """
        Check if the cart is at the home position (limit switch 0).
        :return: True if limit switch 0 is pressed, False otherwise.
        """
        if self.get_position() == 0: 
            self.logger.log("INFO", "Cart is at home position", "PositionHandler") 
            
        return self.get_position() == 0

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
        self.logger.log("INFO", "GPIO cleanup complete", "PositionHandler")
