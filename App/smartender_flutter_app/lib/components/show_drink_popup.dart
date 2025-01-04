// lib/components/show_drink_popup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../provider/theme_provider.dart';
import '../services/order_drink_service.dart';
import '../services/recipe_service.dart';
import 'my_button.dart';

/// Zeigt ein Popup-Dialog für ein bestimmtes Getränk an.
///
/// [context] - Der BuildContext, in dem das Dialog angezeigt wird.
/// [drink] - Eine Map mit den Details des Getränks.
///
/// Gibt `true` zurück, wenn eine Änderung an den Favoriten vorgenommen wurde, andernfalls `false`.
Future<bool> showDrinkPopup(BuildContext context, Map<String, dynamic> drink) async {
  final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
  bool isFavorite = drink['is_favorite'] ?? false;
  bool changed = false; // Flag, um Änderungen (z.B. Favorit) zu verfolgen
  bool isProcessing = false; // Flag, um den Verarbeitungsstatus zu verfolgen

  // Debug-Ausgabe: Wir zeigen einmal ALLES, was im drink-Objekt drinsteckt
  debugPrint("[DEBUG showDrinkPopup] Drink-Objekt:\n$drink");

  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding * 2,
          vertical: 20,
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schließen-Button (X)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: theme.tertiaryColor),
                    onPressed: () => Navigator.of(context).pop(changed),
                  ),
                ),

                // Cocktail-Bild
                Center(
                  child: Image.asset(
                    drink['image'] ?? "lib/images/cocktails/cocktail_unavailable.png",
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        "lib/images/cocktails/cocktail_unavailable.png",
                        height: 150,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Titel & Favoriten-Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      drink['name'] ?? "Unknown Drink",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.tertiaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : theme.tertiaryColor,
                      ),
                      onPressed: isProcessing
                          ? null // Deaktiviert die Schaltfläche während der Verarbeitung
                          : () async {
                        setState(() {
                          isProcessing = true;
                        });

                        final recipeService = Provider.of<RecipeService>(context, listen: false);
                        bool success;

                        if (isFavorite) {
                          success = await recipeService.removeRecipeFromFavorites(drink['recipe_id']);
                        } else {
                          success = await recipeService.addRecipeToFavorites(drink['recipe_id']);
                        }

                        if (success) {
                          setState(() {
                            isFavorite = !isFavorite;
                            changed = true; // Änderung festgestellt
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update favorite status")),
                          );
                        }

                        setState(() {
                          isProcessing = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Zutaten-Titel
                Text(
                  "Ingredients:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.tertiaryColor,
                  ),
                ),
                const SizedBox(height: 5),

                // Zutaten-Liste
                // Hier prüfen wir explizit, ob ingredient['missing'] == true und machen den Text ggf. rot.
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: (drink['ingredients'] as List<Map<String, dynamic>>?)?.map((ingredient) {
                    final bool missing = ingredient['missing'] == true;

                    // Debug-Ausgabe
                    debugPrint("[DEBUG showDrinkPopup] "
                        "Zutat '${ingredient['name']}' => missing=$missing");

                    return Chip(
                      label: Text(
                        ingredient['name'] ?? "Unnamed",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: missing ? theme.falseColor : theme.tertiaryColor,
                        ),
                      ),
                      // Um "fehlende" Zutaten visuell noch deutlicher zu machen,
                      // können wir das Chip-Design bei missing ändern:
                      backgroundColor: missing
                          ? theme.falseColor.withOpacity(0.1)
                          : theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: missing ? theme.falseColor : theme.tertiaryColor,
                          width: 1.0,
                        ),
                      ),
                    );
                  }).toList() ??
                      [],
                ),
                const SizedBox(height: 20),

                // Order-Button
                MyButton(
                  onTap: () async {
                    bool orderSuccess = await orderDrink(context, drink['recipe_id']);
                    Navigator.of(context).pop(); // Schließen des Popups

                    if (orderSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bestellung erfolgreich aufgegeben")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bestellung fehlgeschlagen")),
                      );
                    }
                  },
                  text: "Order",
                  hasMargin: false,
                ),
              ],
            );
          },
        ),
      );
    },
  ) ??
      false; // Rückgabe von false, falls kein Ergebnis
}

Future<bool> orderDrink(BuildContext context, int recipeId) async {
  final orderDrinkService = Provider.of<OrderDrinkService>(context, listen: false);
  bool success = await orderDrinkService.orderDrink(recipeId);
  return success;
}
