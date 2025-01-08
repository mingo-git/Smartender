import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/provider/theme_provider.dart';
import 'package:smartender_flutter_app/services/recipe_service.dart';
import '../../../components/manage_tile.dart';
import 'create_drink_screen.dart'; // Passe den Pfad an!

class ManageDrinksScreen extends StatefulWidget {
  const ManageDrinksScreen({Key? key}) : super(key: key);

  @override
  State<ManageDrinksScreen> createState() => _ManageDrinksScreenState();
}

class _ManageDrinksScreenState extends State<ManageDrinksScreen> {
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _filteredRecipes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true; // Ob gerade geladen wird

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _searchController.addListener(_filterRecipes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRecipes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final allData = await recipeService.fetchRecipesFromLocal();

    // Kombiniere available und unavailable
    final available = allData["available"] ?? [];
    final unavailable = allData["unavailable"] ?? [];
    final allRecipes = [...available, ...unavailable];  // Zusammenführen

    setState(() {
      _recipes = List<Map<String, dynamic>>.from(allRecipes);
      _filteredRecipes = _recipes;
      _isLoading = false;
    });
  }


  void _filterRecipes() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecipes = _recipes;
      } else {
        _filteredRecipes = _recipes.where((recipe) {
          final name = (recipe["recipe_name"] ?? "").toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _confirmDeleteRecipe(int index) async {
    final recipe = _filteredRecipes[index];
    final recipeName = recipe["recipe_name"] ?? "Unnamed";
    final recipeId = recipe["recipe_id"];

    if (recipeId == null) {
      print("Cannot delete recipe without an ID");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          title: Text(
            'Delete Recipe',
            style: TextStyle(color: theme.tertiaryColor),
          ),
          content: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Are you sure you want to delete "$recipeName"?\n',
                  style: TextStyle(color: theme.tertiaryColor),
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
      await _deleteRecipe(recipeId);
    }
  }

  Future<void> _deleteRecipe(int recipeId) async {
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final success = await recipeService.deleteRecipe(recipeId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe deleted successfully!")),
      );
      await _loadRecipes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete recipe.")),
      );
    }
  }

  Future<void> _editRecipe(int index) async {
    final recipe = _filteredRecipes[index];
    final recipeId = recipe["recipe_id"];
    final recipeName = recipe["recipe_name"] ?? "Unnamed";
    final ingredientsResponse = recipe["ingredientsResponse"] ?? [];
    final pictureId = recipe["picture_id"]; // Hole die picture_id aus dem Rezept

    if (recipeId == null) {
      print("Cannot edit recipe without an ID");
      return;
    }

    // Bereite die ingredients für CreateDrinkScreen vor:
    final initialIngredients = ingredientsResponse.map<Map<String, dynamic>>((ing) {
      final drink = ing["drink"];
      return {
        "id": drink["drink_id"],
        "name": drink["drink_name"],
        "quantity": (ing["quantity_ml"] ?? 0).toDouble(),
        "color": null,
      };
    }).toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDrinkScreen(
          recipeId: recipeId,
          initialName: recipeName,
          initialIngredients: initialIngredients,
          initialPictureId: pictureId, // Übergibt die picture_id
        ),
      ),
    );

    // Wenn result == true, bedeutet das erfolgreich gespeichert -> neu laden
    if (result == true) {
      await _loadRecipes();
    }
  }


  bool _isRecipeAlcoholic(Map<String, dynamic> recipe) {
    final ingredients = recipe["ingredientsResponse"] ?? [];
    for (var ingredient in ingredients) {
      final drink = ingredient["drink"];
      if (drink != null && drink["is_alcoholic"] == true) {
        return true;
      }
    }
    return false;
  }

  Future<void> _createNewRecipe() async {
    // Öffnet CreateDrinkScreen ohne Parameter -> neuer Drink
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateDrinkScreen()),
    );

    // Wenn result == true, neu laden
    if (result == true) {
      await _loadRecipes();
    }
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
          "Manage Drinks",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.tertiaryColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.primaryColor,
                      hintText: 'Search recipes',
                      hintStyle: TextStyle(color: theme.tertiaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.tertiaryColor),
                        borderRadius: defaultBorderRadius,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.tertiaryColor, width: 2.0),
                        borderRadius: defaultBorderRadius,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add, color: theme.tertiaryColor, size: 35),
                  onPressed: _createNewRecipe,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.tertiaryColor))
                  : (_filteredRecipes.isEmpty
                  ? Center(
                child: Text(
                  'No recipes found.',
                  style: TextStyle(color: theme.tertiaryColor),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: _filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _filteredRecipes[index];
                  final recipeName = recipe["recipe_name"] ?? "Unnamed";
                  final isAlcoholic = _isRecipeAlcoholic(recipe);

                  return ManageTile(
                    name: recipeName,
                    isAlcoholic: isAlcoholic,
                    onDelete: () => _confirmDeleteRecipe(index),
                    onEdit: () => _editRecipe(index),
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
