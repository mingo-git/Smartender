// lib/services/slot_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'auth_service.dart';
import 'fetchable_service.dart';

class SlotService extends ChangeNotifier implements FetchableService {
  final String _allSlotsUrl = "/user/hardware/2/slots";

  @override
  Future<void> fetchAndSaveData() async {
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
        print("SLOTS fetched and saved locally.");
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
        await fetchAndSaveData(); // Slots nach Update synchronisieren
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
}
