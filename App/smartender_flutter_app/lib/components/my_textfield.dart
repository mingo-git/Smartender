import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';

import '../provider/theme_provider.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  }) : super(key: key);

  @override
  _MyTextFieldState createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: defaultBorderRadius,
          border: Border.all(
            color: theme.tertiaryColor, // Rahmenfarbe
          ),
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: theme.hintTextColor),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
            suffixIcon: widget.obscureText
                ? IconButton(
              iconSize: 28, // Größe des Icons anpassen
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: theme.hintTextColor,
              ),
              onPressed: _toggleObscureText,
            )
                : null,
          ),
          style: TextStyle(
            color: theme.tertiaryColor, // Textfarbe auf tertiaryColor setzen
            fontSize: 20,
          ),
          cursorColor: theme.tertiaryColor, // Cursor-Farbe anpassen
        ),
      ),
    );
  }

}
