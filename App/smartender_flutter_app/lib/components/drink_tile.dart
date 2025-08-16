// lib/components/drink_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import '../provider/theme_provider.dart';

class DrinkTile extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isAlcoholic;
  final VoidCallback? onTap;

  const DrinkTile({
    Key? key,
    required this.name,
    required this.imagePath,
    required this.isAlcoholic,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: theme.tertiaryColor,
          backgroundColor: theme.primaryColor,
          minimumSize: const Size(double.infinity, 80),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
          side: BorderSide(color: theme.tertiaryColor),
        ),
        child: Column(
          children: [
            // 1) Kopfzeile (Icon oder Platzhalter, um Konsistenz zu gewährleisten)
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, left: 0),
                child: isAlcoholic
                    ? Icon(
                  Icons.eighteen_up_rating_outlined,
                  color: theme.falseColor,
                  size: 28,
                )
                    : const SizedBox(
                  width: 28,
                  height: 28,
                ), // Platzhalter mit gleicher Größe wie das Icon
              ),
            ),

            // 2) Bild
            Expanded(
              flex: 6,
              child: Center(
                child: Image.asset(
                  imagePath,
                  scale: 5,
                ),
              ),
            ),

            // 3) Name
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
