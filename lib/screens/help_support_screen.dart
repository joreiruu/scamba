import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@scamba.com',
    );
    
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: isDarkMode ? null : const Color(0xFF85BBD9),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Contact Support'),
              subtitle: const Text('support@scamba.com'),
              onTap: _launchEmail,
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text('FAQs'),
              children: [
                ListTile(
                  title: Text('How does spam detection work?'),
                  subtitle: Text('Our app uses machine learning to analyze message patterns and identify potential spam messages.'),
                ),
                ListTile(
                  title: Text('How to report false positives?'),
                  subtitle: Text('You can mark messages as "Not Spam" by long-pressing the message and selecting the appropriate option.'),
                ),
                ListTile(
                  title: Text('Is my data secure?'),
                  subtitle: Text('Yes, all message processing is done locally on your device. We do not store your messages on our servers.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report a Bug'),
              onTap: _launchEmail,
            ),
          ),
        ],
      ),
    );
  }
}