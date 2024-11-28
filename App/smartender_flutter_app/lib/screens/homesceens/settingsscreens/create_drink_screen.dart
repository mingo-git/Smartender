import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../components/my_togglebutton.dart';
import '../../../components/liter_display.dart';
import '../../../components/search_dropdown.dart';
import '../../../config/constants.dart';
import '../../../services/drink_service.dart';

class CreateDrinkScreen extends StatefulWidget {
  const CreateDrinkScreen({Key? key}) : super(key: key);

  @override
  State<CreateDrinkScreen> createState() => _CreateDrinkScreenState();
}

class _CreateDrinkScreenState extends State<CreateDrinkScreen> {
  bool isLiterMode = true;
  double filledAmount = 0.2;
  final TextEditingController drinkNameController = TextEditingController();
  final List<Map<String, dynamic>> ingredients = [];

  void _addIngredientField() {
    setState(() {
      ingredients.add({"ingredient": null, "quantity": 0.0});
    });
  }

  bool _canSaveDrink() {
    return drinkNameController.text.trim().isNotEmpty &&
        ingredients.any((ingredient) =>
        ingredient["ingredient"] != null && ingredient["quantity"] > 0);
  }

  void _saveDrink() {
    final drinkName = drinkNameController.text.trim();
    final selectedIngredients = ingredients
        .where((ingredient) =>
    ingredient["ingredient"] != null && ingredient["quantity"] > 0)
        .toList();

    print("Drink Name: $drinkName");
    print("Ingredients: $selectedIngredients");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Drink saved successfully!")),
    );

    setState(() {
      drinkNameController.clear();
      ingredients.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final drinkService = Provider.of<DrinkService>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 35),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Create Drink",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        actions: [
          MyToggleButton(
            onText: "L",
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
                      currentAmount: filledAmount,
                      maxCapacity: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Container(
                        color: Colors.black,
                        width: 170,
                        height: 200,
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 170,
                          height: (filledAmount / 0.4) * 200,
                          color: Colors.blue,
                        ),
                      ),
                    ],
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
            StreamBuilder<List<String>>(
              stream: drinkService.drinksStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No ingredients available.");
                } else {
                  final drinks = snapshot.data!;
                  return Column(
                    children: List.generate(
                      ingredients.length,
                          (index) => Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SearchDropdown(
                              items: drinks,
                              hintText: "Search Ingredient",
                              onItemSelected: (value) {
                                setState(() {
                                  ingredients[index]["ingredient"] = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "L",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  ingredients[index]["quantity"] =
                                      double.tryParse(value) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            if (_canSaveDrink())
              ElevatedButton(
                onPressed: _saveDrink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: defaultBorderRadius,
                  ),
                ),
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
    );
  }
}
