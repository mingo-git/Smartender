import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/drink_service.dart';
import 'add_drink_popup.dart';

class IngredientPopup extends StatefulWidget {
  final Function(Map<String, dynamic>) onIngredientSelected;

  const IngredientPopup({Key? key, required this.onIngredientSelected})
      : super(key: key);

  @override
  _IngredientPopupState createState() => _IngredientPopupState();
}

class _IngredientPopupState extends State<IngredientPopup> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allIngredients = [];
  List<Map<String, dynamic>> _filteredIngredients = [];

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
      builder: (context) => const AddDrinkPopup(),
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
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Select Ingredient"),
          IconButton(
            icon: const Icon(Icons.close),
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
                    decoration: const InputDecoration(
                      hintText: 'Search ingredients',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _openAddDrinkPopup,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _filteredIngredients.isEmpty
                  ? const Center(child: Text("No ingredients found."))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _filteredIngredients[index];
                  return ListTile(
                    title: Text(ingredient["drink_name"]),
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
    );
  }
}
