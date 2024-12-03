import 'package:flutter/material.dart';
import '../../../components/cup_display.dart';
import '../../../components/my_togglebutton.dart';
import '../../../components/liter_display.dart';
import '../../../config/constants.dart';
import '../../../services/recipe_service.dart';
import '../../../components/ingredient_popup.dart';

class CreateDrinkScreen extends StatefulWidget {
  const CreateDrinkScreen({Key? key}) : super(key: key);

  @override
  State<CreateDrinkScreen> createState() => _CreateDrinkScreenState();
}

class _CreateDrinkScreenState extends State<CreateDrinkScreen> {
  bool isLiterMode = true;
  double filledAmount = 200; // In Millilitern
  final TextEditingController drinkNameController = TextEditingController();
  final List<Map<String, dynamic>> ingredients = [];
  final RecipeService recipeService = RecipeService();

  @override
  void initState() {
    super.initState();
    drinkNameController.addListener(() {
      setState(() {}); // Aktualisiere den Zustand, wenn sich der Name ändert
    });
  }

  @override
  void dispose() {
    drinkNameController.removeListener(() {});
    drinkNameController.dispose();
    super.dispose();
  }

  void _addIngredientField() {
    if (ingredients.length < 11) {
      setState(() {
        ingredients.add({
          "id": null,
          "name": null,
          "quantity": 0.0,
        });
        _updateIngredientColors();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can only add up to 11 ingredients."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteIngredientField(int index) {
    setState(() {
      ingredients.removeAt(index);
      _updateIngredientColors(); // Aktualisiere Farben
    });
  }

  void _updateIngredientColors() {
    for (int i = 0; i < ingredients.length; i++) {
      ingredients[i]["color"] = Colors.primaries[i % Colors.primaries.length];
    }
  }

  void _openIngredientPopup(int index) async {
    showDialog(
      context: context,
      builder: (context) => IngredientPopup(
        onIngredientSelected: (ingredient) {
          setState(() {
            ingredients[index]["id"] = ingredient["drink_id"];
            ingredients[index]["name"] = ingredient["drink_name"];
          });
        },
      ),
    );
  }

  void _saveRecipe() async {
    String recipeName = drinkNameController.text.trim();
    List<Map<String, dynamic>> recipeIngredients = ingredients
        .where((ingredient) => ingredient["id"] != null && ingredient["quantity"] > 0)
        .map((ingredient) => {
      "id": ingredient["id"],
      "quantity": ingredient["quantity"],
    })
        .toList();

    bool success = await recipeService.addRecipe(recipeName, recipeIngredients);

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Recipe saved successfully!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to save recipe. Please try again."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _canSaveDrink() {
    return drinkNameController.text.trim().isNotEmpty &&
        ingredients.any((ingredient) =>
        ingredient["id"] != null && ingredient["quantity"] > 0);
  }

  Future<bool> _confirmDiscardChanges() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard Changes?"),
        content: const Text(
            "You have unsaved changes. Do you really want to discard them?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Discard"),
          ),
        ],
      ),
    ) ??
        false;
  }

  double _calculateFilledAmount() {
    return ingredients.fold<double>(
      0.0,
          (sum, ingredient) => sum + (ingredient["quantity"] ?? 0.0),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_canSaveDrink()) {
          return await _confirmDiscardChanges();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 35),
            onPressed: () async {
              if (_canSaveDrink()) {
                bool discard = await _confirmDiscardChanges();
                if (discard) Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            "Create Drink",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          actions: [
            MyToggleButton(
              onText: "ml",
              offText: "%",
              initialValue: isLiterMode,
              onToggle: (value) => setState(() => isLiterMode = value),
              width: 80,
              height: 40,
              fontSize: 20,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: LiterDisplay(
                        currentAmount: _calculateFilledAmount(),
                        maxCapacity: 400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: CupDisplay(
                      currentAmount: _calculateFilledAmount(), // Dynamische Füllmenge
                      maxCapacity: 400, // Maximale Kapazität
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 20),
              TextField(
                controller: drinkNameController,
                decoration: InputDecoration(
                  hintText: "Enter drink name",
                  border: OutlineInputBorder(
                    borderRadius: defaultBorderRadius,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ingredients",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 30),
                    onPressed: _addIngredientField,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: ElevatedButton(
                          onPressed: () => _openIngredientPopup(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black, width: 1),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: defaultBorderRadius,
                            ),
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                ingredient["name"] ?? "Search Ingredient",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "0",
                            suffix: const Text(
                              "ml",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            contentPadding: const EdgeInsets.only(right: 8.0),
                            border: OutlineInputBorder(
                              borderRadius: defaultBorderRadius,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            final quantity = double.tryParse(value) ?? 0.0;
                            setState(() {
                              ingredient["quantity"] = quantity;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ingredient["color"],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.black),
                        onPressed: () => _deleteIngredientField(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              if (_canSaveDrink())
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: defaultBorderRadius,
                    ),
                  ),
                  onPressed: _saveRecipe,
                  child: const Text(
                    "Save Drink",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
