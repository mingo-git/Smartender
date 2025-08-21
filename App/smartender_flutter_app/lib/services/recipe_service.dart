// lib/services/recipe_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/websocket/websocket_message.dart';
import 'auth_service.dart';
import 'fetchable_service.dart';
import 'websocket_service.dart';
import 'package:flutter/foundation.dart'; // Für ChangeNotifier

class RecipeService extends ChangeNotifier implements FetchableService {
  final String _recipeUrl = "/user/hardware/2/recipes";
  final String _favoriteUrl = "/user/hardware/2/favorite"; // Korrigierte URL
  final WebSocketService _webSocketService = WebSocketService();

  // Flag to prevent loops when updating from WebSocket
  bool _isUpdatingFromWebSocket = false;

  RecipeService() {
    _initializeWebSocketHandlers();
  }

  /// Initialize WebSocket message handlers
  void _initializeWebSocketHandlers() {
    _webSocketService.addMessageHandler(
      WebSocketMessageType.recipeUpdate,
      _handleRecipeUpdate,
    );
    _webSocketService.addMessageHandler(
      WebSocketMessageType.favoriteUpdate,
      _handleFavoriteUpdate,
    );
    _webSocketService.addMessageHandler(
      WebSocketMessageType.ingredientUpdate,
      _handleIngredientUpdate,
    );
    print("RecipeService: WebSocket handlers registered");
  }

  /// Handle incoming recipe updates from WebSocket
  void _handleRecipeUpdate(WebSocketMessage message) async {
    try {
      final recipeUpdate = RecipeUpdateMessage.fromJson(message.data);
      print("RecipeService: Received ${recipeUpdate.action.value} for recipe: ${recipeUpdate.recipe?['recipe_id']}");

      _isUpdatingFromWebSocket = true;

      switch (recipeUpdate.action) {
        case WebSocketAction.created:
          await _handleRecipeCreated(recipeUpdate.recipe);
          break;
        case WebSocketAction.updated:
          await _handleRecipeUpdated(recipeUpdate.recipe);
          break;
        case WebSocketAction.deleted:
          await _handleRecipeDeleted(recipeUpdate.recipe);
          break;
        case WebSocketAction.unknown:
          print("RecipeService: Unknown recipe action received");
          break;
      }

      _isUpdatingFromWebSocket = false;
      notifyListeners();

    } catch (e) {
      print("RecipeService: Error handling recipe update: $e");
      _isUpdatingFromWebSocket = false;
    }
  }

  /// Handle incoming favorite updates from WebSocket
  void _handleFavoriteUpdate(WebSocketMessage message) async {
    try {
      final favoriteUpdate = FavoriteUpdateMessage.fromJson(message.data);
      print("RecipeService: Received favorite ${favoriteUpdate.action.value} for recipe: ${favoriteUpdate.recipeId}");

      _isUpdatingFromWebSocket = true;

      switch (favoriteUpdate.action) {
        case WebSocketAction.created:
          await _handleFavoriteAdded(favoriteUpdate.recipeId);
          break;
        case WebSocketAction.deleted:
          await _handleFavoriteRemoved(favoriteUpdate.recipeId);
          break;
        case WebSocketAction.updated:
        case WebSocketAction.unknown:
          print("RecipeService: Unhandled favorite action: ${favoriteUpdate.action.value}");
          break;
      }

      _isUpdatingFromWebSocket = false;
      notifyListeners();

    } catch (e) {
      print("RecipeService: Error handling favorite update: $e");
      _isUpdatingFromWebSocket = false;
    }
  }

  /// Handle incoming ingredient updates from WebSocket
  void _handleIngredientUpdate(WebSocketMessage message) async {
    try {
      final ingredientUpdate = IngredientUpdateMessage.fromJson(message.data);
      print("RecipeService: Received ingredient ${ingredientUpdate.action.value} for recipe: ${ingredientUpdate.recipeId}");

      _isUpdatingFromWebSocket = true;

      // For ingredient updates, we need to refetch the entire recipe to get updated ingredient list
      if (ingredientUpdate.recipeId != null) {
        await _handleRecipeIngredientChange(ingredientUpdate.recipeId!);
      }

      _isUpdatingFromWebSocket = false;
      notifyListeners();

    } catch (e) {
      print("RecipeService: Error handling ingredient update: $e");
      _isUpdatingFromWebSocket = false;
    }
  }

  /// Handle recipe created via WebSocket
  Future<void> _handleRecipeCreated(Map<String, dynamic>? recipeData) async {
    if (recipeData == null) return;

    try {
      final recipesData = await fetchRecipesFromLocal();
      final recipeId = recipeData['recipe_id'];

      // Process the recipe with ingredients and missing flags
      final processedRecipe = await _processRecipeData(recipeData);

      // Add to available recipes (new recipes are typically available)
      final available = List<Map<String, dynamic>>.from(recipesData['available'] ?? []);
      final existingIndex = available.indexWhere((r) => r['recipe_id'] == recipeId);

      if (existingIndex == -1) {
        available.add(processedRecipe);
        recipesData['available'] = available;
        await _saveRecipesLocally(recipesData);
        print("RecipeService: Added new recipe via WebSocket: ${recipeData['recipe_name']}");
      } else {
        print("RecipeService: Recipe already exists, skipping creation: $recipeId");
      }
    } catch (e) {
      print("RecipeService: Error handling recipe creation: $e");
    }
  }

  /// Handle recipe updated via WebSocket
  Future<void> _handleRecipeUpdated(Map<String, dynamic>? recipeData) async {
    if (recipeData == null) return;

    try {
      final recipesData = await fetchRecipesFromLocal();
      final recipeId = recipeData['recipe_id'];

      // Process the recipe with ingredients and missing flags
      final processedRecipe = await _processRecipeData(recipeData);

      // Check both available and unavailable lists
      final available = List<Map<String, dynamic>>.from(recipesData['available'] ?? []);
      final unavailable = List<Map<String, dynamic>>.from(recipesData['unavailable'] ?? []);

      bool found = false;

      // Update in available list
      final availableIndex = available.indexWhere((r) => r['recipe_id'] == recipeId);
      if (availableIndex != -1) {
        available[availableIndex] = processedRecipe;
        found = true;
      }

      // Update in unavailable list
      final unavailableIndex = unavailable.indexWhere((r) => r['recipe_id'] == recipeId);
      if (unavailableIndex != -1) {
        unavailable[unavailableIndex] = processedRecipe;
        found = true;
      }

      if (!found) {
        // Recipe doesn't exist locally, add to available
        available.add(processedRecipe);
      }

      recipesData['available'] = available;
      recipesData['unavailable'] = unavailable;
      await _saveRecipesLocally(recipesData);
      print("RecipeService: Updated recipe via WebSocket: ${recipeData['recipe_name']}");
    } catch (e) {
      print("RecipeService: Error handling recipe update: $e");
    }
  }

  /// Handle recipe deleted via WebSocket
  Future<void> _handleRecipeDeleted(Map<String, dynamic>? recipeData) async {
    if (recipeData == null) return;

    try {
      final recipesData = await fetchRecipesFromLocal();
      final recipeId = recipeData['recipe_id'];

      // Remove from both available and unavailable lists
      final available = List<Map<String, dynamic>>.from(recipesData['available'] ?? []);
      final unavailable = List<Map<String, dynamic>>.from(recipesData['unavailable'] ?? []);

      available.removeWhere((r) => r['recipe_id'] == recipeId);
      unavailable.removeWhere((r) => r['recipe_id'] == recipeId);

      recipesData['available'] = available;
      recipesData['unavailable'] = unavailable;
      await _saveRecipesLocally(recipesData);
      print("RecipeService: Removed recipe via WebSocket: ${recipeData['recipe_name']}");
    } catch (e) {
      print("RecipeService: Error handling recipe deletion: $e");
    }
  }

  /// Handle favorite added via WebSocket
  Future<void> _handleFavoriteAdded(int? recipeId) async {
    if (recipeId == null) return;

    try {
      await _updateRecipeFavoriteStatus(recipeId, true);
      print("RecipeService: Added favorite via WebSocket: $recipeId");
    } catch (e) {
      print("RecipeService: Error handling favorite addition: $e");
    }
  }

  /// Handle favorite removed via WebSocket
  Future<void> _handleFavoriteRemoved(int? recipeId) async {
    if (recipeId == null) return;

    try {
      await _updateRecipeFavoriteStatus(recipeId, false);
      print("RecipeService: Removed favorite via WebSocket: $recipeId");
    } catch (e) {
      print("RecipeService: Error handling favorite removal: $e");
    }
  }

  /// Handle recipe ingredient changes
  Future<void> _handleRecipeIngredientChange(int recipeId) async {
    try {
      // We need to refetch this specific recipe from the server to get updated ingredients
      // For now, we'll trigger a full refresh if WebSocket is not providing complete data
      print("RecipeService: Ingredient changed for recipe $recipeId - triggering refresh");

      // In a real implementation, you might want to fetch only the specific recipe
      // For simplicity, we'll do a full refresh
      if (!_isUpdatingFromWebSocket) {
        await fetchAndSaveData();
      }
    } catch (e) {
      print("RecipeService: Error handling ingredient change: $e");
    }
  }

  /// Update favorite status for a specific recipe
  Future<void> _updateRecipeFavoriteStatus(int recipeId, bool isFavorite) async {
    try {
      final recipesData = await fetchRecipesFromLocal();

      // Update in both available and unavailable lists
      final available = List<Map<String, dynamic>>.from(recipesData['available'] ?? []);
      final unavailable = List<Map<String, dynamic>>.from(recipesData['unavailable'] ?? []);

      // Update in available list
      for (var recipe in available) {
        if (recipe['recipe_id'] == recipeId) {
          recipe['is_favorite'] = isFavorite;
        }
      }

      // Update in unavailable list
      for (var recipe in unavailable) {
        if (recipe['recipe_id'] == recipeId) {
          recipe['is_favorite'] = isFavorite;
        }
      }

      recipesData['available'] = available;
      recipesData['unavailable'] = unavailable;
      await _saveRecipesLocally(recipesData);
    } catch (e) {
      print("RecipeService: Error updating favorite status: $e");
    }
  }

  /// Process recipe data with ingredients and missing flags
  Future<Map<String, dynamic>> _processRecipeData(Map<String, dynamic> recipeData) async {
    try {
      // Get slot drink IDs for missing ingredient detection
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
        } catch (e) {
          print("Error decoding slots from SharedPreferences: $e");
        }
      }

      // Process ingredients
      final ingredientsResponse = recipeData['ingredientsResponse'] as List<dynamic>?;
      if (ingredientsResponse != null) {
        recipeData['ingredients'] = ingredientsResponse.map((ing) {
          final int drinkId = ing['drink']['drink_id'] ?? -1;
          final String drinkName = ing['drink']['drink_name'] ?? "Unknown";
          final int quantityMl = ing['quantity_ml'] ?? 0;
          bool isMissing = !slotDrinkIds.contains(drinkId);

          return {
            'drink_id': drinkId,
            'name': drinkName,
            'quantity_ml': quantityMl,
            'missing': isMissing,
          };
        }).toList();
      } else {
        recipeData['ingredients'] = [];
      }

      return recipeData;
    } catch (e) {
      print("RecipeService: Error processing recipe data: $e");
      return recipeData;
    }
  }

  /// Abrufen und Speichern der Rezepte vom Backend
  @override
  Future<void> fetchAndSaveData() async {
    // Skip HTTP fetch if we just updated from WebSocket
    if (_isUpdatingFromWebSocket) {
      print("RecipeService: Skipping HTTP fetch - just updated from WebSocket");
      return;
    }

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
          decoded = json.decode(utf8.decode(recipeResponse.bodyBytes));

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
        } catch (e) {
          print("Error decoding slots from SharedPreferences: $e");
        }
      } else {
        print("[DEBUG] Keine Slots in SharedPreferences gefunden. slotDrinkIds bleibt leer.");
      }

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

            bool isMissing = !slotDrinkIds.contains(drinkId);

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

      // Save combined data locally
      await _saveRecipesLocally(decoded);
      print("RECIPES and FAVORITES fetched and saved locally via HTTP. "
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
  }

  /// Abrufen der Rezepte aus den SharedPreferences
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

  /// Fügt ein neues Rezept hinzu.
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
      // Schritt 1: Rezept anlegen
      final recipeResponse = await http.post(
        recipeUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "recipe_name": recipeName,
          "picture_id": pictureId ?? 0,
        }),
      );

      if (recipeResponse.statusCode != 201) {
        print("Failed to create recipe: ${recipeResponse.statusCode}, Response: ${recipeResponse.body}");
        return false;
      }

      // Extrahiere die Rezept-ID aus der Antwort
      final responseData = json.decode(recipeResponse.body);
      final int recipeId = responseData["recipe_id"];
      print("Recipe created with ID: $recipeId");

      // Schritt 2: Zutaten hinzufügen
      final ingredientsUrl = Uri.parse("$baseUrl$_recipeUrl/$recipeId/ingredients");

      for (final ingredient in ingredients) {
        final response = await http.post(
          ingredientsUrl,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            "drink_id": ingredient["id"],
            "quantity_ml": ingredient["quantity"],
          }),
        );

        if (response.statusCode != 201) {
          print("Failed to add ingredient: ${response.statusCode}, Response: ${response.body}");
          return false;
        }

        print("Ingredient added successfully: ${ingredient["id"]} with quantity ${ingredient["quantity"]}ml");
      }

      // Schritt 3: Erfolgreicher Abschluss
      print("All ingredients added successfully.");
      // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
      if (!_webSocketService.isConnected) {
        // Fallback: Only fetch if WebSocket is not connected
        await fetchAndSaveData();
      }
      return true;
    } catch (e) {
      print("Error adding recipe: $e");
      return false;
    }
  }

  /// Aktualisiert ein bestehendes Rezept mit neuen Zutaten.
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
          "picture_id": pictureId ?? 0,
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

        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
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
        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
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
        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
        notifyListeners();
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
        // Note: Don't call fetchAndSaveData() here - WebSocket will handle the update
        if (!_webSocketService.isConnected) {
          // Fallback: Only fetch if WebSocket is not connected
          await fetchAndSaveData();
        }
        notifyListeners();
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

  /// Check if WebSocket is providing real-time updates
  bool get isRealTimeEnabled => _webSocketService.isConnected;

  /// Get WebSocket connection status
  String get connectionStatus => _webSocketService.connectionStatusText;

  @override
  void dispose() {
    // Remove WebSocket handlers
    _webSocketService.removeMessageHandler(
      WebSocketMessageType.recipeUpdate,
      _handleRecipeUpdate,
    );
    _webSocketService.removeMessageHandler(
      WebSocketMessageType.favoriteUpdate,
      _handleFavoriteUpdate,
    );
    _webSocketService.removeMessageHandler(
      WebSocketMessageType.ingredientUpdate,
      _handleIngredientUpdate,
    );
    super.dispose();
  }

  // Temporäre Debug-Methode - Füge das in recipe_service.dart hinzu

  /// 🔧 DEBUG: Test HTTP connection
  Future<void> debugHttpConnection() async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    print("🔍 === HTTP API DEBUG ===");
    print("🔍 BASE_URL: '$baseUrl'");
    print("🔍 API_KEY: '$apiKey'");
    print("🔍 Token exists: ${token != null}");
    print("🔍 Token (first 50 chars): ${token?.substring(0, 50)}...");

    // Test verschiedene Endpoints
    final testUrls = [
      "/user/hardware/2/recipes",
      "/user/hardware/2/drinks",
      "/user/hardware/2/slots",
      "/user/hardware/2", // Parent endpoint
      "/user", // Even higher level
    ];

    for (final path in testUrls) {
      final url = Uri.parse(baseUrl + path);
      print("🔍 Testing: $url");

      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'Authorization': 'Bearer $token',
          },
        );

        print("🔍 Response [$path]: ${response.statusCode}");
        if (response.statusCode != 200) {
          print("🔍 Response body: ${response.body}");
        }
      } catch (e) {
        print("🔍 Error [$path]: $e");
      }
    }
    print("🔍 === END HTTP API DEBUG ===");
  }
}