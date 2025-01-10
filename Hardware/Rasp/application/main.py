from modules.websocket_handler import WebSocketHandler
from modules.motor_controller import MotorController
from modules.pump_controller import PumpController
from modules.position_handler import PositionHandler
from modules.led_controller import LEDController
from modules.error_handler import ErrorHandler
from modules.command_mapper import CommandMapper
from modules.utils.logger import Logger

def main():
  logger = Logger()
  # Log-Einträge erzeugen
  logger.log("INFO", "Die Anwendung wurde gestartet", "Main")
  logger.log("ERROR", "Ein Fehler ist aufgetreten", "Database")
  logger.log("DEBUG", "Debugging des Moduls", "ModuleA")
  logger.log("ALERT", "Kritischer Zustand erkannt", "SystemMonitor")
  print(main)

if __name__ == "__main__":
  main()