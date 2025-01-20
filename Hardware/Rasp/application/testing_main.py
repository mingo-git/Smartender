
# from modules.weight_sensor import WeightSensor
# import time


# weight_sensor = WeightSensor(dt_pin=20, sck_pin=21)

# weight_sensor.tare()

# time.sleep(0.5)


# weight_sensor.read_weight()


from modules.actuator_controller import ActuatorController
import time

actuator_controller = ActuatorController(
    in_pins={"in3": 7, "in4": 1},
    weight_sensor=None,
    position_handler=None,
)

actuator_controller._move_up(2.5)
time.sleep(3)
actuator_controller.cleanup()