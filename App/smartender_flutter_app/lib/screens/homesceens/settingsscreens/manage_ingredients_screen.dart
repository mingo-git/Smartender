import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/provider/theme_provider.dart';
import 'package:smartender_flutter_app/services/drink_service.dart';

import '../../../components/manage_tile.dart';

class ManageIngredientsScreen extends StatefulWidget {
  const ManageIngredientsScreen({Key? key}) : super(key: key);

  @override
  State<ManageIngredientsScreen> createState() => _ManageIngredientsScreenState();
}

class _ManageIngredientsScreenState extends State<ManageIngredientsScreen> {
  List<Map<String, dynamic>> _drinks = [];

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    final drinkService = DrinkService();
    final drinks = await drinkService.fetchDrinksFromLocal();
    setState(() {
      _drinks = drinks;
    });
  }

  Future<void> _confirmDeleteDrink(int index) async {
    final drink = _drinks[index];
    final drinkName = drink["drink_name"] ?? "Unnamed";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Drink'),
          content: Text('Are you sure you want to delete "$drinkName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteDrink(index);
    }
  }

  Future<void> _deleteDrink(int index) async {
    // TODO: Hier Funktion zum Löschen implementieren (Backend-Aufruf)
    print("Drink deleted: ${_drinks[index]["drink_name"]}");

    // Falls du auch lokal entfernen willst:
    setState(() {
      _drinks.removeAt(index);
    });
  }

  Future<void> _editDrink(int index) async {
    // TODO: Hier Funktion zum Bearbeiten implementieren (z.B. Popup für neuen Namen)
    print("Edit pressed for drink: ${_drinks[index]["drink_name"]}");
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
          "Manage Ingredients",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: _drinks.isEmpty
            ? Center(
          child: CircularProgressIndicator(color: theme.tertiaryColor),
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: _drinks.length,
          itemBuilder: (context, index) {
            final drink = _drinks[index];
            final drinkName = drink["drink_name"] ?? "Unnamed";
            final isAlcoholic = drink["is_alcoholic"] == true;

            return ManageTile(
              name: drinkName,
              isAlcoholic: isAlcoholic,
              onDelete: () => _confirmDeleteDrink(index),
              onEdit: () => _editDrink(index),
            );
          },
        ),
      ),
    );
  }
}
