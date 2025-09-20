import time
import threading
from rpi_ws281x import PixelStrip, Color

class LEDController:
    def __init__(self, LV1_pin=18, led_count=41, brightness=128):
        # Basic init log
        print("LED Controller initializing…")

        # ----------------------
        #   KONFIGURATION
        # ----------------------
        self.LED_COUNT      = int(led_count)      # Anzahl deiner LEDs
        self.LED_PIN        = LV1_pin      # GPIO (BCM) für DATA
        self.LED_FREQ_HZ    = 800000  # Frequenz
        # Use a DMA channel unlikely to conflict with pigpio (e.g., 5)
        self.LED_DMA        = 5       # DMA channel
        self.LED_INVERT     = False   
        self.LED_BRIGHTNESS = int(brightness)     # (0-255)
        # Select channel based on pin
        # PWM mode: 12/18->ch0, 13/19->ch1; PCM mode (GPIO21) uses channel 0
        if self.LED_PIN in (12, 18, 21):
            self.LED_CHANNEL = 0
        elif self.LED_PIN in (13, 19):
            self.LED_CHANNEL = 1
        else:
            self.LED_CHANNEL = 0

        # Erzeuge ein PixelStrip-Objekt
        self.strip = PixelStrip(
            self.LED_COUNT, self.LED_PIN, 
            self.LED_FREQ_HZ, self.LED_DMA,
            self.LED_INVERT, self.LED_BRIGHTNESS, 
            self.LED_CHANNEL
        )

        self.strip.begin()
        print(f"LED Controller ready (pin={self.LED_PIN}, count={self.LED_COUNT}, brightness={self.LED_BRIGHTNESS}, channel={self.LED_CHANNEL})")
        # Concurrency/suspension control to avoid conflicts during critical motions
        self._suspend = False
        self._lock = threading.Lock()
        self._strobe_thread = None
        self._strobe_stop = threading.Event()

    def cleanup(self):
        """
        Schaltet alle LEDs aus (schwarz).
        """
        self.stop_strobe()
        self.set_off()

    def set_off(self):
        with self._lock:
            if self._suspend:
                return
            for i in range(self.strip.numPixels()):
                self.strip.setPixelColor(i, Color(0, 0, 0))
            self.strip.show()

    def set_brightness(self, value: int):
        with self._lock:
            self.LED_BRIGHTNESS = max(0, min(255, int(value)))
            self.strip.setBrightness(self.LED_BRIGHTNESS)
            if self._suspend:
                return
            self.strip.show()

    def set_color(self, r: int, g: int, b: int):
        with self._lock:
            if self._suspend:
                return
            r = max(0, min(255, int(r)))
            g = max(0, min(255, int(g)))
            b = max(0, min(255, int(b)))
            for i in range(self.strip.numPixels()):
                self.strip.setPixelColor(i, Color(r, g, b))
            self.strip.show()

    def _strobe_loop(self, r: int, g: int, b: int, period_s: float):
        on = True
        while not self._strobe_stop.is_set():
            if self._suspend:
                # When suspended, keep LEDs off and wait
                self.set_off()
                time.sleep(period_s)
                continue
            if on:
                self.set_color(r, g, b)
            else:
                self.set_off()
            on = not on
            time.sleep(period_s)

    def start_strobe(self, r: int, g: int, b: int, speed_hz: float = 8.0):
        with self._lock:
            self.stop_strobe()
            period = max(0.01, 1.0 / float(speed_hz))
            self._strobe_stop.clear()
            self._strobe_thread = threading.Thread(target=self._strobe_loop, args=(r, g, b, period), daemon=True)
            self._strobe_thread.start()

    def stop_strobe(self):
        if self._strobe_thread and self._strobe_thread.is_alive():
            self._strobe_stop.set()
            self._strobe_thread.join(timeout=0.5)
        self._strobe_thread = None

    def set_progress(self, progress: float):
        """
        Setze einen statischen Progress (0..1): von Rot (0) zu Grün (1),
        wobei der gefüllte Anteil links→rechts grün und der Rest rot ist.
        """
        p = max(0.0, min(1.0, float(progress)))
        total = self.strip.numPixels()
        green_pixels = int(round(p * total))
        with self._lock:
            if self._suspend:
                return
            for i in range(total):
                if i < green_pixels:
                    self.strip.setPixelColor(i, Color(0, 255, 0))
                else:
                    self.strip.setPixelColor(i, Color(255, 0, 0))
            self.strip.show()

    def suspend(self, enabled: bool):
        """Temporarily suspend LED updates during critical motions."""
        with self._lock:
            self._suspend = bool(enabled)
            if self._suspend:
                try:
                    self.set_off()
                except Exception:
                    pass
