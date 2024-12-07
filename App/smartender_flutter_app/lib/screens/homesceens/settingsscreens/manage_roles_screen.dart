import 'package:flutter/material.dart';

class ManageRolesScreen extends StatelessWidget {
  const ManageRolesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Manage Roles"),
      ),
      body: Center(
        child: Text("Connected to Beispiel Mac-Adresse"),
      ),
    );
  }
}
