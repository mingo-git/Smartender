import 'package:flutter/material.dart';

class BottleSlotsScreen extends StatelessWidget {
  const BottleSlotsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Bottle Slots"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(
            5,
                (index) => Column(
              children: [
                Icon(Icons.local_drink, size: 30),
                Text("Bottle ${index + 1}: Vodka"), // Beispieltext
              ],
            ),
          ),
        ),
      ),
    );
  }
}
