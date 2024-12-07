import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';
import '../../../config/custom_theme.dart';
import '../../../provider/theme_provider.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  _ThemeScreenState createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  bool useSystemTheme = true;

  @override
  void initState() {
    super.initState();
    _loadSystemThemePreference();
  }

  Future<void> _loadSystemThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
    });
  }

  Future<void> _saveSystemThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', value);
  }

  void _setTheme(String theme) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    switch (theme) {
      case 'Light':
        themeProvider.isDarkMode = false;
        break;
      case 'Dark':
        themeProvider.isDarkMode = true;
        break;
      case 'Sommer':
        themeProvider.setCustomTheme(CustomTheme.sommerTheme);
        break;
      case 'Crazy':
        themeProvider.setCustomTheme(CustomTheme.crazyTheme);
        break;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryFontColor, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Theme",
          style: TextStyle(
            fontSize: 24,
            color: theme.primaryFontColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20,),
          // Toggle für Systemthema
          SwitchListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 10.0), // Verschiebt den Text um 10 Pixel nach rechts
              child: Text(
                "Use System Theme",
                style: TextStyle(
                  fontSize: 18,
                  color: theme.primaryFontColor,
                ),
              ),
            ),
            value: useSystemTheme,
            onChanged: (value) {
              setState(() {
                useSystemTheme = value;
                _saveSystemThemePreference(value);
                themeProvider.useSystemTheme = value;
                if (value) {
                  final brightness =
                      WidgetsBinding.instance.window.platformBrightness;
                  themeProvider.updateThemeFromSystem(brightness);
                }
              });
            },
          ),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16.0),
              childAspectRatio: 0.7,
              children: [
                _buildThemeTile("Light", "lib/images/themes/screen.png", theme,
                    CustomTheme.lightTheme),
                _buildThemeTile("Dark", "lib/images/themes/screen.png", theme,
                    CustomTheme.darkTheme),
                _buildThemeTile("Sommer", "lib/images/themes/screen.png", theme,
                    CustomTheme.lightTheme),
                _buildThemeTile("Crazy", "lib/images/themes/screen.png", theme,
                    CustomTheme.lightTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
      String themeName,
      String imagePath,
      CustomTheme theme,
      CustomTheme tileTheme,
      ) {
    return GestureDetector(
      onTap: useSystemTheme
          ? null
          : () => _setTheme(themeName), // Nur anklickbar, wenn "Use System Theme" deaktiviert ist
      child: Opacity(
        opacity: useSystemTheme ? 0.5 : 1.0, // Kacheln ausgrauen, wenn "Use System Theme" aktiv ist
        child: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: defaultBorderRadius, // Verwende den defaultBorderRadius
            border: Border.all(
              color: Colors.black, // Schwarzer Rahmen
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bild
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              // Hintergrund und Titel
              Container(
                height: 50, // Feste Höhe für den Titelbereich
                decoration: BoxDecoration(
                  color: tileTheme.backgroundColor, // Hintergrundfarbe aus dem Theme
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24.0), // Nur unten abrunden
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  themeName,
                  style: TextStyle(
                    color: tileTheme.primaryFontColor, // Schriftfarbe aus dem Theme
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
