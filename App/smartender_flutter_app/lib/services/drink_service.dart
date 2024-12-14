import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';
import 'fetch_data_service.dart';

class DrinkService implements FetchableService {
  final String _allDrinksUrl = "/user/hardware/2/drinks";

  /// Abrufen und Speichern der Drinks vom Backend
  @override
  Future<void> fetchAndSaveData() async {
    final AuthService authService = AuthService(); // Auth-Service
    final String? token = await authService.getToken(); // Token abrufen

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
        // Prüfe, ob der Body leer ist oder nicht
        if (response.body.isEmpty) {
          // Kein Inhalt, leere Liste speichern
          await _saveDrinksLocally([]);
          print("No drinks returned by the server. Saved empty list locally.");
          return;
        }

        // Versuche zu decodieren
        List<dynamic> drinks;
        try {
          final decoded = json.decode(response.body);

          // Stelle sicher, dass decoded auch eine Liste ist
          if (decoded is List) {
            drinks = decoded;
          } else {
            // Falls kein Listenobjekt, verwende eine leere Liste
            drinks = [];
            print("Response did not return a list, using empty list.");
          }
        } catch (e) {
          // Falls decoding fehlschlägt
          drinks = [];
          print("Error decoding response: $e. Using empty list.");
        }

        // Drinks als vollständige Objekte speichern
        await _saveDrinksLocally(drinks);
        print("DRINKS fetched and saved locally. Count: ${drinks.length}");
      } else {
        print("Failed to fetch DRINKS: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching DRINKS: $e");
    }
  }


  /// Speichere die Drinks lokal in SharedPreferences
  Future<void> _saveDrinksLocally(List<dynamic> drinks) async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = json.encode(drinks);
    await prefs.setString('drinks', drinksJson);
  }

  /// Abrufen der Drinks aus den SharedPreferences
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
      print("No token available. Cannot add drink.");
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
        print("DRINK added successfully: $drinkName");
        await fetchAndSaveData(); // Daten nach Hinzufügen aktualisieren
        return true;
      } else {
        print("Failed to add DRINK: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error adding DRINK: $e");
      return false;
    }
  }

  /// Aktualisieren eines bestehenden Drinks (PUT)
  Future<bool> updateDrink(int drinkId, String drinkName, bool isAlcoholic) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot update drink.");
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
        print("DRINK updated successfully: $drinkName (ID: $drinkId)");
        await fetchAndSaveData(); // Daten nach Aktualisieren neu laden
        return true;
      } else {
        print("Failed to update DRINK: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error updating DRINK: $e");
      return false;
    }
  }

  /// Löschen eines Drinks (DELETE)
  Future<bool> deleteDrink(int drinkId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot delete drink.");
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

      if (response.statusCode == 200) {
        print("DRINK deleted successfully (ID: $drinkId)");
        await fetchAndSaveData(); // Daten nach Löschen neu laden
        return true;
      } else {
        print("Failed to delete DRINK: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error deleting DRINK: $e");
      return false;
    }
  }
}
