import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';

import '../provider/theme_provider.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;

  const SquareTile({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: defaultBorderRadius,
        border: Border.all(
          color: theme.tertiaryColor, // Rahmenfarbe, wie bei den Textinput-Feldern
        ),
      ),
      child: Image.asset(
        imagePath,
        height: 50,
      ),
    );
  }
}
