import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/drink_service.dart';
import '../provider/theme_provider.dart';
import 'my_button.dart';

class CreateEditDrinkPopup extends StatefulWidget {
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
      success = await drinkService.addDrink(drinkName, _isAlcoholic);
    } else {
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
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final isEditMode = widget.drinkId != null;

    return AlertDialog(
      backgroundColor: theme.backgroundColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEditMode ? "Edit Drink" : "Add New Drink",
            style: TextStyle(color: theme.tertiaryColor),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.tertiaryColor),
            onPressed: _closePopup,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _drinkNameController,
            decoration: InputDecoration(
              hintText: "Enter drink name",
              hintStyle: TextStyle(color: theme.hintTextColor),
            ),
            style: TextStyle(color: theme.tertiaryColor),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Contains Alcohol",
                style: TextStyle(color: theme.tertiaryColor),
              ),
              Switch(
                value: _isAlcoholic,
                onChanged: (value) {
                  setState(() {
                    _isAlcoholic = value;
                  });
                },
                activeColor: theme.tertiaryColor,
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
