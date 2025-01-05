import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/services/slot_service.dart';
import 'package:smartender_flutter_app/components/select_ingredient_popup.dart';

import '../../../provider/theme_provider.dart';

class BottleSlotsScreen extends StatefulWidget {
  const BottleSlotsScreen({Key? key}) : super(key: key);

  @override
  State<BottleSlotsScreen> createState() => _BottleSlotsScreenState();
}

class _BottleSlotsScreenState extends State<BottleSlotsScreen> {
  List<Map<String, dynamic>> slots = List.generate(
    11,
        (index) => {"id": null, "name": "Empty"},
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
        int slotIndex = (slot["slot_number"] ?? 1) - 1;
        if (slotIndex >= 0 && slotIndex < slots.length) {
          final drink = slot["drink"];
          slots[slotIndex] = {
            "id": drink != null ? drink["drink_id"] : null,
            "name": drink != null ? drink["drink_name"] : "Empty",
          };
        }
      }
    });
  }

  void _changeSlotPopup(int index) async {
    showDialog(
      context: context,
      builder: (context) => SelectIngredientPopup(
        onIngredientSelected: (selectedDrink) async {
          setState(() {
            slots[index] = {
              "id": selectedDrink["drink_id"],
              "name": selectedDrink["drink_name"],
            };
          });

          final slotService = Provider.of<SlotService>(context, listen: false);
          await slotService.updateSlot(index + 1, selectedDrink["drink_id"]);
        },
        showClearButton: true,
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
          icon: Icon(Icons.arrow_back, size: 35, color: theme.tertiaryColor),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                    (index) => _buildSpiritsWithBorder(context, index),
              ),
            ),
            // 6 SVGs mit Umrandung in einer Reihe
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                    (index) => _buildBottleWithBorder(context, index),
              ),
            ),
            const SizedBox(height: 30),

            // Labels für die Kategorien
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Spirits",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Mixers",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Slot-Buttons
            Expanded(
              child: Row(
                children: [
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
                            child: _buildSlotText(index),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            child: _buildSlotText(index + 5),
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

  Widget _buildBottleWithBorder(BuildContext context, int index) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final svgAsset = Provider.of<ThemeProvider>(context, listen: false).isDarkMode
        ? 'lib/images/drink_dark.svg'
        : 'lib/images/drink.svg';
    final borderColor = theme.slotColors[index % theme.slotColors.length];

    return Container(
      width: MediaQuery.of(context).size.width * 0.15,  // Zurück zur vorherigen Höhe
      height: MediaQuery.of(context).size.height * 0.15,
      clipBehavior: Clip.none,  // Keine Begrenzung auf Container-Ränder
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: MediaQuery.of(context).size.width * 0.1,
            height: MediaQuery.of(context).size.height * 0.1,
            colorFilter: ColorFilter.mode(borderColor, BlendMode.srcATop),
            fit: BoxFit.contain,
          ),
          SvgPicture.asset(
            svgAsset,
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.height * 0.2,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritsWithBorder(BuildContext context, int index) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final svgAsset = Provider.of<ThemeProvider>(context, listen: false).isDarkMode
        ? 'lib/images/wine_dark.svg'
        : 'lib/images/wine.svg';
    final borderColor = theme.slotColors[index % theme.slotColors.length];

    return Container(
      width: MediaQuery.of(context).size.width * 0.15,  // Zurück zur vorherigen Höhe
      height: MediaQuery.of(context).size.height * 0.15,
      clipBehavior: Clip.none,  // Keine Begrenzung auf Container-Ränder
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: MediaQuery.of(context).size.width * 0.1,
            height: MediaQuery.of(context).size.height * 0.1,
            colorFilter: ColorFilter.mode(borderColor, BlendMode.srcATop),
            fit: BoxFit.contain,
          ),
          SvgPicture.asset(
            svgAsset,
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.height * 0.2,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }


  Widget _buildSlotText(int index) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          slots.length > index && slots[index]["name"] != null ? slots[index]["name"] : "Empty",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: theme.tertiaryColor),
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
    );
  }
}
