import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamba/providers/theme_provider.dart';
import 'package:scamba/providers/filter_provider.dart'; // ✅ Added FilterProvider import
import 'package:scamba/providers/conversation_provider.dart'; 
import 'screens/splash_screen.dart'; // Import the SplashScreen

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // ✅ Theme Provider
        ChangeNotifierProvider(create: (context) => FilterProvider()), // ✅ Added FilterProvider to manage message filtering
        ChangeNotifierProvider(create: (context) => ConversationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scamba',
      themeMode: themeProvider.themeMode, // Apply ThemeProvider's mode
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
