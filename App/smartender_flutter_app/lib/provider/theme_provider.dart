import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/custom_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _useSystemTheme = true;
  CustomTheme _currentTheme = CustomTheme.lightTheme;

  ThemeProvider() {
    _loadThemePreferences();
  }

  // Getter für das aktuelle Theme
  CustomTheme get currentTheme => _currentTheme;

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  // Setter für Dark Mode
  set isDarkMode(bool value) {
    _isDarkMode = value;
    _currentTheme = value ? CustomTheme.darkTheme : CustomTheme.lightTheme;
    _saveThemePreferences();
    notifyListeners();
  }

  // Setter für System Theme
  set useSystemTheme(bool value) {
    _useSystemTheme = value;
    if (value) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      updateThemeFromSystem(brightness);
    }
    _saveThemePreferences();
    notifyListeners();
  }

  // Aktualisiere das aktuelle Thema basierend auf dem Systemthema
  void updateThemeFromSystem(Brightness brightness) {
    if (_useSystemTheme) {
      isDarkMode = (brightness == Brightness.dark);
    }
  }

  // Methode zum Wechseln zu einem benutzerdefinierten Theme
  void setCustomTheme(CustomTheme customTheme) {
    _currentTheme = customTheme;
    _useSystemTheme = false;
    _saveThemePreferences(customThemeName: _getCustomThemeName(customTheme));
    notifyListeners();
  }

  // Lade Theme-Präferenzen aus SharedPreferences
  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    if (_useSystemTheme) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      updateThemeFromSystem(brightness);
    } else {
      final themeName = prefs.getString('selectedTheme') ?? 'Light';
      switch (themeName) {
        case 'Dark':
          _currentTheme = CustomTheme.darkTheme;
          break;
        default:
          _currentTheme = CustomTheme.lightTheme;
      }
    }
    notifyListeners();
  }

  // Speichere Theme-Präferenzen in SharedPreferences
  Future<void> _saveThemePreferences({String? customThemeName}) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('useSystemTheme', _useSystemTheme);
    prefs.setBool('isDarkMode', _isDarkMode);
    if (!_useSystemTheme && customThemeName != null) {
      prefs.setString('selectedTheme', customThemeName);
    }
  }

  // Hilfsmethode: Gibt den Namen des benutzerdefinierten Themes zurück
  String _getCustomThemeName(CustomTheme theme) {
    if (theme == CustomTheme.lightTheme) return 'Light';
    if (theme == CustomTheme.darkTheme) return 'Dark';
    return 'Custom';
  }
}
