import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamba/providers/theme_provider.dart';
import 'package:scamba/providers/filter_provider.dart';
import 'package:scamba/providers/conversation_provider.dart';
import '../screens/about_screen.dart';
import '../screens/home_screen.dart';
import '../screens/favorites_screen.dart';


class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final filterProvider = Provider.of<FilterProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    // Use your specified color for dark mode
    final accentColor = const Color(0xFF85BBD9);
    
    return Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Square corners
      ),
      backgroundColor: isDarkMode ? Color(0xFF23272A) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal header with X button
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, 
                    size: 24, 
                    color: isDarkMode ? Colors.white : Colors.black54,
                  ),
                  splashRadius: 24,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Main menu options group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Archive Option
                  _buildMenuItem(
  context,
  icon: Icons.archive_outlined,
  title: 'Archived',
  color: isDarkMode ? Colors.white : Colors.black54,
  isDarkMode: isDarkMode,
  onTap: () {
    Navigator.pop(context);
    // Find the nearest HomeScreenState and call its method
    final homeState = context.findAncestorStateOfType<HomeScreenState>();
    if (homeState != null) {
      homeState.openArchivedScreen();
    }
  },
),
                  
                  const SizedBox(height: 4),
                  
                  // Recently Deleted Option
                  _buildMenuItem(
  context,
  icon: Icons.delete_outline,
  title: 'Recently Deleted',
  color: isDarkMode ? Colors.white : Colors.black54,
  isDarkMode: isDarkMode,
  onTap: () {
    Navigator.pop(context);
    // Find the nearest HomeScreenState and call its method
    final homeState = context.findAncestorStateOfType<HomeScreenState>();
    if (homeState != null) {
      homeState.openDeletedScreen();
    }
  },
),
                  
                  const SizedBox(height: 4),
                  
                  // Mark All as Read Option
                  // In your HamburgerMenu class, modify the onTap for "Mark All as Read"
_buildMenuItem(
  context,
  icon: Icons.mark_email_read_outlined,
  title: 'Mark All as Read',
  color: isDarkMode ? Colors.white : Colors.black54,
  isDarkMode: isDarkMode,
  onTap: () {
    // Call the markAllAsRead method
    Provider.of<ConversationProvider>(context, listen: false).markAllAsRead();
    
    // Show a snackbar to confirm the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All messages marked as read'),
        duration: Duration(seconds: 2),
        backgroundColor: isDarkMode ? Color(0xFF85BBD9) : Colors.blue,
      ),
    );
    
    // Close the drawer
    Navigator.pop(context);
  },
),
                  
                  const SizedBox(height: 4),
                  
                  // Favorites Option
                  _buildMenuItem(
  context,
  icon: Icons.favorite_border,
  title: 'Favorites',
  color: isDarkMode ? Colors.white : Colors.black54,
  isDarkMode: isDarkMode,
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  },
),


                  const SizedBox(height: 4),

                  _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  color: isDarkMode ? Colors.white : Colors.black54,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 0.5, color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
            const SizedBox(height: 16),
            
            // Settings options group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Ham Messages Toggle
                  _buildSwitchItem(
                    context,
                    title: 'Filter Ham Messages',
                    value: filterProvider.filterHamMessages,
                    onChanged: (value) => filterProvider.toggleFilter(value),
                    activeColor: accentColor,
                    isDarkMode: isDarkMode,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Dark Mode Toggle
                  _buildSwitchItem(
                    context,
                    title: 'Dark Mode',
                    value: isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(value),
                    activeColor: accentColor,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Custom menu item with hover effect
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: isDarkMode ? color.withAlpha(26) : null, // 0.1 * 255 = 25.5, rounded to 26
        splashColor: isDarkMode ? color.withAlpha(26) : null, // 0.2 * 255 ≈ 26

        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: color, // Using your accent color
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Custom switch item with better dark mode visibility
  Widget _buildSwitchItem(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required bool isDarkMode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDarkMode ? Colors.white : Colors.white,
          activeTrackColor: activeColor,
          inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.white,
          inactiveTrackColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
        ),
      ],
    );
  }
}