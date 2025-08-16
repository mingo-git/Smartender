import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger
from rx import create
from rx.subject import Subject

class PumpController:
    def __init__(self, pump_pins, weight_sensor, position_handler):
        """
        Initialize the pump controller.
        :param pump_pins: List of GPIO pins for the pumps.
        """
        self.logger = Logger()
        self.message_subject = Subject()
        self.weight_sensor = weight_sensor
        self.position_handler = position_handler
        self.pump_pins = pump_pins
        GPIO.setmode(GPIO.BCM)
        for pin in self.pump_pins:
            GPIO.setup(pin, GPIO.OUT)
            GPIO.output(pin, GPIO.LOW)

    def subscribe(self):
        """
        Subscribe to limit switch events.
        :return: Subscription object.
        """
        return self.message_subject.subscribe()

    def activate_pump(self, pump_index: int, amount: int):
        """
        Activate a specific pump for a given duration.
        :param pump_index: Index of the pump (0-based).
        :param duration: Duration in seconds to run the pump.
        """

        if self.position_handler.get_position()!= 0:
            self.logger.log("ERROR", "Pump can only be activated in position 0", "PumpController")
            raise ValueError("Pump can only be activated in position 0")

        if pump_index < 0 or pump_index >= len(self.pump_pins):
            self.logger.log("ERROR", f"Invalid pump index: {pump_index}", "PumpController")
            raise ValueError("Invalid pump index")

        #weight_before_pour = self.weight_sensor.get_weight()
        added_liquid = 0
        # TODO: make interruptable if weight sensor detects liquid overflow
        GPIO.output(self.pump_pins[pump_index], GPIO.HIGH)
        #while self.weight_sensor.get_weight() > 400 and added_liquid < amount:
        #    GPIO.output(self.pump_pins[pump_index], GPIO.LOW)
        #    added_liquid = self.weight_sensor.get_weight() - weight_before_pour
        time.sleep(amount)
        GPIO.output(self.pump_pins[pump_index], GPIO.LOW)


    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
        self.logger.log("INFO", "GPIO cleanup complete", "PumpController")
