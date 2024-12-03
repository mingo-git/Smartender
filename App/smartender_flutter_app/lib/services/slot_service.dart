import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';
import 'fetch_data_service.dart';

class SlotService implements FetchableService {
  final String _allSlotsUrl = "/user/hardware/2/slots";

  /// Abrufen und Speichern der Slots vom Backend
  @override
  Future<void> fetchAndSaveData() async {
    final AuthService authService = AuthService(); // Auth-Service
    final String? token = await authService.getToken(); // Token abrufen

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

        // Extrahiere `slot_number`, `drink_id` und `drink_name`
        final formattedSlots = slots.map((slot) {
          final slotNumber = slot['slot_number'];
          final drink = slot['drink'];
          final drinkId = drink != null ? drink['drink_id'] : null;
          final drinkName = drink != null ? drink['drink_name'] : "Empty";

          return {
            "slot_number": slotNumber,
            "drink_id": drinkId,
            "drink_name": drinkName,
          };
        }).toList();

        // Speichere die formatierten Slots
        await _saveSlotsLocally(formattedSlots);
        print("Slots fetched and saved locally.");
      } else {
        print("Failed to fetch slots: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching slots: $e");
    }
  }

  /// Speichere die Slots lokal in SharedPreferences
  Future<void> _saveSlotsLocally(List<dynamic> slots) async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = json.encode(slots);
    await prefs.setString('slots', slotsJson);
  }

  /// Abrufen der Slots aus den SharedPreferences
  Future<List<Map<String, dynamic>>> fetchSlotsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getString('slots');
    if (slotsJson != null) {
      final slots = List<Map<String, dynamic>>.from(json.decode(slotsJson));
      return slots;
    }
    print("No slots found in SharedPreferences.");
    return [];
  }
}
