import RPi.GPIO as GPIO
import time

# Pin Definitions
DIR_PIN = 16    # GPIO 27 (Pin 36)
PULL_PIN = 12   # GPIO 12 (PWM0 on Pin 32)

# Stepper motor settings
STEP_DELAY = 0.000001 # Delay between steps in seconds (adjust for speed)
DIRECTION = 1       # 1 for clockwise, 0 for counter-clockwise

# GPIO Setup
GPIO.setmode(GPIO.BCM)
GPIO.setup(DIR_PIN, GPIO.OUT)
GPIO.setup(PULL_PIN, GPIO.OUT)

def set_direction(direction):
    """Set the direction of the stepper motor."""
    GPIO.output(DIR_PIN, direction)

def step_motor(steps, delay=STEP_DELAY):
    """Pulse the pull pin to step the motor."""
    for _ in range(steps):
        GPIO.output(PULL_PIN, GPIO.HIGH)
        time.sleep(delay)
        GPIO.output(PULL_PIN, GPIO.LOW)
        time.sleep(delay)

def cleanup():
    """Clean up GPIO settings."""
    GPIO.cleanup()

if __name__ == "__main__":
    try:
        # Example: Move motor 200 steps clockwise
        print("Moving motor clockwise...")
        set_direction(DIRECTION)  # Clockwise
        step_motor(20000)

        time.sleep(1)

        # Example: Move motor 200 steps counter-clockwise
        print("Moving motor counter-clockwise...")
        set_direction(1 - DIRECTION)  # Counter-clockwise
        step_motor(20000)

    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")

    finally:
        cleanup()
        print("GPIO cleaned up.")

