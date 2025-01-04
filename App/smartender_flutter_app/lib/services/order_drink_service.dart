// lib/services/order_drink_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/constants.dart';
import 'auth_service.dart';

class OrderDrinkService {
  final String _orderDrinkUrl = "/user/hardware/2/order";

  /// Funktion zum Bestellen eines Getränks.
  /// [recipeId] - Die ID des Rezepts, das bestellt werden soll.
  ///
  /// Gibt `true` zurück, wenn die Bestellung erfolgreich war, andernfalls `false`.
  Future<bool> orderDrink(int recipeId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot order drink.");
      return false;
    }

    final url = Uri.parse(baseUrl + _orderDrinkUrl);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({"recipe_id": recipeId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Drink order placed successfully for Recipe ID: $recipeId");
        return true;
      } else {
        print("Failed to place drink order: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error placing drink order: $e");
      return false;
    }
  }
}
