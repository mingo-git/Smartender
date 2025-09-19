import RPi.GPIO as GPIO
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
        # Ensure GPIO mode is set (required by hx711 lib)
        try:
            GPIO.setwarnings(False)
            GPIO.setmode(GPIO.BCM)
        except Exception:
            pass
        self.hx = HX711(dt_pin, sck_pin)
        self.scaling_factor = scaling_factor
        self.weight_samples = []
        self.offset = 0  # raw offset established during tare

    def subscribe(self):
        """
        Subscribe to limit switch events.
        :return: Subscription object.
        """
        return self.message_subject.subscribe()

    def tare(self):
        """Set the tare (zero) value for the scale; refresh raw offset."""
        self.logger.log("INFO", "Taring weight sensor", "WeightSensor")
        # Reset/zero device if supported
        for fn in ("tare", "zero", "reset"):
            try:
                getattr(self.hx, fn)()
                break
            except Exception:
                continue
        # Establish raw offset from mean of several readings
        samples = []
        for _ in range(10):
            raw = self.read_raw()
            if raw is not None:
                samples.append(raw)
        self.offset = int(statistics.median(samples)) if samples else 0

    # TODO: raise error if value is None/ over a certain threshold
    def read_weight(self):
        """Read and return the current weight (grams)."""
        raw = self.read_raw()
        if raw is None:
            self.logger.log("ERROR", "Scale could not be reached", "Weight Sensor")
            return None

        try:
            # Convert raw counts to grams using scaling factor and offset
            weight = (float(raw) - float(self.offset)) / float(self.scaling_factor)
        except Exception:
            weight = None

        if weight is None:
            self.logger.log("ERROR", "Invalid weight reading", "Weight Sensor")
            return None

        self.weight_samples.append(weight)
        self.weight_samples = self.weight_samples[-5:]  # Keep last 5 samples
        median = statistics.median(self.weight_samples)
        self.logger.log("INFO", f"Weight: {median}", "Weight Sensor")
        return median

    def read_raw(self):
        """Return a raw reading if supported (int), else None."""
        try:
            return self.hx.get_raw_data_mean()
        except Exception:
            try:
                return self.hx.get_last_raw_data()
            except Exception:
                return None
