import os
import threading
from datetime import datetime

class Logger:
    _instance = None
    _lock = threading.Lock()  # Für Thread-Sicherheit bei Multithreading

    LOG_FILE = "log.txt"
    MAX_LINES = 1000

    def __new__(cls):
        """Implementierung des Singleton-Musters"""
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(Logger, cls).__new__(cls)
                cls._instance._initialize()
        return cls._instance

    def _initialize(self):
        """Initialisiert den Logger"""
        self.log_levels = ["ALERT", "CRITICAL", "ERROR", "WARNING", "NOTICE", "INFO", "DEBUG"]

    def log(self, level: str, message: str, context: str):
        """
        Fügt einen Log-Eintrag hinzu, formatiert ihn tabellarisch und schreibt ihn in die Konsole und eine Datei.

        Diese Methode erzeugt einen Log-Eintrag im Format:
        "| <timestamp> | <level> | <context> | <message>"
        Der Eintrag wird in der Konsole ausgegeben und in eine Log-Datei geschrieben. 
        Wenn die maximale Zeilenanzahl der Log-Datei überschritten wird, werden ältere Einträge entfernt,
        um Platz für neue Einträge zu schaffen.

        :param level: (str) Das Log-Level, das die Priorität oder Schwere des Logs angibt. 
                    Mögliche Werte: "ALERT", "CRITICAL", "ERROR", "WARNING", "NOTICE", "INFO", "DEBUG".
        :param message: (str) Die Nachricht, die den eigentlichen Inhalt des Logs beschreibt.
        :param context: (str) Der Kontext, der den Ursprung oder die Komponente des Logs angibt (z. B. "Main", "Database").

        :raises ValueError: Wird ausgelöst, wenn das angegebene `level` nicht zu den erlaubten Log-Levels gehört.

        Log-Level-Beschreibungen:
            - ALERT: Kritische Ereignisse, die sofortiges Eingreifen erfordern.
            - CRITICAL: Schwere Fehler, die die Anwendung beeinträchtigen könnten.
            - ERROR: Fehler, die eine Funktionalität verhindern.
            - WARNING: Warnungen, die auf potenzielle Probleme hinweisen.
            - NOTICE: Normale, aber wichtige Ereignisse.
            - INFO: Allgemeine Informationen zum Ablauf der Anwendung.
            - DEBUG: Detaillierte Debug-Informationen für die Fehleranalyse.

        Beispiel:
            >>> logger = Logger()
            >>> logger.log("INFO", "Die Anwendung wurde gestartet", "Main")
            Ausgabe in Konsole:
            | 2025-01-10 14:25:37 | INFO     | Main            | Die Anwendung wurde gestartet
            Eintrag in der Datei:
            | 2025-01-10 14:25:37 | INFO     | Main            | Die Anwendung wurde gestartet

        Hinweis:
            - Die Logs in der Datei sind auf eine maximale Zeilenanzahl (`MAX_LINES`) begrenzt.
            - Ältere Einträge werden entfernt, wenn die Anzahl der Zeilen überschritten wird.
    
        """
        if level not in self.log_levels:
            raise ValueError(f"Ungültiges Log-Level: {level}")
        
        # Log-Formatierung mit fester Spaltenbreite
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = (
            f"| {timestamp:<19} | {level:<8} | {context:<20} | {message}\n"
        )

        # Ausgabe in die Konsole
        print(log_entry, end="")

        # Schreiben in die Datei
        self._write_to_file(log_entry)

    def _write_to_file(self, log_entry: str):
        """Schreibt den Log-Eintrag in die Datei, entfernt alte Einträge bei Überschreitung"""
        if not os.path.exists(self.LOG_FILE):
            with open(self.LOG_FILE, "w") as log_file:
                log_file.write(log_entry)
            return

        # Datei lesen und die Anzahl der Zeilen prüfen
        with open(self.LOG_FILE, "r") as log_file:
            lines = log_file.readlines()

        # Neue Zeile hinzufügen und ggf. ältere entfernen
        lines.append(log_entry)
        if len(lines) > self.MAX_LINES:
            lines = lines[-self.MAX_LINES:]  # Nur die letzten MAX_LINES behalten

        # Datei überschreiben
        with open(self.LOG_FILE, "w") as log_file:
            log_file.writelines(lines)