import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
              _buildTitle('DhvaniCast – Privacy Policy'),
              const SizedBox(height: 12),
              _buildParagraph(
                'At DhvaniCast, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy outlines how we collect, use, and safeguard your data when you use our internet-based radio and global-connect platform.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('1. Information We Collect'),
              _buildParagraph(
                'We collect the following types of information:\n\n'
                '• Personal Information: Name, mobile number, email address, and state/location when you register or update your profile.\n\n'
                '• Usage Data: Information about how you use the app, including features accessed, frequencies joined, and communication logs.\n\n'
                '• Device Information: Device type, operating system, unique device identifiers, and network information.\n\n'
                '• Audio Data: Voice messages and audio communications when you use our radio features.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('2. How We Use Your Information'),
              _buildParagraph(
                'Your information is used to:\n\n'
                '• Provide and improve our services\n'
                '• Authenticate and secure your account\n'
                '• Enable communication features\n'
                '• Send notifications and updates\n'
                '• Analyze app usage and performance\n'
                '• Comply with legal obligations',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('3. Data Sharing and Disclosure'),
              _buildParagraph(
                'We do not sell your personal information. We may share data only in these circumstances:\n\n'
                '• With your explicit consent\n'
                '• To comply with legal requirements\n'
                '• To protect our rights and prevent fraud\n'
                '• With service providers who assist in app operations (under strict confidentiality agreements)',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('4. Data Security'),
              _buildParagraph(
                'We implement industry-standard security measures including:\n\n'
                '• Encrypted data transmission\n'
                '• Secure authentication protocols\n'
                '• Regular security audits\n'
                '• Access controls and monitoring',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('5. Your Rights'),
              _buildParagraph(
                'You have the right to:\n\n'
                '• Access your personal information\n'
                '• Update or correct your data\n'
                '• Delete your account and associated data\n'
                '• Opt-out of promotional communications\n'
                '• Request data portability',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('6. Data Retention'),
              _buildParagraph(
                'We retain your personal information only as long as necessary to provide services or as required by law. Upon account deletion, your data will be permanently removed within 30 days.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('7. Children\'s Privacy'),
              _buildParagraph(
                'DhvaniCast is intended for users aged 18 and above. We do not knowingly collect information from children under 18.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('8. Changes to Privacy Policy'),
              _buildParagraph(
                'We may update this Privacy Policy from time to time. Changes will be notified through the app or via email.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('9. Contact Us'),
              _buildParagraph(
                'For privacy-related questions or concerns:\n\n'
                'Email: support@dhvanicast.com\n'
                'In-App: Help & Support section',
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('For More Info Visit'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () =>
                    _launchURL('https://dhvanicast.com/privacy-policy'),
                child: const Text(
                  'https://dhvanicast.com/privacy-policy',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF00ff88),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF00ff88),
                  ),
                ),
              ),
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
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF00ff88),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
