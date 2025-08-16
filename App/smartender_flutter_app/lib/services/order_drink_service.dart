// lib/services/order_drink_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../provider/theme_provider.dart';
import 'auth_service.dart';

class OrderDrinkService {
  final String _orderDrinkUrl = "/user/action";

  /// Funktion zum Bestellen eines Getränks.
  /// [recipeId] - Die ID des Rezepts, das bestellt werden soll.
  ///
  /// Gibt `true` zurück, wenn die Bestellung erfolgreich war, andernfalls `false`.
  Future<bool> orderDrink(int recipeId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      debugPrint("No token available. Cannot order drink.");
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
        body: json.encode({
          "hardware_id": 2, // Hardware-ID festgelegt
          "recipe_id": recipeId,
        }),
      );

      var statusCode = response.statusCode;

      debugPrint("STATUS CODE: $statusCode");

      if (statusCode == 200 || statusCode == 201) {
        debugPrint("Drink order placed successfully for Recipe ID: $recipeId");
        return true;
      } else {
        // Fehlerbehandlung für verschiedene Statuscodes
        if (statusCode == 404) {
          _showErrorMessage("Smartender could not be reached");
        } else if (statusCode == 400) {
          _showErrorMessage("Bad request: Missing or incorrect data");
        } else {
          _showErrorMessage("Drink order failed");
        }
        debugPrint(
            "Failed to place drink order: $statusCode, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error placing drink order: $e");
      _showErrorMessage("An unexpected error occurred");
      return false;
    }
  }

  /// Zeigt eine Fehlermeldung als Snackbar an.
  void _showErrorMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      final theme = Provider.of<ThemeProvider>(context!, listen: false).currentTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: theme.primaryColor)),
          backgroundColor: theme.falseColor,
        ),
      );
        });
  }
}
