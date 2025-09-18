import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/theme_provider.dart';

class ManageRolesScreen extends StatelessWidget {
  const ManageRolesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 35),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
            "Manage Roles",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text("Connected to Beispiel Mac-Adresse"),
      ),
    );
  }
}
