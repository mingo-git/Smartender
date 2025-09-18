// lib/services/order_drink_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import '../provider/theme_provider.dart';

class OrderDrinkService {
  /// Bestellt einen Drink (HTTP-basiert, über den zentralen ApiClient).
  /// [recipeId] – ID des Rezepts, das bestellt werden soll.
  ///
  /// Gibt `true` zurück, wenn die Bestellung erfolgreich war, sonst `false`.
  Future<bool> orderDrink(int recipeId) async {
    try {
      final response = await ApiClient().orderDrink(recipeId);

      final statusCode = response.statusCode;
      debugPrint("STATUS CODE: $statusCode");

      if (statusCode == 200 || statusCode == 201) {
        debugPrint("Drink order placed successfully for Recipe ID: $recipeId");
        return true;
      } else {
        // Versuche, eine spezifische Fehlermeldung herauszulesen
        String message = _friendlyMessageForStatus(statusCode);
        try {
          final body = response.body;
          if (body.isNotEmpty) {
            final decoded = json.decode(body);
            if (decoded is Map && decoded['message'] is String) {
              message = decoded['message'];
            }
          }
        } catch (_) {
          // Ignorieren; fallback auf statusbasierte Nachricht
        }
        _showErrorMessage(message);
        debugPrint("Failed to place drink order: $statusCode, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error placing drink order: $e");
      _showErrorMessage("An unexpected error occurred");
      return false;
    }
  }

  String _friendlyMessageForStatus(int statusCode) {
    if (statusCode == 404) return "Smartender could not be reached";
    if (statusCode == 400) return "Bad request: Missing or incorrect data";
    return "Drink order failed";
  }

  /// Zeigt eine Fehlermeldung als Snackbar an.
  void _showErrorMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context == null) return; // Sicherstellen, dass ein Kontext vorhanden ist
      final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: theme.primaryColor)),
          backgroundColor: theme.falseColor,
        ),
      );
    });
  }
}
