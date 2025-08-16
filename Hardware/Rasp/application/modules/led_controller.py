import time
from rpi_ws281x import PixelStrip, Color

class LEDController:
    def __init__(self, LV1_pin=18):
        print("LED Controller initialized")

        # ----------------------
        #   KONFIGURATION
        # ----------------------
        self.LED_COUNT      = 41      # Anzahl deiner LEDs
        self.LED_PIN        = LV1_pin      # GPIO (BCM) für DATA
        self.LED_FREQ_HZ    = 800000  # Frequenz
        self.LED_DMA        = 10      # DMA-Kanal
        self.LED_INVERT     = False   
        self.LED_BRIGHTNESS = 128     # (0-255)
        self.LED_CHANNEL    = 0       # Meist 0, wenn du GPIO18 nutzt

        # Erzeuge ein PixelStrip-Objekt
        self.strip = PixelStrip(
            self.LED_COUNT, self.LED_PIN, 
            self.LED_FREQ_HZ, self.LED_DMA,
            self.LED_INVERT, self.LED_BRIGHTNESS, 
            self.LED_CHANNEL
        )

        self.strip.begin()

    def cleanup(self):
        """
        Schaltet alle LEDs aus (schwarz).
        """
        for i in range(self.strip.numPixels()):
            self.strip.setPixelColor(i, Color(0, 0, 0))
        self.strip.show()

    def progress_bar(self):
        """
        Erzeugt einen Ladebalken-Effekt:
        - Zunächst sind alle LEDs Rot
        - Dann 'wandert' Grün von links nach rechts,
            so dass man einen Fortschritt von Rot -> Grün sieht.
        """
        # 1) Alle LEDs Rot
        for i in range(self.strip.numPixels()):
            self.strip.setPixelColor(i, Color(255, 0, 0))  # Rot
        self.strip.show()
        time.sleep(0.5)

        # 2) "Ladebalken": Grün wandert von links nach rechts
        for i in range(self.strip.numPixels()):
            self.strip.setPixelColor(i, Color(0, 255, 0))  # Grün
            self.strip.show()
            time.sleep(0.05)  # Geschwindigkeit anpassen
        
        # Am Ende kurz warten, damit man das volle Grün sieht
        time.sleep(0.5)
