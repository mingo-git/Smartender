import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';

import '../provider/theme_provider.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  final bool hasMargin; // Neuer Parameter

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    this.hasMargin = true, // Standardwert ist true
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: hasMargin ? EdgeInsets.symmetric(horizontal: horizontalPadding) : null,
        decoration: BoxDecoration(
          color: theme.tertiaryColor,
          borderRadius: defaultBorderRadius,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
