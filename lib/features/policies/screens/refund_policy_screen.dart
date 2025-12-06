import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Refund Policy',
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
              _buildTitle('DhvaniCast – Refund Policy'),
              const SizedBox(height: 12),
              _buildParagraph(
                'At DhvaniCast, we aim to provide a seamless, high-quality communication experience through our internet-based radio and global-connect platform. This Refund Policy explains the conditions under which refunds may be issued for our digital services or subscriptions.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('1. Digital Service Nature'),
              _buildParagraph(
                'DhvaniCast operates entirely online. All features, premium tools, and subscriptions are digital services and do not involve any physical product or shipment.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('2. Refund Eligibility'),
              _buildParagraph(
                'Refunds are handled carefully to prevent misuse. You may be eligible for a refund only under the following conditions:',
              ),
              const SizedBox(height: 12),

              _buildSubsectionTitle('a. Duplicate Payment'),
              _buildParagraph(
                'If you were charged twice for the same subscription or feature, we will issue a full refund after verification.',
              ),
              const SizedBox(height: 12),

              _buildSubsectionTitle('b. Technical Issues (Unresolved)'),
              _buildParagraph(
                'If you experience a technical problem that prevents you from using a paid feature and our support team cannot resolve it within 72 hours, you may request a refund.',
              ),
              const SizedBox(height: 12),

              _buildSubsectionTitle('c. Service Not Activated'),
              _buildParagraph(
                'If a paid feature or premium access was never activated on your account despite successful payment, a refund will be issued.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('3. Non-Refundable Situations'),
              _buildParagraph(
                'Refunds will not be provided in the following cases:\n\n'
                '• Change of mind after purchase\n'
                '• Partial usage of a subscription\n'
                '• Temporary outages or server maintenance\n'
                '• User error or incorrect account details during purchase\n'
                '• Violation of DhvaniCast\'s terms leading to account restrictions\n\n'
                'Once digital services have been accessed or used, they are considered consumed and cannot be refunded.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('4. Refund Request Process'),
              _buildParagraph(
                'To submit a refund request, please contact our support team through:\n\n'
                '• In-App Support → Help → Billing\n'
                '• Email: support@dhvanicast.com\n\n'
                'Please provide:\n'
                '• Registered mobile number / email\n'
                '• Payment ID / Transaction ID\n'
                '• Description of the issue\n\n'
                'Refund evaluations typically take 3–7 working days.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('5. Refund Mode & Timeline'),
              _buildParagraph(
                '• Approved refunds will be processed back to the original payment method.\n'
                '• Refund completion may take 5–10 working days, depending on the bank or payment provider.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('6. Subscription Cancellations'),
              _buildParagraph(
                '• You may cancel your DhvaniCast subscription anytime.\n'
                '• However, cancellation does not generate an automatic refund.\n'
                '• Your premium access will continue until the end of the billing period.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('7. Policy Changes'),
              _buildParagraph(
                'DhvaniCast reserves the right to update or modify this Refund Policy at any time. Changes will be posted within the app or on our website.',
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('For More Info Visit'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _launchURL('https://dhvanicast.com/refund-policy'),
                child: const Text(
                  'https://dhvanicast.com/refund-policy',
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

  Widget _buildSubsectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF00ff88),
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
