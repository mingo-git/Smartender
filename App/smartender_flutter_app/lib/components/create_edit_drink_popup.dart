import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/drink_service.dart';
import 'my_button.dart';

class CreateEditDrinkPopup extends StatefulWidget {
  /// Wenn `drinkId` null ist, wird ein neuer Drink angelegt.
  /// Wenn `drinkId` gesetzt ist, wird der bestehende Drink editiert.
  final int? drinkId;
  final String? initialName;
  final bool? initialIsAlcoholic;

  const CreateEditDrinkPopup({
    Key? key,
    this.drinkId,
    this.initialName,
    this.initialIsAlcoholic,
  }) : super(key: key);

  @override
  State<CreateEditDrinkPopup> createState() => _CreateEditDrinkPopupState();
}

class _CreateEditDrinkPopupState extends State<CreateEditDrinkPopup> {
  final TextEditingController _drinkNameController = TextEditingController();
  bool _isAlcoholic = false;

  @override
  void initState() {
    super.initState();
    // Vorbelegung wenn wir im Editier-Modus sind
    if (widget.drinkId != null) {
      _drinkNameController.text = widget.initialName ?? "";
      _isAlcoholic = widget.initialIsAlcoholic ?? false;
    }
  }

  void _closePopup() {
    Navigator.of(context).pop();
  }

  Future<void> _saveDrink() async {
    final drinkName = _drinkNameController.text.trim();
    if (drinkName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a drink name.")),
      );
      return;
    }

    final drinkService = Provider.of<DrinkService>(context, listen: false);

    bool success;
    if (widget.drinkId == null) {
      // Neuen Drink erstellen
      success = await drinkService.addDrink(drinkName, _isAlcoholic);
    } else {
      // Bestehenden Drink aktualisieren
      // Diese Funktion muss noch im DrinkService implementiert werden!
      success = await drinkService.updateDrink(widget.drinkId!, drinkName, _isAlcoholic);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.drinkId == null
            ? "Drink added successfully!"
            : "Drink updated successfully!")),
      );
      _closePopup();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save drink. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.drinkId != null;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isEditMode ? "Edit Drink" : "Add New Drink"),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closePopup,
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
            onTap: _saveDrink,
            text: "Save",
            hasMargin: false,
          ),
        ),
      ],
    );
  }
}
