import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/config/constants.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;

  const SquareTile({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: defaultBorderRadius,
        border: Border.all(
          color: Colors.grey, // Rahmenfarbe, wie bei den Textinput-Feldern
        ),
      ),
      child: Image.asset(
        imagePath,
        height: 50,
      ),
    );
  }
}
