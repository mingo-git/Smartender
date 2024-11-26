import 'package:flutter/material.dart';
import 'package:smartender_flutter_app/config/constants.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Language"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildLanguageOption("English"),
            _buildLanguageOption("German"),
            _buildLanguageOption("French"),
            _buildLanguageOption("Spanish"),
            _buildLanguageOption("Italian"),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorderRadius,
          border: Border.all(color: Colors.grey),
        ),
        child: Text(
          language,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
