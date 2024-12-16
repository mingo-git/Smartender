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
          // Ungültige picture_id, verwende Standardbild
          imagePath = "lib/images/cocktails/cocktail_unavailable.png";
        }
      } else {
        // Keine picture_id vorhanden, verwende Standardbild
        imagePath = "lib/images/cocktails/cocktail_unavailable.png";
      }

      // Prüfen wir pro Zutat, ob sie fehlt:
      // Fehlend, wenn 'drink == null' oder 'drink["hardware_id"] != 2'
      // Hier wird '2' als hardware_id des Geräts angenommen
      final ingredientList = ingredientsResponse.map<Map<String, dynamic>>((ing) {
        final drinkMap = ing["drink"] as Map<String, dynamic>?;
        final missing = (drinkMap == null || drinkMap["hardware_id"] != 2);
        final name = missing ? "Unknown" : (drinkMap["drink_name"] ?? "Unknown");
        return {
          "name": name,
          "missing": missing,
        };
      }).toList();

      return {
        "name": recipeName,
        "image": imagePath,
        "ingredients": ingredientList,
        "isLiked": false,
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
    final isAvailable = drink["isAvailable"] == true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
          contentPadding: const EdgeInsets.symmetric(horizontal: horizontalPadding * 2, vertical: 20),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final ingredients = drink["ingredients"] as List<Map<String, dynamic>>;

              return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
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
                        drink["image"],
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback bei fehlendem Bild
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
                          drink["name"],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.tertiaryColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            drink["isLiked"] ? Icons.favorite : Icons.favorite_border,
                            color: drink["isLiked"] ? Colors.red : theme.tertiaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              drink["isLiked"] = !drink["isLiked"];
                            });
                            _changeFavorite(drink["name"], drink["isLiked"]);
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
                      children: ingredients.map((ingredient) {
                        final missing = ingredient["missing"] == true;
                        final ingredientName = ingredient["name"] as String;
                        return Chip(
                          label: Text(
                            ingredientName,
                            style: TextStyle(color: missing ? Colors.red : theme.tertiaryColor),
                          ),
                          backgroundColor: theme.primaryColor,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    MyButton(
                      onTap: isAvailable
                          ? () {
                        Navigator.of(context).pop();
                        // TODO: Logik für Bestellung hinzufügen
                      }
                          : null,
                      text: "Order",
                      hasMargin: false,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _changeFavorite(String drinkName, bool isLiked) {
    print("Favorited $drinkName: $isLiked");
    // TODO: Favoriten-Logik implementieren
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
