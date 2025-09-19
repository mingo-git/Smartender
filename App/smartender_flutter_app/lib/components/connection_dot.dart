import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/theme_provider.dart';
import '../services/websocket_service.dart';

class ConnectionDot extends StatelessWidget {
  const ConnectionDot({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Consumer<WebSocketService>(
      builder: (context, ws, _) {
        final bool connected = ws.isConnected;

        // Choose colors based on app theme config
        Color okColor;
        final dynamic t = theme.trueColor;
        if (t is Color) {
          okColor = t;
        } else {
          okColor = Colors.greenAccent;
        }
        final Color badColor = theme.falseColor;

        // Vorher: 12 px → jetzt 40% davon
        const double previousSize = 12.0;
        final double size = previousSize * 0.4; // ≈ 4.8 px

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: connected ? okColor : badColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.tertiaryColor, width: 0.8),
          ),
        );
      },
    );
  }
}
