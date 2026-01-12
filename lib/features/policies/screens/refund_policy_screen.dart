import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://dhvanicast.com/refund-policy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Refund Policy',
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
              _buildContactCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('9.2 Refund Eligibility Criteria'),
              _buildParagraph(
                'Refunds are granted only in limited circumstances where:',
              ),
              const SizedBox(height: 8),
              _buildBulletPoints([
                'Payment has been successfully completed, and',
                'The purchased service is not delivered due to a verified technical failure attributable solely to Dhvani Cast',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'Refunds are not issued for reasons including, but not limited to:',
              ),
              const SizedBox(height: 8),
              _buildBulletPoints([
                'User dissatisfaction',
                'Accidental purchases',
                'Failure to use the service within the validity period',
                'Issues arising from password sharing or user error',
              ]),
              const SizedBox(height: 20),

              _buildSectionTitle('9.3 Refund Request and Processing'),
              _buildParagraph(
                'Refund requests must be submitted within 24 hours of the transaction and must include relevant transaction details, such as the payment reference number and account information.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'All refund requests are reviewed on a case-by-case basis. If approved, refunds are processed through the original payment method in accordance with Razorpay\'s processing timelines and applicable regulations.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast reserves the right to deny refund requests that do not meet the eligibility criteria or where misuse or abuse is identified.',
              ),
              const SizedBox(height: 32),

              _buildWebsiteButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refund Policy',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00ff88),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Effective Date: 31 December 2025\nJurisdiction: India',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
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
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.white70, fontSize: 13),
              children: [
                TextSpan(
                  text: 'General Support & Enquiries:\n',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: 'support@dhvanicast.com',
                  style: TextStyle(
                    color: Color(0xFF00ff88),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.white70, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Child Safety & CSAE Reporting:\n',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: 'csae@dhvanicast.com',
                  style: TextStyle(
                    color: Color(0xFF00ff88),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
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
      style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white70),
      textAlign: TextAlign.justify,
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
                    '• ',
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

  Widget _buildWebsiteButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _launchWebsite,
        icon: const Icon(Icons.open_in_browser),
        label: const Text('View Full Refund Policy on Website'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: const Color(0xFF00ff88),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
