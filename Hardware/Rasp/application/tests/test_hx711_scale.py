"""
HX711 Weight Sensor Test

Purpose
- Tare (zero) the scale and then print several weight readings.

Pins (BCM)
- DT  (DOUT)  -> GPIO 20
- SCK (PD_SCK)-> GPIO 21

Run
  sudo -E /home/admin/myenv/bin/python3 Hardware/Rasp/application/tests/test_hx711_scale.py
"""

import time
from modules.weight_sensor import WeightSensor


def main():
    sensor = WeightSensor(dt_pin=20, sck_pin=21)

    print("[HX711] Taring (zeroing) the scale… Keep it unloaded.")
    sensor.tare()
    time.sleep(0.5)

    print("[HX711] Readings (g):")
    for i in range(10):
        w = sensor.read_weight()
        print(f"  {i+1:02d}: {w}")
        time.sleep(0.5)


if __name__ == "__main__":
    main()

