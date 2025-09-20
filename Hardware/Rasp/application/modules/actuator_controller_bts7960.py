import RPi.GPIO as GPIO
import time
from modules.utils.logger import Logger


class ActuatorControllerBTS7960:
    def __init__(self, pins, weight_sensor=None, position_handler=None, pwm_freq_hz: int = 1000, invert: bool = False):
        """
        BTS7960-based linear actuator controller.

        pins: dict with keys
          - 'r_en': BCM pin for right enable
          - 'l_en': BCM pin for left enable
          - 'r_pwm': BCM pin for right PWM (extend/out)
          - 'l_pwm': BCM pin for left PWM (retract/in)
        invert: if True, swaps OUT/IN mapping relative to _move_up/_move_down
        """
        self.logger = Logger()
        self.weight_sensor = weight_sensor
        self.position_handler = position_handler
        self.r_en = pins["r_en"]
        self.l_en = pins["l_en"]
        self.r_pwm_pin = pins["r_pwm"]
        self.l_pwm_pin = pins["l_pwm"]
        self.freq = pwm_freq_hz
        self.invert = invert

        GPIO.setmode(GPIO.BCM)
        GPIO.setwarnings(False)
        GPIO.setup(self.r_en, GPIO.OUT)
        GPIO.setup(self.l_en, GPIO.OUT)
        GPIO.setup(self.r_pwm_pin, GPIO.OUT)
        GPIO.setup(self.l_pwm_pin, GPIO.OUT)

        GPIO.output(self.r_en, GPIO.LOW)
        GPIO.output(self.l_en, GPIO.LOW)

        self.r_pwm = GPIO.PWM(self.r_pwm_pin, self.freq)
        self.l_pwm = GPIO.PWM(self.l_pwm_pin, self.freq)
        self._r_started = False
        self._l_started = False

    # ---------------- internal helpers ----------------
    def _enable(self, on: bool):
        GPIO.output(self.r_en, GPIO.HIGH if on else GPIO.LOW)
        GPIO.output(self.l_en, GPIO.HIGH if on else GPIO.LOW)

    def _stop_pwm(self):
        try:
            if self._r_started:
                self.r_pwm.ChangeDutyCycle(0)
            if self._l_started:
                self.l_pwm.ChangeDutyCycle(0)
        except Exception:
            pass

    def _drive(
        self,
        out: bool,
        duty: int,
        duration_s: float,
        ramp_up_s: float = 0.4,
        ramp_steps: int = 12,
        ramp_down_s: float = 0.3,
        ramp_down_steps: int = 10,
    ):
        """
        Drive with soft-start ramp to reduce inrush current/spikes.
        - ramp_up_s: seconds to ramp from 0 → duty
        - ramp_steps: subdivisions of the ramp
        """
        duty = max(0, min(100, int(duty)))
        ramp_up_s = max(0.0, float(ramp_up_s))
        ramp_steps = max(1, int(ramp_steps))

        # Ensure only one side is active and start PWM at 0% duty
        if out:
            if self._l_started:
                self.l_pwm.stop()
                self._l_started = False
            if not self._r_started:
                self.r_pwm.start(0)
                self._r_started = True
            set_duty = self.r_pwm.ChangeDutyCycle
        else:
            if self._r_started:
                self.r_pwm.stop()
                self._r_started = False
            if not self._l_started:
                self.l_pwm.start(0)
                self._l_started = True
            set_duty = self.l_pwm.ChangeDutyCycle

        self._enable(True)

        # Ramp up
        if ramp_up_s > 0:
            step_sleep = ramp_up_s / ramp_steps
            for i in range(1, ramp_steps + 1):
                try:
                    set_duty(duty * i / ramp_steps)
                except Exception:
                    pass
                time.sleep(step_sleep)
            remaining = max(0.0, duration_s - ramp_up_s)
        else:
            try:
                set_duty(duty)
            except Exception:
                pass
            remaining = max(0.0, duration_s)

        # Hold at target duty
        if remaining > 0:
            time.sleep(remaining)

        # Ramp down to 0 to avoid voltage/current spikes
        if ramp_down_s > 0:
            step_sleep = ramp_down_s / max(1, ramp_down_steps)
            for i in range(ramp_down_steps, -1, -1):
                try:
                    set_duty(duty * i / max(1, ramp_down_steps))
                except Exception:
                    pass
                time.sleep(step_sleep)

        # Finally stop outputs
        self._stop_pwm()
        self._enable(False)

    # ---------------- public API (compatible with old controller) ----------------
    def _move_up(self, duration):
        # In legacy semantics, "up" lifts/extends to pour. Map to OUT unless inverted.
        out = not self.invert
        self.logger.log("INFO", f"Actuator (BTS7960) moving {'OUT' if out else 'IN'} for {duration}s", "ActuatorController")
        self._drive(out=out, duty=100, duration_s=duration, ramp_up_s=0.4, ramp_steps=12, ramp_down_s=0.3, ramp_down_steps=10)

    def _move_down(self, duration):
        out = self.invert
        self.logger.log("INFO", f"Actuator (BTS7960) moving {'OUT' if out else 'IN'} for {duration}s", "ActuatorController")
        self._drive(out=out, duty=100, duration_s=duration, ramp_up_s=0.4, ramp_steps=12, ramp_down_s=0.3, ramp_down_steps=10)

    def _emergency_stop(self):
        self._stop_pwm()
        self._enable(False)
        self.logger.log("ALERT", "Actuator (BTS7960) emergency stop", "ActuatorController")

    def cleanup(self):
        try:
            self._stop_pwm()
            try:
                if self._r_started:
                    self.r_pwm.stop()
                if self._l_started:
                    self.l_pwm.stop()
            except Exception:
                pass
            GPIO.cleanup([self.r_en, self.l_en, self.r_pwm_pin, self.l_pwm_pin])
        finally:
            self.logger.log("INFO", "GPIO cleanup complete for actuator (BTS7960)", "ActuatorController")
