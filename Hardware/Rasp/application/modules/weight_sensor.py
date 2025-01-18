from hx711 import HX711
import statistics
from modules.utils.logger import Logger
from rx import create
from rx.subject import Subject

class WeightSensor:
    def __init__(self, dt_pin=20, sck_pin=21, scaling_factor=1140):
        """
        Initialize the weight sensor (scale).
        :param dt_pin: GPIO pin for data.
        :param sck_pin: GPIO pin for clock.
        :param scaling_factor: Scaling factor for the sensor.
        """
        self.logger = Logger()
        self.message_subject = Subject()
        self.hx = HX711(dt_pin, sck_pin)
        self.scaling_factor = scaling_factor
        self.weight_samples = []

    def subscribe(self):
        """
        Subscribe to limit switch events.
        :return: Subscription object.
        """
        return self.message_subject.subscribe()

    def tare(self):
        """Set the tare (zero) value for the scale."""
        self.logger.log("INFO", "Taring weight sensor", "WeightSensor")
        self.hx.reset()

    # TODO: raise error if value is None/ over a certain threshold
    def read_weight(self):
        """Read and return the current weight."""
        raw_data = self.hx.get_raw_data()
        if raw_data is not None:
            avg_data = sum(raw_data) / len(raw_data)
            weight = avg_data / self.scaling_factor
            self.weight_samples.append(weight)
            self.weight_samples = self.weight_samples[-5:]  # Keep last 5 samples
            self.logger.log("INFO", f"Weight: {statistics.median(self.weight_samples)}", "Weight Sensor")
            return statistics.median(self.weight_samples)
        self.logger.log("ERROR", "Scale could not be reached", "Weight Sensor")
        return None
