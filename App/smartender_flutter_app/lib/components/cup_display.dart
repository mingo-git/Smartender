import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CupDisplay extends StatelessWidget {
  final double currentAmount; // Aktuelle Füllmenge
  final double maxCapacity; // Maximale Kapazität

  const CupDisplay({
    Key? key,
    required this.currentAmount,
    required this.maxCapacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verhältnis der aktuellen Füllmenge zur maximalen Kapazität
    double fillPercentage = (currentAmount / maxCapacity).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Dynamisches Trapez für die Füllung (im Hintergrund)
        Positioned(
          bottom: 10, // Abstand vom unteren Rand
          child: ClipPath(
            clipper: TrapezoidClipper(fillPercentage: fillPercentage),
            child: Container(
              width: 140, // Fixierte Breite des Trapezes
              height: 190, // Fixierte Höhe des Trapezes
              color: Colors.blue,
            ),
          ),
        ),
        // Der Cup (SVG-Datei, im Vordergrund)
        SvgPicture.asset(
          'lib/images/cup.svg',
          width: 170,
          height: 200,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class TrapezoidClipper extends CustomClipper<Path> {
  final double fillPercentage;

  TrapezoidClipper({required this.fillPercentage});

  @override
  Path getClip(Size size) {
    Path path = Path();
    double bottomInset = size.width * 0.25; // Fixierte Breite unten
    double topInset = size.width * 0.1; // Fixierte Breite oben
    double totalHeight = size.height * fillPercentage; // Dynamische Höhe des Trapezes
    double topHeight = size.height - totalHeight; // Dynamische Position oben

    path.moveTo(bottomInset, size.height); // Start unten links
    path.lineTo(size.width - bottomInset, size.height); // Unten rechts
    path.lineTo(size.width - topInset, topHeight); // Oben rechts
    path.lineTo(topInset, topHeight); // Oben links
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true; // Neuberechnung, wenn sich die Füllmenge ändert
  }
}
