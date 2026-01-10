import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPolicyScreen extends StatelessWidget {
  const PaymentPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF00ff88),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetaInfo(
                'Effective Date: 31 December 2025\nJurisdiction: India',
              ),
              const SizedBox(height: 20),
              _buildContactBox(),
              const SizedBox(height: 20),
              _buildSectionTitle(
                '8.1 Payment Processing, Pricing, and Disclosure',
              ),
              _buildParagraph(
                'Dhvani Cast offers certain paid features, including private frequency access, which are processed exclusively through Razorpay, a regulated Indian payment gateway.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Before any purchase is completed, users are clearly informed of:',
              ),
              _buildBulletPoints([
                'The price of the service',
                'The duration and nature of the service',
                'Any applicable terms or limitations',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'Charges are applied only after successful transaction confirmation from Razorpay. Dhvani Cast does not process payments directly and does not store sensitive payment credentials such as card numbers, CVV codes, or UPI identifiers.',
              ),
              // ...existing code...
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff88),
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final url = Uri.parse('https://dhvanicast.com/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visit dhvanicast.com'),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 20),
              _buildSectionTitle('8.2 Fraud Detection and Risk Management'),
              _buildParagraph(
                'To protect users and the platform from financial misuse, Dhvani Cast monitors transactions for indicators of fraud, abuse, or unauthorized activity. This may include detecting unusual transaction patterns, repeated failed payment attempts, chargeback abuse, or violations of payment gateway policies.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Where suspicious activity is detected, Dhvani Cast may:',
              ),
              _buildBulletPoints([
                'Temporarily block or cancel transactions',
                'Suspend or restrict associated accounts',
                'Require additional verification',
                'Cooperate with Razorpay, financial institutions, or authorities',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'These measures are implemented to protect legitimate users, ensure compliance with financial regulations, and maintain platform integrity.',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('8.3 User Payment Responsibilities'),
              _buildParagraph('Users are responsible for:'),
              _buildBulletPoints([
                'Reviewing pricing and service details before purchase',
                'Ensuring that payment methods used are authorized and secure',
                'Maintaining the confidentiality of their payment credentials',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast is not responsible for unauthorized transactions resulting from user negligence, compromised payment methods, or third-party access to user accounts.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
    );
  }

  Widget _buildContactBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00ff88).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00ff88), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official Contact Emails',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00ff88),
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            'General Support & Enquiries:',
            'support@dhvanicast.com',
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            'Child Safety & CSAE Reporting:',
            'csae@dhvanicast.com',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String label, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF00ff88),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00ff88),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
    );
  }

  Widget _buildBulletPoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\u2022 ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF00ff88)),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
