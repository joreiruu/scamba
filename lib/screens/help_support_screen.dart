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
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Help & Support',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.email_outlined), // Changed to outlined
              title: const Text('Contact Support'),
              children: [
                ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/images/leandro.jpg'),
                      radius: 20,
                    ),
                  ),
                  title: const Text('Leandro Abardo'),
                  subtitle: const Text('leandrosambajon.abardo@bicol-u.edu.ph'),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'leandrosambajon.abardo@bicol-u.edu.ph',
                    );
                    try {
                      await launchUrl(emailUri);
                    } catch (e) {
                      debugPrint('Could not launch email: $e');
                    }
                  },
                ),
                ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/images/nickol.jpg'),
                      radius: 20,
                    ),
                  ),
                  title: const Text('Nickol Jairo Belgica'),
                  subtitle: const Text('nickoljairobarizo.belgica@bicol-u.edu.ph'),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'nickoljairobarizo.belgica@bicol-u.edu.ph',
                    );
                    try {
                      await launchUrl(emailUri);
                    } catch (e) {
                      debugPrint('Could not launch email: $e');
                    }
                  },
                ),
                ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/images/joriel.jpg'),
                      radius: 20,
                    ),
                  ),
                  title: const Text('Joriel Espinocilla'),
                  subtitle: const Text('jorielogayon.espinocilla@bicol-u.edu.ph'),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'jorielogayon.espinocilla@bicol-u.edu.ph',
                    );
                    try {
                      await launchUrl(emailUri);
                    } catch (e) {
                      debugPrint('Could not launch email: $e');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ExpansionTile(
              leading: Icon(Icons.help_outline), // Already outlined
              title: Text('FAQs'),
              children: [
                ListTile(
                  title: Text('How does SCAMBA detect spam messages?'),
                  subtitle: Text('SCAMBA employs a deep learning model trained to analyze SMS content and classify messages as spam or legitimate.'),
                ),
                ListTile(
                  title: Text('Does SCAMBA store my messages?'),
                  subtitle: Text('No. All message processing occurs locally on your device. Your data remains private and is not shared with external parties without consent.'),
                ),
                ListTile(
                  title: Text('How do I report a misclassified message?'),
                  subtitle: Text('Contact our support team using the email addresses provided above. We continuously improve our classification model based on feedback.'),
                ),
                ListTile(
                  title: Text('Can I use SCAMBA without internet?'),
                  subtitle: Text('Yes. SCAMBA supports offline mode with limited functionality. Real-time classification accuracy may be reduced without connection.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ExpansionTile(
              leading: Icon(Icons.info_outline),
              title: Text('Core Features'),
              children: [
                ListTile(
                  title: Text('Spam Classification System'),
                  subtitle: Text('• Spam messages: Marked with a red icon and warning sign\n• Ham messages (legitimate): Marked with a blue icon\n• Message detail view shows a red bubble with confidence bar for spam messages\n• Safe messages appear in a blue bubble'),
                ),
                ListTile(
                  title: Text('Message Management'),
                  subtitle: Text('• Swipe left: Delete a message\n• Swipe right: Archive a message\n• Long press: Select messages for batch actions\n• Tap: Expand message to view full content'),
                ),
                ListTile(
                  title: Text('Navigation & Customization'),
                  subtitle: Text('• Dark/Light Mode: Toggle between themes\n• Offline Mode: Limited functionality available\n• Menu Options: Archive, Recently Deleted, Mark All as Read, Favorites'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}