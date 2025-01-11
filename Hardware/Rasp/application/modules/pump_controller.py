import RPi.GPIO as GPIO
import time


class PumpController:
    def __init__(self, pump_pins):
        """
        Initialize the pump controller.
        :param pump_pins: List of GPIO pins for the pumps.
        """
        self.pump_pins = pump_pins

        GPIO.setmode(GPIO.BCM)
        for pin in self.pump_pins:
            GPIO.setup(pin, GPIO.OUT)
            GPIO.output(pin, GPIO.LOW)

    def activate_pump(self, pump_index, duration):
        """
        Activate a specific pump for a given duration.
        :param pump_index: Index of the pump (0-based).
        :param duration: Duration in seconds to run the pump.
        """
        if pump_index < 0 or pump_index >= len(self.pump_pins):
            raise ValueError("Invalid pump index")
        GPIO.output(self.pump_pins[pump_index], GPIO.HIGH)
        time.sleep(duration)
        GPIO.output(self.pump_pins[pump_index], GPIO.LOW)

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
