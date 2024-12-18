import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/drink_tile.dart';
import '../../components/device_dropdown.dart';
import '../../components/my_button.dart';
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
    final allRecipes = [...available, ...unavailable];

    final newDrinks = allRecipes.map<Map<String, dynamic>>((recipe) {
      final recipeId = recipe["recipe_id"] ?? -1; // Sicherstellen, dass recipe_id verfügbar ist
      final recipeName = recipe["recipe_name"] ?? "Unnamed";
      final ingredientsResponse = recipe["ingredientsResponse"] ?? [];
      final isAvailable = available.contains(recipe);

      // Extrahiere picture_id und setze imagePath entsprechend
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

      // Zutaten extrahieren und prüfen
      final ingredientList = ingredientsResponse.map<Map<String, dynamic>>((ing) {
        final drinkMap = ing["drink"] as Map<String, dynamic>?;
        final missing = (drinkMap == null || drinkMap["hardware_id"] != 2);
        final name = missing ? "Unknown" : (drinkMap["drink_name"] ?? "Unknown");
        return {
          "name": name,
          "missing": missing,
        };
      }).toList();

      final isFavorite = recipe["is_favorite"] ?? false; // Prüfe is_favorite
      print("Recipe: $recipeName, Recipe ID: $recipeId, Is Favorite: $isFavorite");

      return {
        "recipe_id": recipeId,
        "name": recipeName,
        "image": imagePath,
        "ingredients": ingredientList,
        "is_favorite": isFavorite, // Beibehalten von is_favorite
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

  void _showDrinkPopup(BuildContext context, Map<String, dynamic> drink) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    bool isFavorite = drink['is_favorite'] ?? false;

    print("Opening Popup for: ${drink['name']}, isFavorite: $isFavorite"); // Debugging-Ausgabe

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
          contentPadding: const EdgeInsets.symmetric(horizontal: horizontalPadding * 2, vertical: 20),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: theme.tertiaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      drink['image'],
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          "lib/images/cocktails/cocktail_unavailable.png",
                          height: 150,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        drink['name'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.tertiaryColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : theme.tertiaryColor,
                        ),
                        onPressed: () async {
                          final recipeService = RecipeService();
                          bool success;

                          if (isFavorite) {
                            success = await recipeService.removeRecipeFromFavorites(drink['recipe_id']);
                          } else {
                            success = await recipeService.addRecipeToFavorites(drink['recipe_id']);
                          }

                          if (success) {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? "Added to favorites"
                                      : "Removed from favorites",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to update favorite status")),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ingredients:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.tertiaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: (drink['ingredients'] as List<Map<String, dynamic>>).map((ingredient) {
                      final missing = ingredient['missing'] == true;
                      return Chip(
                        label: Text(
                          ingredient['name'],
                          style: TextStyle(
                            color: missing ? Colors.red : theme.tertiaryColor,
                          ),
                        ),
                        backgroundColor: theme.primaryColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  MyButton(
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Add ordering logic here
                    },
                    text: "Order",
                    hasMargin: false,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }







  void _changeFavorite(int recipeId, bool isFavorite) async {
    final recipeService = RecipeService();
    bool success;

    if (isFavorite) {
      success = await recipeService.addRecipeToFavorites(recipeId);
    } else {
      success = await recipeService.removeRecipeFromFavorites(recipeId);
    }

    if (success) {
      setState(() {
        // Aktualisiere den lokalen Zustand des Rezepts
        drinks = drinks.map((drink) {
          if (drink['recipe_id'] == recipeId) {
            drink['is_favorite'] = isFavorite;
          }
          return drink;
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status')),
      );
    }
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
                padding: const EdgeInsets.only(top: 130.0),
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
                        name: drink["name"],
                        imagePath: drink["image"],
                        onTap: () => _showDrinkPopup(context, drink),
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
