// lib/screens/searchdrinks_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/drink_tile.dart';
import '../../components/show_drink_popup.dart';
import '../../config/constants.dart';
import '../../provider/theme_provider.dart';
import '../../services/recipe_service.dart';

class SearchdrinksScreen extends StatefulWidget {
  const SearchdrinksScreen({super.key});

  @override
  State<SearchdrinksScreen> createState() => _SearchdrinksScreenState();
}

class _SearchdrinksScreenState extends State<SearchdrinksScreen> {
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> drinks = [];
  List<Map<String, dynamic>> filteredDrinks = [];

  @override
  void initState() {
    super.initState();
    loadRecipes();
  }

  /// Lädt alle Rezepte (available + unavailable) und packt sie in [drinks].
  Future<void> loadRecipes() async {
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final recipesData = await recipeService.fetchRecipesFromLocal();

    final available = recipesData["available"] ?? [];
    final unavailable = recipesData["unavailable"] ?? [];
    final allRecipes = [...available, ...unavailable];

    // Wir mappen jedes Rezept auf eine Map, die wir für die UI verwenden
    final newDrinks = allRecipes.map<Map<String, dynamic>>((recipe) {
      final recipeId = recipe["recipe_id"] ?? -1;
      final recipeName = recipe["recipe_name"] ?? "Unnamed";

      // 1) Ingredients (so wie in deinem ursprünglichen Code)
      final List<dynamic> recipeIngredients =
      (recipe["ingredients"] as List<dynamic>? ?? []);

      // Baue eine "ingredients"-Liste für das Popup
      final ingredientList = recipeIngredients.map<Map<String, dynamic>>((ing) {
        return {
          "name": ing["name"] ?? "Unknown",
          "missing": ing["missing"] ?? false,
          "quantity_ml": ing["quantity_ml"] ?? 0, // <--- Menge in ml
        };
      }).toList();

      // 2) Alkohol-Check (z. B. via ingredientsResponse, falls vorhanden)
      bool isAlcoholic = false;
      final List<dynamic> ingredientsResponse =
          recipe["ingredientsResponse"] as List<dynamic>? ?? [];
      for (var ingResp in ingredientsResponse) {
        final ingDrink = ingResp["drink"];
        if (ingDrink != null && ingDrink["is_alcoholic"] == true) {
          isAlcoholic = true;
          break;
        }
      }

      // 3) Bild-Auswahl
      final pictureId = recipe["picture_id"];
      String imagePath;
      if (pictureId != null && pictureId is int) {
        if (pictureId >= 1 && pictureId <= 30) {
          imagePath = "lib/images/cocktails/$pictureId.png";
        } else if (pictureId == 0) {
          imagePath = "lib/images/cocktails/cocktail_unavailable.png";
        } else {
          imagePath = "lib/images/cocktails/cocktail_unavailable.png";
        }
      } else {
        imagePath = "lib/images/cocktails/cocktail_unavailable.png";
      }

      // 4) Favorit, Verfügbarkeit
      final isFavorite = recipe["is_favorite"] ?? false;
      final isAvailable = available.contains(recipe);

      return {
        "recipe_id": recipeId,
        "recipe_name": recipeName,  // => Für DrinkTile-Name
        "image": imagePath,
        "ingredients": ingredientList, // => Für das Popup
        "is_favorite": isFavorite,
        "isAvailable": isAvailable,
        "isAlcoholic": isAlcoholic,
      };
    }).toList();

    setState(() {
      drinks = newDrinks;
      filteredDrinks = drinks;
    });
  }

  /// Filtert die Drinks nach dem 'recipe_name'.
  void filterDrinks(String query) {
    setState(() {
      final lowerCaseQuery = query.toLowerCase();
      filteredDrinks = drinks.where((drink) {
        final name = (drink["recipe_name"] ?? "").toLowerCase();
        return name.contains(lowerCaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 140.0, left: 10, right: 10),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredDrinks.length,
                  itemBuilder: (context, index) {
                    final drink = filteredDrinks[index];
                    final isAvailable = drink["isAvailable"] == true;

                    return Opacity(
                      opacity: isAvailable ? 1.0 : 0.5,
                      child: DrinkTile(
                        name: drink["recipe_name"] ?? "Unnamed",
                        imagePath: drink["image"] ?? "lib/images/cocktails/cocktail_unavailable.png",
                        isAlcoholic: drink["isAlcoholic"] == true,
                        onTap: () async {
                          bool changed = await showDrinkPopup(context, drink);
                          if (changed) {
                            await loadRecipes();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            // Hintergrund-Verlauf oben
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 170.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.backgroundColor,
                        theme.backgroundColor,
                        theme.backgroundColor,
                        theme.fadeOutBackground0,
                        theme.fadeOutBackground1,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Suchfeld
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Smartender",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: theme.tertiaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: searchController,
                      onChanged: (value) => filterDrinks(value),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: theme.hintTextColor),
                        hintText: 'Search drinks...',
                        hintStyle: TextStyle(color: theme.hintTextColor),
                        border: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                          borderSide: BorderSide(
                            color: theme.tertiaryColor,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                          borderSide: BorderSide(
                            color: theme.tertiaryColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                          borderSide: BorderSide(
                            color: theme.tertiaryColor,
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                          borderSide: BorderSide(
                            color: theme.tertiaryColor,
                            width: 1.5,
                          ),
                        ),
                        fillColor: theme.primaryColor,
                        filled: true,
                      ),
                      style: TextStyle(color: theme.tertiaryColor),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
