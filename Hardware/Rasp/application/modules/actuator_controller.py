import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger
from rx import create
from rx.subject import Subject

class ActuatorController:
    def __init__(self, in_pins, weight_sensor, position_handler):
        """
        Initialize the actuator controller.
        :param in_pins: List of GPIO pins for actuator control.
        """
        self.logger = Logger()
        self.message_subject = Subject()
        self.weight_sensor = weight_sensor
        self.position_handler = position_handler
        self.in_pins = in_pins
        GPIO.setmode(GPIO.BCM)
        for pin in self.in_pins:
            GPIO.setup(pin, GPIO.OUT)
            GPIO.output(pin, GPIO.LOW)

    def subscribe(self):
        """
        Subscribe to limit switch events.
        :return: Subscription object.
        """
        return self.message_subject.subscribe()

    def activate(self, amount: int):
        """
        Activate the actuator for a given duration.
        :param duration: Duration in seconds to activate the actuator.
        """
        if self.position_handler.current_position is None:
            self.logger.log("ERROR", "Actuator can only be activated in valid Positions", "ActuatorController")
            raise ValueError("Actuator can only be activated in valid positions")

        weight_before_pour = self.weight_sensor.get_weight()

        self._move_up()
        while self.weight_sensor.get_weight() - weight_before_pour < amount:
            if self.weight_sensor.get_weight() > 400:
                self._emergency_stop()
                self.logger.log("ERROR", "Weight sensor detected liquid overflow", "ActuatorController")
                break
        self._move_down()

        return

    def _move_up(self):
        # for pin in self.in_pins:
        #     GPIO.output(pin, GPIO.HIGH)
        # time.sleep(duration)
        # for pin in self.in_pins:
        #     GPIO.output(pin, GPIO.LOW) 
        return
    
    def _move_down(self):
        # for pin in self.in_pins:
        #     GPIO.output(pin, GPIO.HIGH)
        # time.sleep(duration)
        # for pin in self.in_pins:
        #     GPIO.output(pin, GPIO.LOW) 
        return
    
    def _emergency_stop(self):
        self._move_down()
        # for pin in self.in_pins:
        #     GPIO.output(pin, GPIO.HIGH)
        # time.sleep(duration)
        # for pin in self.in_pins:
        #     GPIO.output(pin, GPIO.LOW) 
        return

    def cleanup(self):
        """Clean up GPIO settings."""
        GPIO.cleanup()
