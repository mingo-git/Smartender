import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/constants.dart';
import 'package:smartender_flutter_app/config/constants.dart';

class RecipeService {

  final String _recipeUrl = "/user/hardware/2/recipes";



  Future<bool> addRecipe(String recipeName, List<Map<String, dynamic>> ingredients) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    print("Recipe Name: $recipeName");
    print("Ingredients: $ingredients");

    if (token == null) {
      print("No token available. Cannot add recipe.");
      return false;
    }

    final recipeUrl = Uri.parse(baseUrl + _recipeUrl);
    print("Recipe URL: $recipeUrl");

    try {
      // 1. Füge das Rezept hinzu
      final response = await http.post(
        recipeUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "recipe_name": recipeName,
          "ingredients": [],
        }),
      );

      if (response.statusCode == 201) {
        // Rezept erfolgreich erstellt
        final responseData = json.decode(response.body);
        final int recipeId = responseData["recipe_id"];
        print("Recipe created with ID: $recipeId");

        // 2. Warten, bis das Rezept verfügbar ist
        final bool recipeReady = await _waitForRecipeAvailability(recipeId, token);
        if (!recipeReady) {
          print("Recipe not available after retries.");
          return false;
        }

        // 3. Füge die Zutaten einzeln hinzu
        for (var ingredient in ingredients) {
          final ingredientResponse = await _addIngredientToRecipe(
            recipeId,
            ingredient["id"],
            ingredient["quantity"],
          );

          if (!ingredientResponse) {
            print("Failed to add ingredient with ID: ${ingredient["id"]}");
            return false; // Abbrechen, wenn das Hinzufügen einer Zutat fehlschlägt
          }
        }

        print("All ingredients added successfully.");
        return true;
      } else {
        print("Failed to add recipe: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error adding recipe: $e");
      return false;
    }
  }

  Future<bool> _waitForRecipeAvailability(int recipeId, String token, {int retries = 5, Duration delay = const Duration(seconds: 1)}) async {
    final recipeCheckUrl = Uri.parse(baseUrl + _recipeUrl + "/$recipeId");
    print("Checking recipe availability at: $recipeCheckUrl");

    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.get(
          recipeCheckUrl,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          print("Recipe is now available: $recipeId");
          return true;
        }
      } catch (e) {
        print("Error checking recipe availability: $e");
      }

      // Wartezeit vor erneutem Versuch
      await Future.delayed(delay);
    }

    print("Recipe check retries exceeded.");
    return false;
  }

  Future<bool> _addIngredientToRecipe(int recipeId, int drinkId, double quantity) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot add ingredient to recipe.");
      return false;
    }

    final url = Uri.parse(baseUrl + _recipeUrl + "/$recipeId/ingredients");
    print("Adding ingredient URL: $url");

    // Sicherstellen, dass der Body die korrekten Datentypen hat
    final body = {
      "drink_id": drinkId, // Bleibt ein Integer
      "quantity_ml": quantity.toInt(), // Konvertiert die Menge zu einem Integer
    };
    print("Request Body: $body");

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

      if (response.statusCode == 201) {
        print("Ingredient added successfully: Drink ID: $drinkId, Quantity: ${quantity.toInt()}");
        return true;
      } else {
        print("Failed to add ingredient: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error adding ingredient: $e");
      return false;
    }
  }



}
