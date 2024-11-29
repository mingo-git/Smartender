import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/constants.dart';

class RecipeService {
  final String _baseUrl; // Füge das fehlende Feld hinzu

  RecipeService({required String baseUrl}) : _baseUrl = baseUrl;

  Future<bool> addRecipe(String recipeName, List<Map<String, dynamic>> ingredients) async {
    final AuthService authService = AuthService();
    final String? token = await authService.getToken();

    print("Name $recipeName");
    print(ingredients);

    if (token == null) {
      print("No token available. Cannot add recipe.");
      return false;
    }

    final url = Uri.parse("$_baseUrl/recipes");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "recipe_name": recipeName,
          "ingredients": ingredients,
        }),
      );

      if (response.statusCode == 201) {
        print("Recipe added successfully.");
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
}
