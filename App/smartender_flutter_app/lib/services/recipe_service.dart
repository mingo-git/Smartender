// lib/services/recipe_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'auth_service.dart';
import 'fetchable_service.dart';
import 'package:flutter/foundation.dart'; // Für ChangeNotifier

class RecipeService extends ChangeNotifier implements FetchableService {
  final String _recipeUrl = "/user/hardware/2/recipes";
  final String _favoriteUrl = "/user/hardware/2/favorite"; // Korrigierte URL

  /// Abrufen und Speichern der Rezepte vom Backend
  @override
  Future<void> fetchAndSaveData() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Skipping fetch.");
      return;
    }

    final recipeUrl = Uri.parse(baseUrl + _recipeUrl);
    final favoriteUrl = Uri.parse(baseUrl + _favoriteUrl + "s"); // Korrigierte URL


    Map<String, dynamic> decoded = {};
    List<int> favoriteIds = [];

    try {
      // Fetch Recipes
      final recipeResponse = await http.get(
        recipeUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
      );

      if (recipeResponse.statusCode == 200) {
        final body = recipeResponse.body;

        if (body.isEmpty) {
          await _saveRecipesLocally({});
          print("No recipes returned by the server. Saved empty map locally.");
          return;
        }

        try {
          decoded = json.decode(body);
          if (!decoded.containsKey("available") || !decoded.containsKey("unavailable")) {
            print("Response does not contain expected keys. Saving empty map.");
            decoded = {};
          }
        } catch (e) {
          decoded = {};
          print("Error decoding recipe response: $e. Using empty map.");
        }
      } else {
        print("Failed to fetch RECIPES: ${recipeResponse.statusCode}, Response: ${recipeResponse.body}");
        return;
      }

      // Fetch Favorite Recipe IDs
      final favoriteResponse = await http.get(
        favoriteUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
      );

      if (favoriteResponse.statusCode == 200) {
        try {
          final favoriteBody = json.decode(favoriteResponse.body);
          favoriteIds = List<int>.from(favoriteBody);
          print("Fetched favorite recipe IDs: $favoriteIds");
        } catch (e) {
          print("Error decoding favorite response: $e");
        }
      } else {
        print("Failed to fetch FAVORITES: ${favoriteResponse.statusCode}, Response: ${favoriteResponse.body}");
      }

      // ----------------------------------------------------------------------------
      // SLOTS aus SharedPreferences laden, um zu prüfen, ob ein drink_id verfügbar ist
      final prefs = await SharedPreferences.getInstance();
      final slotsJson = prefs.getString('slots');
      final Set<int> slotDrinkIds = {};

      if (slotsJson != null) {
        try {
          final List<dynamic> slotList = json.decode(slotsJson);

          for (var slot in slotList) {
            if (slot['drink'] != null && slot['drink']['drink_id'] != null) {
              slotDrinkIds.add(slot['drink']['drink_id'] as int);
            }
          }
          // Debug-Ausgabe: Zeigt alle in Slots gespeicherten drink_ids.
          print("[DEBUG] Slot Drink IDs (aus SharedPrefs geladen): $slotDrinkIds");
        } catch (e) {
          print("Error decoding slots from SharedPreferences: $e");
        }
      } else {
        print("[DEBUG] Keine Slots in SharedPreferences gefunden. slotDrinkIds bleibt leer.");
      }
      // ----------------------------------------------------------------------------

      // Add 'is_favorite' attribute to recipes
      // UND: Erzeuge ein 'ingredients'-Array mit 'missing = true/false'
      decoded['available'] = (decoded['available'] as List<dynamic>?)
          ?.map((recipe) {
        int recipeId = recipe['recipe_id'] is int
            ? recipe['recipe_id']
            : int.tryParse(recipe['recipe_id'].toString()) ?? -1;

        // Markiere, ob das Rezept zu den Favoriten gehört
        recipe['is_favorite'] = favoriteIds.contains(recipeId);

        // Ingredients anhand des "ingredientsResponse" umwandeln
        final ingredientsResponse = recipe['ingredientsResponse'] as List<dynamic>?;
        if (ingredientsResponse != null) {
          recipe['ingredients'] = ingredientsResponse.map((ing) {
            final int drinkId = ing['drink']['drink_id'] ?? -1;
            final String drinkName = ing['drink']['drink_name'] ?? "Unknown";
            final int quantityMl = ing['quantity_ml'] ?? 0;

            // Debug: genau ausdrucken, was verglichen wird
            bool isMissing = !slotDrinkIds.contains(drinkId);
            print("[DEBUG] (AVAILABLE) Checking ingredient drink_id=$drinkId "
                "($drinkName), inSlots=${slotDrinkIds.contains(drinkId)} -> missing=$isMissing");

            return {
              'drink_id': drinkId,
              'name': drinkName,
              'quantity_ml': quantityMl,
              // Wenn nicht in slots vorhanden => missing = true
              'missing': isMissing,
            };
          }).toList();
        } else {
          recipe['ingredients'] = [];
        }

        return recipe;
      }).toList();

      decoded['unavailable'] = (decoded['unavailable'] as List<dynamic>?)
          ?.map((recipe) {
        int recipeId = recipe['recipe_id'] is int
            ? recipe['recipe_id']
            : int.tryParse(recipe['recipe_id'].toString()) ?? -1;

        // Markiere, ob das Rezept zu den Favoriten gehört
        recipe['is_favorite'] = favoriteIds.contains(recipeId);

        // Ingredients anhand des "ingredientsResponse" umwandeln
        final ingredientsResponse = recipe['ingredientsResponse'] as List<dynamic>?;
        if (ingredientsResponse != null) {
          recipe['ingredients'] = ingredientsResponse.map((ing) {
            final int drinkId = ing['drink']['drink_id'] ?? -1;
            final String drinkName = ing['drink']['drink_name'] ?? "Unknown";
            final int quantityMl = ing['quantity_ml'] ?? 0;

            bool isMissing = !slotDrinkIds.contains(drinkId);
            print("[DEBUG] (UNAVAILABLE) Checking ingredient drink_id=$drinkId "
                "($drinkName), inSlots=${slotDrinkIds.contains(drinkId)} -> missing=$isMissing");

            return {
              'drink_id': drinkId,
              'name': drinkName,
              'quantity_ml': quantityMl,
              'missing': isMissing,
            };
          }).toList();
        } else {
          recipe['ingredients'] = [];
        }

        return recipe;
      }).toList();

      // DEBUG-Ausgabe (optional)
      print("\n[DEBUG] Available Recipes:");
      (decoded['available'] as List<dynamic>?)?.forEach((recipe) {
        final recipeName = recipe['recipe_name'] ?? "Unknown";
        final isFavorite = recipe['is_favorite'] ?? false;
        print("  Recipe ID: ${recipe['recipe_id']}, Name: $recipeName, Is Favorite: $isFavorite");
        if (recipe.containsKey('ingredients')) {
          for (var ingredient in recipe['ingredients']) {
            print("    -> Ingredient: ${ingredient['name']} (ID: ${ingredient['drink_id']}), "
                "Missing: ${ingredient['missing']}, "
                "Quantity: ${ingredient['quantity_ml']} ml");
          }
        }
      });

      print("\n[DEBUG] Unavailable Recipes:");
      (decoded['unavailable'] as List<dynamic>?)?.forEach((recipe) {
        final recipeName = recipe['recipe_name'] ?? "Unknown";
        final isFavorite = recipe['is_favorite'] ?? false;
        print("  Recipe ID: ${recipe['recipe_id']}, Name: $recipeName, Is Favorite: $isFavorite");
        if (recipe.containsKey('ingredients')) {
          for (var ingredient in recipe['ingredients']) {
            print("    -> Ingredient: ${ingredient['name']} (ID: ${ingredient['drink_id']}), "
                "Missing: ${ingredient['missing']}, "
                "Quantity: ${ingredient['quantity_ml']} ml");
          }
        }
      });

      // Save combined data locally
      await _saveRecipesLocally(decoded);
      print("RECIPES and FAVORITES fetched and saved locally. "
          "Available Count: ${decoded['available']?.length ?? 0}, "
          "Unavailable Count: ${decoded['unavailable']?.length ?? 0}");

      notifyListeners(); // Benachrichtigen der Zuhörer
    } catch (e) {
      print("Error fetching RECIPES or FAVORITES: $e");
    }
  }

  /// Speichere die Rezepte lokal in SharedPreferences
  Future<void> _saveRecipesLocally(Map<String, dynamic> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = json.encode(recipes);
    await prefs.setString('recipes', recipesJson);
    print("RECIPES saved to SharedPreferences: $recipesJson");

    // Debugging: Ausgabe der Recipes mit deren Ingredients und drink_id nach dem Speichern
    print("Gespeicherte Recipes mit drink_id:");
    recipes.forEach((key, value) {
      print("Recipe Category: $key");
      if (value is List) {
        for (var recipe in value) {
          print("  Recipe ID: ${recipe['recipe_id']}, Name: ${recipe['recipe_name']}, Is Favorite: ${recipe['is_favorite']}");
          if (recipe.containsKey('ingredients')) {
            for (var ingredient in recipe['ingredients']) {
              print("    Ingredient Drink ID: ${ingredient['drink_id']}, "
                  "Missing: ${ingredient['missing']}, "
                  "Quantity: ${ingredient['quantity_ml']} ml");
            }
          }
        }
      }
    });
  }

  /// Abrufen der Rezepte aus den SharedPreferences
  Future<Map<String, dynamic>> fetchRecipesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getString('recipes');
    if (recipesJson != null) {
      final recipes = Map<String, dynamic>.from(json.decode(recipesJson));

      // Debugging: Ausgabe der Recipes mit deren Ingredients und drink_id
      print("Recipes aus SharedPreferences:");
      recipes.forEach((key, value) {
        print("Recipe Category: $key");
        if (value is List) {
          for (var recipe in value) {
            print("  Recipe ID: ${recipe['recipe_id']}, Name: ${recipe['recipe_name']}, Is Favorite: ${recipe['is_favorite']}");
            if (recipe.containsKey('ingredients')) {
              for (var ingredient in recipe['ingredients']) {
                print("    Ingredient Drink ID: ${ingredient['drink_id']}, "
                    "Missing: ${ingredient['missing']}, "
                    "Quantity: ${ingredient['quantity_ml']} ml");
              }
            }
          }
        }
      });

      return recipes;
    }
    print("No RECIPES found in SharedPreferences.");
    return {};
  }

  /// Fügt ein neues Rezept hinzu.
  /// [recipeName] - Der Name des Rezepts.
  /// [ingredients] - Eine Liste von Zutaten mit deren ID und Menge.
  /// [pictureId] - Optional: Die ID des ausgewählten Bildes.
  Future<bool> addRecipe(
      String recipeName, List<Map<String, dynamic>> ingredients,
      {int? pictureId}) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    print("Recipe Name: $recipeName");
    print("Ingredients: $ingredients");
    print("Picture ID: $pictureId");

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
          "ingredients": ingredients.map((ing) => {
            "drink_id": ing["id"],
            "quantity_ml": ing["quantity"],
          }).toList(),
          "picture_id": pictureId ?? 0, // Hier wird picture_id hinzugefügt
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final int recipeId = responseData["recipe_id"];
        print("Recipe created with ID: $recipeId");

        final bool recipeReady = await _waitForRecipeAvailability(recipeId, token);
        if (!recipeReady) {
          print("Recipe not available after retries.");
          return false;
        }

        print("All ingredients added successfully.");
        return true;
      } else {
        print("Failed to add recipe: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error adding recipe: $e");
      return false;
    }
  }

  /// Aktualisiert ein bestehendes Rezept mit neuen Zutaten.
  /// [recipeId] - Die ID des zu aktualisierenden Rezepts.
  /// [recipeName] - Der neue Name des Rezepts.
  /// [newIngredients] - Die neuen Zutaten des Rezepts.
  /// [originalIngredients] - Die ursprünglichen Zutaten des Rezepts.
  /// [pictureId] - Optional: Die ID des ausgewählten Bildes.
  Future<bool> updateRecipeWithIngredients(
      int recipeId,
      String recipeName,
      List<Map<String, dynamic>> newIngredients,
      List<Map<String, dynamic>> originalIngredients,
      {int? pictureId}
      ) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    print("Updating Recipe ID: $recipeId");
    print("New Name: $recipeName");
    print("New Ingredients: $newIngredients");
    print("Original Ingredients: $originalIngredients");
    print("Picture ID: $pictureId");

    if (token == null) {
      print("No token available. Cannot update recipe.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_recipeUrl/$recipeId");
    print("Update Recipe URL: $url");

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "recipe_name": recipeName,
          "picture_id": pictureId ?? 0, // Hier wird picture_id hinzugefügt
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Recipe updated successfully: $recipeName (ID: $recipeId)");

        final originalById = {for (var ing in originalIngredients) ing["id"]: ing};
        final newById = {for (var ing in newIngredients) ing["id"]: ing};

        // Entferne Zutaten, die nicht mehr vorhanden sind
        for (var oid in originalById.keys) {
          if (!newById.containsKey(oid)) {
            final deleted = await _deleteIngredientFromRecipe(recipeId, oid);
            if (!deleted) {
              print("Failed to delete ingredient $oid from recipe $recipeId");
              return false;
            }
          }
        }

        // Füge neue Zutaten hinzu oder aktualisiere bestehende
        for (var nid in newById.keys) {
          if (!originalById.containsKey(nid)) {
            final added = await _addIngredientToRecipe(
                recipeId, nid, (newById[nid]?["quantity"] as int?)?.toDouble() ?? 0.0);
            if (!added) {
              print("Failed to add new ingredient $nid to recipe $recipeId");
              return false;
            }
          } else {
            final oldQty = (originalById[nid]?["quantity"]) ?? 0;
            final newQty = (newById[nid]?["quantity"]) ?? 0;
            if (oldQty != newQty) {
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
        print("Failed to update RECIPE: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating RECIPE: $e");
      return false;
    }
  }

  /// Löscht eine Zutat aus einem Rezept.
  /// [recipeId] - Die ID des Rezepts.
  /// [drinkId] - Die ID der Zutat.
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

  /// Aktualisiert die Menge einer Zutat in einem Rezept.
  /// [recipeId] - Die ID des Rezepts.
  /// [drinkId] - Die ID der Zutat.
  /// [quantity] - Die neue Menge der Zutat in ml.
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

  /// Löscht ein Rezept.
  /// [recipeId] - Die ID des zu löschenden Rezepts.
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
        print("Failed to delete RECIPE: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error deleting RECIPE: $e");
      return false;
    }
  }

  /// Wartet darauf, dass das Rezept im Backend verfügbar ist.
  /// [recipeId] - Die ID des Rezepts.
  /// [token] - Das Authentifizierungstoken.
  /// [retries] - Anzahl der Wiederholungen.
  /// [delay] - Verzögerung zwischen den Wiederholungen.
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

  /// Fügt eine Zutat zu einem Rezept hinzu.
  /// [recipeId] - Die ID des Rezepts.
  /// [drinkId] - Die ID der Zutat.
  /// [quantity] - Die Menge der Zutat in ml.
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

  /// Fügt ein Rezept zur Favoritenliste hinzu.
  /// [recipeId] - Die ID des Rezepts, das als Favorit markiert werden soll.
  Future<bool> addRecipeToFavorites(int recipeId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot add to favorites.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_favoriteUrl/$recipeId");
    print("Add to Favorites URL: $url");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
      );

      print("RESPONSE: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Recipe (ID: $recipeId) successfully added to favorites.");
        await fetchAndSaveData(); // Aktualisiere die lokale Speicherung
        notifyListeners(); // Benachrichtigen der Zuhörer
        return true;
      } else {
        print("Failed to add to favorites: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error adding to favorites: $e");
      return false;
    }
  }

  /// Entfernt ein Rezept aus der Favoritenliste.
  /// [recipeId] - Die ID des Rezepts, das aus der Favoritenliste entfernt werden soll.
  Future<bool> removeRecipeFromFavorites(int recipeId) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    if (token == null) {
      print("No token available. Cannot remove from favorites.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_favoriteUrl/$recipeId");
    print("Remove from Favorites URL: $url");

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
        print("Recipe (ID: $recipeId) successfully removed from favorites.");
        await fetchAndSaveData(); // Aktualisiere die lokale Speicherung
        notifyListeners(); // Benachrichtigen der Zuhörer
        return true;
      } else {
        print("Failed to remove from favorites: ${response.statusCode}, Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error removing from favorites: $e");
      return false;
    }
  }
}
