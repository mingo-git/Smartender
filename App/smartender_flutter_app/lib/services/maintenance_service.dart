// lib/services/maintenance_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import '../provider/theme_provider.dart';

class MaintenanceService extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  /// Generische Maintenance-Operation (HTTP über ApiClient).
  /// Übergib NUR die maintenance-spezifischen Felder, KEIN `hardware_id` (setzt ApiClient selbst).
  Future<bool> performMaintenance({
    required String maintenanceType,
    int? slotNumber,
  }) async {
    final payload = <String, dynamic>{
      'maintenance_type': maintenanceType,
      if (slotNumber != null) 'slot_number': slotNumber,
    };
    return await sendMaintenanceCommand(payload);
  }

  /// Generischer Command-Sender mit beliebigem Payload.
  /// `hardware_id` wird automatisch vom ApiClient gesetzt – falls vorhanden, wird es entfernt.
  Future<bool> sendMaintenanceCommand(Map<String, dynamic> requestBody) async {
    try {
      final payload = Map<String, dynamic>.from(requestBody);
      payload.remove('hardware_id'); // ApiClient setzt hardware_id selbst

      final response = await _api.performMaintenance(payload);
      final statusCode = response.statusCode;

      debugPrint("MAINTENANCE STATUS CODE: $statusCode");
      debugPrint("MAINTENANCE RESPONSE: ${response.body}");

      if (statusCode == 200 || statusCode == 201) {
        return true;
      } else {
        String message = _friendlyMessageForStatus(statusCode);
        try {
          if (response.body.isNotEmpty) {
            final decoded = json.decode(response.body);
            if (decoded is Map && decoded['message'] is String) {
              message = decoded['message'];
            }
          }
        } catch (_) {
          // ignore decode errors -> fallback message
        }
        debugPrint("Maintenance operation failed: $statusCode - $message");
        _showErrorMessage(message);
        return false;
      }
    } catch (e) {
      debugPrint("Error performing maintenance operation: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Komfort-Methoden (nutzen spezialisierte ApiClient-Calls)
  // ────────────────────────────────────────────────────────────────────────────

  // Hold-to-Flush: Start/Stop Pumpe
  Future<bool> startPumpHold(int pumpIndex) async {
    try {
      final res = await _api.performMaintenance({
        'maintenance_type': 'pump_hold',
        'pump_index': pumpIndex,
        'action': 'start',
      });
      // Bei Hold-Events keine Snackbars spammen: nur Status evaluieren
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('startPumpHold error: $e');
      return false;
    }
  }

  Future<bool> stopPumpHold(int pumpIndex) async {
    try {
      final res = await _api.performMaintenance({
        'maintenance_type': 'pump_hold',
        'pump_index': pumpIndex,
        'action': 'stop',
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('stopPumpHold error: $e');
      return false;
    }
  }

  Future<bool> setLightMode(String mode, {String? colorHex, int? brightness, double? speedHz}) async {
    try {
      final res = await _api.setLightMode(mode, colorHex: colorHex, brightness: brightness, speedHz: speedHz);
      return _handleResponse(res, defaultError: "Lichtmodus konnte nicht gesetzt werden");
    } catch (e) {
      debugPrint("setLightMode error: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  Future<bool> setSolidColor({required int r, required int g, required int b, int? brightness}) async {
    final hex = _rgbToHex(r, g, b);
    return await setLightMode('solid', colorHex: hex, brightness: brightness);
  }

  Future<bool> startStrobe({required int r, required int g, required int b, int? brightness, double speedHz = 8.0}) async {
    final hex = _rgbToHex(r, g, b);
    return await setLightMode('strobe', colorHex: hex, brightness: brightness, speedHz: speedHz);
  }

  Future<bool> turnOffLights() async => await setLightMode('off');

  String _rgbToHex(int r, int g, int b) {
    String two(int v) => v.clamp(0, 255).toInt().toRadixString(16).padLeft(2, '0');
    return '#'+two(r)+two(g)+two(b);
  }

  Future<bool> moveAxes({required double x, required double z}) async {
    try {
      // ApiClient clamped bereits, wir clampen hier zusätzlich zur Sicherheit
      final cx = x.clamp(-100.0, 100.0);
      final cz = z.clamp(-100.0, 100.0);
      final res = await _api.moveAxes(x: cx, z: cz);
      return _handleResponse(res, defaultError: "Bewegung konnte nicht ausgeführt werden");
    } catch (e) {
      debugPrint("moveAxes error: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  Future<bool> flushAllPumps() async {
    try {
      final res = await _api.flushAllPumps();
      return _handleResponse(res, defaultError: "Spülvorgang (alle) fehlgeschlagen");
    } catch (e) {
      debugPrint("flushAllPumps error: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  Future<bool> flushSlot(int slotNumber) async {
    try {
      final res = await _api.flushSlot(slotNumber);
      return _handleResponse(res, defaultError: "Spülvorgang (Slot $slotNumber) fehlgeschlagen");
    } catch (e) {
      debugPrint("flushSlot error: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      final res = await _api.performMaintenance({'maintenance_type': 'test_connection'});
      return _handleResponse(res, defaultError: "Verbindungstest fehlgeschlagen");
    } catch (e) {
      debugPrint("testConnection error: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  Future<bool> emergencyStop() async {
    try {
      final res = await _api.emergencyStop();
      return _handleResponse(res, defaultError: "Emergency Stop fehlgeschlagen");
    } catch (e) {
      debugPrint("emergencyStop error: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  bool _handleResponse(response, {required String defaultError}) {
    final statusCode = response.statusCode;
    if (statusCode == 200 || statusCode == 201) return true;

    String message = _friendlyMessageForStatus(statusCode);
    try {
      if (response.body is String && (response.body as String).isNotEmpty) {
        final decoded = json.decode(response.body as String);
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'];
        }
      }
    } catch (_) {
      // ignore decode errors -> fallback message
      if (message == "Wartungsvorgang fehlgeschlagen (Code: $statusCode)") {
        message = defaultError;
      }
    }

    _showErrorMessage(message);
    return false;
  }

  String _friendlyMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return "Ungültige Wartungsparameter";
      case 401:
        return "Nicht autorisiert";
      case 403:
        return "Keine Berechtigung für diese Hardware";
      case 404:
        return "Smartender konnte nicht erreicht werden";
      case 500:
        return "Server-Fehler";
      default:
        return "Wartungsvorgang fehlgeschlagen (Code: $statusCode)";
    }
  }

  void _showErrorMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context == null) return;
      final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: theme.primaryColor)),
          backgroundColor: theme.falseColor,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }
}
