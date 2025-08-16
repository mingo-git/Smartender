import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';

import '../provider/theme_provider.dart';

class CupDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> ingredients; // Liste der Zutaten mit Farben und Mengen
  final double maxCapacity; // Maximale Kapazität des Bechers

  const CupDisplay({
    Key? key,
    required this.ingredients,
    required this.maxCapacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ThemeProvider holen, um zu prüfen, ob Dark Mode aktiv ist
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = themeProvider.currentTheme;
    final bool isDarkMode = themeProvider.isDarkMode;

    // Abhängig vom Dark Mode den Pfad wählen
    final String cupSvgPath = isDarkMode
        ? 'lib/images/cup_dark.svg'  // Dunkle Version
        : 'lib/images/cup.svg';      // Helle Version

    double totalHeight = 200.0; // Maximale Höhe des Cups

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Dynamische Füllstreifen basierend auf Zutaten
        Positioned(
          bottom: totalHeight * 0.05, // Start 5 % weiter oben
          child: Container(
            width: 175,
            height: totalHeight * 0.84, // Höhe des Bechers
            color: Colors.transparent,
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: ingredients.map((ingredient) {
                double ingredientHeight = ((ingredient["quantity"] ?? 0.0) / maxCapacity)
                    .clamp(0.0, 1.0) *
                    (totalHeight * 0.84);
                return Container(
                  width: 160,
                  height: ingredientHeight,
                  color: ingredient["color"], // Farbe der Zutat
                );
              }).toList(),
            ),
          ),
        ),

        // Ausschnitt mit trapezförmigem Loch
        Positioned(
          bottom: totalHeight * 0.05, // Start 5 % weiter oben
          child: ClipPath(
            clipper: TrapezoidCutoutClipper(),
            child: Container(
              width: 170,
              height: totalHeight * 0.84,
              color: theme.backgroundColor, // Farbe des Rahmens
            ),
          ),
        ),

        // Der Cup (SVG-Datei, im Vordergrund) - abhängig vom Dark Mode
        SvgPicture.asset(
          cupSvgPath,
          width: 170,
          height: totalHeight,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class TrapezoidCutoutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double bottomInset = size.width * 0.30; // Verkleinert die Breite unten
    double topInset = size.width * 0.18;    // Verkleinert die Breite oben
    double bottomHeightInset = size.height * 0.05; // Abstand vom unteren Rand
    double topHeightInset = size.height * 0.05;    // Abstand vom oberen Rand

    // Vollflächiges Rechteck
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Trapezförmiger Ausschnitt in der Mitte
    Path trapezoid = Path();
    trapezoid.moveTo(bottomInset, size.height - bottomHeightInset);           // Unten links
    trapezoid.lineTo(size.width - bottomInset, size.height - bottomHeightInset); // Unten rechts
    trapezoid.lineTo(size.width - topInset, topHeightInset);                  // Oben rechts
    trapezoid.lineTo(topInset, topHeightInset);                               // Oben links
    trapezoid.close();

    // Ausschnitt entfernen
    path.addPath(trapezoid, Offset.zero);
    path.fillType = PathFillType.evenOdd; // Ausschnitt durchsichtig machen

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false; // Keine Neuberechnung erforderlich
  }
}
