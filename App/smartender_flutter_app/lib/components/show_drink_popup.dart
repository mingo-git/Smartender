// lib/components/show_drink_popup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../provider/theme_provider.dart';
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
  bool changed = false; // Flag, um Änderungen zu verfolgen
  bool isProcessing = false; // Flag, um den Verarbeitungsstatus zu verfolgen

  print("Opening Popup for: ${drink['name']}, isFavorite: $isFavorite");

  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
        contentPadding: const EdgeInsets.symmetric(horizontal: horizontalPadding * 2, vertical: 20),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: theme.tertiaryColor),
                    onPressed: () => Navigator.of(context).pop(changed),
                  ),
                ),
                Center(
                  child: Image.asset(
                    drink['image'],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      drink['name'],
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
                Text(
                  "Ingredients:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.tertiaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: (drink['ingredients'] as List<Map<String, dynamic>>).map((ingredient) {
                    final missing = ingredient['missing'] == true;
                    return Chip(
                      label: Text(
                        ingredient['name'],
                        style: TextStyle(
                          color: missing ? Colors.red : theme.tertiaryColor,
                        ),
                      ),
                      backgroundColor: theme.primaryColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                MyButton(
                  onTap: () {
                    Navigator.of(context).pop(changed);
                    // TODO: Add ordering logic here
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
  ) ?? false; // Rückgabe von false, falls kein Ergebnis
}
