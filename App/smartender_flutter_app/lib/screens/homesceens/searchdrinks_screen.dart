import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/drink_tile.dart';
import '../../components/device_dropdown.dart';
import '../../components/my_button.dart';
import '../../config/constants.dart';
import '../../provider/theme_provider.dart';

class SearchdrinksScreen extends StatefulWidget {
  const SearchdrinksScreen({super.key});

  @override
  State<SearchdrinksScreen> createState() => _SearchdrinksScreenState();
}

class _SearchdrinksScreenState extends State<SearchdrinksScreen> {
  String selectedDevice = "Exampledevice";
  TextEditingController searchController = TextEditingController();
  bool isAvailable = false;

  // List of devices with additional status
  final List<Map<String, dynamic>> devices = [
    {"name": "Exampledevice", "status": "active"},
    {"name": "Exampledevice1", "status": "inactive"},
    {"name": "Add new Device", "status": "new"}
  ];

  List<Map<String, dynamic>> drinks = [
    {
      "name": "Touchdown",
      "image": "lib/images/cocktails/aperol.png",
      "ingredients": ["Vodka", "Orange Juice", "Lime", "Orange Slice"],
      "isLiked": false
    },
    {
      "name": "Margarita",
      "image": "lib/images/cocktails/gin_tino.png",
      "ingredients": ["Tequila", "Lime Juice", "Triple Sec"],
      "isLiked": false
    },
    {
      "name": "Tequila Sunrise",
      "image": "lib/images/cocktails/guaro.png",
      "ingredients": ["Tequila", "Orange Juice", "Grenadine"],
      "isLiked": false
    },
    {
      "name": "Pina Colada",
      "image": "lib/images/cocktails/strawberry_ice.png",
      "ingredients": ["Rum", "Coconut Cream", "Pineapple Juice"],
      "isLiked": false
    },
    {
      "name": "Bloody Mary",
      "image": "lib/images/cocktails/touch_down.png",
      "ingredients": ["Vodka", "Tomato Juice", "Tabasco", "Celery Salt", "Lemon"],
      "isLiked": false
    },
    {
      "name": "Martini",
      "image": "lib/images/cocktails/tequila_sunrise.png",
      "ingredients": ["Gin", "Dry Vermouth", "Olive"],
      "isLiked": false
    },
    {
      "name": "Mojito",
      "image": "lib/images/cocktails/aperol.png",
      "ingredients": ["Rum", "Mint", "Lime", "Sugar", "Soda Water"],
      "isLiked": false
    },
    {
      "name": "Whiskey Sour",
      "image": "lib/images/cocktails/gin_tino.png",
      "ingredients": ["Whiskey", "Lemon Juice", "Sugar", "Egg White"],
      "isLiked": false
    },
    {
      "name": "Gin Tonic",
      "image": "lib/images/cocktails/strawberry_ice.png",
      "ingredients": ["Gin", "Tonic Water", "Lime"],
      "isLiked": false
    },
  ];

  List<Map<String, dynamic>> filteredDrinks = [];

  @override
  void initState() {
    super.initState();
    filteredDrinks = drinks;
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
          backgroundColor: theme.backgroundColor, // Hintergrund des Popups
          shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
          contentPadding: const EdgeInsets.symmetric(horizontal: horizontalPadding * 2, vertical: 20),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.9, // Feste Breite
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Flexible Höhe
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Schließen-Button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close, color: theme.tertiaryColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    // Bild des Drinks
                    Center(
                      child: Image.asset(
                        drink["image"],
                        height: 150, // Größeres Bild
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
                      children: drink["ingredients"].map<Widget>((ingredient) {
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
                        // Logik für die Bestellung hier hinzufügen
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
            // Overlay für den Gradient-Effekt, der das GridView überlagert
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                // Nur die visuelle Überlagerung ohne Interaktivität
                child: Container(
                  height: 170.0, // Höhe des Überlagerungsbereichs
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
                          flex: 7,
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
                        const SizedBox(width: 10),
                        //TODO: Button noch anpassen mit farbe
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                            color: isAvailable ? theme.trueColor : theme.primaryColor,
                              borderRadius: defaultBorderRadius,
                              border: Border.all(
                                color: theme.tertiaryColor
                              ), // Border hinzugefügt
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isAvailable = !isAvailable;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // Transparenter Hintergrund
                                shadowColor: Colors.transparent, // Entfernt Schatten
                                shape: RoundedRectangleBorder(
                                  borderRadius: defaultBorderRadius,
                                ),
                              ),
                              child: Text(
                                "Available",
                                style: TextStyle(
                                  color: isAvailable ? theme.backgroundColor : theme.tertiaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                            color: theme.tertiaryColor, // Farbe für die Border
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                          borderSide: BorderSide(
                            color: theme.tertiaryColor, // Farbe für die Border, wenn das Feld aktiv ist
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                          borderSide: BorderSide(
                            color: theme.tertiaryColor, // Farbe für die Border, wenn es fokussiert ist
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                          borderSide: BorderSide(
                            color: theme.tertiaryColor, // Farbe für die Border, wenn es einen Fehler gibt
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
