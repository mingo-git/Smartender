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

  // Beispiel-Geräte
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

    final newDrinks = available.map<Map<String, dynamic>>((recipe) {
      final recipeName = recipe["recipe_name"] ?? "Unnamed";
      final ingredientsResponse = recipe["ingredientsResponse"] ?? [];
      final ingredientNames = ingredientsResponse.map((ing) {
        final drink = ing["drink"];
        return drink != null ? (drink["drink_name"] ?? "Unknown") : "Unknown";
      }).toList().cast<String>(); // Wichtig: cast<String>()

      return {
        "name": recipeName,
        "image": "lib/images/cocktails/guaro.png", // Platzhalterbild
        "ingredients": ingredientNames,
        "isLiked": false,
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
        final name = drink["name"]!.toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showDrinkPopup(BuildContext context, Map<String, dynamic> drink) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
          contentPadding: const EdgeInsets.symmetric(horizontal: horizontalPadding * 2, vertical: 20),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
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
                      children: (drink["ingredients"] as List<String>).map((ingredient) {
                        return Chip(
                          label: Text(
                            ingredient,
                            style: TextStyle(color: theme.tertiaryColor),
                          ),
                          backgroundColor: theme.primaryColor,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    MyButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: Logik für Bestellung hinzufügen
                      },
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
    // TODO: Logik für das Hinzufügen/Entfernen zu den Favoriten implementieren
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredDrinks.length,
                  itemBuilder: (context, index) {
                    final drink = filteredDrinks[index];
                    return DrinkTile(
                      name: drink["name"],
                      imagePath: drink["image"],
                      onTap: () => _showDrinkPopup(context, drink),
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
