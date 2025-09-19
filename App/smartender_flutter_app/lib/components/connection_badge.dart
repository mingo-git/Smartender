import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/theme_provider.dart';

class ConnectionBadge extends StatelessWidget {
  final String label;
  final bool ok;

  const ConnectionBadge({super.key, required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    // Farben aus Theme
    Color okColor;
    final dynamic t = theme.trueColor;
    if (t is Color) {
      okColor = t;
    } else {
      okColor = Colors.greenAccent;
    }
    final Color badColor = theme.falseColor;

    // Basisgröße: 14 px; aktuell 3x größer als die letzte (40%) Variante -> 14 * 1.2 ≈ 16.8 px
    const double previousCircle = 14.0;
    final double circle = previousCircle * 1.2; // ≈ 16.8 px
    final double fontSize = circle * 0.65; // lesbarer Buchstabe im Kreis

    return Container(
      width: circle,
      height: circle,
      decoration: BoxDecoration(
        color: ok ? okColor : badColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.tertiaryColor, width: 1.0),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.backgroundColor,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1.0,
        ),
      ),
    );
  }
}
