import pigpio
import time

PUL = 12
DIR = 16

pi = pigpio.pi()
pi.set_mode(PUL, pigpio.OUTPUT)
pi.set_mode(DIR, pigpio.OUTPUT)

def rotate_stepper_pigpio(steps, direction, frequency):
    pi.write(DIR, direction)
    pi.hardware_PWM(PUL, frequency, 750000)  # 50% duty cycle
    time.sleep(steps / frequency)
    pi.hardware_PWM(PUL, 0, 0)  # Stop PWM

rotate_stepper_pigpio(2000, 0, 4000)  # 1000 steps at 1 kHz
