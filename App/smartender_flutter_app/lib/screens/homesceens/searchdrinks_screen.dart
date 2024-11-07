import 'package:flutter/material.dart';
import '../../components/drink_tile.dart';
import '../../config/constants.dart';

class SearchdrinksScreen extends StatefulWidget {
  const SearchdrinksScreen({super.key});

  @override
  State<SearchdrinksScreen> createState() => _SearchdrinksScreenState();
}

class _SearchdrinksScreenState extends State<SearchdrinksScreen> {
  String selectedDevice = "Exampledevice";
  TextEditingController searchController = TextEditingController();
  List<String> devices = ["Exampledevice", "Exampledevice2", "Add a device"];
  List<Map<String, String>> drinks = [
    {"name": "Touchdown", "image": "lib/images/cocktails/aperol.png"},
    {"name": "Margarita", "image": "lib/images/cocktails/gin_tino.png"},
    {"name": "Tequila Sunrise", "image": "lib/images/cocktails/guaro.png"},
    {"name": "Pina Colada", "image": "lib/images/cocktails/strawberry_ice.png"},
    {"name": "Bloody Mary", "image": "lib/images/cocktails/touch_down.png"},
    {"name": "Martini", "image": "lib/images/cocktails/tequila_sunrise.png"},
    {"name": "Mojito", "image": "lib/images/cocktails/tequila_sunrise.png"},
    {"name": "Whiskey Sour", "image": "lib/images/cocktails/tequila_sunrise.png"},
    {"name": "Gin Tonic mag doch eh keiner", "image": "lib/images/cocktails/tequila_sunrise.png"},
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
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding), // Einheitlicher Abstand für alle Seiteninhalte
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

            // Roter Container mit Dropdown und Suchfeld
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
                      const Color(0xE5F2F2F2),
                      const Color(0x00f2f2f2),
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 50),
                child: Column(
                  children: [
                    // Geräteauswahl Dropdown
                    DropdownButton<String>(
                      value: selectedDevice,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedDevice = newValue;
                          });
                        }
                      },
                      items: devices.map<DropdownMenuItem<String>>((String device) {
                        return DropdownMenuItem<String>(
                          value: device,
                          child: Text(device, style: const TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Suchfeld
                    TextField(
                      controller: searchController,
                      onChanged: (value) => filterDrinks(value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search drinks...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
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
