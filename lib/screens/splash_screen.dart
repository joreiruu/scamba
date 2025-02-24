import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the HomeScreen to navigate after the splash

// SplashScreen StatefulWidget to manage animations and navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Animation controller to handle the fade-in effect
  late Animation<double> _fadeAnimation; // Animation for logo fading effect

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with a duration of 1.5 seconds
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this, // Uses SingleTickerProviderStateMixin for efficient animation handling
    );

    // Defines a fade-in animation from 0 (transparent) to 1 (fully visible)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth transition effect
      ),
    );

    _controller.forward(); // Start the fade-in animation
    _navigateToHome(); // Start the delay and navigate to HomeScreen
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the animation controller to free up resources
    super.dispose();
  }

  // Function to delay for 2 seconds before navigating to the home screen
  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return; // Ensures the widget is still in the widget tree

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()), // Navigate to HomeScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detect the current system theme (Light or Dark mode)
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white, // Adaptive background color
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation, // Apply fade animation to the content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center items on the screen
            children: [
              // Container for the logo with a circular shadow effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
  color: isDarkMode 
      ? Colors.red.withAlpha((0.3 * 255).toInt()) // Red glow in dark mode
      : Colors.blue.withAlpha((0.3 * 255).toInt()), // Blue glow in light mode
  blurRadius: 20, // Soft blurred glow effect
  spreadRadius: 5, // Slight expansion of glow
),

                  ],
                ),
                child: Image.asset(
                  'assets/scamba_logo.png', // Load the logo from assets
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain, // Keep original aspect ratio
                ),
              ),
              const SizedBox(height: 20), // Add spacing below the logo

              // App name text with adaptive color
              Text(
                'SCAMBA',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black, // Text color adapts to theme
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'Montserrat', // Custom font
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
