import RPi.GPIO as GPIO


class PositionHandler:
    def __init__(self, limit_switch_pins):
        """
        Initialize the position handler for limit switches.
        :param limit_switch_pins: List of GPIO pins for the limit switches.
        """
        self.limit_switch_pins = limit_switch_pins

        GPIO.setmode(GPIO.BCM)
        for pin in self.limit_switch_pins:
            GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    def get_position(self):
        """
        Check which limit switch is pressed.
        :return: Index of the active limit switch, or None if none are active.
        """
        for idx, pin in enumerate(self.limit_switch_pins):
            if GPIO.input(pin) == GPIO.LOW:
                return idx + 1  # Return 1-based index
        return None

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
