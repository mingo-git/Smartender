import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/provider/theme_provider.dart';

class ManageDrinksScreen extends StatefulWidget {
  const ManageDrinksScreen({Key? key}) : super(key: key);

  @override
  State<ManageDrinksScreen> createState() => _ManageDrinksScreenState();
}

class _ManageDrinksScreenState extends State<ManageDrinksScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 35, color: theme.tertiaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Manage Drinks",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: theme.tertiaryColor),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Hier alles weitere implementieren
          ],
        ),
      ),
    );
  }
}
