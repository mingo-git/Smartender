import RPi.GPIO as GPIO
import time

SWITCH_PIN = 4  # GPIO 26 (Pin 37)

# GPIO-Setup
GPIO.setmode(GPIO.BCM)
GPIO.setup(SWITCH_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

try:
    while True:
        pin_state = GPIO.input(SWITCH_PIN)
        if pin_state == GPIO.LOW:
            print("Schalter gedrückt (LOW)")
        else:
            print("Schalter nicht gedrückt (HIGH)")
        time.sleep(0.5)

except KeyboardInterrupt:
    GPIO.cleanup()
    print("GPIO sauber gemacht.")

