import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamba/providers/theme_provider.dart';

class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to get and change the theme mode
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Remove default padding
        children: [
          // Drawer header with a title
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue), // Background color
            child: Text(
              'Menu', 
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),

          // Home button that closes the drawer when tapped
          ListTile(
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),

          // Toggle switch for dark mode
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode'),
                Switch(
                  value: themeProvider.themeMode == ThemeMode.dark, // Check if dark mode is active
                  onChanged: (value) {
                    themeProvider.toggleTheme(value); // Toggle theme when switch is changed
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
