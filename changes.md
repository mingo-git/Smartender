# Smartender – Änderungen und aktueller Stand

Dieses Dokument hält fortlaufend alle vorgenommenen Änderungen fest (Backend, Hardware, App). Bitte bei weiteren Anpassungen weiterpflegen.

## 2025-09-19 – Phase 0, Schritte 1 & 2

Ziele:
- Phase 0: Maintenance-Endpoint + Protokoll + Hardware-Dispatch.
- Schritt 1: Flush single slot (Hold-to-Flush) – 6 Pumpen als 2x3-Raster, gedrückt halten = Pumpe läuft.
- Schritt 2: „Flush complete system“ vorerst ausblenden (Feature-Flag).

Änderungen – Backend (Go):
- Neuer Endpoint POST `/api/user/maintenance`.
  - Datei: `Server/internal/server/routes.go` – Route registriert.
  - Datei (neu): `Server/internal/handlers/maintenance.go` – validiert Payload und sendet über bestehende Hardware-WebSocket-Verbindung weiter.
- Unterstützte Typen: `pump_hold` (start/stop), `manual_move` (x/z), `emergency_stop`, `flush_slot`, `flush_all`, `light_mode` (defensiv weitergeleitet).

Änderungen – Hardware (Raspberry Pi / Python):
- Maintenance-Verarbeitung vor Cocktail-Mapper in `main.py`.
  - `manual_move`: X steuert Stepper (Riemen), Z steuert Linearantrieb (zeitbasiert, Treiber). 
  - `emergency_stop`: stoppt Stepper-PWM und Aktuator.
  - `pump` (für `pump_hold`): start/stop einzelner Pumpe; Safety: nur in Home-Position (Limit 0). Falls nicht Home → erst heimfahren, dann Pumpe schalten.
- PumpController erweitert um `start_pump(pump_index)` und `stop_pump(pump_index)`.
- Dateien:
  - `Hardware/Rasp/application/main.py` – Maintenance-Dispatch + Pumpe-Start/Stop integriert.
  - `Hardware/Rasp/application/modules/pump_controller.py` – neue Methoden, Logging, Safety.

Änderungen – App (Flutter):
- Maintenance UI:
  - „Flush complete system“ ausgeblendet per Flag `_showFlushAll = false`.
  - Neuer Abschnitt „Flush single slot (Hold)“: 2x3 Grid „Pumpe 1..6“, gedrückt halten startet Pumpe, loslassen stoppt; visuelles Highlight im aktiven Zustand.
- Services:
  - `MaintenanceService`: `startPumpHold(pumpIndex)` und `stopPumpHold(pumpIndex)` hinzugefügt.
- Dateien:
  - `App/smartender_flutter_app/lib/services/maintenance_service.dart`
  - `App/smartender_flutter_app/lib/screens/homesceens/settingsscreens/maintenance_screen.dart`

Akzeptanz – erreicht:
- POST `/api/user/maintenance` erreicht Hardware; unbekannte Payloads crashen nicht.
- Hold-to-Flush funktioniert: gedrückt halten läuft, loslassen stoppt; UI-Feedback sichtbar.
- „Flush complete system“ ist nicht sichtbar, App baut weiterhin.

Offene Punkte/Nächstes:
- LEDs und Waage bleiben unberührt bis der Piston/Driver stabil ist.
- Optional: WebSocket-Status zurück zur App für aktives Pumpen-Feedback (derzeit lokales Press-Highlight).

## 2025-09-19 – Docker Compose Dev-Override

- Neues File: `Server/docker-compose.dev.yaml` (Compose-Override) setzt `ENVIRONMENT=dev` für `smartender-app`.
- Start im Dev-Modus (inkl. DB) jetzt mit:
 - Verworfen zugunsten eines vereinfachten Default-Setups (keine getrennten dev/prod Files).

### Logging-Verbesserungen (Server)
  - `Server/internal/handlers/maintenance.go`: Ausführlichere Logs für `/maintenance`:
  - user_id, hardware_id, maintenance_type
  - Bei `pump_hold`: index und action
- Vollständiges gesendetes Payload und Hinweis, wenn Hardware nicht verbunden ist

## 2025-09-19 – Single-Device Mode (ohne hardware_id)

- WebSocket Hardware: `Server/internal/handlers/socket.go` akzeptiert jede MAC und ordnet die Verbindung fest `hardware_id=1` zu.
- Maintenance-Endpoint: `Server/internal/handlers/maintenance.go` macht `hardware_id` optional. Wenn nicht gesetzt, wird die erste aktive Hardware-Verbindung verwendet.
- App: `ApiClient.performMaintenance(...)` sendet kein `hardware_id` mehr.
- Sonstiges bleibt unverändert (Drinks/Slots weiterhin hardware_id-basiert).

### Stabiler Gerätebezug (Fake MAC + feste Hardware-ID)
- Dev-Seeding aktualisiert: `Server/internal/query/createTables.go`
  - Hardware ID 1 erhält feste MAC `AA:BB:CC:DD:EE:FF` und Name "Smartender Single-Device".
  - User 1 ist nun Admin für Hardware 1 (zusätzlich zu bestehenden Beispielen).
- App: `_hardwareId = '1'` für Drinks/Slots/Rezepte.
- Hardware-Client (`main.py`): unterstützt `STATIC_MAC` Env, um die gesendete MAC zu fixieren.

## 2025-09-19 – Vereinfachtes Default-Compose & Start-Skripte

- `Server/docker-compose.yml` ist das Standard-Compose (keine dev/prod Variants).
- `ENVIRONMENT=prod` bleibt Standard; fällt automatisch auf lokale Postgres-DSN zurück, wenn `INSTANCE_CONNECTION_NAME` fehlt (siehe `internal/config/config.go`).
- Skripte hinzugefügt:
- `Server/start.sh` – Build & Up (detached)
  - `Server/stop.sh` – Down
  - `Server/restart.sh` – Down + Up mit Build
- `Server/logs.sh` – Folgt Backend-Logs (`smartender-app`)

## 2025-09-19 – App: Server-Verbindungsstatus (grüner/roter Punkt)

- Neuer Component: `lib/components/connection_dot.dart` – zeigt kleinen Punkt je nach WebSocket-Status (grün=verbunden, rot=getrennt/Fehler).
- Global in `MaterialApp.builder` eingeblendet (Top-Right), sodass es auf allen Screens sichtbar ist.

### 2025-09-19 – App UI Feinschliff Status-Badges (S/H)
- Anpassung der globalen Statusanzeigen (rechts oben):
  - Darstellung von Buchstaben im Kreis: „S“ (Server) und „H“ (Hardware) statt separatem Punkt+Label.
  - Größenanpassungen:
    - Erste Iteration: Reduktion auf ca. 40% der ursprünglichen Größe (Kreise ~4.8–5.6 px) – Feedback: zu klein.
    - Final: Vergrößert auf ~16.8 px Durchmesser, Text zentriert im Kreis; vertikal exakt zum „Smartender“-Titel (30 px) ausgerichtet.
- Dateien:
  - `App/smartender_flutter_app/lib/components/connection_badge.dart` – Kreis mit Buchstabe („S“/„H“), Größenlogik, Theme‑Farben.
  - `App/smartender_flutter_app/lib/main.dart` – exakte vertikale Ausrichtung relativ zur Titelzeile (Safe‑Area + Padding + (30 − Kreis)/2).
  - `App/smartender_flutter_app/lib/components/connection_dot.dart` – interner Punkt initial verkleinert (40%); aktuell Badge‑Variante aktiv im Header.

Akzeptanz – erreicht:
- Statuskreise sind klar erkennbar, Buchstaben zentriert, optisch am „Smartender“-Schriftzug ausgerichtet.

### 2025-09-19 – App Maintenance-UI: Pumpen-Tiles mit Ingredient
- Tiles im Bereich „Flush single slot (Hold)“ zeigen jetzt die zugeordnete Zutat (Ingredient) pro Pumpe an, statt „Zum Spülen halten“.
- Beschriftung vereinheitlicht: „Pump 1..6“ (nicht „Pumpe …“).
- Umsetzung: liest Slot-Daten lokal (WebSocket-first) und mappt Pumpen 1..6 → Slots 6..11; zeigt `drink.name`/`drink_name` oder „Empty“.
- Dateien:
  - `App/smartender_flutter_app/lib/screens/homesceens/settingsscreens/maintenance_screen.dart` (Import `SlotService`, FutureBuilder je Tile, Textanpassungen)

## 2025-09-19 – Hardware Start & Debug Verbesserungen

- `Hardware/Rasp/application/main.py`
  - WebSocket-URL konfigurierbar via Env `SMARTENDER_WS_URL` (Fallback: prod-URL).
  - Boot-Marker `boot_marker.txt` wird bei Start geschrieben (hilft, Programmausführung zu prüfen).
  - Ausführlichere Logs rund um Homing (Check, Start, Ende, Fehlerbehandlung).
- `Hardware/Rasp/application/modules/motor_controller.py`
  - Prüft `pigpio`-Verbindung und loggt Fehler, wenn `pigpiod` nicht läuft.

### 2025-09-19 – WebSocket Sofortlösung & Log-Reduktion
- Ursache 404 (Cloud Run) umgangen: Pi verbindet sich jetzt zuverlässig mit `wss://smartender.lextron.dev/smartender/socket` über `.env`.
- Änderung: `.env` wird in `main.py` vor dem Lesen der URL geladen, damit `SMARTENDER_WS_URL` sicher greift.
  - Datei: `Hardware/Rasp/application/main.py` – `load_dotenv()` vor den `os.getenv()`‑Zugriff verschoben; WS‑URL geloggt.
- Hardware‑Client Trace optional: `WEBSOCKET_TRACE=true` schaltet `websocket-client` Trace an; standardmäßig aus (ruhigere Logs).
  - Datei: `Hardware/Rasp/application/modules/websocket_handler.py` – `websocket.enableTrace()` per Env steuerbar.
- Frontend‑WebSocket Ping/Pong Logs reduziert (Keep‑Alive bleibt):
  - Datei: `Server/internal/handlers/websocket_frontend.go` – „Pong erhalten“/„Ping gesendet“ nicht mehr gespammt; nur Fehler bleiben sichtbar.

Akzeptanz – erreicht:
- Hardware nutzt `.env`‑URL; weniger Lograuschen; Ping/Pong funktioniert weiter als Keep‑Alive ohne unnötige Ausgaben.

### 2025-09-19 – WebSocket URL hart verdrahtet (Hardware)
- Beobachtung: Trotz `.env` nutzte die Hardware teils eine falsche WS‑URL → Verbindungsversuche auf Cloud‑Run endeten mit 404.
- Entscheidung: Bis das Cloud‑Routing stabil ist, wird die Hardware fest auf den funktionierenden Socket verdrahtet.
  - Datei: `Hardware/Rasp/application/main.py` – `url = "wss://smartender.lextron.dev/smartender/socket"` hartcodiert; Logausgabe angepasst.
- Hinweis: Sobald Cloud‑Run stabil erreichbar ist, `SMARTENDER_WS_URL` wieder aus `.env` lesen (Change hier rückbaubar).

#### Nachtrag: Legacy Listener korrigiert
- `Hardware/Rasp/websocket_listener.py` verwendete noch die alte Cloud‑Run‑URL und falsche Header.
- Aktualisiert auf harte Produktionswerte:
  - URL: `wss://smartender.lextron.dev/smartender/socket`
  - Header: `x-api-key`, `Hardware-Auth-Key`, `Identifier=AA:BB:CC:DD:EE:FF`
  - Trace disabled (weniger Lograuschen)

### 2025-09-19 – Re-Enable .env gesteuerte WS-URL (Hardware)
- Wunsch: Option über `.env` wieder aktivieren, damit Deployments per Umgebungsvariable steuerbar bleiben.
- Umsetzung: In `Hardware/Rasp/application/main.py` wird `.env` früh geladen und `SMARTENDER_WS_URL` genutzt – mit Fallback auf `wss://smartender.lextron.dev/smartender/socket`.
- Wirkung: Prod bleibt unverändert lauffähig; Test-/Staging-Umgebungen können die URL per `.env` übersteuern.

## 2025-09-19 – Autostart (Hardware) für Entwicklung deaktiviert

- Systemd-Service `myapp.service` identifiziert als Autostart der Hardware.
- Für Entwicklung deaktiviert/gestoppt:
  - `sudo systemctl disable myapp`
  - `sudo systemctl stop myapp`
- Geplantes Re-Enable (später):
  - `sudo systemctl enable myapp && sudo systemctl start myapp`
- Empfohlene Service-Konfiguration (prüfen/anpassen vor Re-Enable):
  - `WorkingDirectory=/home/admin/Smartender/Hardware/Rasp/application`
  - `EnvironmentFile=/home/admin/Smartender/Hardware/Rasp/application/.env`
  - `ExecStart=/home/admin/myenv/bin/python3 /home/admin/Smartender/Hardware/Rasp/application/main.py`

### 2025-09-19 – Logging gestrafft (Server) & Flush-Fix (Hardware)
- Server-Logs komprimiert für Slots/Drinks:
  - `Server/internal/handlers/slots.go`: Einzelzeilen pro Drink/Slot entfernt; ein kompaktes Mapping in einer Zeile (`🍹 [SLOTS MAP] ...`).
- Hardware Flush (Hold-to-Flush) repariert und sichtbar gemacht:
  - `Hardware/Rasp/application/main.py`: `process_maintenance` vor Aufruf definiert; zusätzlicher Log `Pump hold: idx=… action=…`.

### 2025-09-19 – BTS7960 Testskript + Verdrahtung
- Neues Testskript für Linearaktuator via BTS7960:
  - Datei: `Hardware/Rasp/application/tests/test_bts7960_actuator.py`
  - Funktionen: EN- und PWM-Pins initialisieren, Vollhub OUT→IN bei 100% Duty, sauberes Stoppen.
  - Standard-Pins (BCM): `R_EN=23`, `L_EN=24`, `R_PWM=18`, `L_PWM=25`, `PWM_FREQ=1kHz`.
  - Parameter: `FULL_TRAVEL_S` (Standard 6.0s) bestimmt die Vollhubdauer je Richtung.
- Verdrahtung (Kurzanleitung):
  - RPi: `5V → VCC` (Logik), `GND → GND` (gemeinsame Masse), Steuerleitungen wie oben.
  - Netzteil 12V → BTS7960 Leistungseingang (VIN+/VIN-), Aktuator an OUT+/OUT-.
  - Nur eine PWM-Seite aktiv: OUT = `R_PWM>0 & L_PWM=0`; IN = `L_PWM>0 & R_PWM=0`; beide EN=HIGH beim Fahren, sonst LOW.
- Aufruf: `sudo -E /home/admin/myenv/bin/python3 Hardware/Rasp/application/tests/test_bts7960_actuator.py`
  - Anpassung: Hub-Reihenfolge gedreht (erst IN/einfahren, dann OUT/ausfahren), um beobachtetes Verhalten zu spiegeln.
