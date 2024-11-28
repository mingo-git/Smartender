import 'package:flutter/material.dart';

class LiterDisplay extends StatelessWidget {
  final double currentAmount; // Aktuelle Füllmenge
  final double maxCapacity; // Maximale Kapazität

  const LiterDisplay({
    Key? key,
    required this.currentAmount,
    required this.maxCapacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100, // Breite des gesamten Widgets
      height: 80, // Höhe des Widgets
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Oberer Text (z. B. 0,20 L)
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              "${currentAmount.toStringAsFixed(2)} L",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
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
                color: Colors.black,
              ),
            ),
          ),
          // Unterer Text (z. B. 0,40 L)
          Positioned(
            top: 50,
            right: 0,
            child: Text(
              "${maxCapacity.toStringAsFixed(2)} L",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
