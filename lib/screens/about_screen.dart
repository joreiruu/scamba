import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamba/providers/theme_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('About', 
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDarkMode ? Color(0xFF23272A) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: isDarkMode ? Color(0xFF23272A) : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo image
              Center(
                child: Image.asset(
                  'assets/scamba_logo.png',
                  height: 120,
                  width: 120,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // SCAMBA title with your specified styling
              Text(
                'SCAMBA',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'Montserrat',
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App description
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
              
              const SizedBox(height: 16),

              Text(
                'SCAMBA: A Deep Learning-Based Android Spam Classifier for Monolingual and Code-Switched SMS in the Philippines\n\n'
                'An Undergraduate Thesis\n'
                'Presented to the Faculty of Computer Science Department\n'
                'Bicol University College of Science\n'
                'Legazpi City\n'
                'In Partial Fulfillment of the Requirements for the Degree of\n'
                'Bachelor of Science in Computer Science\n\n'
                'By:\n'
                'Leandro S. Abardo\n'
                'Nickol Jairo B. Belgica\n'
                'Joriel O. Espinocilla\n\n'
                'SCAMBA is an Android-based SMS spam classification system that aims to improve mobile security by filtering spam messages in real-time. SCAMBA uses advanced deep learning techniques to detect spam in monolingual and code-switched texts in English and Filipino. The application offers users a straightforward experience, ensuring that unwanted and possibly harmful SMS messages are accurately classified.\n\n'
                'Objectives of the Project:\n'
                '• To build the training datasets from various sources\n'
                '• To execute and evaluate different deep learning models using metrics such as accuracy, precision, recall, and F1-score\n'
                '• To integrate the best deep learning model in the Android prototype messaging application for real-time SMS spam classification\n\n'
                'Scope and Limitations:\n'
                'SCAMBA focuses on SMS spam identification in the Philippine linguistic context, which includes English, Filipino, and code-switched texts. It uses deep learning models trained on various datasets to improve classification accuracy. The application is designed for real-time classification but does not include further spam filtering features such as categorizing distinct spam types or resolving ethical concerns about data privacy.',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),

              const SizedBox(height: 24),
              
              // Divider
              Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
              
              const SizedBox(height: 16),
              
              // Footer text
              Text(
  'SCAMBA | All Rights Reserved',
  style: TextStyle(
    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
    fontSize: 14,
  ),
  textAlign: TextAlign.center,
),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
  
}