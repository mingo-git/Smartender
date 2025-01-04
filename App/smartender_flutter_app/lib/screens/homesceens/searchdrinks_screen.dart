// lib/screens/searchdrinks_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/drink_tile.dart';
import '../../components/device_dropdown.dart';
import '../../components/my_button.dart';
import '../../components/show_drink_popup.dart'; // Import der neuen Datei
import '../../config/constants.dart';
import '../../provider/theme_provider.dart';
import '../../services/recipe_service.dart';

class SearchdrinksScreen extends StatefulWidget {
  const SearchdrinksScreen({super.key});

  @override
  State<SearchdrinksScreen> createState() => _SearchdrinksScreenState();
}

class _SearchdrinksScreenState extends State<SearchdrinksScreen> {
  String selectedDevice = "Exampledevice";
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> drinks = [];
  List<Map<String, dynamic>> filteredDrinks = [];

  final List<Map<String, dynamic>> devices = [
    {"name": "Exampledevice", "status": "active"},
    {"name": "Exampledevice1", "status": "inactive"},
    {"name": "Add new Device", "status": "new"}
  ];

  @override
  void initState() {
    super.initState();
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final recipesData = await recipeService.fetchRecipesFromLocal();

    final available = recipesData["available"] ?? [];
    final unavailable = recipesData["unavailable"] ?? [];
    // Kombiniere beide Listen, damit wir alle Rezepte haben
    final allRecipes = [...available, ...unavailable];

    // Wir bauen aus jedem "recipe" eine Map für unser UI
    final newDrinks = allRecipes.map<Map<String, dynamic>>((recipe) {
      final recipeId = recipe["recipe_id"] ?? -1;
      final recipeName = recipe["recipe_name"] ?? "Unnamed";

      // In recipe_service.dart wird bereits "ingredients" erzeugt,
      // welches 'missing' korrekt enthält:
      final List<dynamic> recipeIngredients =
      (recipe["ingredients"] as List<dynamic>? ?? []);

      // Bild-Auswahl
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

      // Wichtig: Nutze direkt recipe['ingredients'] statt 'ingredientsResponse'
      final ingredientList = recipeIngredients.map<Map<String, dynamic>>((ing) {
        return {
          "name": ing["name"] ?? "Unknown",
          // Hier übernehmen wir den bereits in recipe_service.dart gesetzten missing-Wert
          "missing": ing["missing"] ?? false,
          // Optional kannst du auch die Menge übernehmen
          "quantity_ml": ing["quantity_ml"] ?? 0,
        };
      }).toList();

      final isFavorite = recipe["is_favorite"] ?? false;
      // "isAvailable" definieren wir so, dass es true ist, wenn das Rezept in der available-Liste steht
      final isAvailable = available.contains(recipe);

      return {
        "recipe_id": recipeId,
        "name": recipeName,
        "image": imagePath,
        "ingredients": ingredientList,
        "is_favorite": isFavorite,
        "isAvailable": isAvailable
      };
    }).toList();

    setState(() {
      drinks = newDrinks;
      filteredDrinks = drinks;
    });
  }

  void filterDrinks(String query) {
    setState(() {
      filteredDrinks = drinks.where((drink) {
        final name = (drink["name"] as String).toLowerCase();
        return name.contains(query.toLowerCase());
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
                      opacity: isAvailable ? 1.0 : 0.5, // leicht ausgegraut, wenn nicht verfügbar
                      child: DrinkTile(
                        name: drink["name"],
                        imagePath: drink["image"],
                        onTap: () async {
                          // Hier übergeben wir 'drink' direkt an showDrinkPopup
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
                              fontSize: 30,             // Schriftgröße
                              fontWeight: FontWeight.bold,  // Fettdruck
                              color: theme.tertiaryColor,    // Farbe aus dem aktuellen Theme
                            ),
                          ),
                        ),
/*                        Expanded(
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
                        ),*/
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
