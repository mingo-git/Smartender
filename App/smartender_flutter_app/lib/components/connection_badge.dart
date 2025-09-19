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

    Color okColor;
    final dynamic t = theme.trueColor;
    if (t is Color) {
      okColor = t;
    } else {
      okColor = Colors.greenAccent;
    }
    final Color badColor = theme.falseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? okColor.withOpacity(0.2) : badColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? okColor : badColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: ok ? okColor : badColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.tertiaryColor, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.tertiaryColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

