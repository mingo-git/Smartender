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

    def subscribe(self):
        """
        Subscribe to limit switch events.
        :return: Subscription object.
        """
        return self.message_subject.subscribe()

    def tare(self):
        """Set the tare (zero) value for the scale (best-effort across libs)."""
        self.logger.log("INFO", "Taring weight sensor", "WeightSensor")
        # Try multiple common APIs across hx711 variants
        try:
            # Some libs
            self.hx.tare()
            return
        except Exception:
            pass
        try:
            # Some variants use zero()
            self.hx.zero()
            return
        except Exception:
            pass
        try:
            # Fallback
            self.hx.reset()
        except Exception:
            pass

    # TODO: raise error if value is None/ over a certain threshold
    def read_weight(self):
        """Read and return the current weight (grams)."""
        value = None
        # Try several common accessors in order of preference
        try:
            # Many libs provide mean weight (already averaged)
            value = self.hx.get_weight_mean(10)
        except Exception:
            try:
                value = self.hx.get_weight(5)
            except Exception:
                # Try raw means
                raw = None
                try:
                    raw = self.hx.get_raw_data_mean()
                except Exception:
                    try:
                        raw = self.hx.get_last_raw_data()
                    except Exception:
                        raw = None
                if raw is not None:
                    value = raw

        if value is None:
            self.logger.log("ERROR", "Scale could not be reached", "Weight Sensor")
            return None

        try:
            # Convert to grams using scaling factor
            weight = float(value) / float(self.scaling_factor)
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
