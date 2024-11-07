import 'package:flutter/material.dart';
import '../../components/drink_tile.dart';
import '../../components/device_dropdown.dart';
import '../../config/constants.dart';

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

  List<Map<String, String>> drinks = [
    {"name": "Touchdown", "image": "lib/images/cocktails/aperol.png"},
    {"name": "Margarita", "image": "lib/images/cocktails/gin_tino.png"},
    {"name": "Tequila Sunrise", "image": "lib/images/cocktails/guaro.png"},
    {"name": "Pina Colada", "image": "lib/images/cocktails/strawberry_ice.png"},
    {"name": "Bloody Mary", "image": "lib/images/cocktails/touch_down.png"},
    {"name": "Martini", "image": "lib/images/cocktails/tequila_sunrise.png"},
    {"name": "Mojito", "image": "lib/images/cocktails/tequila_sunrise.png"},
    {"name": "Whiskey Sour", "image": "lib/images/cocktails/tequila_sunrise.png"},
    {"name": "Gin Tonic", "image": "lib/images/cocktails/tequila_sunrise.png"},
  ];

  List<Map<String, String>> filteredDrinks = [];

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Stack(
          children: [
            // GridView für die Getränkekacheln im Hintergrund
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
                      name: drink["name"]!,
                      imagePath: drink["image"]!,
                      onTap: () {
                        // Logik für den Drink-Klick hinzufügen, falls erforderlich
                      },
                    );
                  },
                ),
              ),
            ),

            // Dropdown und Suchfeld überlagern den GridView
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor,
                      backgroundColor,
                      backgroundColor,
                      const Color(0xdff2f2f2),
                      const Color(0x00f2f2f2),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                child: Column(
                  children: [
                    // Row für Geräteauswahl Dropdown und ToggleButton
                    Row(
                      children: [
                        // Dropdown mit 70% Breite
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
                        // ToggleButton mit 30% Breite
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isAvailable = !isAvailable;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAvailable ? Colors.green : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: defaultBorderRadius,
                              ),
                            ),
                            child: Text(
                              "Available",
                              style: TextStyle(
                                color: isAvailable ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),

                    // Suchfeld
                    TextField(
                      controller: searchController,
                      onChanged: (value) => filterDrinks(value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search drinks...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: defaultBorderRadius,
                        ),
                        fillColor: Colors.white, // Hintergrundfarbe auf Weiß setzen
                        filled: true, // fillColor aktivieren
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 50,)
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
