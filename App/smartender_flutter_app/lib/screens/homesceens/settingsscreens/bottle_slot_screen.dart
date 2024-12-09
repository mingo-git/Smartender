//TODO: Wenn Hardware oder App keine Verbindung zum Backend. evtl gar keine Items angzeigen (Vllt auch ueberall Meldung anzeigen)
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/services/slot_service.dart';
import 'package:smartender_flutter_app/components/ingredient_popup.dart';

import '../../../provider/theme_provider.dart';

class BottleSlotsScreen extends StatefulWidget {
  const BottleSlotsScreen({Key? key}) : super(key: key);

  @override
  State<BottleSlotsScreen> createState() => _BottleSlotsScreenState();
}

class _BottleSlotsScreenState extends State<BottleSlotsScreen> {
  List<Map<String, dynamic>> slots = List.generate(
    11,
        (index) => {"id": null, "name": "Empty"}, // Standardwerte für die Slots
  );

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final slotService = Provider.of<SlotService>(context, listen: false);
    final fetchedSlots = await slotService.fetchSlotsFromLocal();

    setState(() {
      for (var slot in fetchedSlots) {
        int slotIndex = (slot["slot_number"] ?? 1) - 1; // Konvertiere slot_number zu Index (1-basiert auf 0-basiert)
        if (slotIndex >= 0 && slotIndex < slots.length) {
          final drink = slot["drink"]; // Extrahiere den Drink aus dem Slot
          slots[slotIndex] = {
            "id": drink != null ? drink["drink_id"] : null,
            "name": drink != null ? drink["drink_name"] : "Empty",
          };
        }
      }
    });
  }


//TODO: Screen evtl. nochmal neu laden wenn aktualisiert -> Bei Fehlern steht sonst etwas falsches drin
  void _changeSlotPopup(int index) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    showDialog(
      context: context,
      builder: (context) => IngredientPopup(
        onIngredientSelected: (selectedDrink) async {
          // Lokale Aktualisierung des Slots
          setState(() {
            slots[index] = {
              "id": selectedDrink["drink_id"],
              "name": selectedDrink["drink_name"],
            };
          });

          // Backend-Aufruf, um den Slot zu aktualisieren
          final slotService = Provider.of<SlotService>(context, listen: false);
          await slotService.updateSlot(index + 1, selectedDrink["drink_id"]); // index + 1, da Slots 1-basiert sind
        },
        showClearButton: true, // Aktiviert den Clear-Button
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 35, color: theme.tertiaryColor,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
            "Bottle Slots",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
        ),
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
                            onPressed: () => _changeSlotPopup(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              side: BorderSide(color: theme.tertiaryColor),
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: defaultBorderRadius,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  slots.length > index && slots[index]["name"] != null
                                      ? slots[index]["name"]
                                      : "Empty",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: theme.tertiaryColor,
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.slotColors[index % theme.slotColors.length],
                                  ),
                                ),
                              ],
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
                            onPressed: () => _changeSlotPopup(index + 5),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              side: BorderSide(color: theme.tertiaryColor),
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: defaultBorderRadius,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  slots.length > index + 5 && slots[index + 5]["name"] != null
                                      ? slots[index + 5]["name"]
                                      : "Empty",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: theme.tertiaryColor
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.slotColors[(index + 5) % theme.slotColors.length],
                                  ),
                                ),
                              ],
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
