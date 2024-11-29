import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/drink_service.dart';

class IngredientPopup extends StatefulWidget {
  final Function(String) onIngredientSelected;

  const IngredientPopup({Key? key, required this.onIngredientSelected})
      : super(key: key);

  @override
  _IngredientPopupState createState() => _IngredientPopupState();
}

class _IngredientPopupState extends State<IngredientPopup> {
  TextEditingController _searchController = TextEditingController();
  List<String> _allIngredients = [];
  List<String> _filteredIngredients = [];

  @override
  void initState() {
    super.initState();
    final drinkService = Provider.of<DrinkService>(context, listen: false);
    drinkService.fetchDrinksFromLocal().then((ingredients) {
      setState(() {
        _allIngredients = ingredients;
        _filteredIngredients = ingredients;
      });
    });
    _searchController.addListener(_filterIngredients);
  }

  void _filterIngredients() {
    setState(() {
      _filteredIngredients = _allIngredients
          .where((ingredient) => ingredient
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterIngredients);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Zutat auswählen"),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Suche Zutaten',
              ),
            ),
            const SizedBox(height: 10),
            // Hier verwenden wir Flexible
            Flexible(
              child: _filteredIngredients.isEmpty
                  ? const Center(child: Text("Keine Zutaten gefunden."))
                  : ListView.builder(
                // Entferne shrinkWrap
                itemCount: _filteredIngredients.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_filteredIngredients[index]),
                    onTap: () {
                      widget.onIngredientSelected(
                          _filteredIngredients[index]);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Abbrechen"),
        ),
      ],
    );
  }
}
