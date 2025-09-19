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

