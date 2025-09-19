"""
BTS7960 Linear Actuator Test Script (RPi GPIO)

Purpose
- Safely test a 12V linear actuator driven by a BTS7960 H-Bridge.
- Moves the actuator OUT (extend) for a short time, stops, then IN (retract).

Wiring (BCM numbering)
- Logic power and reference:
  - RPi GND  -> BTS7960 GND (logic GND and power GND must be common)
  - RPi 5V   -> BTS7960 VCC (logic supply, NOT motor power)
  - 12V PSU  -> BTS7960 VIN+/VIN- (big terminals per board manual)
  - Motor    -> BTS7960 OUT+/OUT- (big terminals to actuator)

- Control signals (recommended defaults in this script):
  - R_EN  -> BCM 23 (GPIO 23)
  - L_EN  -> BCM 24 (GPIO 24)
  - R_PWM -> BCM 18 (GPIO 18)
  - L_PWM -> BCM 25 (GPIO 25)

Notes
- Use only ONE PWM side at a time: when driving OUT, set R_PWM duty>0 and L_PWM=0; for IN, L_PWM>0 and R_PWM=0.
- Keep both EN pins HIGH while moving; set both LOW to disable the driver when idle.
- Start with small durations (e.g., 0.5–1.0s) and ensure full mechanical clearance.
- If your board labels differ (RPWM/LPWM, ENA/ENB), map accordingly: RPWM~R_PWM, LPWM~L_PWM, ENA~R_EN, ENB~L_EN.

Run
  sudo -E /home/admin/myenv/bin/python3 Hardware/Rasp/application/tests/test_bts7960_actuator.py
"""

import time
import sys

import RPi.GPIO as GPIO


# ----------------------------- Pin configuration (BCM) -----------------------------
PIN_R_EN = 23
PIN_L_EN = 24
PIN_R_PWM = 18
PIN_L_PWM = 25

# PWM parameters
PWM_FREQ_HZ = 1000  # 1 kHz is fine for DC motors; adjust as needed
DEFAULT_DUTY = 100  # percent


def setup():
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)

    GPIO.setup(PIN_R_EN, GPIO.OUT)
    GPIO.setup(PIN_L_EN, GPIO.OUT)
    GPIO.setup(PIN_R_PWM, GPIO.OUT)
    GPIO.setup(PIN_L_PWM, GPIO.OUT)

    # Initialize EN low (disabled)
    GPIO.output(PIN_R_EN, GPIO.LOW)
    GPIO.output(PIN_L_EN, GPIO.LOW)

    # Prepare PWM objects (stopped)
    r_pwm = GPIO.PWM(PIN_R_PWM, PWM_FREQ_HZ)
    l_pwm = GPIO.PWM(PIN_L_PWM, PWM_FREQ_HZ)
    r_pwm_started = False
    l_pwm_started = False

    return r_pwm, l_pwm, r_pwm_started, l_pwm_started


def enable_driver(enable: bool):
    GPIO.output(PIN_R_EN, GPIO.HIGH if enable else GPIO.LOW)
    GPIO.output(PIN_L_EN, GPIO.HIGH if enable else GPIO.LOW)


def drive(r_pwm, l_pwm, r_pwm_started: bool, l_pwm_started: bool, *, direction: str, duty: int, duration_s: float):
    """Drive actuator in one direction with a specific duty for duration_s seconds."""
    if direction not in ("out", "in"):
        raise ValueError("direction must be 'out' or 'in'")

    # Safety: ensure only one side is active
    if direction == "out":
        # R active, L off
        if l_pwm_started:
            l_pwm.stop()
            l_pwm_started = False
        if not r_pwm_started:
            r_pwm.start(0)
            r_pwm_started = True
        r_pwm.ChangeDutyCycle(max(0, min(100, duty)))
    else:
        # IN: L active, R off
        if r_pwm_started:
            r_pwm.stop()
            r_pwm_started = False
        if not l_pwm_started:
            l_pwm.start(0)
            l_pwm_started = True
        l_pwm.ChangeDutyCycle(max(0, min(100, duty)))

    enable_driver(True)
    time.sleep(max(0.0, duration_s))

    # Stop PWM after movement
    if r_pwm_started:
        r_pwm.ChangeDutyCycle(0)
    if l_pwm_started:
        l_pwm.ChangeDutyCycle(0)
    enable_driver(False)

    return r_pwm_started, l_pwm_started


def emergency_stop(r_pwm, l_pwm):
    try:
        r_pwm.ChangeDutyCycle(0)
        l_pwm.ChangeDutyCycle(0)
    except Exception:
        pass
    enable_driver(False)


def main():
    print("[BTS7960] Setup…")
    r_pwm, l_pwm, r_started, l_started = setup()
    try:
        print("[BTS7960] Test sequence starting (OUT 1.0s → pause → IN 1.0s)…")
        r_started, l_started = drive(r_pwm, l_pwm, r_started, l_started, direction="out", duty=DEFAULT_DUTY, duration_s=1.0)
        time.sleep(0.5)
        r_started, l_started = drive(r_pwm, l_pwm, r_started, l_started, direction="in", duty=DEFAULT_DUTY, duration_s=1.0)

        print("[BTS7960] Ramp test (OUT 0→80%→0)…")
        enable_driver(True)
        if not r_started:
            r_pwm.start(0)
            r_started = True
        for d in range(0, 81, 10):
            r_pwm.ChangeDutyCycle(d)
            time.sleep(0.15)
        for d in range(80, -1, -20):
            r_pwm.ChangeDutyCycle(d)
            time.sleep(0.1)
        r_pwm.ChangeDutyCycle(0)
        enable_driver(False)

        print("[BTS7960] Done.")
    except KeyboardInterrupt:
        print("[BTS7960] Interrupted – stopping…")
    except Exception as e:
        print(f"[BTS7960] ERROR: {e}", file=sys.stderr)
    finally:
        try:
            emergency_stop(r_pwm, l_pwm)
        except Exception:
            pass
        try:
            r_pwm.stop()
        except Exception:
            pass
        try:
            l_pwm.stop()
        except Exception:
            pass
        GPIO.cleanup()
        print("[BTS7960] Cleaned up GPIO.")


if __name__ == "__main__":
    main()

