// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/drink_tile.dart';
// import '../../components/device_dropdown.dart';  // Falls du das Dropdown wieder nutzen willst
// import '../../components/my_button.dart';
import '../../components/show_drink_popup.dart';
import '../../config/constants.dart';
import '../../provider/theme_provider.dart';
import '../../services/recipe_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String selectedDevice = "Exampledevice";
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> drinks = [];
  List<Map<String, dynamic>> filteredDrinks = [];

  // Wenn du das Dropdown wieder nutzen willst, kannst du diese Liste wiederverwenden
  final List<Map<String, dynamic>> devices = [
    {"name": "Exampledevice", "status": "active"},
    {"name": "Exampledevice1", "status": "inactive"},
    {"name": "Add new Device", "status": "new"}
  ];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  /// Lädt nur die favorisierten Rezepte und bereitet sie für die UI auf
  Future<void> loadFavorites() async {
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final recipesData = await recipeService.fetchRecipesFromLocal();

    final available = recipesData["available"] ?? [];
    final unavailable = recipesData["unavailable"] ?? [];
    final allRecipes = [...available, ...unavailable];

    // Nur Favoriten extrahieren
    final favoriteRecipes = allRecipes.where((recipe) => recipe["is_favorite"] == true).toList();

    final newDrinks = favoriteRecipes.map<Map<String, dynamic>>((recipe) {
      final recipeId = recipe["recipe_id"] ?? -1;
      final recipeName = recipe["recipe_name"] ?? "Unnamed";
      final pictureId = recipe["picture_id"];
      final isFavorite = recipe["is_favorite"] ?? false;

      // 1) Zutaten aus "ingredients" (wie in SearchdrinksScreen)
      final List<dynamic> recipeIngredients =
      (recipe["ingredients"] as List<dynamic>? ?? []);
      // Für das Popup
      final ingredientList = recipeIngredients.map<Map<String, dynamic>>((ing) {
        return {
          "name": ing["name"] ?? "Unknown",
          "missing": ing["missing"] ?? false,
          "quantity_ml": ing["quantity_ml"] ?? 0, // <--- Menge in ml
        };
      }).toList();

      // 2) Alkohol-Check (via "ingredientsResponse" falls vorhanden)
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

      // 3) Bild-Pfad bestimmen
      String imagePath;
      if (pictureId != null && pictureId is int) {
        if (pictureId >= 1 && pictureId <= 30) {
          imagePath = "lib/images/cocktails/$pictureId.png";
        } else {
          imagePath = "lib/images/cocktails/cocktail_unavailable.png";
        }
      } else {
        imagePath = "lib/images/cocktails/cocktail_unavailable.png";
      }

      // 4) Verfügbarkeit ermitteln
      // a) Serverseitig "available" = in der "available" Liste
      final bool isActuallyAvailableOnServer = available.contains(recipe);
      // b) Prüfen, ob eine fehlende Zutat dabei ist
      final bool anyMissing = recipeIngredients.any((ing) => ing["missing"] == true);
      // => isAvailable nur, wenn serverseitig verfügbar UND nichts fehlt
      final bool isAvailable = isActuallyAvailableOnServer && !anyMissing;

      return {
        "recipe_id": recipeId,
        "recipe_name": recipeName,
        "image": imagePath,
        "ingredients": ingredientList,
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

  /// Filtert die Drinks nach Suchbegriff
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
            // Grid mit den Favoriten
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
                          // Wenn das Popup schließt und sich was geändert hat:
                          bool changed = await showDrinkPopup(context, drink);
                          if (changed) {
                            await loadFavorites();
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

            // Suchfeld & Titel
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
                        // Falls du dein DeviceDropdown wieder nutzen willst, entkommentieren
                        /*
                        Expanded(
                          child: DeviceDropdown(
                            devices: devices,
                            selectedDevice: selectedDevice,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedDevice = newValue;
                                });
                              }
                            },
                          ),
                        ),
                        */
                      ],
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: searchController,
                      onChanged: (value) => filterDrinks(value),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: theme.hintTextColor),
                        hintText: 'Search favorites...',
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
