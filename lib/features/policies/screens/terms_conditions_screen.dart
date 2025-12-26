import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
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
              _buildTitle('DhvaniCast – Terms & Conditions'),
              const SizedBox(height: 12),
              _buildParagraph(
                'Welcome to DhvaniCast. By accessing or using our internet-based radio and global-connect platform, you agree to be bound by these Terms and Conditions. Please read them carefully.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('1. Acceptance of Terms'),
              _buildParagraph(
                'By creating an account or using DhvaniCast services, you acknowledge that you have read, understood, and agree to these Terms & Conditions, as well as our Privacy Policy and Refund Policy.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('2. User Eligibility'),
              _buildParagraph(
                '• You must be at least 18 years old to use DhvaniCast.\n'
                '• You are responsible for maintaining the confidentiality of your account credentials.\n'
                '• You agree to provide accurate and complete information during registration.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('3. Acceptable Use'),
              _buildParagraph(
                'You agree NOT to:\n\n'
                '• Use the platform for any illegal or unauthorized purpose\n'
                '• Transmit harmful, offensive, or inappropriate content\n'
                '• Harass, threaten, or impersonate other users\n'
                '• Attempt to hack, disrupt, or compromise platform security\n'
                '• Share your account with others\n'
                '• Use automated bots or scripts to access the service',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('4. User Content'),
              _buildParagraph(
                '• You retain ownership of content you create (voice messages, profile information).\n'
                '• By using DhvaniCast, you grant us a license to store, process, and transmit your content as necessary to provide services.\n'
                '• You are solely responsible for the content you share.\n'
                '• We reserve the right to remove content that violates these terms.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('5. Premium Services & Payments'),
              _buildParagraph(
                '• Some features require a paid subscription.\n'
                '• All payments are processed securely through third-party payment gateways.\n'
                '• Subscription fees are non-refundable except as stated in our Refund Policy.\n'
                '• We reserve the right to change pricing with prior notice.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('6. Service Availability'),
              _buildParagraph(
                '• DhvaniCast operates on an "as is" and "as available" basis.\n'
                '• We do not guarantee uninterrupted or error-free service.\n'
                '• Scheduled maintenance may cause temporary service disruptions.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('7. Account Termination'),
              _buildParagraph(
                'We reserve the right to suspend or terminate accounts that:\n\n'
                '• Violate these Terms & Conditions\n'
                '• Engage in fraudulent or abusive behavior\n'
                '• Pose security risks to other users\n\n'
                'You may delete your account at any time through the app settings.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('8. Intellectual Property'),
              _buildParagraph(
                '• DhvaniCast, its logo, and all related trademarks are owned by us.\n'
                '• You may not use our intellectual property without written permission.\n'
                '• The app interface, design, and functionality are protected by copyright.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('9. Limitation of Liability'),
              _buildParagraph(
                'DhvaniCast shall not be liable for:\n\n'
                '• Loss of data or communications\n'
                '• Indirect, incidental, or consequential damages\n'
                '• Service interruptions or technical failures\n'
                '• Actions of other users on the platform',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10. Governing Law'),
              _buildParagraph(
                'These Terms & Conditions are governed by the laws of India. Any disputes shall be subject to the jurisdiction of Indian courts.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('11. Changes to Terms'),
              _buildParagraph(
                'We may update these Terms & Conditions from time to time. Continued use of DhvaniCast after changes constitutes acceptance of the updated terms.',
              ),
              const SizedBox(height: 20),

              // Clickable URL to full terms
              Center(
                child: InkWell(
                  onTap: () async {
                    final url = Uri.parse(
                      'https://dhvanicast.com/terms-of-use',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ff88).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00ff88),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.open_in_new,
                          color: Color(0xFF00ff88),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'View Complete Terms of Use',
                          style: TextStyle(
                            color: Color(0xFF00ff88),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
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
}
