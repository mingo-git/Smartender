import 'package:flutter/material.dart';
import 'my_button.dart';
import 'ingredient_popup.dart';

class AddDrinkPopup extends StatefulWidget {
  const AddDrinkPopup({Key? key}) : super(key: key);

  @override
  State<AddDrinkPopup> createState() => _AddDrinkPopupState();
}

class _AddDrinkPopupState extends State<AddDrinkPopup> {
  final TextEditingController _drinkNameController = TextEditingController();
  bool _isAlcoholic = false;

  void _closeAndReopenIngredientPopup(BuildContext context) {
    Navigator.of(context).pop(); // Schließe AddDrinkPopup
    showDialog(
      context: context,
      builder: (context) => IngredientPopup(
        onIngredientSelected: (ingredient) {
          // Handle ingredient selection if necessary
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Add New Drink"),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _closeAndReopenIngredientPopup(context),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _drinkNameController,
            decoration: const InputDecoration(
              hintText: "Enter drink name",
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Contains Alcohol"),
              Switch(
                value: _isAlcoholic,
                onChanged: (value) {
                  setState(() {
                    _isAlcoholic = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: MyButton(
            onTap: () {
              // Handle save logic for new drink here
              print("Drink Name: ${_drinkNameController.text}");
              print("Contains Alcohol: $_isAlcoholic");
              Navigator.of(context).pop();
            },
            text: "Save",
            hasMargin: false, // Kein zusätzliches Margin, um den Button ins Popup zu integrieren
          ),
        ),
      ],
    );
  }
}
