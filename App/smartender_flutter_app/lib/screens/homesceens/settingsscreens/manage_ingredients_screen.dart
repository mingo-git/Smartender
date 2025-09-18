import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/components/create_edit_drink_popup.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/provider/theme_provider.dart';
import 'package:smartender_flutter_app/services/drink_service.dart';
import '../../../components/manage_tile.dart';

class ManageIngredientsScreen extends StatefulWidget {
  const ManageIngredientsScreen({Key? key}) : super(key: key);

  @override
  State<ManageIngredientsScreen> createState() =>
      _ManageIngredientsScreenState();
}

class _ManageIngredientsScreenState extends State<ManageIngredientsScreen> {
  List<Map<String, dynamic>> _drinks = [];
  List<Map<String, dynamic>> _filteredDrinks = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true; // Ob gerade geladen wird

  @override
  void initState() {
    super.initState();
    _loadDrinks();
    _searchController.addListener(_filterDrinks);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDrinks);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrinks() async {
    final drinkService = Provider.of<DrinkService>(context, listen: false);
    final drinks = await drinkService.fetchDrinksFromLocal();
    setState(() {
      _drinks = drinks;
      _filteredDrinks = drinks;
      _isLoading = false; // Laden abgeschlossen
    });
  }

  void _filterDrinks() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDrinks = _drinks;
      } else {
        _filteredDrinks = _drinks.where((drink) {
          final name = (drink["drink_name"] ?? "").toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _confirmDeleteDrink(int index) async {
    final drink = _filteredDrinks[index];
    final drinkName = drink["drink_name"] ?? "Unnamed";
    final drinkId = drink["drink_id"];

    if (drinkId == null) {
      print("Cannot delete drink without an ID");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          title: Text(
            'Delete Ingredient',
            style: TextStyle(color: theme.tertiaryColor),
          ),
          content: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Are you sure you want to delete "$drinkName"?\n',
                  style: TextStyle(color: theme.tertiaryColor, fontSize: 17),
                ),
                TextSpan(
                  text: 'This ingredient will be removed from every drink that contains it.',
                  style: TextStyle(color: theme.falseColor, fontSize: 17),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'No',
                style: TextStyle(color: theme.tertiaryColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Yes',
                style: TextStyle(color: theme.tertiaryColor),
              ),
            ),
          ],
        );
      },
    );


    if (confirmed == true) {
      await _deleteDrink(drinkId);
    }
  }

  Future<void> _deleteDrink(int drinkId) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final drinkService = Provider.of<DrinkService>(context, listen: false);
    final success = await drinkService.deleteDrink(drinkId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Drink deleted successfully!", style: TextStyle(color: theme.primaryColor),),
          backgroundColor: theme.trueColor,

        ),
      );
      await _loadDrinks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to delete drink.", style: TextStyle(color: theme.primaryColor),),
          backgroundColor: theme.falseColor,
        ),
      );
    }
  }

  Future<void> _editDrink(int index) async {
    final drink = _filteredDrinks[index];
    final drinkId = drink["drink_id"];
    final drinkName = drink["drink_name"] ?? "Unnamed";
    final isAlcoholic = drink["is_alcoholic"] == true;

    if (drinkId == null) {
      print("Cannot edit drink without an ID");
      return;
    }

    // Öffne das CreateEditDrinkPopup im Editiermodus
    await showDialog(
      context: context,
      builder: (context) => CreateEditDrinkPopup(
        drinkId: drinkId,
        initialName: drinkName,
        initialIsAlcoholic: isAlcoholic,
      ),
    );

    // Nach Schließen des Popups die Liste neu laden
    await _loadDrinks();
  }

  Future<void> _createNewDrink() async {
    await showDialog(
      context: context,
      builder: (context) => const CreateEditDrinkPopup(),
    );

    // Nach Schließen des Popups neu laden
    await _loadDrinks();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 35, color: theme.tertiaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Manage Ingredients",
          style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: theme.tertiaryColor),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Zeile mit Suchfeld links und "+"-Button rechts
            Row(
              children: [
                // Suchfeld (Expanded, um den restlichen Platz einzunehmen)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.tertiaryColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.primaryColor,
                      hintText: 'Search ingredients',
                      hintStyle: TextStyle(color: theme.tertiaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.tertiaryColor),
                        borderRadius: defaultBorderRadius,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: theme.tertiaryColor, width: 2.0),
                        borderRadius: defaultBorderRadius,
                      ),
                      // Größeres Padding für höhere Input-Field-Höhe
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add, color: theme.tertiaryColor, size: 35),
                  onPressed: _createNewDrink,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                  child:
                  CircularProgressIndicator(color: theme.tertiaryColor))
                  : (_filteredDrinks.isEmpty
                  ? Center(
                child: Text(
                  'No ingredients found.',
                  style: TextStyle(color: theme.tertiaryColor),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: _filteredDrinks.length,
                itemBuilder: (context, index) {
                  final drink = _filteredDrinks[index];
                  final drinkName = drink["drink_name"] ?? "Unnamed";
                  final isAlcoholic = drink["is_alcoholic"] == true;

                  return ManageTile(
                    name: drinkName,
                    isAlcoholic: isAlcoholic,
                    onDelete: () => _confirmDeleteDrink(index),
                    onEdit: () => _editDrink(index),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}
