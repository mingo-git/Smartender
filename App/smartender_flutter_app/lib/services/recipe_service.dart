// lib/services/recipe_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/websocket/websocket_message.dart';
import 'fetchable_service.dart';
import 'websocket_service.dart';
import 'api_client.dart';

class RecipeService extends ChangeNotifier implements FetchableService {
  final WebSocketService _webSocketService = WebSocketService();
  final ApiClient _api = ApiClient();

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
      final recipeId = recipeUpdate.recipe?['recipe_id'];
      print("RecipeService: Received ${recipeUpdate.action.value} for recipe: $recipeId");

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
  /// FIX: IngredientUpdateMessage hat KEIN `recipe`-Feld. Nur `recipeId`.
  void _handleIngredientUpdate(WebSocketMessage message) async {
    try {
      final ingredientUpdate = IngredientUpdateMessage.fromJson(message.data);
      print("RecipeService: Received ingredient ${ingredientUpdate.action.value} for recipe: ${ingredientUpdate.recipeId}");

      _isUpdatingFromWebSocket = true;

      // Es gibt in IngredientUpdateMessage kein komplettes Rezept-Objekt.
      // Wir markieren daher nur die Zutaten dieses Rezepts als "dirty",
      // sodass das UI (oder ein Fallback) reagieren kann.
      if (ingredientUpdate.recipeId != null) {
        await _markRecipeIngredientsDirty(ingredientUpdate.recipeId!);
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
      final processed = await _processRecipeData(Map<String, dynamic>.from(recipeData));
      await _upsertRecipeLocally(processed, preferAvailable: true);
      print("RecipeService: Added new recipe via WebSocket: ${recipeData['recipe_name']}");
    } catch (e) {
      print("RecipeService: Error handling recipe creation: $e");
    }
  }

  /// Handle recipe updated via WebSocket
  Future<void> _handleRecipeUpdated(Map<String, dynamic>? recipeData) async {
    if (recipeData == null) return;
    try {
      final processed = await _processRecipeData(Map<String, dynamic>.from(recipeData));
      await _upsertRecipeLocally(processed);
      print("RecipeService: Updated recipe via WebSocket: ${recipeData['recipe_name']}");
    } catch (e) {
      print("RecipeService: Error handling recipe update: $e");
    }
  }

  /// Handle recipe deleted via WebSocket
  Future<void> _handleRecipeDeleted(Map<String, dynamic>? recipeData) async {
    if (recipeData == null) return;
    try {
      final recipeId = recipeData['recipe_id'];
      final recipesData = await fetchRecipesFromLocal();

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

  /// Wenn nur die Zutaten geändert wurden, aber kein kompletter Snapshot vorliegt:
  Future<void> _markRecipeIngredientsDirty(int recipeId) async {
    final data = await fetchRecipesFromLocal();
    bool changed = false;

    for (final key in ['available', 'unavailable']) {
      final list = List<Map<String, dynamic>>.from(data[key] ?? []);
      for (final r in list) {
        if (r['recipe_id'] == recipeId) {
          // Markiere als "dirty" (kann das UI optional nutzen)
          r['ingredients_dirty'] = true;
          changed = true;
        }
      }
      data[key] = list;
    }

    if (changed) {
      await _saveRecipesLocally(data);
    }
  }

  /// Update favorite status for a specific recipe
  Future<void> _updateRecipeFavoriteStatus(int recipeId, bool isFavorite) async {
    try {
      final recipesData = await fetchRecipesFromLocal();

      for (final key in ['available', 'unavailable']) {
        final list = List<Map<String, dynamic>>.from(recipesData[key] ?? []);
        for (var recipe in list) {
          if (recipe['recipe_id'] == recipeId) {
            recipe['is_favorite'] = isFavorite;
          }
        }
        recipesData[key] = list;
      }

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

      // Accept either 'ingredientsResponse' or already flattened 'ingredients'
      final ingredientsResponse = recipeData['ingredientsResponse'] as List<dynamic>?;
      final existingIngredients = recipeData['ingredients'] as List<dynamic>?;

      if (ingredientsResponse != null) {
        recipeData['ingredients'] = ingredientsResponse.map((ing) {
          final int drinkId = ing['drink']?['drink_id'] ?? -1;
          final String drinkName = ing['drink']?['drink_name'] ?? "Unknown";
          final int quantityMl = ing['quantity_ml'] ?? 0;
          final bool isMissing = !slotDrinkIds.contains(drinkId);

          return {
            'drink_id': drinkId,
            'name': drinkName,
            'quantity_ml': quantityMl,
            'missing': isMissing,
          };
        }).toList();
      } else if (existingIngredients != null) {
        // Recompute 'missing' based on slots
        recipeData['ingredients'] = existingIngredients.map((ing) {
          final int drinkId = ing['drink_id'] ?? ing['drink']?['drink_id'] ?? -1;
          final String drinkName = ing['name'] ?? ing['drink']?['drink_name'] ?? "Unknown";
          final int quantityMl = ing['quantity_ml'] ?? ing['quantity'] ?? 0;
          final bool isMissing = !slotDrinkIds.contains(drinkId);
          return {
            'drink_id': drinkId,
            'name': drinkName,
            'quantity_ml': quantityMl,
            'missing': isMissing,
          };
        }).toList();
      } else {
        recipeData['ingredients'] = <Map<String, dynamic>>[];
      }

      return recipeData;
    } catch (e) {
      print("RecipeService: Error processing recipe data: $e");
      return recipeData;
    }
  }

  /// Fügt/aktualisiert ein Rezept lokal (in available/unavailable, falls vorhanden)
  Future<void> _upsertRecipeLocally(
      Map<String, dynamic> processedRecipe, {
        bool preferAvailable = false,
      }) async {
    final recipesData = await fetchRecipesFromLocal();
    final recipeId = processedRecipe['recipe_id'];

    final available = List<Map<String, dynamic>>.from(recipesData['available'] ?? []);
    final unavailable = List<Map<String, dynamic>>.from(recipesData['unavailable'] ?? []);

    bool updated = false;

    // Update in available
    final ai = available.indexWhere((r) => r['recipe_id'] == recipeId);
    if (ai != -1) {
      available[ai] = processedRecipe;
      updated = true;
    }

    // Update in unavailable
    final ui = unavailable.indexWhere((r) => r['recipe_id'] == recipeId);
    if (ui != -1) {
      unavailable[ui] = processedRecipe;
      updated = true;
    }

    // Wenn gar nicht vorhanden: füge hinzu (bevorzugt 'available' wenn gewünscht)
    if (!updated) {
      if (preferAvailable) {
        available.add(processedRecipe);
      } else {
        available.add(processedRecipe); // default: available
      }
    }

    recipesData['available'] = available;
    recipesData['unavailable'] = unavailable;

    await _saveRecipesLocally(recipesData);
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
      try {
        final recipes = Map<String, dynamic>.from(json.decode(recipesJson));
        return recipes;
      } catch (_) {
        // Fallback bei korrupten Daten
      }
    }
    return {'available': <Map<String, dynamic>>[], 'unavailable': <Map<String, dynamic>>[]};
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Aktionen (HTTP) – nur über ApiClient
  // ────────────────────────────────────────────────────────────────────────────

  /// Fügt ein neues Rezept hinzu (HTTP Aktion).
  Future<bool> addRecipe(
      String recipeName,
      List<Map<String, dynamic>> ingredients, {
        int? pictureId,
      }) async {
    try {
      final createRes = await _api.createRecipe(recipeName, pictureId: pictureId);
      if (createRes.statusCode != 201) {
        print("Failed to create recipe: ${createRes.statusCode} ${createRes.body}");
        return false;
      }

      final created = json.decode(createRes.body);
      final int recipeId = (created['recipe_id'] as num).toInt();
      print("Recipe created with ID: $recipeId");

      for (final ing in ingredients) {
        final drinkId = ((ing['id'] ?? ing['drink_id']) as num).toInt();
        final qty = ((ing['quantity'] ?? ing['quantity_ml'] ?? 0) as num).toInt();
        final r = await _api.addIngredientToRecipe(recipeId, drinkId, qty);
        if (r.statusCode != 201) {
          print("Failed to add ingredient $drinkId: ${r.statusCode} ${r.body}");
          return false;
        }
      }

      // Kein fetch-Fallback – WebSocket liefert die Aktualisierung
      return true;
    } catch (e) {
      print("Error adding recipe: $e");
      return false;
    }
  }

  /// Aktualisiert ein bestehendes Rezept + Zutaten (HTTP Aktionen).
  Future<bool> updateRecipeWithIngredients(
      int recipeId,
      String recipeName,
      List<Map<String, dynamic>> newIngredients,
      List<Map<String, dynamic>> originalIngredients, {
        int? pictureId,
      }) async {
    try {
      final upd = await _api.updateRecipe(recipeId, recipeName, pictureId: pictureId);
      if (upd.statusCode != 200 && upd.statusCode != 204) {
        print("Failed to update recipe: ${upd.statusCode} ${upd.body}");
        return false;
      }

      final Map<int, Map<String, dynamic>> originalById = {
        for (var ing in originalIngredients)
          ((ing["id"] ?? ing["drink_id"]) as num).toInt(): ing
      };
      final Map<int, Map<String, dynamic>> newById = {
        for (var ing in newIngredients)
          ((ing["id"] ?? ing["drink_id"]) as num).toInt(): ing
      };

      // Early exit: if no diffs in set of IDs and quantities, skip ingredient ops
      bool identicalSets = true;
      if (originalById.length != newById.length) {
        identicalSets = false;
      } else {
        for (final id in originalById.keys) {
          if (!newById.containsKey(id)) { identicalSets = false; break; }
          final o = originalById[id];
          final n = newById[id];
          final oQty = ((o?["quantity"] ?? o?["quantity_ml"] ?? 0) as num).toInt();
          final nQty = ((n?["quantity"] ?? n?["quantity_ml"] ?? 0) as num).toInt();
          if (oQty != nQty) { identicalSets = false; break; }
        }
      }
      if (identicalSets) {
        // Nothing to change on ingredients (likely only picture/name updated)
        return true;
      }

      // Entfernen
      for (final oid in originalById.keys) {
        if (!newById.containsKey(oid)) {
          final resp = await _api.removeIngredientFromRecipe(recipeId, oid);
          if (resp.statusCode != 200 && resp.statusCode != 204) {
            print("Failed to delete ingredient $oid: ${resp.statusCode} ${resp.body}");
            return false;
          }
        }
      }

      // Hinzufügen/Updaten
      for (final nid in newById.keys) {
        final newQty = ((newById[nid]?["quantity"] ?? newById[nid]?["quantity_ml"] ?? 0) as num).toInt();
        if (!originalById.containsKey(nid)) {
          final resp = await _api.addIngredientToRecipe(recipeId, nid, newQty);
          if (resp.statusCode != 201) {
            print("Failed to add ingredient $nid: ${resp.statusCode} ${resp.body}");
            return false;
          }
        } else {
          final oldQty = ((originalById[nid]?["quantity"] ?? originalById[nid]?["quantity_ml"] ?? 0) as num).toInt();
          if (oldQty != newQty) {
            final resp = await _api.updateIngredientInRecipe(recipeId, nid, newQty);
            if (resp.statusCode != 200 && resp.statusCode != 204) {
              print("Failed to update ingredient $nid: ${resp.statusCode} ${resp.body}");
              return false;
            }
          }
        }
      }

      // Kein fetch-Fallback – WebSocket liefert die Aktualisierung
      return true;
    } catch (e) {
      print("Error updating recipe: $e");
      return false;
    }
  }

  /// Löscht ein Rezept (HTTP Aktion).
  Future<bool> deleteRecipe(int recipeId) async {
    try {
      final resp = await _api.deleteRecipe(recipeId);
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return true;
      }
      print("Failed to delete recipe: ${resp.statusCode} ${resp.body}");
      return false;
    } catch (e) {
      print("Error deleting recipe: $e");
      return false;
    }
  }

  /// Fügt ein Rezept zu Favoriten hinzu (HTTP Aktion).
  Future<bool> addRecipeToFavorites(int recipeId) async {
    try {
      final resp = await _api.addToFavorites(recipeId);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return true;
      }
      print("Failed to add favorite: ${resp.statusCode} ${resp.body}");
      return false;
    } catch (e) {
      print("Error adding favorite: $e");
      return false;
    }
  }

  /// Entfernt ein Rezept aus Favoriten (HTTP Aktion).
  Future<bool> removeRecipeFromFavorites(int recipeId) async {
    try {
      final resp = await _api.removeFromFavorites(recipeId);
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return true;
      }
      print("Failed to remove favorite: ${resp.statusCode} ${resp.body}");
      return false;
    } catch (e) {
      print("Error removing favorite: $e");
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // WebSocket-First: Keine HTTP-Fetches mehr in diesem Service
  // ────────────────────────────────────────────────────────────────────────────

  /// WebSocket-First – keine HTTP-Fetches hier.
  @override
  Future<void> fetchAndSaveData() async {
    if (_isUpdatingFromWebSocket) {
      print("RecipeService: Skipping fetch (just updated from WebSocket).");
      return;
    }
    // Absichtlich leer: Initial-Load / HTTP-Fallback wird zentral im FetchDataService gehandhabt.
    print("RecipeService: WebSocket-first – HTTP fetch disabled (no-op).");
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
}
