import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/theme_provider.dart';

class LiterDisplay extends StatelessWidget {
  final double currentAmount; // Aktuelle Füllmenge
  final double maxCapacity; // Maximale Kapazität
  final Color? color; // Benutzerdefinierte Farbe

  const LiterDisplay({
    Key? key,
    required this.currentAmount,
    required this.maxCapacity,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    // Fallback auf Theme-Farbe, falls keine benutzerdefinierte Farbe angegeben ist
    final displayColor = color ?? theme.tertiaryColor;

    return SizedBox(
      width: 100, // Breite des gesamten Widgets
      height: 80, // Höhe des Widgets
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Oberer Text (z. B. 200 ml)
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              "${currentAmount.toInt()} ml", // Ganze Zahl ohne Nachkommastellen
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ),
          // Diagonaler Strich
          Positioned(
            top: 40, // Strich ist weiter nach unten verschoben
            child: Transform.rotate(
              angle: -0.5, // Steilerer Winkel für den Strich
              child: Container(
                width: 150, // Länge des Strichs
                height: 2, // Dicke des Strichs
                color: displayColor,
              ),
            ),
          ),
          // Unterer Text (z. B. 400 ml)
          Positioned(
            top: 50,
            right: 0,
            child: Text(
              "${maxCapacity.toInt()} ml", // Ganze Zahl ohne Nachkommastellen
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
