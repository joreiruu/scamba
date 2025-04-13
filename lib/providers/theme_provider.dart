import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode; // Getter to access the current theme mode

  ThemeProvider() {
    _loadTheme(); // Load saved theme preference when the provider is initialized
  }

  // Toggles between light and dark mode and saves the preference
  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify UI about theme change

    // Save user preference in local storage
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDark);
  }

  // Loads the saved theme preference from local storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false; // Default to false (light mode)
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Update UI with loaded theme
  }
}
