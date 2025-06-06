import RPi.GPIO as GPIO
import time


class ActuatorController:
    def __init__(self, in_pins):
        """
        Initialize the actuator controller.
        :param in_pins: List of GPIO pins for actuator control.
        """
        self.in_pins = in_pins

        GPIO.setmode(GPIO.BCM)
        for pin in self.in_pins:
            GPIO.setup(pin, GPIO.OUT)
            GPIO.output(pin, GPIO.LOW)

    def activate(self, duration):
        """
        Activate the actuator for a given duration.
        :param duration: Duration in seconds to activate the actuator.
        """
        for pin in self.in_pins:
            GPIO.output(pin, GPIO.HIGH)
        time.sleep(duration)
        for pin in self.in_pins:
            GPIO.output(pin, GPIO.LOW)

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
