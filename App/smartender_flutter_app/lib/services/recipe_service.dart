import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'auth_service.dart';
import 'fetch_data_service.dart';

class RecipeService implements FetchableService {
  final String _recipeUrl = "/user/hardware/2/recipes";

  @override
  Future<void> fetchAndSaveData() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Skipping fetch.");
      return;
    }

    final url = Uri.parse(baseUrl + _recipeUrl);
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
        final body = response.body;
        if (body.isEmpty) {
          await _saveRecipesLocally({});
          print("No recipes returned by the server. Saved empty map locally.");
          return;
        }

        Map<String, dynamic> decoded;
        try {
          decoded = json.decode(body);
          if (!decoded.containsKey("available") || !decoded.containsKey("unavailable")) {
            print("Response does not contain expected keys. Saving empty map.");
            decoded = {};
          }
        } catch (e) {
          decoded = {};
          print("Error decoding response: $e. Using empty map.");
        }

        await _saveRecipesLocally(decoded);
        print("RECIPES fetched and saved locally. "
            "Available Count: ${decoded['available']?.length ?? 0}, "
            "Unavailable Count: ${decoded['unavailable']?.length ?? 0}");
      } else {
        print("Failed to fetch RECIPES: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching RECIPES: $e");
    }
  }

  Future<void> _saveRecipesLocally(Map<String, dynamic> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = json.encode(recipes);
    await prefs.setString('recipes', recipesJson);
  }

  Future<Map<String, dynamic>> fetchRecipesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getString('recipes');
    if (recipesJson != null) {
      final recipes = Map<String, dynamic>.from(json.decode(recipesJson));
      return recipes;
    }
    print("No RECIPES found in SharedPreferences.");
    return {};
  }

  /// Erstellt ein neues Rezept und fügt Zutaten hinzu.
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
        final responseData = json.decode(response.body);
        final int recipeId = responseData["recipe_id"];
        print("Recipe created with ID: $recipeId");

        // Warte bis das Rezept verfügbar ist
        final bool recipeReady = await _waitForRecipeAvailability(recipeId, token);
        if (!recipeReady) {
          print("Recipe not available after retries.");
          return false;
        }

        // Füge die Zutaten hinzu
        for (var ingredient in ingredients) {
          final ingredientResponse = await _addIngredientToRecipe(
            recipeId,
            ingredient["id"],
            ingredient["quantity"].toDouble(),
          );

          if (!ingredientResponse) {
            print("Failed to add ingredient with ID: ${ingredient["id"]}");
            return false;
          }
        }

        print("All ingredients added successfully.");
        await fetchAndSaveData();
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

  /// Aktualisiert ein bestehendes Rezept (Name) und managt die Zutaten:
  /// - Entfernte Zutaten löschen
  /// - Neue Zutaten hinzufügen
  /// - Geänderte Zutaten aktualisieren
  Future<bool> updateRecipeWithIngredients(int recipeId, String recipeName, List<Map<String, dynamic>> newIngredients, List<Map<String, dynamic>> originalIngredients) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    print("Updating Recipe ID: $recipeId");
    print("New Name: $recipeName");
    print("New Ingredients: $newIngredients");
    print("Original Ingredients: $originalIngredients");

    if (token == null) {
      print("No token available. Cannot update recipe.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_recipeUrl/$recipeId");
    print("Update Recipe URL: $url");

    try {
      // 1. Rezeptname aktualisieren
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "recipe_name": recipeName
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Recipe updated successfully: $recipeName (ID: $recipeId)");

        // 2. Änderungen an den Zutaten vornehmen

        final originalById = {for (var ing in originalIngredients) ing["id"]: ing};
        final newById = {for (var ing in newIngredients) ing["id"]: ing};

        // Zutaten, die in original waren, aber nicht mehr in new -> löschen
        for (var oid in originalById.keys) {
          if (!newById.containsKey(oid)) {
            // Diese Zutat wurde entfernt
            final deleted = await _deleteIngredientFromRecipe(recipeId, oid);
            if (!deleted) {
              print("Failed to delete ingredient $oid from recipe $recipeId");
              return false;
            }
          }
        }

        // Zutaten, die in new sind, aber vorher nicht da waren -> hinzufügen
        for (var nid in newById.keys) {
          if (!originalById.containsKey(nid)) {
            // Neue Zutat
            final added = await _addIngredientToRecipe(recipeId, nid, (newById[nid]?["quantity"] as int?)?.toDouble() ?? 0.0);
            if (!added) {
              print("Failed to add new ingredient $nid to recipe $recipeId");
              return false;
            }
          } else {
            // Zutaten, die es vorher gab und jetzt noch gibt -> Menge prüfen
            final oldQty = (originalById[nid]?["quantity"]) ?? 0;
            final newQty = (newById[nid]?["quantity"]) ?? 0;
            if (oldQty != newQty) {
              // Menge hat sich geändert -> PUT-Update
              final updated = await _updateIngredientInRecipe(recipeId, nid, newQty);
              if (!updated) {
                print("Failed to update ingredient $nid in recipe $recipeId");
                return false;
              }
            }
          }
        }

        await fetchAndSaveData();
        return true;
      } else {
        print("Failed to update RECIPE: ${response.statusCode}, ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating RECIPE: $e");
      return false;
    }
  }

  Future<bool> _deleteIngredientFromRecipe(int recipeId, int drinkId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot delete ingredient.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_recipeUrl/$recipeId/ingredients/$drinkId");
    print("Delete Ingredient URL: $url");

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
        print("Ingredient $drinkId deleted successfully from recipe $recipeId");
        return true;
      } else {
        print("Failed to delete ingredient: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error deleting ingredient: $e");
      return false;
    }
  }

  /// Aktualisiert eine einzelne Zutat im Rezept:
  /// PUT /user/hardware/2/recipes/{recipeId}/ingredients/{ingredientId}
  /// Body: {"quantity_ml": <int>}
  Future<bool> _updateIngredientInRecipe(int recipeId, int drinkId, int quantity) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot update ingredient.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_recipeUrl/$recipeId/ingredients/$drinkId");
    print("Update Ingredient URL: $url");
    final body = {
      "quantity_ml": quantity
    };
    print("Update Ingredient Body: $body");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Ingredient (ID:$drinkId) updated to $quantity ml successfully in recipe $recipeId");
        return true;
      } else {
        print("Failed to update ingredient: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating ingredient: $e");
      return false;
    }
  }

  Future<bool> deleteRecipe(int recipeId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot delete recipe.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_recipeUrl/$recipeId");
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
        print("RECIPE deleted successfully (ID: $recipeId)");
        await fetchAndSaveData();
        return true;
      } else {
        print("Failed to delete RECIPE: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error deleting RECIPE: $e");
      return false;
    }
  }

  Future<bool> _waitForRecipeAvailability(int recipeId, String token,
      {int retries = 5, Duration delay = const Duration(seconds: 1)}) async {
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

    final body = {
      "drink_id": drinkId,
      "quantity_ml": quantity.toInt(),
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
