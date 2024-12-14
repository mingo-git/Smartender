import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

        // Slots lokal speichern
        await _saveSlotsLocally(slots);
        print("SLOTS fetched and saved locally.");
      } else {
        print("Failed to fetch SLOTS: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching SLOTS: $e");
    }
  }

  /// Speichere die Slots lokal in SharedPreferences
  Future<void> _saveSlotsLocally(List<dynamic> slots) async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = json.encode(slots);
    await prefs.setString('slots', slotsJson);
  }

  /// Aktualisiere einen spezifischen Slot im Backend
  Future<void> updateSlot(int slotNumber, int? drinkId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Skipping slot update.");
      return;
    }

    final url = Uri.parse("$baseUrl$_allSlotsUrl/$slotNumber");

    // Aufbau der Header
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'Authorization': 'Bearer $token',
    };

    // Aufbau des Bodys
    final body = drinkId != null ? json.encode({"drink_id": drinkId}) : null;

    try {
      // HTTP-PUT-Request ausführen
      final response = await http.put(
        url,
        headers: headers,
        body: body, // Kein Body für "Clear"
      );


      if (response.statusCode == 204) {
        print("SLOT $slotNumber updated successfully.");
        await fetchAndSaveData(); // Slots nach Update synchronisieren
      } else {
        print("Failed to update SLOT: ${response.statusCode}");
      }
    } catch (e) {
      print("Error updating SLOT: $e");
    }
  }


  /// Abrufen der Slots aus den SharedPreferences
  Future<List<Map<String, dynamic>>> fetchSlotsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final slotsJson = prefs.getString('slots');
    if (slotsJson != null) {
      final slots = List<Map<String, dynamic>>.from(json.decode(slotsJson));
      return slots;
    }
    print("No SLOTS found in SharedPreferences.");
    return [];
  }
}
