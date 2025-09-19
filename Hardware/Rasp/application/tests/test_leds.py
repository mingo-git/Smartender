"""
WS281x LED Test (PWM)

Hardcoded config (matches main.py):
- GPIO (DIN): 13
- LED_COUNT: 41
- BRIGHTNESS: 160

Behavior:
- Initializes the strip
- Shows RED → GREEN → BLUE → WHITE each for 1s
- Then turns OFF

Run:
  sudo -E /home/admin/myenv/bin/python3 Hardware/Rasp/application/tests/test_leds.py
"""

import time
from rpi_ws281x import PixelStrip, Color


LED_PIN = 13
LED_COUNT = 41
LED_BRIGHTNESS = 160
LED_FREQ_HZ = 800000
LED_DMA = 10
LED_INVERT = False
LED_CHANNEL = 1  # pin 13 → channel 1


def fill(strip, r, g, b):
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(r, g, b))
    strip.show()


def main():
    print(f"[LED TEST] Init (pin={LED_PIN}, count={LED_COUNT}, ch={LED_CHANNEL})…")
    strip = PixelStrip(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS, LED_CHANNEL)
    strip.begin()
    print("[LED TEST] Showing colors…")

    try:
        for (name, rgb) in (
            ("RED", (255, 0, 0)),
            ("GREEN", (0, 255, 0)),
            ("BLUE", (0, 0, 255)),
            ("WHITE", (255, 255, 255)),
        ):
            print(f"[LED TEST] {name}")
            fill(strip, *rgb)
            time.sleep(1.0)

    finally:
        print("[LED TEST] OFF")
        fill(strip, 0, 0, 0)


if __name__ == "__main__":
    main()

