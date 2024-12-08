import serial
import sys

# Configure serial port
ser = serial.Serial('/dev/serial0', 9600, timeout=1)

def send_to_arduino(data):
    ser.write(data.encode())

if __name__ == "__main__":
    if len(sys.argv) > 1:
        send_to_arduino(sys.argv[1])
    else:
        print("No data provided")

