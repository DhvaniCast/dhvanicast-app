import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a1a), Color(0xFF2a2a2a)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle('Need Help?'),
              const SizedBox(height: 8),
              _buildParagraph(
                'We\'re here to assist you! Choose from the options below to get support.',
              ),
              const SizedBox(height: 32),

              // Contact Options
              _buildContactCard(
                context,
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@dhvanicast.com',
                color: const Color(0xFF00ff88),
                onTap: () => _openEmailApp(context),
              ),
              const SizedBox(height: 16),

              _buildContactCard(
                context,
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                subtitle: 'Help us improve by reporting issues',
                color: Colors.orangeAccent,
                onTap: () => _showReportDialog(context, 'Bug Report'),
              ),
              const SizedBox(height: 16),

              _buildContactCard(
                context,
                icon: Icons.lightbulb_outline,
                title: 'Feature Request',
                subtitle: 'Suggest new features or improvements',
                color: Colors.blueAccent,
                onTap: () => _showReportDialog(context, 'Feature Request'),
              ),
              const SizedBox(height: 16),

              _buildContactCard(
                context,
                icon: Icons.payment_outlined,
                title: 'Billing Support',
                subtitle: 'Issues with payments or subscriptions',
                color: Colors.purpleAccent,
                onTap: () => _showReportDialog(context, 'Billing Issue'),
              ),
              const SizedBox(height: 16),

              _buildContactCard(
                context,
                icon: Icons.shield_outlined,
                title: 'CSAE Reporting',
                subtitle: 'Child Safety and Exploitation reporting',
                color: Colors.redAccent,
                onTap: () => _openChildSafetyUrl(context),
              ),
              const SizedBox(height: 32),

              // FAQ Section
              _buildSectionTitle('Frequently Asked Questions'),
              const SizedBox(height: 16),

              _buildFAQItem(
                'How do I create a private frequency?',
                'Go to Radio tab → Tap "+" button → Select "Private" → Set your password and share with trusted contacts.',
              ),
              const SizedBox(height: 12),

              _buildFAQItem(
                'Can I delete my account?',
                'Yes. Go to Profile → Settings → Delete Account. Your data will be permanently removed within 30 days.',
              ),
              const SizedBox(height: 12),

              _buildFAQItem(
                'How do refunds work?',
                'Refunds are available for duplicate payments, unresolved technical issues, or unactivated services. Check our Refund Policy for details.',
              ),
              const SizedBox(height: 12),

              _buildFAQItem(
                'Is my data secure?',
                'Yes. We use industry-standard encryption and security protocols to protect your data. Read our Privacy Policy for more information.',
              ),
              const SizedBox(height: 12),

              _buildFAQItem(
                'How do I update my profile?',
                'Go to Profile → Edit your name, state, or mobile number → Tap "Save Changes".',
              ),
              const SizedBox(height: 32),

              // App Info
              _buildSectionTitle('App Information'),
              const SizedBox(height: 12),
              _buildInfoRow('Version', '1.0.0'),
              _buildInfoRow('Last Updated', 'December 2025'),
              _buildInfoRow('Platform', 'Android & iOS'),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF00ff88),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.white60),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withOpacity(0.3),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: Color(0xFF00ff88),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white60),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00ff88),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openEmailApp(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@dhvanicast.com',
      query: 'subject=Support Request&body=Hello DhvaniCast Support Team,\n\n',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // If email app is not available, copy to clipboard as fallback
        _copyToClipboard(
          context,
          'support@dhvanicast.com',
          'Email copied to clipboard',
        );
      }
    } catch (e) {
      _copyToClipboard(
        context,
        'support@dhvanicast.com',
        'Email copied to clipboard',
      );
    }
  }

  Future<void> _openChildSafetyUrl(BuildContext context) async {
    final Uri childSafetyUri = Uri.parse('https://dhvanicast.com/child-safety');

    try {
      if (await canLaunchUrl(childSafetyUri)) {
        await launchUrl(childSafetyUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the URL'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening child safety page'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showReportDialog(BuildContext context, String type) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: Text(type, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please describe your $type in detail:',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type here...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00ff88)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ff88),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$type submitted. We\'ll get back to you soon!',
                    ),
                    backgroundColor: const Color(0xFF00ff88),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
