# Smartender – Umsetzungsplan für gewünschte Verbesserungen

Dieser Plan beschreibt die schrittweise Umsetzung der sieben genannten Punkte über App (Flutter), Backend (Go) und Hardware (Raspberry Pi). Für jeden Punkt sind konkrete Aufgaben, betroffene Dateien/Module sowie Akzeptanzkriterien enthalten. Wir arbeiten die Punkte in Phasen ab, sodass nach jedem Schritt ein lauffähiger, getesteter Zustand entsteht.

Repository-Stand (relevant für den Plan):
- App (Flutter): `App/smartender_flutter_app/...`
  - API/Aktionen: `lib/services/api_client.dart`, `lib/services/maintenance_service.dart`
  - UI Maintenance: `lib/screens/homesceens/settingsscreens/maintenance_screen.dart`
- Backend (Go): `Server/internal/server/routes.go`, `Server/internal/handlers/*.go`, `Server/internal/utils/*.go`
  - Es gibt aktuell keinen HTTP-Endpunkt für „/api/user/maintenance“, der in der App bereits verwendet wird.
  - WebSocket zur Hardware existiert: `Server/internal/handlers/socket.go` (Map `hardwareConnections`)
- Hardware (Raspberry Pi): `Hardware/Rasp/application/...`
  - Hauptprogramm: `application/main.py`
  - Pumpen: `modules/pump_controller.py`
  - Stepper: `modules/motor_controller.py`
  - Linearaktuator: `modules/actuator_controller.py`
  - Waage: `modules/weight_sensor.py` (HX711) + Test: `Hardware/Rasp/code_for_components/waage.py`
  - LEDs: `modules/led_controller.py`


## Phase 0 – Grundlagen & technische Voraussetzungen

- Backend ergänzt einen Maintenance-HTTP-Endpunkt (POST `"/api/user/maintenance"`).
  - Datei: `Server/internal/server/routes.go` → `usersRouter.HandleFunc("/maintenance", handlers.PerformMaintenance).Methods("POST")`
  - Datei (neu): `Server/internal/handlers/maintenance.go` für Parsing des Requests und Dispatch an die Hardware (via WebSocket).
- Einfaches, erweiterbares Maintenance-Protokoll über WebSocket definieren:
  - Nachrichtenformat vom Backend → Hardware (JSON):
    - Pumpen-Hold: `{ "maintenance": { "type": "pump", "index": 0..5, "action": "start"|"stop" } }`
    - Licht: `{ "maintenance": { "type": "light", "mode": "Off|Solid|Pulse|Party", "color": "#RRGGBB"?, "brightness": 0..255? } }`
    - Not-Aus (optional): `{ "maintenance": { "type": "emergency_stop" } }`
  - Hardware `main.py` erweitert: neue Message-Pipeline vor dem bestehenden Cocktail-Mapper. Falls `maintenance`-Objekt vorhanden ist, entsprechende Handler aufrufen (Pumpen/LED/…); sonst wie bisher Drinks verarbeiten.
- Docker/ENV: sicherstellen, dass API-Key/Auth wie in App vorhanden (Header `X-API-KEY`) auch für Maintenance gilt und die Hardware weiterhin per WebSocket angemeldet ist.

Akzeptanzkriterien
- POST auf `/api/user/maintenance` mit gültigen Parametern erreicht die Hardware (Log-Ausgaben sichtbar) und führt keinen Crash herbei, wenn `maintenance`-Payload unbekannt ist (defensives Handling).


## 1) Flush single slot – 6 Pumpen als 2x3 Raster mit „Hold-to-Flush“

App (Flutter)
- Maintenance-Screen: Eigenes UI-Element mit 6 Kacheln (2 Spalten x 3 Zeilen), Labels: „Pumpe 1“ … „Pumpe 6“.
  - Datei: `maintenance_screen.dart` – neuen Abschnitt „Flush single slot (Hold)“ mit `GestureDetector` oder `Listener`.
  - Mapping: `Pumpe n` → Pumpenindex `n-1` (Hardware: Pumpenindex 0..5 entspricht Slots 6..11).
- Interaktion: „Hold-to-Flush“
  - `onTapDown`/`onPanDown` → API-Aufruf: `maintenance_type = "pump_hold"`, `action = "start"`, `pump_index = 0..5`
  - `onTapUp`/`onTapCancel` → API-Aufruf: `action = "stop"`
  - API-Client erweitert: `ApiClient().performMaintenance({ "maintenance_type": "pump_hold", ... })` (Methodenwrapper optional).

Backend (Go)
- Handler `PerformMaintenance` wertet `maintenance_type` aus.
  - Für `pump_hold`: validiert `pump_index` und `action` („start|stop“), baut das WebSocket-Maintenance-JSON (siehe Phase 0) und sendet es an die korrekte Hardware-Verbindung (`hardwareConnections`).

Hardware (Python)
- `main.py` ergänzt: Maintenance-Dispatch vor Drink-Processing.
  - Für `type == "pump"`: Falls `action == start` → `GPIO.HIGH` für Index; bei `stop` → `GPIO.LOW`.
  - Sicherheit: Nur pumpen, wenn Position „0“ (Home). Wenn nicht, zuerst nach Home fahren oder Fehler loggen (bestehende Logik in `pump_controller` respektieren).

Akzeptanzkriterien
- Beim Gedrückthalten pumpt die jeweilige Pumpe kontinuierlich, beim Loslassen stoppt sie ohne merkliche Verzögerung (<150ms Netzwerk + Verarbeitung).
- UI zeigt klar an, welche Pumpe gerade aktiv ist (z.B. Kachel-Highlight).


## 2) „Flush complete system“ vorerst ausblenden, nicht löschen

App (Flutter)
- In `maintenance_screen.dart` die Kachel „Flush complete system“ auskommentieren bzw. Feature-Flag `showFlushAll = false` einführen.
- Code der Aktion (Funktion) bleibt im Projekt, wird aber nicht gerendert.

Akzeptanzkriterien
- Die Option ist in der App nicht mehr sichtbar, ohne dass Build-Fehler auftreten.


## 3) Light Settings – LEDs flexibel steuern (App, Backend, Hardware)

App (Flutter)
- UI vorhanden (`_showLightSettingsPopup()`); Dropdown enthält `Off | Solid | Pulse | Party`.
- Optional erweitern um Color-Picker + Helligkeits-Slider (später). Fürs Erste reichen Modi.
- `MaintenanceService.setLightMode(mode)` belässt API-Signatur; Backend übernimmt Übersetzung.

Backend (Go)
- `PerformMaintenance`: Case `maintenance_type == "light_mode"` → WebSocket JSON `{ maintenance: { type: "light", mode: "..." } }` senden.
- Später: optionale Felder `color`, `brightness` akzeptieren und durchreichen.

Hardware (Python)
- `LEDController` existiert. Ergänzen eines Light-Mode-Handlers in `main.py`:
  - `Off`: `cleanup()` (alle LEDs aus)
  - `Solid`: einfarbig setzen (Default-Farbe oder via `color`-Hex)
  - `Pulse`: periodisches Dimmen
  - `Party`: Farbwechsel / Rainbow
- Performance: Effekte als nicht-blockierende Loops (Thread/Task) implementieren, mit Cancel-Flag, damit Modes schnell wechselbar sind.

Akzeptanzkriterien
- Wechsel zwischen den Modi funktioniert stabil. LEDs lassen sich An/Aus schalten. Keine Blockade anderer Funktionen (Pumpen/Stepper).


## 4) Waage – Testen und in den Füllprozess integrieren

Vorhanden
- Modul: `Hardware/Rasp/application/modules/weight_sensor.py` (HX711, Mittelwertbildung)
- Test/Beispiel: `Hardware/Rasp/code_for_components/waage.py`

A) Testcode ausführen (auf dem Raspberry Pi)
- Voraussetzungen (einmalig auf dem Pi):
  - `sudo apt-get update && sudo apt-get install -y python3-pip python3-venv pigpio` (falls noch nicht vorhanden)
  - `python3 -m venv venv && source venv/bin/activate`
  - `pip install RPi.GPIO hx711 rpi-ws281x pigpio`
  - `sudo systemctl enable pigpiod && sudo systemctl start pigpiod` (für Stepper-Tests nötig)
- Test starten:
  - `cd Hardware/Rasp/code_for_components`
  - `python3 waage.py` (legt Messwerte in `waage.log` ab und gibt Gewicht in g aus)

B) Integration in Füllprozess
- Beim Start: Waage „taren“ (nullen) – z.B. in `main.py` direkt nach HW-Init: `weight_sensor.tare()`.
- Füllen nach Gewicht:
  - Non-Alcoholic („Pumpen“): Pumpdauer dynamisch anhand Gewicht anstatt pauschaler Sekunden. Vorgehen:
    - Gewicht vor Start speichern, Pumpe einschalten und in kurzem Intervall `read_weight()` pollen.
    - Zielmenge in ml → Gramm (≈ 1 ml ~ 1 g; für Liköre später Kalibrierfaktor je Drink).
    - Bei Erreichen des Zielgewichts Pumpe stoppen. Sicherheitsabschaltung bei Obergrenze (Overflow).
  - Alcoholic (Aktuator): Hubzyklen solange wiederholen, bis Zielgewicht erreicht; ggf. Kalibrierung „ml pro Hub“ nutzen und durch Gewicht verifizieren.

Akzeptanzkriterien
- Testcode läuft reproduzierbar. Beim Start nullt die Waage.
- Beim Füllen führt die Gewichtskontrolle zu deutlich konstanteren Ergebnissen als reine Zeitsteuerung.


## 5) Mehr Standard-Getränke anlegen

Option A – per API (empfohlen)
- Endpunkte existieren bereits in Backend/Routes:
  - POST `"/api/user/hardware/{hardware_id}/drinks"` → neuen Drink anlegen
  - PUT/DELETE entsprechend vorhanden
- Beispiele (mit gültigem Token + `X-API-KEY`):
  - `curl -X POST "$BASE/api/user/hardware/2/drinks" -H "Authorization: Bearer <TOKEN>" -H "X-API-KEY: <KEY>" -H "Content-Type: application/json" -d '{"drink_name":"Cola","is_alcoholic":false}'`
- Danach Slots zuweisen: PUT `"/api/user/hardware/{hardware_id}/slots/{slot_number}"` mit `{ "drink_id": <id> }`.

Option B – Seed/Populate
- Datei: `Server/internal/query/createTables.go` (`PopulateDatabase()`) um weitere Standarddrinks erweitern. Nur sinnvoll für Dev/Neuaufsetzen.

Akzeptanzkriterien
- Mehr als 3 Standarddrinks sind per API anlegbar und in der App sichtbar (WebSocket-Daten).


## 6) Stepper-Geschwindigkeit selbst erhöhen (nur zeigen, nicht implementieren)

Wo anpassen
- Datei: `Hardware/Rasp/application/modules/motor_controller.py`
  - Methode `rotate_stepper_pigpio(steps, direction, frequency)` – die `frequency` in Hz bestimmt die Schrittfrequenz (höher = schneller).
  - Methode `rotate_until_limit(..., frequency=2000)` – Default-Frequenz kann hier angepasst werden oder über Aufrufer gesetzt werden.
- Aktuelle Aufrufe in `main.py` nutzen teils `2000` Hz. Für Tuning: die Aufrufer-Frequenzen schrittweise erhöhen (z.B. 2k → 3k → 5k Hz) und Vibration/Verluste prüfen.

Hinweise
- pigpio-PWM-Duty ist aktuell 50%. Bei sehr hohen Frequenzen auf mechanische Limits, Riemenspannung und Stromversorgung achten.

Akzeptanzkriterien
- Dokumentierte Stellen erlauben eine schrittweise Erhöhung ohne Code-Refactor.


## 7) Linearaktuator: Relais → Motortreiber (Empfehlung + Test)

Empfehlung Treiber
- Für einen 12V Linearaktuator (750N, 10 mm/s) mit potenziell hohen Anlaufströmen ist der BTS7960 (bis ~43A) robust und weit verbreitet. Empfehlung: DAOKAI BTS7960.
- Der generische „Dual Channel 5–12V … 0–30A“ kann auch funktionieren, aber BTS7960 hat bewährte Schutzschaltungen und thermische Reserven.

Hardware-Ansteuerung (BTS7960)
- Typische Pins am BTS7960: `R_EN`, `L_EN`, `R_PWM`, `L_PWM`.
- Verdrahtung (Beispiel, BCM-Pins anpassen):
  - RPi 3.3V-Logik → BTS7960-Eingänge (kompatibel)
  - `R_EN` und `L_EN` jeweils auf `HIGH` setzen, wenn aktiv.
  - Richtung „Ausfahren“: `R_PWM` mit PWM (Duty=100% reicht), `L_PWM = 0`.
  - Richtung „Einfahren“: `L_PWM` PWM, `R_PWM = 0`.
  - Gemeinsame GND zwischen RPi und 12V-Versorgung.

Software-Plan
- Neue Implementierung `ActuatorControllerBTS7960` (parallel zu `actuator_controller.py`, nicht direkt überschreiben):
  - Konstruktor: Pins für `R_EN`, `L_EN`, `R_PWM`, `L_PWM` entgegennehmen; `pigpio` oder `RPi.GPIO` PWM initialisieren.
  - Methoden: `move_up(duration_s)`, `move_down(duration_s)`, `stop()`; optional `set_speed(0..100%)`.
- Testskript hinzufügen: `Hardware/Rasp/application/tests/test_bts7960_actuator.py`
  - Sequenz: kurz ausfahren → stoppen → einfahren → stoppen (mit Logs).

Akzeptanzkriterien
- Testskript bewegt den Aktuator zuverlässig in beide Richtungen, ohne Spannungsspitzen/Resets.
- Umstellung im Hauptprogramm erfolgt erst, wenn der Test stabil läuft (Feature-Flag/Config-Schalter).


# Gesamtfahrplan (Reihenfolge)

1) Phase 0 (Backend-Maintenance-Endpoint + Protokoll + Hardware-Dispatch)
2) Punkt 2: „Flush complete system“ ausblenden (schneller Gewinn, UI sauber)
3) Punkt 1: Hold-to-Flush (App/Backend/Hardware – Pumpen halten/stoppen)
4) Punkt 3: Light Settings (Backend-Weiterleitung + Hardware-Implementierung)
5) Punkt 4: Waage testen und Gewichtsbasiertes Füllen integrieren (Non-Alkoholisch zuerst)
6) Punkt 5: Mehr Standard-Drinks anlegen (API-Workflows dokumentiert)
7) Punkt 6: Stepper-Geschwindigkeit – Dokumentationshinweis anwenden
8) Punkt 7: BTS7960 einführen + Testskript, später Umschalten im Hauptprogramm


# Abnahmekriterien je Meilenstein
- M1: `/api/user/maintenance` existiert; Hardware loggt eingehende Maintenance-Nachrichten ohne Ausnahme.
- M2: App zeigt „Flush complete system“ nicht mehr an; Build OK.
- M3: Hold-to-Flush funktioniert für alle 6 Pumpen, UI-Feedback vorhanden.
- M4: LED-Modi „Off|Solid|Pulse|Party“ schaltbar, keine Blockaden anderer Komponenten.
- M5: Waage-Tests erklärbar und nachvollziehbar; Füllen nach Gewicht in der Praxis stabiler als Zeitsteuerung.
- M6: Mind. 5–8 Drinks per API angelegt und den Slots zugewiesen; App zeigt sie korrekt an.
- M7: Entwickler kann Stepper-Speed an vorgegebenen Stellen schrittweise erhöhen.
- M8: BTS7960-Testskript bewegt den Aktuator sicher in beide Richtungen; keine Spannungsspitzen-Probleme mehr.


# Notizen zum aktuellen Code (für die Umsetzung wichtig)
- App nutzt bereits `ApiClient.performMaintenance(...)`, aber der Endpoint `/api/user/maintenance` fehlt im Backend → wird in Phase 0 ergänzt.
- „Flush single slot“ öffnet derzeit eine Flaschenauswahl (Grid) und triggert einmalig `flush_slot` – für „Hold-to-Flush“ bauen wir ein neues UI mit Halten/Loslassen und senden Start/Stop.
- LEDs: `LEDController` vorhanden; Effekte sind blocking – bei Bedarf in Thread/Task packen, um schnelle Moduswechsel zu ermöglichen.
- Waage: `WeightSensor` mit `read_weight()` und `tare()` ist vorhanden; Integration in Pour-Loops geplant.
- Stepper: Frequenz ist Parameter `frequency` in `motor_controller.py` – ideal für kontrolliertes Tuning.
- Aktuator: Derzeit per Relais (Pins `in3`, `in4`), wird später auf BTS7960 umgestellt (neue Klasse + Test).
