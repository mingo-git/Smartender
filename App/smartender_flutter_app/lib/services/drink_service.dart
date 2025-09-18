// lib/services/drink_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/websocket/websocket_message.dart';
import 'fetchable_service.dart';
import 'websocket_service.dart';
import 'api_client.dart';

class DrinkService extends ChangeNotifier implements FetchableService {
  final WebSocketService _webSocketService = WebSocketService();
  final ApiClient _api = ApiClient();

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

  // ────────────────────────────────────────────────────────────────────────────
  // WebSocket-First: Keine HTTP-Fetches mehr in diesem Service
  // ────────────────────────────────────────────────────────────────────────────
  @override
  Future<void> fetchAndSaveData() async {
    if (_isUpdatingFromWebSocket) {
      print("DrinkService: Skipping fetch (just updated from WebSocket).");
      return;
    }
    // Absichtlich leer – Initial Load / HTTP-Fallback übernimmt FetchDataService.
    print("DrinkService: WebSocket-first – HTTP fetch disabled (no-op).");
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Lokaler Cache
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _saveDrinksLocally(List<dynamic> drinks) async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = json.encode(drinks);
    await prefs.setString('drinks', drinksJson);
  }

  Future<List<Map<String, dynamic>>> fetchDrinksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = prefs.getString('drinks');
    if (drinksJson != null) {
      try {
        final drinks = List<Map<String, dynamic>>.from(json.decode(drinksJson));
        return drinks;
      } catch (_) {
        // Fallback bei korrupten Daten
      }
    }
    return <Map<String, dynamic>>[];
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Aktionen (HTTP) – nur über ApiClient
  // ────────────────────────────────────────────────────────────────────────────

  /// Hinzufügen eines neuen Drinks (HTTP Aktion)
  Future<bool> addDrink(String drinkName, bool isAlcoholic) async {
    try {
      final response = await _api.createDrink(drinkName, isAlcoholic);
      if (response.statusCode == 201) {
        // WebSocket liefert den finalen Stand; optional Logging
        print("Drink erfolgreich hinzugefügt: $drinkName");
        return true;
      }
      print("Fehler beim Hinzufügen des Drinks: ${response.statusCode} ${response.body}");
      return false;
    } catch (e) {
      print("Fehler beim Hinzufügen des Drinks: $e");
      return false;
    }
  }

  /// Aktualisieren eines bestehenden Drinks (HTTP Aktion)
  Future<bool> updateDrink(int drinkId, String drinkName, bool isAlcoholic) async {
    try {
      final response = await _api.updateDrink(drinkId, drinkName, isAlcoholic);
      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Drink erfolgreich aktualisiert: $drinkName (ID: $drinkId)");
        return true;
      }
      print("Fehler beim Aktualisieren des Drinks: ${response.statusCode} ${response.body}");
      return false;
    } catch (e) {
      print("Fehler beim Aktualisieren des Drinks: $e");
      return false;
    }
  }

  /// Löschen eines Drinks (HTTP Aktion)
  Future<bool> deleteDrink(int drinkId) async {
    try {
      final response = await _api.deleteDrink(drinkId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Drink erfolgreich gelöscht (ID: $drinkId)");
        return true;
      }
      print("Fehler beim Löschen des Drinks: ${response.statusCode} ${response.body}");
      return false;
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
