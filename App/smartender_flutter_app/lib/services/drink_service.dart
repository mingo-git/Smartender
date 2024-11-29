import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';
import 'fetch_data_service.dart';

class DrinkService implements FetchableService {
  final String _baseUrl;
  final String _allDrinksUrl = "/user/hardware/2/drinks";

  DrinkService({required String baseUrl}) : _baseUrl = baseUrl;

  /// Abrufen und Speichern der Drinks vom Backend
  @override
  Future<void> fetchAndSaveData() async {
    final AuthService authService = AuthService(); // Auth-Service
    final String? token = await authService.getToken(); // Token abrufen

    if (token == null) {
      print("No token available. Skipping fetch.");
      return;
    }

    final url = Uri.parse(_baseUrl + _allDrinksUrl);
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
        final drinks = json.decode(response.body) as List<dynamic>;
        final drinkNames = drinks.map((drink) => drink['drink_name'] as String).toList();

        await _saveDrinksLocally(drinkNames); // Speichere nur die drink_names in SharedPreferences
      } else {
        print("Failed to fetch drinks: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching drinks: $e");
    }
  }

  /// Speichere die Drinks lokal in SharedPreferences
  Future<void> _saveDrinksLocally(List<String> drinkNames) async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = json.encode(drinkNames);
    await prefs.setString('drinks', drinksJson);
  }

  /// Abrufen der Drinks aus den SharedPreferences
  Future<List<String>> fetchDrinksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = prefs.getString('drinks');
    if (drinksJson != null) {
      final drinkNames = List<String>.from(json.decode(drinksJson));
      return drinkNames;
    }
    print("No drinks found in SharedPreferences.");
    return [];
  }
}
