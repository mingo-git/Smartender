import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'auth_service.dart';
import 'fetchable_service.dart';

class DrinkService extends ChangeNotifier implements FetchableService {
  final String _allDrinksUrl = "/user/hardware/2/drinks";

  @override
  Future<void> fetchAndSaveData() async {
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
        print("DRINKS fetched and saved locally. Count: ${drinks.length}");
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
        await fetchAndSaveData(); // Daten nach Hinzufügen aktualisieren
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
        await fetchAndSaveData(); // Daten nach Aktualisieren neu laden
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
        await fetchAndSaveData(); // Daten nach Löschen neu laden
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
}
