// lib/services/order_drink_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class OrderDrinkService {
  final String _orderUrl = "/user/action";
  final String _hardwareId = "2"; // Sie können dies dynamisch machen, falls erforderlich

  /// Sendet eine Bestellung an das Backend.
  ///
  /// [recipeId] - Die ID des Rezepts, das bestellt werden soll.
  ///
  /// Gibt `true` zurück, wenn die Bestellung erfolgreich war, andernfalls `false`.
  Future<bool> orderDrink(int recipeId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();
    final String? apiKey = dotenv.env['API_KEY'];

    if (token == null) {
      print("Kein Token verfügbar. Bestellung kann nicht gesendet werden.");
      return false;
    }

    if (apiKey == null) {
      print("API Key ist nicht gesetzt. Bitte überprüfen Sie Ihre .env Datei.");
      return false;
    }

    final Uri url = Uri.parse("${dotenv.env['BASE_URL'] ?? 'http://localhost:8080'}$_orderUrl");

    final Map<String, dynamic> body = {
      "hardware_id": int.parse(_hardwareId),
      "recipe_id": recipeId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Bestellung erfolgreich gesendet: Rezept ID $recipeId auf Hardware $_hardwareId");
        return true;
      } else {
        print("Fehler beim Senden der Bestellung: ${response.statusCode}, Antwort: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Fehler beim Senden der Bestellung: $e");
      return false;
    }
  }
}
