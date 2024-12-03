import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/services/drink_service.dart';
import 'package:smartender_flutter_app/components/ingredient_popup.dart';

class BottleSlotsScreen extends StatefulWidget {
  const BottleSlotsScreen({Key? key}) : super(key: key);

  @override
  State<BottleSlotsScreen> createState() => _BottleSlotsScreenState();
}

class _BottleSlotsScreenState extends State<BottleSlotsScreen> {
  List<Map<String, dynamic>> slots = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final drinkService = Provider.of<DrinkService>(context, listen: false);
    final fetchedSlots = await drinkService.fetchDrinksFromLocal();
    setState(() {
      slots = fetchedSlots.map((drink) {
        return {
          "id": drink["drink_id"],
          "name": drink["drink_name"],
        };
      }).toList();
    });
  }

  void _openSlotPopup(int index) async {
    showDialog(
      context: context,
      builder: (context) => IngredientPopup(
        onIngredientSelected: (selectedDrink) {
          setState(() {
            slots[index] = {
              "id": selectedDrink["drink_id"],
              "name": selectedDrink["drink_name"],
            };
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Bottle Slots"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row mit 2 SVG-Bildern
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SvgPicture.asset(
                  'lib/images/drink.svg',
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.2,
                  fit: BoxFit.contain,
                ),
                SvgPicture.asset(
                  'lib/images/drink.svg',
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.2,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 50),
            // Überschriften über den Spalten
            const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Spirits",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Mixers",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Buttons für Slots, links 5 und rechts 6
            Expanded(
              child: Row(
                children: [
                  // Erste Spalte: Slots 1-5
                  Expanded(
                    child: Column(
                      children: List.generate(
                        5,
                            (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () => _openSlotPopup(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: defaultBorderRadius,
                              ),
                            ),
                            child: Text(
                              slots.length > index && slots[index]["name"] != null
                                  ? slots[index]["name"]
                                  : "Empty",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Abstand zwischen den Spalten
                  // Zweite Spalte: Slots 6-11
                  Expanded(
                    child: Column(
                      children: List.generate(
                        6,
                            (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () => _openSlotPopup(index + 5),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: defaultBorderRadius,
                              ),
                            ),
                            child: Text(
                              slots.length > index + 5 && slots[index + 5]["name"] != null
                                  ? slots[index + 5]["name"]
                                  : "Empty",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
