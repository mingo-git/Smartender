import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../provider/theme_provider.dart';
import 'auth_service.dart';

class MaintenanceService extends ChangeNotifier {
  final String _maintenanceUrl = "/user/maintenance";

  Future<bool> performMaintenance({
    required String maintenanceType,
    int? slotNumber,
  }) async {
    final Map<String, dynamic> requestBody = {
      "hardware_id": 2,
      "maintenance_type": maintenanceType,
    };
    if (slotNumber != null) {
      requestBody["slot_number"] = slotNumber;
    }
    return await sendMaintenanceCommand(requestBody);
  }

  /// NEW: generic command sender with arbitrary payload (keeps endpoint and headers the same)
  Future<bool> sendMaintenanceCommand(Map<String, dynamic> requestBody) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      debugPrint("No token available. Cannot perform maintenance.");
      return false;
    }

    final url = Uri.parse(baseUrl + _maintenanceUrl);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      var statusCode = response.statusCode;
      debugPrint("MAINTENANCE STATUS CODE: $statusCode");
      debugPrint("MAINTENANCE RESPONSE: ${response.body}");

      if (statusCode == 200 || statusCode == 201) {
        return true;
      } else {
        String errorMessage = _getErrorMessage(statusCode);
        debugPrint("Maintenance operation failed: $statusCode - $errorMessage");
        _showErrorMessage(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint("Error performing maintenance operation: $e");
      _showErrorMessage("Verbindungsfehler aufgetreten");
      return false;
    }
  }

  // NEW: light settings
  Future<bool> setLightMode(String mode) async {
    final body = {
      "hardware_id": 2,
      "maintenance_type": "light_mode",
      "light_mode": mode, // e.g. Off, Solid, Pulse, Party
    };
    return await sendMaintenanceCommand(body);
  }

  // NEW: manual motor control (X/Z axes)
  Future<bool> moveAxes({required double x, required double z}) async {
    // clamp to [-100, 100]
    final clamp = (double v) => v.clamp(-100.0, 100.0);
    final body = {
      "hardware_id": 2,
      "maintenance_type": "manual_move",
      "x": clamp(x),
      "z": clamp(z),
    };
    return await sendMaintenanceCommand(body);
  }

  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 404:
        return "Smartender konnte nicht erreicht werden";
      case 400:
        return "Ungültige Wartungsparameter";
      case 401:
        return "Nicht autorisiert";
      case 403:
        return "Keine Berechtigung für diese Hardware";
      case 500:
        return "Server-Fehler";
      default:
        return "Wartungsvorgang fehlgeschlagen (Code: $statusCode)";
    }
  }

  void _showErrorMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context != null) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: TextStyle(color: theme.primaryColor)),
            backgroundColor: theme.falseColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<bool> testConnection() async {
    return await performMaintenance(maintenanceType: "test_connection");
  }

  Future<bool> emergencyStop() async {
    return await performMaintenance(maintenanceType: "emergency_stop");
  }
}
