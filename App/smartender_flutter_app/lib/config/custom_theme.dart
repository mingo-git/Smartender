import 'package:flutter/material.dart';

class CustomTheme {
  final Color backgroundColor;
  final Color popupBackgroundColor;
  final Color fadeOutBackground0;
  final Color fadeOutBackground1;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color primaryFontColor;
  final Color secondaryFontColor;
  final dynamic trueColor; // Kann eine Farbe oder ein Gradient sein
  final Color falseColor;
  final Color uncertainColor;
  final Color hintTextColor;
  final List<Color> slotColors; // Farben für Slots

  CustomTheme({
    required this.backgroundColor,
    required this.popupBackgroundColor,
    required this.fadeOutBackground0,
    required this.fadeOutBackground1,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.primaryFontColor,
    required this.secondaryFontColor,
    required this.trueColor,
    required this.falseColor,
    required this.uncertainColor,
    required this.hintTextColor,
    required this.slotColors,
  });

  // Light Theme
  static final CustomTheme lightTheme = CustomTheme(
    backgroundColor: const Color(0xFFF2F2F2),
    popupBackgroundColor: Colors.grey.shade200,
    fadeOutBackground0: const Color(0x9effffff),
    fadeOutBackground1: const Color(0x00f2f2f2),
    primaryColor: Colors.white,
    secondaryColor: const Color(0xFFC3C3C3),
    tertiaryColor: Colors.black,
    primaryFontColor: Colors.black,
    secondaryFontColor: Colors.white,
    trueColor: const Color(0xEF5AEC05),
    falseColor: Colors.red,
    uncertainColor: const Color(0xFFCCCCCC),
    hintTextColor: const Color(0xff3c3c3c),
    slotColors: [
      Colors.lightGreen,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.lightBlue,
      Colors.blue,
      Colors.indigo,
      Colors.deepPurple,
      Colors.purple,
      Colors.pink,
      Colors.red,
    ],
  );

  // Dark Theme
  static final CustomTheme darkTheme = CustomTheme(
    backgroundColor: Colors.black,
    popupBackgroundColor: Colors.grey.shade800,
    fadeOutBackground0: Colors.grey.shade900,
    fadeOutBackground1: Colors.grey.shade700,
    primaryColor: Colors.blueGrey,
    secondaryColor: Colors.tealAccent,
    tertiaryColor: Colors.greenAccent,
    primaryFontColor: Colors.white,
    secondaryFontColor: Colors.white70,
    trueColor: Colors.green,
    falseColor: Colors.red,
    uncertainColor: Colors.grey,
    hintTextColor: const Color(0xFFFFFFFF),
    slotColors: [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
    ],
  );

  // Sommer Theme
  static final CustomTheme sommerTheme = CustomTheme(
    backgroundColor: Colors.yellow.shade100,
    popupBackgroundColor: Colors.orange.shade200,
    fadeOutBackground0: Colors.orange.shade100,
    fadeOutBackground1: Colors.yellow.shade50,
    primaryColor: Colors.orange,
    secondaryColor: Colors.yellow,
    tertiaryColor: Colors.green.shade600,
    primaryFontColor: Colors.brown.shade800,
    secondaryFontColor: Colors.white,
    trueColor: Colors.orangeAccent,
    falseColor: Colors.red,
    uncertainColor: Colors.grey,
    hintTextColor: Colors.brown.shade600,
    slotColors: [
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.lightGreen,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ],
  );

  // Crazy Theme
  static final CustomTheme crazyTheme = CustomTheme(
    backgroundColor: Colors.pink.shade50,
    popupBackgroundColor: Colors.purple.shade100,
    fadeOutBackground0: Colors.pink.shade100,
    fadeOutBackground1: Colors.purple.shade50,
    primaryColor: Colors.pink,
    secondaryColor: Colors.purple,
    tertiaryColor: Colors.deepPurple,
    primaryFontColor: Colors.white,
    secondaryFontColor: Colors.yellow,
    trueColor: const LinearGradient(
      colors: [Colors.pink, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    falseColor: Colors.red,
    uncertainColor: Colors.grey,
    hintTextColor: Colors.purple.shade200,
    slotColors: [
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ],
  );
}
