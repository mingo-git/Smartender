import 'package:flutter/material.dart';

class DrinkTile extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback? onTap;

  const DrinkTile({
    Key? key,
    required this.name,
    required this.imagePath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 80),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          side: const BorderSide(color: Colors.black),
        ),
        child: Column(
          children: [
            SizedBox(height: 30,),
            Expanded(
              flex: 6,
              child: Center(
                child: Image.asset(
                  imagePath,
                  scale: 5,
                ),
              ),
            ),
            // Name des Getränks nimmt 30 % der Höhe ein
            Expanded(
              flex: 4,
              child: Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
