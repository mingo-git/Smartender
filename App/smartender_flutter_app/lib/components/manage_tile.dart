import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/provider/theme_provider.dart';

class ManageTile extends StatelessWidget {
  final String name;
  final bool isAlcoholic;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ManageTile({
    Key? key,
    required this.name,
    required this.isAlcoholic,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Container(
      width: double.infinity,
      // Verringerter Abstand zwischen den einzelnen Tiles
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: defaultBorderRadius,
        border: Border.all(color: theme.tertiaryColor),
      ),
      // Höhere Tiles: Vertikales Padding erhöht
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.tertiaryColor,
              ),
            ),
          ),
          // Mehr Abstand zwischen den Icons (Padding von 16 auf 24 erhöht)
          if (isAlcoholic)
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                Icons.eighteen_up_rating_outlined,
                color: theme.falseColor,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: InkWell(
              onTap: onEdit,
              child: Icon(
                Icons.edit,
                color: theme.tertiaryColor,
              ),
            ),
          ),
          InkWell(
            onTap: onDelete,
            child: Icon(
              Icons.delete_forever,
              color: theme.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
