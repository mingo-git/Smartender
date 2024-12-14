import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../components/cup_display.dart';
import '../../../components/liter_display.dart';
import '../../../config/constants.dart';
import '../../../provider/theme_provider.dart';
import '../../../services/recipe_service.dart';
import '../../../components/select_ingredient_popup.dart';

//TODO: Jedes Ingredient nur einma auswaehlbar sonst knallts

class CreateDrinkScreen extends StatefulWidget {
  final int? recipeId;
  final String? initialName;
  final List<Map<String, dynamic>>? initialIngredients;

  const CreateDrinkScreen({
    Key? key,
    this.recipeId,
    this.initialName,
    this.initialIngredients,
  }) : super(key: key);

  @override
  State<CreateDrinkScreen> createState() => _CreateDrinkScreenState();
}

class _CreateDrinkScreenState extends State<CreateDrinkScreen> {
  final TextEditingController drinkNameController = TextEditingController();
  final List<Map<String, dynamic>> ingredients = [];
  final List<TextEditingController> quantityControllers = [];
  final RecipeService recipeService = RecipeService();

  // Zum Vergleichen des ursprünglichen Zustands
  String? _originalName;
  List<Map<String, dynamic>> _originalIngredients = [];

  @override
  void initState() {
    super.initState();

    // Editiermodus: Vorbelegung der Felder + Originalwerte speichern
    if (widget.recipeId != null && widget.initialName != null && widget.initialIngredients != null) {
      drinkNameController.text = widget.initialName!;
      _originalName = widget.initialName!;
      // Erstelle eine tiefe Kopie der initialIngredients als Originalzustand
      _originalIngredients = widget.initialIngredients!.map((ing) => Map<String, dynamic>.from(ing)).toList();
      ingredients.addAll(widget.initialIngredients!);

      for (var ing in ingredients) {
        final intQty = (ing["quantity"] is double) ? (ing["quantity"] as double).toInt() : (ing["quantity"] ?? 0);
        ing["quantity"] = intQty;
        final controller = TextEditingController(text: intQty.toString());
        quantityControllers.add(controller);
      }

      _updateIngredientColors();
    } else {
      // Neuer Drink (kein Editiermodus)
      _originalName = "";
      _originalIngredients = [];
    }

    drinkNameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    drinkNameController.removeListener(() {});
    drinkNameController.dispose();
    for (var c in quantityControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addIngredientField() {
    setState(() {
      if (ingredients.length < 11) {
        ingredients.add({
          "id": null,
          "name": null,
          "quantity": 0,
          "color": null,
        });
        final controller = TextEditingController(text: "0");
        quantityControllers.add(controller);
        _updateIngredientColors();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You can only add up to 11 ingredients."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _deleteIngredientField(int index) {
    setState(() {
      ingredients.removeAt(index);
      quantityControllers.removeAt(index);
      _updateIngredientColors();
    });
  }

  void _updateIngredientColors() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    for (int i = 0; i < ingredients.length; i++) {
      ingredients[i]["color"] = theme.slotColors[i % theme.slotColors.length];
    }
  }

  void _openIngredientPopup(int index) async {
    showDialog(
      context: context,
      builder: (context) => SelectIngredientPopup(
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
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    String recipeName = drinkNameController.text.trim();
    List<Map<String, dynamic>> recipeIngredients = ingredients
        .where((ingredient) => ingredient["id"] != null && ingredient["quantity"] > 0)
        .map((ingredient) => {
      "id": ingredient["id"],
      "quantity": ingredient["quantity"],
    })
        .toList();

    bool success;
    if (widget.recipeId == null) {
      // Neuer Drink
      success = await recipeService.addRecipe(recipeName, recipeIngredients);
    } else {
      // Existierender Drink -> Update mit add/remove/update von Zutaten
      // Hier greifen wir auf _originalIngredients zu, welches wir im initState gespeichert haben.
      // `widget.initialIngredients` entspricht den ursprünglichen Zutaten des Rezepts beim Laden.
      success = await recipeService.updateRecipeWithIngredients(widget.recipeId!, recipeName, recipeIngredients, _originalIngredients);
    }

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.recipeId == null ? "Recipe saved successfully!" : "Recipe updated successfully!"),
            backgroundColor: theme.trueColor,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(true);
        });
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.recipeId == null ? "Failed to save recipe. Please try again." : "Failed to update recipe. Please try again."),
            backgroundColor: theme.falseColor,
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

  /// Prüft, ob es ungespeicherte Änderungen gibt.
  bool _hasUnsavedChanges() {
    // Falls weder Name noch Zutaten eingetragen wurden und kein Editiermodus aktiv ist
    // ist nichts zu verwerfen.
    if (widget.recipeId == null) {
      // Neuer Drink: Änderungen nur, wenn etwas eingegeben wurde
      if (drinkNameController.text.trim().isNotEmpty) return true;
      if (ingredients.isNotEmpty && ingredients.any((ing) => ing["id"] != null && ing["quantity"] > 0)) {
        return true;
      }
      return false;
    } else {
      // Editiermodus: Vergleiche mit ursprünglichem Zustand
      final currentName = drinkNameController.text.trim();
      if (currentName != _originalName) return true;

      // Vergleiche Zutaten. Prüfe auf Anzahl und jede einzelne.
      if (ingredients.length != _originalIngredients.length) return true;

      for (int i = 0; i < ingredients.length; i++) {
        final original = i < _originalIngredients.length ? _originalIngredients[i] : null;
        final current = ingredients[i];

        if (original == null) return true;

        // Vergleiche id, name und quantity
        if (original["id"] != current["id"]) return true;
        if (original["name"] != current["name"]) return true;
        if ((original["quantity"] ?? 0) != (current["quantity"] ?? 0)) return true;
      }

      return false;
    }
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
          (sum, ingredient) => sum + (ingredient["quantity"]?.toDouble() ?? 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges()) {
          return await _confirmDiscardChanges();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: theme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: 35, color: theme.tertiaryColor),
            onPressed: () async {
              if (_hasUnsavedChanges()) {
                bool discard = await _confirmDiscardChanges();
                if (discard) Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.recipeId == null ? "Create Drink" : "Edit Drink",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
          ),
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
                      ingredients: ingredients,
                      maxCapacity: 400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: drinkNameController,
                decoration: InputDecoration(
                  hintText: "Enter drink name",
                  hintStyle: TextStyle(color: theme.hintTextColor),
                  border: OutlineInputBorder(
                    borderRadius: defaultBorderRadius,
                  ),
                  filled: true,
                  fillColor: theme.primaryColor,
                ),
                style: TextStyle(
                  color: drinkNameController.text.isEmpty
                      ? theme.hintTextColor
                      : theme.primaryFontColor,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ingredients",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 30, color: theme.tertiaryColor),
                    onPressed: _addIngredientField,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;

                while (quantityControllers.length <= index) {
                  quantityControllers.add(TextEditingController(text: "0"));
                }
                final quantityController = quantityControllers[index];
                final currentQty = ingredient["quantity"] ?? 0;
                final currentQtyString = currentQty.toString();

                if (quantityController.text != currentQtyString) {
                  quantityController.text = currentQtyString;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: ElevatedButton(
                          onPressed: () => _openIngredientPopup(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.tertiaryColor),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: ingredient["name"] != null ? theme.tertiaryColor : theme.hintTextColor,
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
                          controller: quantityController,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "0 ml",
                            hintStyle: TextStyle(color: theme.hintTextColor),
                            suffix: Text(
                              "ml",
                              style: TextStyle(
                                color: theme.tertiaryColor,
                                fontSize: 16,
                              ),
                            ),
                            contentPadding: const EdgeInsets.only(right: 8.0),
                            border: OutlineInputBorder(
                              borderRadius: defaultBorderRadius,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: defaultBorderRadius,
                              borderSide: BorderSide(
                                color: theme.tertiaryColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: defaultBorderRadius,
                              borderSide: BorderSide(
                                color: theme.tertiaryColor,
                                width: 2.0,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: defaultBorderRadius,
                              borderSide: BorderSide(
                                color: theme.tertiaryColor,
                                width: 1,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.primaryColor,
                          ),
                          style: TextStyle(
                            color: theme.tertiaryColor,
                            fontSize: 16,
                          ),
                          onChanged: (value) {
                            final qty = int.tryParse(value) ?? 0;
                            setState(() {
                              ingredient["quantity"] = qty;
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
                        icon: Icon(Icons.delete_forever, color: theme.tertiaryColor),
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
                    backgroundColor: theme.tertiaryColor,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: defaultBorderRadius,
                    ),
                  ),
                  onPressed: _saveRecipe,
                  child: Text(
                    widget.recipeId == null ? "Save Drink" : "Update Drink",
                    style: TextStyle(
                      color: theme.secondaryFontColor,
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
