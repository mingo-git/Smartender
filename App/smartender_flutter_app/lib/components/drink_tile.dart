// lib/components/drink_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import '../provider/theme_provider.dart';

class DrinkTile extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isAlcoholic;
  final VoidCallback? onTap;

  const DrinkTile({
    Key? key,
    required this.name,
    required this.imagePath,
    required this.isAlcoholic,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: theme.tertiaryColor,
          backgroundColor: theme.primaryColor,
          minimumSize: const Size(double.infinity, 80),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: defaultBorderRadius,
          ),
          side: BorderSide(color: theme.tertiaryColor),
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // (1) Bildbereich + Icon in einem Stack
            Expanded(
              flex: 6,
              child: Stack(
                clipBehavior: Clip.none, // Wichtig: Kein Clipping im Stack
                children: [
                  // Cocktail-Bild mittig
                  Center(
                    child: Image.asset(
                      imagePath,
                      scale: 5,
                    ),
                  ),
                  // Icon unten rechts (leicht überlappend)
                  if (isAlcoholic)
                    Positioned(
                      bottom: -15, // Wert anpassen, um es weiter rausragen zu lassen
                      right: -10,
                      child: Icon(
                        Icons.eighteen_up_rating_outlined,
                        color: theme.falseColor, // Oder theme.tertiaryColor
                        size: 28,
                      ),
                    ),
                ],
              ),
            ),
            // (2) Namensbereich (unverändert)
            Expanded(
              flex: 4,
              child: Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
