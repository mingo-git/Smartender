from hx711 import HX711

hx = HX711(dout_pin=20, pd_sck_pin=21)

try:
    print("Starting basic HX711 test")
    hx.reset()
    print("HX711 reset successful")
    while True:
        data = hx.get_raw_data()
        if data:
            print("Raw data:", data)
        else:
            print("No data received")
except KeyboardInterrupt:
    print("Exiting test")
