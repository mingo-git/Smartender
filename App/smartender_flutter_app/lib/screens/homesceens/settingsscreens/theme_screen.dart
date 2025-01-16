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

  void _setTheme(ThemeProvider themeProvider, String theme) async {
    switch (theme) {
      case 'Light':
        themeProvider.isDarkMode = false;
        break;
      case 'Dark':
        themeProvider.isDarkMode = true;
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
          icon: Icon(Icons.arrow_back, color: theme.tertiaryColor, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Theme",
          style: TextStyle(
            fontSize: 24,
            color: theme.tertiaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Toggle für Systemthema
          SwitchListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                "Use System Theme",
                style: TextStyle(
                  fontSize: 18,
                  color: theme.tertiaryColor, // Textfarbe aus Theme
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
                  final brightness = WidgetsBinding.instance.window.platformBrightness;
                  themeProvider.updateThemeFromSystem(brightness);
                }
              });
            },
            activeColor: theme.tertiaryColor, // Farbe des Toggle-Buttons, wenn aktiv
            inactiveThumbColor: theme.tertiaryColor, // Farbe des Toggle-Buttons, wenn inaktiv
            inactiveTrackColor: theme.primaryColor,
          ),


          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16.0),
              childAspectRatio: 0.7,
              children: [
                _buildThemeTile("Light", "lib/images/screen.png", theme,
                    CustomTheme.lightTheme),
                _buildThemeTile("Dark", "lib/images/screen_dark.png", theme,
                    CustomTheme.darkTheme),
/*                _buildThemeTile("Sommer", "lib/images/themes/screen.png", theme,
                    CustomTheme.lightTheme),
                _buildThemeTile("Crazy", "lib/images/themes/screen.png", theme,
                    CustomTheme.lightTheme),*/
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
          : () {
        final themeProvider =
        Provider.of<ThemeProvider>(context, listen: false);
        _setTheme(themeProvider, themeName);
      },
      child: Opacity(
        opacity: useSystemTheme ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: defaultBorderRadius,
            border: Border.all(
              color: theme.tertiaryColor,
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
                      color: theme.tertiaryColor,
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: theme.backgroundColor,
                      ),
                    ),
                  ),
                ),
              ),
              // Hintergrund und Titel
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: tileTheme.backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24.0),
                  ),
                ),
                alignment: Alignment.center,
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  themeName,
                  style: TextStyle(
                    color: tileTheme.primaryFontColor,
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
