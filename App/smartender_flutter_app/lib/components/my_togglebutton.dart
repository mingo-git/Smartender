import 'package:flutter/material.dart';

class MyToggleButton extends StatefulWidget {
  final String onText;
  final String offText;
  final bool initialValue;
  final Function(bool) onToggle;
  final double width;
  final double height;
  final double fontSize; // Variable Schriftgröße

  const MyToggleButton({
    Key? key,
    required this.onText,
    required this.offText,
    required this.initialValue,
    required this.onToggle,
    this.width = 60, // Standardbreite
    this.height = 30, // Standardhöhe
    this.fontSize = 12, // Standardschriftgröße
  }) : super(key: key);

  @override
  _MyToggleButtonState createState() => _MyToggleButtonState();
}

class _MyToggleButtonState extends State<MyToggleButton> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialValue;
  }

  void _toggle() {
    setState(() {
      isOn = !isOn;
    });
    widget.onToggle(isOn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
          color: isOn ? Colors.green : Colors.grey[400],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: isOn ? 10 : null,
              right: isOn ? null : 10,
              child: Text(
                isOn ? widget.onText : widget.offText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize, // Variable Schriftgröße
                ),
              ),
            ),
            AnimatedAlign(
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                width: widget.height * 0.6, // Kreisgröße relativ zur Höhe
                height: widget.height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
