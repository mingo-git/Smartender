// lib/services/slot_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/websocket/websocket_message.dart';
import 'auth_service.dart';
import 'fetchable_service.dart';
import 'websocket_service.dart';

class SlotService extends ChangeNotifier implements FetchableService {
  final String _allSlotsUrl = "/user/hardware/2/slots";
  final WebSocketService _webSocketService = WebSocketService();

  // Flag to prevent loops when updating from WebSocket
  bool _isUpdatingFromWebSocket = false;

  SlotService() {
    _initializeWebSocketHandlers();
  }

  /// Initialize WebSocket message handlers
  void _initializeWebSocketHandlers() {
    _webSocketService.addMessageHandler(
      WebSocketMessageType.slotUpdate,
      _handleSlotUpdate,
    );
    print("SlotService: WebSocket handlers registered");
  }

  /// Handle incoming slot updates from WebSocket
  void _handleSlotUpdate(WebSocketMessage message) async {
    try {
      final slotUpdate = SlotUpdateMessage.fromJson(message.data);
      print("SlotService: Received ${slotUpdate.action.value} for slot: ${slotUpdate.slot?['slot_number']}");

      _isUpdatingFromWebSocket = true;

      switch (slotUpdate.action) {
        case WebSocketAction.created:
          await _handleSlotCreated(slotUpdate.slot);
          break;
        case WebSocketAction.updated:
          await _handleSlotUpdated(slotUpdate.slot);
          break;
        case WebSocketAction.deleted:
          await _handleSlotDeleted(slotUpdate.slot);
          break;
        case WebSocketAction.unknown:
          print("SlotService: Unknown slot action received");
          break;
      }

      _isUpdatingFromWebSocket = false;
      notifyListeners();

      // Important: Notify other services that slot availability has changed
      // This affects "missing" flags in recipes
      await _notifySlotChangeToOtherServices();

    } catch (e) {
      print("SlotService: Error handling slot update: $e");
      _isUpdatingFromWebSocket = false;
    }
  }

  /// Handle slot created via WebSocket
  Future<void> _handleSlotCreated(Map<String, dynamic>? slotData) async {
    if (slotData == null) return;

    try {
      final slots = await fetchSlotsFromLocal();
      final slotNumber = slotData['slot_number'];

      // Check if slot already exists (avoid duplicates)
      final existingIndex = slots.indexWhere((s) => s['slot_number'] == slotNumber);
      if (existingIndex == -1) {
        slots.add(slotData);
        await _saveSlotsLocally(slots);
        print("SlotService: Added new slot via WebSocket: Slot $slotNumber");
      } else {
        print("SlotService: Slot already exists, skipping creation: $slotNumber");
      }
    } catch (e) {
      print("SlotService: Error handling slot creation: $e");
    }
  }

  /// Handle slot updated via WebSocket
  Future<void> _handleSlotUpdated(Map<String, dynamic>? slotData) async {
    if (slotData == null) return;

    try {
      final slots = await fetchSlotsFromLocal();
      final slotNumber = slotData['slot_number'];

      // Find and update existing slot
      final existingIndex = slots.indexWhere((s) => s['slot_number'] == slotNumber);
      if (existingIndex != -1) {
        slots[existingIndex] = slotData;
        await _saveSlotsLocally(slots);

        final drinkName = slotData['drink']?['drink_name'] ?? 'Empty';
        print("SlotService: Updated slot $slotNumber via WebSocket: $drinkName");
      } else {
        // Slot doesn't exist locally, add it
        slots.add(slotData);
        await _saveSlotsLocally(slots);
        print("SlotService: Added missing slot via WebSocket: Slot $slotNumber");
      }
    } catch (e) {
      print("SlotService: Error handling slot update: $e");
    }
  }

  /// Handle slot deleted via WebSocket
  Future<void> _handleSlotDeleted(Map<String, dynamic>? slotData) async {
    if (slotData == null) return;

    try {
      final slots = await fetchSlotsFromLocal();
      final slotNumber = slotData['slot_number'];

      // Remove slot from local storage
      slots.removeWhere((s) => s['slot_number'] == slotNumber);
      await _saveSlotsLocally(slots);
      print("SlotService: Removed slot via WebSocket: Slot $slotNumber");
    } catch (e) {
      print("SlotService: Error handling slot deletion: $e");
    }
  }

  /// Notify other services that slot configuration has changed
  /// This is important because slot changes affect "missing" ingredient flags in recipes
  Future<void> _notifySlotChangeToOtherServices() async {
    try {
      // We could implement a proper event bus here, but for simplicity,
      // we'll let the other services know through their own fetch mechanisms
      print("SlotService: Slot configuration changed - other services should refresh ingredient availability");

      // In a more sophisticated implementation, you might:
      // 1. Use an event bus to notify RecipeService
      // 2. Or directly trigger RecipeService.updateIngredientAvailability()
      // 3. Or use a global state management solution

      // For now, we rely on the periodic fetch or manual refresh
    } catch (e) {
      print("SlotService: Error notifying other services: $e");
    }
  }

  @override
  Future<void> fetchAndSaveData() async {
    // Skip HTTP fetch if we just updated from WebSocket
    if (_isUpdatingFromWebSocket) {
      print("SlotService: Skipping HTTP fetch - just updated from WebSocket");
      return;
    }

    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Skipping fetch.");
      return;
    }

    final url = Uri.parse(baseUrl + _allSlotsUrl);
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
        final slots = json.decode(response.body) as List<dynamic>;

        await _saveSlotsLocally(slots);
        print("SLOTS fetched and saved locally via HTTP. Count: ${slots.length}");
        notifyListeners();
      } else {
        print("Failed to fetch SLOTS: ${response.statusCode}, Response: ${response.body}");
      }
    } catch (e) {
      print("Error fetching SLOTS: $e");
    }
  }

  Future<void> _saveSlotsLocally(List<dynamic> slots) async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = json.encode(slots);
    await prefs.setString('slots', slotsJson);
  }

  Future<List<Map<String, dynamic>>> fetchSlotsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getString('slots');
    if (slotsJson != null) {
      final slotsList = json.decode(slotsJson) as List<dynamic>;
      final slots = slotsList.map((slot) {
        return Map<String, dynamic>.from(slot);
      }).toList();

      return slots;
    }
    print("No SLOTS found in SharedPreferences.");
    return [];
  }

  /// Update a slot with a new drink
  Future<bool> updateSlot(int slotNumber, int? drinkId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot update slot.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_allSlotsUrl/$slotNumber");

    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'Authorization': 'Bearer $token',
    };

    final body = drinkId != null ? json.encode({"drink_id": drinkId}) : null;

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body, // Kein Body für "Clear"
      );

      if (response.statusCode == 204) {
        print("SLOT $slotNumber updated successfully.");
        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
        notifyListeners();
        return true;
      } else {
        print("Failed to update SLOT: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating SLOT: $e");
      return false;
    }
  }

  /// Get available drink IDs from all slots (used by other services for missing ingredient detection)
  Future<Set<int>> getAvailableDrinkIds() async {
    try {
      final slots = await fetchSlotsFromLocal();
      final Set<int> availableDrinkIds = {};

      for (var slot in slots) {
        if (slot['drink'] != null && slot['drink']['drink_id'] != null) {
          availableDrinkIds.add(slot['drink']['drink_id'] as int);
        }
      }

      print("SlotService: Available drink IDs: $availableDrinkIds");
      return availableDrinkIds;
    } catch (e) {
      print("SlotService: Error getting available drink IDs: $e");
      return {};
    }
  }

  /// Check if a specific drink is available in any slot
  Future<bool> isDrinkAvailable(int drinkId) async {
    final availableDrinkIds = await getAvailableDrinkIds();
    return availableDrinkIds.contains(drinkId);
  }

  /// Get slot information for a specific drink
  Future<Map<String, dynamic>?> getSlotForDrink(int drinkId) async {
    try {
      final slots = await fetchSlotsFromLocal();

      for (var slot in slots) {
        if (slot['drink'] != null && slot['drink']['drink_id'] == drinkId) {
          return slot;
        }
      }

      return null;
    } catch (e) {
      print("SlotService: Error getting slot for drink $drinkId: $e");
      return null;
    }
  }

  /// Get empty slots (useful for UI)
  Future<List<Map<String, dynamic>>> getEmptySlots() async {
    try {
      final slots = await fetchSlotsFromLocal();
      return slots.where((slot) => slot['drink'] == null).toList();
    } catch (e) {
      print("SlotService: Error getting empty slots: $e");
      return [];
    }
  }

  /// Get occupied slots (useful for UI)
  Future<List<Map<String, dynamic>>> getOccupiedSlots() async {
    try {
      final slots = await fetchSlotsFromLocal();
      return slots.where((slot) => slot['drink'] != null).toList();
    } catch (e) {
      print("SlotService: Error getting occupied slots: $e");
      return [];
    }
  }

  /// Clear a slot (remove drink)
  Future<bool> clearSlot(int slotNumber) async {
    return await updateSlot(slotNumber, null);
  }

  /// Get slot status summary for debugging/UI
  Future<Map<String, dynamic>> getSlotStatusSummary() async {
    try {
      final slots = await fetchSlotsFromLocal();
      final emptySlots = await getEmptySlots();
      final occupiedSlots = await getOccupiedSlots();
      final availableDrinkIds = await getAvailableDrinkIds();

      return {
        'total_slots': slots.length,
        'empty_slots': emptySlots.length,
        'occupied_slots': occupiedSlots.length,
        'available_drinks': availableDrinkIds.length,
        'available_drink_ids': availableDrinkIds.toList(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print("SlotService: Error getting slot status summary: $e");
      return {
        'error': e.toString(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check if WebSocket is providing real-time updates
  bool get isRealTimeEnabled => _webSocketService.isConnected;

  /// Get WebSocket connection status
  String get connectionStatus => _webSocketService.connectionStatusText;

  /// Force refresh slot data (useful for manual refresh)
  Future<void> forceRefresh() async {
    print("SlotService: Force refreshing slot data...");
    _isUpdatingFromWebSocket = false; // Allow HTTP fetch
    await fetchAndSaveData();
  }

  @override
  void dispose() {
    // Remove WebSocket handlers
    _webSocketService.removeMessageHandler(
      WebSocketMessageType.slotUpdate,
      _handleSlotUpdate,
    );
    super.dispose();
  }
}