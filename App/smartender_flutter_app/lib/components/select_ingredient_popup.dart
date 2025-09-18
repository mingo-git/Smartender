import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../provider/theme_provider.dart';
import '../services/drink_service.dart';
import 'create_edit_drink_popup.dart';

class SelectIngredientPopup extends StatefulWidget {
  final Function(Map<String, dynamic>) onIngredientSelected;
  final bool showClearButton;
  final Set<int?> alreadySelectedIds; // Neuer Parameter

  const SelectIngredientPopup({
    Key? key,
    required this.onIngredientSelected,
    this.showClearButton = false,
    this.alreadySelectedIds = const {}, // Standardwert ist ein leeres Set
  }) : super(key: key);

  @override
  _SelectIngredientPopupState createState() => _SelectIngredientPopupState();
}

class _SelectIngredientPopupState extends State<SelectIngredientPopup> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allIngredients = [];
  List<Map<String, dynamic>> _filteredIngredients = [];

  @override
  void initState() {
    super.initState();
    final drinkService = Provider.of<DrinkService>(context, listen: false);
    drinkService.fetchDrinksFromLocal().then((ingredients) {
      setState(() {
        // Entferne bereits ausgewählte IDs aus der Liste der Zutaten
        _allIngredients = ingredients
            .where((ingredient) =>
        !widget.alreadySelectedIds.contains(ingredient["drink_id"]))
            .toList();
        _filteredIngredients = _allIngredients;
      });
    });
    _searchController.addListener(_filterIngredients);
  }

  void _filterIngredients() {
    setState(() {
      _filteredIngredients = _allIngredients
          .where((ingredient) =>
          ingredient["drink_name"]
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _openAddDrinkPopup() {
    Navigator.of(context).pop(); // Schließt das aktuelle Popup
    showDialog(
      context: context,
      builder: (context) => const CreateEditDrinkPopup(),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterIngredients);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return AlertDialog(
      backgroundColor: theme.primaryColor, // Hintergrundfarbe des Popups
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Select Ingredient",
            style: TextStyle(
              color: theme.tertiaryColor, // Textfarbe
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.tertiaryColor), // Icon-Farbe
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.tertiaryColor), // Textfarbe im Eingabefeld
                    decoration: InputDecoration(
                      hintText: 'Search ingredients',
                      hintStyle: TextStyle(color: theme.tertiaryColor), // HintText-Farbe
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.tertiaryColor), // Rahmenfarbe
                        borderRadius: defaultBorderRadius, // Abgerundete Ecken
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.tertiaryColor, width: 2.0),
                        borderRadius: defaultBorderRadius, // Abgerundete Ecken
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: theme.tertiaryColor), // Icon-Farbe
                  onPressed: _openAddDrinkPopup,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _filteredIngredients.isEmpty
                  ? Center(
                child: Text(
                  "No ingredients found.",
                  style: TextStyle(color: theme.tertiaryColor), // Textfarbe für "No ingredients found"
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _filteredIngredients[index];
                  return ListTile(
                    title: Text(
                      ingredient["drink_name"],
                      style: TextStyle(color: theme.tertiaryColor), // Textfarbe
                    ),
                    onTap: () {
                      widget.onIngredientSelected(ingredient);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: widget.showClearButton
          ? [
        Center(
          child: TextButton(
            onPressed: () {
              widget.onIngredientSelected({
                "drink_id": null,
                "drink_name": "Empty",
              });
              Navigator.of(context).pop();
            },
            child: Text(
              "Clear",
              style: TextStyle(color: theme.falseColor), // Textfarbe des Buttons
            ),
          ),
        ),
      ]
          : null,
    );
  }
}
