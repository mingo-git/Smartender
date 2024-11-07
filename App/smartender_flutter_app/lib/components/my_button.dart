import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/config/constants.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: hasMargin ? EdgeInsets.symmetric(horizontal: horizontalPadding) : null,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: defaultBorderRadius,
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
