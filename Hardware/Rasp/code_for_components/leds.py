#!/usr/bin/env python3

import time
from rpi_ws281x import PixelStrip, Color

# ----------------------
#   KONFIGURATION
# ----------------------
LED_COUNT      = 41      # Anzahl deiner LEDs
LED_PIN        = 18      # GPIO (BCM) für DATA
LED_FREQ_HZ    = 800000  # Frequenz
LED_DMA        = 10      # DMA-Kanal
LED_INVERT     = False   
LED_BRIGHTNESS = 255     # (0-255)
LED_CHANNEL    = 0       # Meist 0, wenn du GPIO18 nutzt

# Erzeuge ein PixelStrip-Objekt
strip = PixelStrip(
    LED_COUNT, LED_PIN, 
    LED_FREQ_HZ, LED_DMA,
    LED_INVERT, LED_BRIGHTNESS, 
    LED_CHANNEL
)

def clear_strip(strip):
    """
    Schaltet alle LEDs aus (schwarz).
    """
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(0, 0, 0))
    strip.show()

def progress_bar(strip):
    """
    Erzeugt einen Ladebalken-Effekt:
      - Zunächst sind alle LEDs Rot
      - Dann 'wandert' Grün von links nach rechts,
        so dass man einen Fortschritt von Rot -> Grün sieht.
    """
    # 1) Alle LEDs Rot
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(255, 0, 0))  # Rot
    strip.show()
    time.sleep(0.5)

    # 2) "Ladebalken": Grün wandert von links nach rechts
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(0, 255, 0))  # Grün
        strip.show()
        time.sleep(0.05)  # Geschwindigkeit anpassen
    
    # Am Ende kurz warten, damit man das volle Grün sieht
    time.sleep(0.5)
def main():
    # LED-Streifen initialisieren
    strip.begin()
    print("Starte Ladebalken. Beenden mit STRG+C ...")

    try:
        while True:
            progress_bar(strip)
            # Nach dem Fortschritt kannst du hier
            # andere Effekte programmieren oder einfach neu starten.
    except KeyboardInterrupt:
        # Falls man per STRG+C abbricht:
        print("\nProgramm wird beendet. Schalte LEDs aus ...")
    finally:
        # Dieser Block wird IMMER ausgeführt (auch bei Fehlern oder STRG+C).
        clear_strip(strip)
        print("Alle LEDs ausgeschaltet. Programm beendet.")


if __name__ == "__main__":
    main()
