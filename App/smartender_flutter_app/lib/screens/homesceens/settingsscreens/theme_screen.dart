import 'package:flutter/material.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  Widget _buildThemeTile(String title, Color color) {
    return GestureDetector(
      onTap: () {
        // Theme-Änderungslogik hier einfügen
      },
      child: Container(
        margin: EdgeInsets.all(4.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Theme"),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildThemeTile("Light", Colors.white),
          _buildThemeTile("Dark", Colors.black),
          _buildThemeTile("Blue", Colors.blue),
          _buildThemeTile("Green", Colors.green),
        ],
      ),
    );
  }
}
