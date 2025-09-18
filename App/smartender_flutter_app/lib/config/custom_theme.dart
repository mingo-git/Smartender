import 'package:flutter/material.dart';

class CustomTheme {
  final Color backgroundColor;
  final Color popupBackgroundColor;
  final Color fadeOutBackground0;
  final Color fadeOutBackground1;
  final Color primaryColor;
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
/*    secondaryColor: const Color(0xFFC3C3C3),*/
    tertiaryColor: Colors.black,
    primaryFontColor: Colors.black,
    secondaryFontColor: Colors.white,
    trueColor: const Color(0xF461874E),
    falseColor: const Color(0xF49A242B),
    uncertainColor: const Color(0xFFCCCCCC),
    hintTextColor: const Color(0xd03c3c3c),
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
    backgroundColor: const Color(0xFF121212),
    popupBackgroundColor: const Color(0xFF9A2323),
    fadeOutBackground0: const Color(0x7B121212),
    fadeOutBackground1: const Color(0x2121212),
    primaryColor: const Color(0xff373737),
    //primaryColor: Color(0xff3f3f3f),
/*    secondaryColor: Color(0xFFE30000),*/
    tertiaryColor: const Color(0xffc4dfb9),
    //tertiaryColor: Color(0xffbed8b3),
    primaryFontColor: Colors.white,
    secondaryFontColor: Colors.black,
    trueColor: const Color(0xF4C4FAAD),
    falseColor: const Color(0xF4FB4750),
    uncertainColor: Colors.grey,
    hintTextColor: const Color(0x8CB6EF93),
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

}
