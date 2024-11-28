import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'fetch_data_service.dart';

class DrinkService implements FetchableService {
  final String _baseUrl;
  final String _allDrinksUrl = "/user/hardware/2/drinks";

  final StreamController<List<String>> _drinksController =
  StreamController<List<String>>.broadcast();

  Stream<List<String>> get drinksStream => _drinksController.stream;

  DrinkService({required String baseUrl}) : _baseUrl = baseUrl {
    _loadDrinksFromLocalStorage(); // Initiale Drinks laden
  }

  Future<void> fetchAndSaveData() async {
    final url = Uri.parse(_baseUrl + _allDrinksUrl);
    try {
      print("Fetching drinks from $url");
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer YOUR_AUTH_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        final drinks = json.decode(response.body) as List<dynamic>;
        await _saveDrinksLocally(drinks);
        _updateDrinksStream(); // Drinks im Stream aktualisieren
        print("Fetched Drinks: $drinks");
      } else {
        print("Failed to fetch drinks: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching drinks: $e");
    }
  }

  Future<void> _saveDrinksLocally(List<dynamic> drinks) async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = json.encode(drinks);
    await prefs.setString('drinks', drinksJson);
    print("Drinks saved locally: $drinks");
  }

  Future<void> _loadDrinksFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = prefs.getString('drinks');
    if (drinksJson != null) {
      final drinks = json.decode(drinksJson) as List<dynamic>;
      final drinkNames =
      drinks.map<String>((drink) => drink['drink_name'] as String).toList();
      _drinksController.add(drinkNames);
      print("Loaded drinks from local storage: $drinkNames");
    } else {
      _drinksController.add([]);
      print("No drinks found in local storage.");
    }
  }

  void _updateDrinksStream() async {
    final prefs = await SharedPreferences.getInstance();
    final drinksJson = prefs.getString('drinks');
    if (drinksJson != null) {
      final drinks = json.decode(drinksJson) as List<dynamic>;
      final drinkNames =
      drinks.map<String>((drink) => drink['drink_name'] as String).toList();
      _drinksController.add(drinkNames);
      print("Updated drinks stream: $drinkNames");
    }
  }

  void dispose() {
    _drinksController.close();
  }
}
