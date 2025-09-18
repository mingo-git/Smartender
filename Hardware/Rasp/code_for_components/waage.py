import RPi.GPIO as GPIO
from hx711 import HX711
import time
import logging
from collections import deque
import statistics

# Logging konfigurieren
logging.basicConfig(filename="waage.log", level=logging.INFO, format="%(asctime)s - Gewicht: %(message)s g")

# Pin-Definitionen
DT_PIN = 20   # GPIO 5 (Pin 29)
SCK_PIN = 21  # GPIO 6 (Pin 31)

# HX711 initialisieren
hx = HX711(DT_PIN, SCK_PIN)

print("Test")

# Skalierungsfaktor
SCALING_FACTOR = 1140

# Median-Filter mit den letzten 5 Werten
NUM_SAMPLES = 5
weight_samples = deque(maxlen=NUM_SAMPLES)

def clean_and_exit():
    print("GPIO sauber gemacht. Tschüss, Bruder!")
    GPIO.cleanup()
    exit()

def read_weight():
    """Liest die rohen Daten und berechnet das Gewicht in Gramm."""
    data = hx.get_raw_data()
    if data is not None:
        avg_data = sum(data) / len(data)  # Durchschnitt berechnen
        weight_in_grams = avg_data / SCALING_FACTOR
        return weight_in_grams
    else:
        print("Fehler beim Lesen der Daten.")
        return None

try:
    # Initialisieren und tarieren
    print("initializing")
    hx.reset()
    print("Bitte kalibrieren... Stelle die Waage auf 0.")
    time.sleep(0.5)
    tare_value = read_weight()
    print(f"Tara-Wert gesetzt: {tare_value}")

    print("Waage kalibriert. Messe Gewicht...")

    while True:
        weight = read_weight()
        if weight is not None:
            net_weight = weight - tare_value
            weight_samples.append(net_weight)

            # Median berechnen
            smoothed_weight = statistics.median(weight_samples)

            output = f"Gewicht: {smoothed_weight:.2f} g"
            print(output)
            logging.info(f"{smoothed_weight:.2f}")

            # Beispiel: System stoppen bei mehr als 400 g
            if smoothed_weight > 1000:
                print("System wird gestoppt: Gewicht über 400 g!")
                logging.info("System gestoppt: Gewicht über 400 g!")
                clean_and_exit()
                break

        time.sleep(0.25)

except KeyboardInterrupt:
    clean_and_exit()

