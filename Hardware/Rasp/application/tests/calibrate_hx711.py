"""
HX711 Calibration Helper

Steps
1) Tare the empty scale
2) Prompt for a reference weight (grams) and instruct to place it
3) Read raw mean and compute a suggested scaling_factor

Run
  sudo -E /home/admin/myenv/bin/python3 Hardware/Rasp/application/tests/calibrate_hx711.py  (then follow prompts)
"""

import os
import sys
import time

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
if APP_DIR not in sys.path:
    sys.path.insert(0, APP_DIR)

from modules.weight_sensor import WeightSensor


def main():
    sensor = WeightSensor(dt_pin=20, sck_pin=21)

    print("[CAL] Taring empty scale…")
    sensor.tare()
    time.sleep(0.5)

    # Baseline raw
    baseline = sensor.read_raw()
    print(f"[CAL] Baseline raw: {baseline}")

    # Ask for reference weight
    try:
        ref_str = input("[CAL] Enter reference weight in grams (e.g., 200): ").strip()
        ref_g = float(ref_str)
    except Exception:
        print("[CAL] Invalid input.")
        return

    input("[CAL] Place the reference weight on the scale, then press Enter…")
    time.sleep(1.0)

    # Average several raw readings
    readings = []
    for _ in range(10):
        r = sensor.read_raw()
        if r is not None:
            readings.append(r)
        time.sleep(0.2)

    if not readings:
        print("[CAL] No raw readings available. Check wiring/power.")
        return

    raw_mean = sum(readings) / len(readings)
    print(f"[CAL] Raw with weight: {raw_mean:.2f}")

    if baseline is None:
        baseline = 0
    delta = abs(raw_mean - baseline)
    if ref_g <= 0:
        print("[CAL] Reference weight must be > 0.")
        return

    scale = delta / ref_g
    print("[CAL] Suggested scaling_factor:")
    print(f"      scaling_factor ≈ {scale:.4f}")
    print("[CAL] Update WeightSensor(dt_pin, sck_pin, scaling_factor=…) with this value.")


if __name__ == "__main__":
    main()

