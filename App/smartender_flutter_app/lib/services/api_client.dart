// lib/services/api_client.dart - NUR FÜR AKTIONEN (nicht für Fetching)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';

/// 🎯 Zentraler API-Client für HTTP-AKTIONEN
/// WebSocket übernimmt das Fetching von Daten
/// HTTP nur für: Create, Update, Delete, Order, Maintenance
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final AuthService _authService = AuthService();

  /// 🔧 API-KONFIGURATION
  static const String _apiPrefix = '/api';
  static const String _userPath = '/user';
  static const String _hardwareId = '2'; // Kann später dynamisch gemacht werden

  /// Generiere Standard-Headers für alle Requests
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey, // ✅ Korrigierter Header-Name (Großbuchstaben)
    };

    if (includeAuth) {
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Erstelle vollständige URL mit /api Präfix
  String _buildUrl(String endpoint) {
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }

    // Wenn der endpoint bereits mit /api beginnt, verwende ihn direkt
    if (endpoint.startsWith('/api')) {
      return baseUrl + endpoint;
    }

    // Andernfalls füge /api hinzu
    return baseUrl + _apiPrefix + endpoint;
  }

  /// 🚀 ZENTRALE HTTP-METHODEN (mit Logging)

  Future<http.Response> _request(String method, String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final url = Uri.parse(_buildUrl(endpoint));
    final headers = await _getHeaders(includeAuth: includeAuth);
    final bodyJson = body != null ? json.encode(body) : null;

    print("🎯 API $method: $url");
    if (body != null) {
      print("🎯 Body: ${json.encode(body)}");
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: bodyJson);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: bodyJson);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print("🎯 Response: ${response.statusCode}");
      if (response.statusCode >= 400) {
        print("🎯 Error Body: ${response.body}");
      }

      return response;
    } catch (e) {
      print("🎯 Request Error: $e");
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint, {bool includeAuth = true}) =>
      _request('GET', endpoint, includeAuth: includeAuth);

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body, bool includeAuth = true}) =>
      _request('POST', endpoint, body: body, includeAuth: includeAuth);

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body, bool includeAuth = true}) =>
      _request('PUT', endpoint, body: body, includeAuth: includeAuth);

  Future<http.Response> delete(String endpoint, {bool includeAuth = true}) =>
      _request('DELETE', endpoint, includeAuth: includeAuth);

  /// 🎯 RECIPE-AKTIONEN (Create, Update, Delete)

  /// Erstelle neues Rezept
  Future<http.Response> createRecipe(String recipeName, {int? pictureId}) =>
      post('/user/hardware/$_hardwareId/recipes', body: {
        "recipe_name": recipeName,
        "picture_id": pictureId ?? 0,
      });

  /// Update Rezept
  Future<http.Response> updateRecipe(int recipeId, String recipeName, {int? pictureId}) =>
      put('/user/hardware/$_hardwareId/recipes/$recipeId', body: {
        "recipe_name": recipeName,
        "picture_id": pictureId ?? 0,
      });

  /// Lösche Rezept
  Future<http.Response> deleteRecipe(int recipeId) =>
      delete('/user/hardware/$_hardwareId/recipes/$recipeId');

  /// Füge Zutat zu Rezept hinzu
  Future<http.Response> addIngredientToRecipe(int recipeId, int drinkId, int quantityMl) =>
      post('/user/hardware/$_hardwareId/recipes/$recipeId/ingredients', body: {
        "drink_id": drinkId,
        "quantity_ml": quantityMl,
      });

  /// Update Zutat in Rezept
  Future<http.Response> updateIngredientInRecipe(int recipeId, int drinkId, int quantityMl) =>
      put('/user/hardware/$_hardwareId/recipes/$recipeId/ingredients/$drinkId', body: {
        "quantity_ml": quantityMl,
      });

  /// Entferne Zutat aus Rezept
  Future<http.Response> removeIngredientFromRecipe(int recipeId, int drinkId) =>
      delete('/user/hardware/$_hardwareId/recipes/$recipeId/ingredients/$drinkId');

  /// 🎯 FAVORITEN-AKTIONEN

  /// Füge zu Favoriten hinzu
  Future<http.Response> addToFavorites(int recipeId) =>
      post('/user/hardware/$_hardwareId/favorite/$recipeId');

  /// Entferne von Favoriten
  Future<http.Response> removeFromFavorites(int recipeId) =>
      delete('/user/hardware/$_hardwareId/favorite/$recipeId');

  /// 🎯 DRINK-AKTIONEN (Create, Update, Delete)

  /// Erstelle neuen Drink
  Future<http.Response> createDrink(String drinkName, bool isAlcoholic) =>
      post('/user/hardware/$_hardwareId/drinks', body: {
        "drink_name": drinkName,
        "is_alcoholic": isAlcoholic,
      });

  /// Update Drink
  Future<http.Response> updateDrink(int drinkId, String drinkName, bool isAlcoholic) =>
      put('/user/hardware/$_hardwareId/drinks/$drinkId', body: {
        "drink_name": drinkName,
        "is_alcoholic": isAlcoholic,
      });

  /// Lösche Drink
  Future<http.Response> deleteDrink(int drinkId) =>
      delete('/user/hardware/$_hardwareId/drinks/$drinkId');

  /// 🎯 SLOT-AKTIONEN

  /// Update Slot (setze Drink oder leere Slot)
  Future<http.Response> updateSlot(int slotNumber, int? drinkId) {
    if (drinkId != null) {
      return put('/user/hardware/$_hardwareId/slots/$slotNumber', body: {
        "drink_id": drinkId,
      });
    } else {
      // Für leeren Slot - kein Body
      return put('/user/hardware/$_hardwareId/slots/$slotNumber');
    }
  }

  /// 🎯 ORDER-AKTIONEN

  /// Bestelle Drink
  Future<http.Response> orderDrink(int recipeId) =>
      post('/user/action', body: {
        "hardware_id": int.parse(_hardwareId),
        "recipe_id": recipeId,
      });

  /// 🎯 MAINTENANCE-AKTIONEN

  /// Allgemeine Maintenance-Aktion
  Future<http.Response> performMaintenance(Map<String, dynamic> maintenanceData) =>
      post('/user/maintenance', body: {
        "hardware_id": int.parse(_hardwareId),
        ...maintenanceData,
      });

  /// Spezifische Maintenance-Aktionen
  Future<http.Response> flushAllPumps() =>
      performMaintenance({"maintenance_type": "flush_all"});

  Future<http.Response> flushSlot(int slotNumber) =>
      performMaintenance({
        "maintenance_type": "flush_slot",
        "slot_number": slotNumber
      });

  Future<http.Response> setLightMode(String mode) =>
      performMaintenance({
        "maintenance_type": "light_mode",
        "light_mode": mode,
      });

  Future<http.Response> moveAxes({required double x, required double z}) =>
      performMaintenance({
        "maintenance_type": "manual_move",
        "x": x.clamp(-100.0, 100.0),
        "z": z.clamp(-100.0, 100.0),
      });

  Future<http.Response> emergencyStop() =>
      performMaintenance({"maintenance_type": "emergency_stop"});

  /// 🔧 HEALTH & TESTING (für Debugging)

  /// Teste API-Verbindung (ohne Auth)
  Future<http.Response> healthCheck() => get('/health', includeAuth: false);

  /// Teste API-Status (ohne Auth)
  Future<http.Response> statusCheck() => get('/status', includeAuth: false);

  /// 🎯 CONVENIENCE - Teste ob Actions funktionieren
  Future<void> testApiActions() async {
    print("🎯 === TESTING API ACTIONS ===");

    final testActions = [
          () => healthCheck(),
          () => statusCheck(),
    ];

    for (int i = 0; i < testActions.length; i++) {
      try {
        final response = await testActions[i]();
        final actionName = i == 0 ? 'Health Check' : 'Status Check';

        if (response.statusCode == 200) {
          print("🎯 ✅ $actionName: SUCCESS");
        } else {
          print("🎯 ❌ $actionName: ${response.statusCode}");
        }
      } catch (e) {
        print("🎯 💥 Action $i Error: $e");
      }

      await Future.delayed(Duration(milliseconds: 300));
    }

    print("🎯 === END API ACTIONS TEST ===");
  }

  /// 🔧 GET CURRENT HARDWARE ID (für dynamische Konfiguration später)
  String get currentHardwareId => _hardwareId;

  /// Set Hardware ID dynamisch (für Multi-Device Support später)
  void setHardwareId(String hardwareId) {
    // Implementierung für später, wenn mehrere Geräte unterstützt werden
    print("🎯 Hardware ID would be set to: $hardwareId (not implemented yet)");
  }
}