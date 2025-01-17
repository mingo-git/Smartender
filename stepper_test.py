import RPi.GPIO as GPIO
import time

# Pin Definitions
PUL = 12  # GPIO pin connected to PUL+
DIR = 16  # GPIO pin connected to DIR+

# Setup GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(PUL, GPIO.OUT)
GPIO.setup(DIR, GPIO.OUT)

def rotate_stepper(steps, direction, start_delay=0.002, end_delay=0.0005, acceleration_steps=100):
    GPIO.output(DIR, direction)
    delay = start_delay
    step = 0
    while step < steps:
        GPIO.output(PUL, GPIO.HIGH)
        time.sleep(delay)
        GPIO.output(PUL, GPIO.LOW)
        time.sleep(delay)
        if step < acceleration_steps:
            delay -= (start_delay - end_delay) / acceleration_steps
        step += 1

try:
    # Rotate 200 steps counterclockwise with acceleration ramping
    rotate_stepper(steps=1000*8, direction=0, start_delay=0.001/8, end_delay=0.0005/8, acceleration_steps=2000)
    time.sleep(1)  # Pause for 1 second
    # Rotate 200 steps clockwise with acceleration ramping
    rotate_stepper(steps=1000*8, direction=1, start_delay=0.001/8, end_delay=0.0005/8, acceleration_steps=2000)


except KeyboardInterrupt:
    print("Program stopped")

finally:
    GPIO.cleanup()
