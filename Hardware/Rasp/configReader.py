import json

CONFIG_PATH = "./Hardware/Rasp/config.json"

# Funktion zum Lesen und Deserialisieren der config.json
def readConfig(file_path=CONFIG_PATH):
    try:
        with open(file_path, "r") as file:
            config = json.load(file)
        return config  # Gibt das deserialisierte Objekt zurück
    except FileNotFoundError:
        print(f"Error: {file_path} wurde nicht gefunden.")
        return None
    except json.JSONDecodeError:
        print(f"Error: {file_path} enthält ungültiges JSON.")
        return None

# Funktion zum Speichern und Überschreiben der config.json
def safeConfig(config, file_path=CONFIG_PATH):
    try:
        with open(file_path, "w") as file:
            json.dump(config, file, indent=4)
        print(f"Die Konfiguration wurde erfolgreich in {file_path} gespeichert.")
    except Exception as e:
        print(f"Error beim Speichern der Konfiguration: {e}")

# Beispielnutzung:
if __name__ == "__main__":

    # Lesen der Konfiguration
    config = readConfig()

    if config:
        print("Aktuelle Konfiguration:", config)

    # Konfiguration ändern und speichern
    new_config = {
        "wlan_ssid": "MeinNetzwerk",
        "wlan_pass": "SicheresPasswort123",
        "user_id": 42
    }
    
    safeConfig(new_config)
