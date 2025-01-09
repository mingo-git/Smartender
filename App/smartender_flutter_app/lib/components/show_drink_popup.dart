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
  bool isFavorite = drink['is_favorite'] ?? false;
  bool changed = false;
  bool isProcessing = false;

  debugPrint("[DEBUG showDrinkPopup] Drink-Objekt:\n$drink");

  return await showDialog<bool>(
    context: context,
    // 1) barrierDismissible = true: Antippen außerhalb schließt das erste Popup
    barrierDismissible: true,
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
                // "X"-Button oben rechts
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: theme.tertiaryColor),
                    onPressed: () => Navigator.of(context).pop(changed),
                  ),
                ),
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
                          ? null
                          : () async {
                        setState(() {
                          isProcessing = true;
                        });

                        final recipeService =
                        Provider.of<RecipeService>(context, listen: false);
                        bool success;

                        if (isFavorite) {
                          success = await recipeService
                              .removeRecipeFromFavorites(drink['recipe_id']);
                        } else {
                          success = await recipeService
                              .addRecipeToFavorites(drink['recipe_id']);
                        }

                        if (success) {
                          setState(() {
                            isFavorite = !isFavorite;
                            changed = true;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Failed to update favorite status")),
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
                  children:
                  (drink['ingredients'] as List<Map<String, dynamic>>?)?.map((ingredient) {
                    final bool missing = ingredient['missing'] == true;

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
                MyButton(
                  onTap: () async {
                    // 2) Das erste Popup bleibt offen. Wir schließen es NICHT.
                    bool orderSuccess = await orderDrink(context, drink['recipe_id']);
                    if (orderSuccess) {
                      // 3) Zeige das zweite Popup
                      showOrderProcessingPopup(context, theme);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Order failed")),
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
      false;
}

/// Zeigt das zweite Popup an. Nach 10 Sekunden werden automatisch beide Popups
/// geschlossen – sofern sie zu diesem Zeitpunkt noch offen sind.
Future<void> showOrderProcessingPopup(BuildContext parentContext, CustomTheme theme) async {
  showDialog(
    context: parentContext,
    // barrierDismissible = true => Tap außerhalb schließt das zweite Popup
    // Aber wir wollen *unsere* _closeBothPopups()-Logik.
    // => Dafür verwenden wir WillPopScope in der Widget-Hierarchie.
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

    // 1) RotationController erstellen
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Eine volle Umdrehung dauert 2 Sekunden
    );

    // 2) RotationAnimation setzen
    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_rotationController);

    // 3) Endlosschleife
    _rotationController.repeat();

    // Punkte animieren (alle 500ms)
    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // ".", "..", "...", ""
      });
    });

    // Automatisch nach 10 Sekunden beide Popups schließen
    Future.delayed(const Duration(seconds: 10), () {
      _closeBothPopups();
    });
  }

  /// Schließt zuerst das zweite (aktuelle) Popup,
  /// dann das erste (Drink-Popup), falls es noch offen ist.
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

    // 4) WillPopScope: Wir fangen "Tap-outside" ab
    // Der "Tap-outside" löst normalerweise ein pop() aus,
    // wir möchten aber *beide* Popups schließen => _closeBothPopups()
    return WillPopScope(
      onWillPop: () async {
        _closeBothPopups();
        // false => Wir übernehmen das Schließen manuell
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
              // Zahnrad rotiert
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
              // "X"-Button oben rechts
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: theme.tertiaryColor),
                  onPressed: _closeBothPopups,
                ),
              ),
              // Inhalt in der Mitte
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

/// "Bestellen"-Methode: Simuliert das Ordern eines Drinks
Future<bool> orderDrink(BuildContext context, int recipeId) async {
  final orderDrinkService = Provider.of<OrderDrinkService>(context, listen: false);
  bool success = await orderDrinkService.orderDrink(recipeId);
  return success;
}
