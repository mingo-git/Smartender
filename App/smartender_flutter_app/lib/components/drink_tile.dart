import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';

import '../provider/theme_provider.dart';

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
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Padding(
      padding: EdgeInsets.all(1),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: theme.tertiaryColor,
          backgroundColor: theme.primaryColor,
          minimumSize: const Size(double.infinity, 80),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: defaultBorderRadius,
          ),
          side: BorderSide(color: theme.tertiaryColor),
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
