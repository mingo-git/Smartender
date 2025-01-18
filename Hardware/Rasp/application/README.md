# Suggested File structure according to ChadGPT

``` plainText
iot_project/
│
├── main.py                    # Einstiegspunkt der Anwendung
├── config.py                  # Konfigurationsdateien und Parameter
├── modules/                   # Modulverzeichnis
│   ├── websocket_handler.py   # Websocket-Logik
│   ├── motor_controller.py    # Steuerung des Servo- und Linearmotors
│   ├── pump_controller.py     # Pumpensteuerung
│   ├── position_handler.py    # Logik für Endschalter und Positionshandling
│   ├── weight_sensor.py       # Waagenanbindung
│   ├── led_controller.py      # Steuerung des LED-Streifens
│   ├── command_mapper.py      # Befehlsmapper für Websocket-Befehle
│   ├── error_handler.py       # Fehlerbehandlung und Rückmeldungen
│   └── utils/                 # Hilfsfunktionen und Utility-Skripte
│       └── logger.py          # Logging
│
└── tests/                     # Unittests
    ├── test_websocket.py
    ├── test_motors.py
    ├── test_pumps.py
    └── ...
```

## TODOs

- [ ] main.py anlegen und füllen
- [ ] Websocket Klasse implementieren
- [ ] Websocket automatischer reconnect wenn Verbindung unterbrochen wird
- [ ] MotorController Klasse anlegen
- [ ] PumpController Klasse anlegen
- [ ] PositionHandler Klasse anlegen
- [ ] WeightSensor Klasse anlegen
- [ ] LEDController Klasse anlegen
- [x] CommandMapper Klasse anlegen
- [ ] ErrorHandler Klasse anlegen
- [x] Logger Klasse anlegen
- [ ] BashScript für schnelle Installation aller Python Packages

## Pins

| PINS   | INFO          | USAGE            | PINS   |INFO           | USAGE                   |
| ------ | ------------- | ---------------- | ------ | ------------- | ----------------------- |
| Pin 1  | 3.3 V         |                  | Pin 2  | 5 V           |                         |
| Pin 3  | GPIO 2        |                  | Pin 3  | 5 V           |                         |
| Pin 5  | GPIO 3        |                  | Pin 6  | Ground        | Ground for Raspberry Pi |
| Pin 7  | GPIO 4        | Limit Switch 1 C | Pin 8  | GPIO 14       | LCD SDA                 |
| Pin 9  | Ground        |                  | Pin 10 | GPIO 15       | LCD SCL                 |
| Pin 11 | GPIO 17       | Limit Switch 2 C | Pin 12 | GPIO 18 (PWM) | LED LV1                 |
| Pin 13 | GPIO 27       | Limit Switch 3 C | Pin 14 | Ground        | Shared Ground           |
| Pin 15 | GPIO 22       | Limit Switch 4 C | Pin 16 | GPIO 23       |                         |
| Pin 17 | 3.3 V         |                  | Pin 18 | GPIO 24       |                         |
| Pin 19 | GPIO 10       | Limit Switch 5 C | Pin 20 | Ground        |                         |
| Pin 21 | GPIO  9       | Limit Switch 6 C | Pin 22 | GPIO 25       | Linear Actuator IN1     |
| Pin 23 | GPIO 11       | Limit Switch 7 C | Pin 24 | GPIO 8        | Linear Actuator IN2     |
| Pin 25 | Ground        |                  | Pin 26 | GPIO 7        | Linear Actuator IN3     |
| Pin 27 | GPIO 0        | Pump 1           | Pin 28 | GPIO 1        | Linear Actuator IN4     |
| Pin 29 | GPIO 5        | Pump 2           | Pin 30 | Ground        |                         |
| Pin 31 | GPIO 6        | Pump 3           | Pin 32 | GPIO 12 (PWM) | Stepper DA              |
| Pin 33 | GPIO 13 (PWM) | Pump 4           | Pin 34 | Ground        | Ground Stepper          |
| Pin 35 | GPIO 19 (PWM) | Pump 5           | Pin 36 | GPIO 16       | Stepper Dir             |
| Pin 37 | GPIO 26       | Pump 6           | Pin 38 | GPIO 20       | Scale DT                |
| Pin 39 | Ground        |                  | Pin 40 | GPIO 21       | Scale SCK               |

## Liste der nötigen Python-Imports

- `sudo apt install python3-websocket`
- `sudo apt install python3-rx`
- `sudo apt-get install python3-pip`
- `pip install --break-system-packages 'git+https://github.com/gandalf15/HX711.git#egg=HX711&subdirectory=HX711_Python3'`

- `sudo pip3 install XYZ --break-system-packages`
