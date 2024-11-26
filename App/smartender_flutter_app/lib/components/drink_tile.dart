import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/config/constants.dart';

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
      padding: EdgeInsets.all(horizontalPadding),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 80),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: defaultBorderRadius,
          ),
          side: const BorderSide(color: Colors.black),
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Expanded(
              flex: 6,
              child: Center(
                child: Image.asset(
                  imagePath,
                  scale: 5,
                ),
              ),
            ),
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
