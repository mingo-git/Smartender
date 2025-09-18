// lib/components/show_drink_popup.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/custom_theme.dart';
import '../provider/theme_provider.dart';
import '../services/order_drink_service.dart';
import '../services/recipe_service.dart';
import 'my_button.dart';

Future<bool> showDrinkPopup(BuildContext context, Map<String, dynamic> drink) async {
  final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

  final bool isFavoriteInitial = drink['is_favorite'] ?? false;
  final bool isAlcoholic = drink['isAlcoholic'] ?? false;
  final String drinkName = drink['recipe_name'] ?? "Unknown Drink";

  // Zutaten-Infos (name, missing, quantity_ml) aus searchdrinks_screen.dart
  final List<Map<String, dynamic>> ingredients =
      drink['ingredients'] as List<Map<String, dynamic>>? ?? [];

  bool isFavorite = isFavoriteInitial;
  bool changed = false;
  bool isProcessing = false;

  return await showDialog<bool>(
    context: context,
    barrierDismissible: true, // Tap außerhalb schließt Popup
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding * 2,
          vertical: 20,
        ),
        // Mindestbreite 250 px, kann bei Bedarf breiter/höher werden
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 250),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------------------------------------
                    // 1) Kopfzeile: Alkohol-Icon links, X-Button rechts
                    // ---------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isAlcoholic)
                          Icon(
                            Icons.eighteen_up_rating_outlined,
                            color: theme.falseColor,
                            size: 32,
                          ),
                        if (!isAlcoholic)
                          const SizedBox(
                            width: 32,
                            height: 32,
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.tertiaryColor),
                          onPressed: () => Navigator.of(context).pop(changed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ---------------------------------------------
                    // 2) Bild (ohne Alkohol-Icon)
                    // ---------------------------------------------
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
                    const SizedBox(height: 20),

                    // ---------------------------------------------
                    // 3) Name + Favoriten-Icon
                    // ---------------------------------------------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            drinkName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.tertiaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : theme.tertiaryColor,
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                            setState(() => isProcessing = true);

                            final recipeService =
                            Provider.of<RecipeService>(context, listen: false);
                            final recipeId = drink['recipe_id'] as int? ?? -1;
                            bool success;

                            if (isFavorite) {
                              success =
                              await recipeService.removeRecipeFromFavorites(recipeId);
                            } else {
                              success = await recipeService.addRecipeToFavorites(recipeId);
                            }

                            if (success) {
                              setState(() {
                                isFavorite = !isFavorite;
                                changed = true;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to update favorite status", style: TextStyle(color: theme.primaryColor)),
                                  backgroundColor: theme.falseColor,
                                ),
                              );
                            }
                            setState(() => isProcessing = false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ---------------------------------------------
                    // 4) Zutaten (Ingredients)
                    // ---------------------------------------------
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
                      runSpacing: 2.0,
                      children: ingredients.map((ingredient) {
                        final bool missing = ingredient['missing'] == true;
                        final String name = ingredient['name'] ?? "Unnamed";
                        final int quantity = (ingredient['quantity_ml'] as int?) ?? 0;

                        // Label: "Name (xx ml)" oder nur "Name"
                        String ingredientLabel = name;
                        if (quantity > 0) {
                          ingredientLabel = "$name ($quantity ml)";
                        }

                        return Chip(
                          label: Text(
                            ingredientLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: missing ? theme.falseColor : theme.tertiaryColor,
                            ),
                          ),
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
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ---------------------------------------------
                    // 5) Order-Button
                    // ---------------------------------------------
                    MyButton(
                      onTap: () async {
                        bool orderSuccess =
                        await orderDrink(context, drink['recipe_id'] as int? ?? -1);
                        if (orderSuccess) {
                          showOrderProcessingPopup(context, theme);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      text: "Order",
                      hasMargin: false,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  ) ??
      false;
}

// ----------------------------------------------
// Ab hier unverändert: Bestell-Popup etc.
// ----------------------------------------------

Future<void> showOrderProcessingPopup(BuildContext parentContext, CustomTheme theme) async {
  showDialog(
    context: parentContext,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return _OrderProcessingDialog(
        theme: theme,
        parentContext: parentContext,
      );
    },
  );
}

class _OrderProcessingDialog extends StatefulWidget {
  final CustomTheme theme;
  final BuildContext parentContext;

  const _OrderProcessingDialog({
    Key? key,
    required this.theme,
    required this.parentContext,
  }) : super(key: key);

  @override
  State<_OrderProcessingDialog> createState() => _OrderProcessingDialogState();
}

class _OrderProcessingDialogState extends State<_OrderProcessingDialog>
    with SingleTickerProviderStateMixin {
  int dotCount = 0;
  Timer? _animationTimer;

  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_rotationController);
    _rotationController.repeat();

    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // ".", "..", "...", ""
      });
    });

    // Nach 10s beide Popups schließen:
    Future.delayed(const Duration(seconds: 10), () {
      _closeBothPopups();
    });
  }

  void _closeBothPopups() {
    if (mounted) {
      Navigator.of(context).pop(); // Popup 2 schließen
      if (Navigator.canPop(widget.parentContext)) {
        Navigator.of(widget.parentContext).pop(); // Popup 1 schließen
      }
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final progressText = "In Progress${'.' * dotCount}";

    return WillPopScope(
      onWillPop: () async {
        _closeBothPopups();
        return false;
      },
      child: AlertDialog(
        backgroundColor: theme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
        content: SizedBox(
          height: 430,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 95,
                right: 30,
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: Image.asset(
                    Provider.of<ThemeProvider>(widget.parentContext, listen: false).isDarkMode
                        ? 'lib/images/gear_dark.png'
                        : 'lib/images/gear.png',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: theme.tertiaryColor),
                  onPressed: _closeBothPopups,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    Provider.of<ThemeProvider>(widget.parentContext, listen: false).isDarkMode
                        ? 'lib/images/cup_with_background_dark.png'
                        : 'lib/images/cup_with_background.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    progressText,
                    style: TextStyle(
                      color: theme.tertiaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> orderDrink(BuildContext context, int recipeId) async {
  final orderDrinkService = Provider.of<OrderDrinkService>(context, listen: false);
  return await orderDrinkService.orderDrink(recipeId);
}
