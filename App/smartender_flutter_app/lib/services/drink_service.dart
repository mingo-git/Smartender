import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/websocket/websocket_message.dart';
import 'auth_service.dart';
import 'fetchable_service.dart';
import 'websocket_service.dart';

class DrinkService extends ChangeNotifier implements FetchableService {
  final String _allDrinksUrl = "/user/hardware/2/drinks";
  final WebSocketService _webSocketService = WebSocketService();

  // Flag to prevent loops when updating from WebSocket
  bool _isUpdatingFromWebSocket = false;

  DrinkService() {
    _initializeWebSocketHandlers();
  }

  /// Initialize WebSocket message handlers
  void _initializeWebSocketHandlers() {
    _webSocketService.addMessageHandler(
      WebSocketMessageType.drinkUpdate,
      _handleDrinkUpdate,
    );
    print("DrinkService: WebSocket handlers registered");
  }

  /// Handle incoming drink updates from WebSocket
  void _handleDrinkUpdate(WebSocketMessage message) async {
    try {
      final drinkUpdate = DrinkUpdateMessage.fromJson(message.data);
      print("DrinkService: Received ${drinkUpdate.action.value} for drink: ${drinkUpdate.drink?['drink_id']}");

      _isUpdatingFromWebSocket = true;

      switch (drinkUpdate.action) {
        case WebSocketAction.created:
          await _handleDrinkCreated(drinkUpdate.drink);
          break;
        case WebSocketAction.updated:
          await _handleDrinkUpdated(drinkUpdate.drink);
          break;
        case WebSocketAction.deleted:
          await _handleDrinkDeleted(drinkUpdate.drink);
          break;
        case WebSocketAction.unknown:
          print("DrinkService: Unknown drink action received");
          break;
      }

      _isUpdatingFromWebSocket = false;
      notifyListeners();

    } catch (e) {
      print("DrinkService: Error handling drink update: $e");
      _isUpdatingFromWebSocket = false;
    }
  }

  /// Handle drink created via WebSocket
  Future<void> _handleDrinkCreated(Map<String, dynamic>? drinkData) async {
    if (drinkData == null) return;

    try {
      final drinks = await fetchDrinksFromLocal();
      final drinkId = drinkData['drink_id'];

      // Check if drink already exists (avoid duplicates)
      final existingIndex = drinks.indexWhere((d) => d['drink_id'] == drinkId);
      if (existingIndex == -1) {
        drinks.add(drinkData);
        await _saveDrinksLocally(drinks);
        print("DrinkService: Added new drink via WebSocket: ${drinkData['drink_name']}");
      } else {
        print("DrinkService: Drink already exists, skipping creation: $drinkId");
      }
    } catch (e) {
      print("DrinkService: Error handling drink creation: $e");
    }
  }

  /// Handle drink updated via WebSocket
  Future<void> _handleDrinkUpdated(Map<String, dynamic>? drinkData) async {
    if (drinkData == null) return;

    try {
      final drinks = await fetchDrinksFromLocal();
      final drinkId = drinkData['drink_id'];

      // Find and update existing drink
      final existingIndex = drinks.indexWhere((d) => d['drink_id'] == drinkId);
      if (existingIndex != -1) {
        drinks[existingIndex] = drinkData;
        await _saveDrinksLocally(drinks);
        print("DrinkService: Updated drink via WebSocket: ${drinkData['drink_name']}");
      } else {
        // Drink doesn't exist locally, add it
        drinks.add(drinkData);
        await _saveDrinksLocally(drinks);
        print("DrinkService: Added missing drink via WebSocket: ${drinkData['drink_name']}");
      }
    } catch (e) {
      print("DrinkService: Error handling drink update: $e");
    }
  }

  /// Handle drink deleted via WebSocket
  Future<void> _handleDrinkDeleted(Map<String, dynamic>? drinkData) async {
    if (drinkData == null) return;

    try {
      final drinks = await fetchDrinksFromLocal();
      final drinkId = drinkData['drink_id'];

      // Remove drink from local storage
      drinks.removeWhere((d) => d['drink_id'] == drinkId);
      await _saveDrinksLocally(drinks);
      print("DrinkService: Removed drink via WebSocket: ${drinkData['drink_name']}");
    } catch (e) {
      print("DrinkService: Error handling drink deletion: $e");
    }
  }

  @override
  Future<void> fetchAndSaveData() async {
    // Skip HTTP fetch if we just updated from WebSocket
    if (_isUpdatingFromWebSocket) {
      print("DrinkService: Skipping HTTP fetch - just updated from WebSocket");
      return;
    }

    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Skipping fetch.");
      return;
    }

    final url = Uri.parse(baseUrl + _allDrinksUrl);
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          await _saveDrinksLocally([]);
          print("No drinks returned by the server. Saved empty list locally.");
          return;
        }

        List<dynamic> drinks;
        try {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded is List) {
            drinks = decoded;
          } else {
            drinks = [];
            print("Response did not return a list, using empty list.");
          }
        } catch (e) {
          drinks = [];
          print("Error decoding response: $e. Using empty list.");
        }

        await _saveDrinksLocally(drinks);
        print("DRINKS fetched and saved locally via HTTP. Count: ${drinks.length}");
        notifyListeners();
      } else {
        print("Failed to fetch DRINKS: ${response.statusCode}, Response: ${response.body}");
      }
    } catch (e) {
      print("Error fetching DRINKS: $e");
    }
  }

  Future<void> _saveDrinksLocally(List<dynamic> drinks) async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = json.encode(drinks);
    await prefs.setString('drinks', drinksJson);
  }

  Future<List<Map<String, dynamic>>> fetchDrinksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = prefs.getString('drinks');
    if (drinksJson != null) {
      final drinks = List<Map<String, dynamic>>.from(json.decode(drinksJson));
      return drinks;
    }
    print("No DRINKS found in SharedPreferences.");
    return [];
  }

  /// Hinzufügen eines neuen Drinks (POST)
  Future<bool> addDrink(String drinkName, bool isAlcoholic) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("Kein Token verfügbar. Kann Drink nicht hinzufügen.");
      return false;
    }

    final url = Uri.parse(baseUrl + _allDrinksUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "drink_name": drinkName,
          "is_alcoholic": isAlcoholic,
        }),
      );

      if (response.statusCode == 201) {
        print("Drink erfolgreich hinzugefügt: $drinkName");
        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
        return true;
      } else {
        print("Fehler beim Hinzufügen des Drinks: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Fehler beim Hinzufügen des Drinks: $e");
      return false;
    }
  }

  /// Aktualisieren eines bestehenden Drinks (PUT)
  Future<bool> updateDrink(int drinkId, String drinkName, bool isAlcoholic) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("Kein Token verfügbar. Kann Drink nicht aktualisieren.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_allDrinksUrl/$drinkId");
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "drink_name": drinkName,
          "is_alcoholic": isAlcoholic,
        }),
      );

      if (response.statusCode == 204) {
        print("Drink erfolgreich aktualisiert: $drinkName (ID: $drinkId)");
        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
        return true;
      } else {
        print("Fehler beim Aktualisieren des Drinks: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Fehler beim Aktualisieren des Drinks: $e");
      return false;
    }
  }

  /// Löschen eines Drinks (DELETE)
  Future<bool> deleteDrink(int drinkId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("Kein Token verfügbar. Kann Drink nicht löschen.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_allDrinksUrl/$drinkId");
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Drink erfolgreich gelöscht (ID: $drinkId)");
        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
        return true;
      } else {
        print("Fehler beim Löschen des Drinks: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Fehler beim Löschen des Drinks: $e");
      return false;
    }
  }

  /// Check if WebSocket is providing real-time updates
  bool get isRealTimeEnabled => _webSocketService.isConnected;

  /// Get WebSocket connection status
  String get connectionStatus => _webSocketService.connectionStatusText;

  @override
  void dispose() {
    // Remove WebSocket handlers
    _webSocketService.removeMessageHandler(
      WebSocketMessageType.drinkUpdate,
      _handleDrinkUpdate,
    );
    super.dispose();
  }
}