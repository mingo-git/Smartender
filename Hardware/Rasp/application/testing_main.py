
from modules.weight_sensor import WeightSensor
import time


weight_sensor = WeightSensor(dt_pin=20, sck_pin=21)

weight_sensor.tare()

time.sleep(0.5)


weight_sensor.read_weight()
