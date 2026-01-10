import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  // Function to launch website URL
  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://dhvanicast.com/terms-of-use');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Use',
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
              // Contact Emails Card
              _buildContactCard(),
              const SizedBox(height: 24),
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
            const SizedBox(height: 8),
            _buildParagraph(
              'By accessing, registering for, or using Dhvani Cast in any manner, you acknowledge that you have read, understood, and agreed to be legally bound by these Terms. If you do not agree with any part of these Terms, you must immediately discontinue use of the Service.',
            ),
              const SizedBox(height: 8),
              _buildParagraph(
                'These Terms constitute a legally binding agreement between you and the operator of Dhvani Cast.',
              ),
              const SizedBox(height: 20),

              // Section 1.2
              _buildSectionTitle(
                '1.2 Eligibility and Age Restriction (Strict 18+ Platform)',
              ),
              _buildParagraph(
                'Dhvani Cast is designed and operated exclusively for adult users.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Only individuals who are 18 years of age or older are permitted to create an account, access frequencies, or use any feature of the platform. There are no teen accounts, no child accounts, and no minor-accessible modes available on Dhvani Cast.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'By registering on the platform, the user explicitly represents and warrants that:',
              ),
              const SizedBox(height: 8),
              _buildBulletPoints([
                'They are at least 18 years old at the time of registration',
                'All information provided during registration is truthful and accurate',
                'They possess the legal capacity to enter into a binding agreement',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'If Dhvani Cast becomes aware, through reports, investigations, or technical detection, that an account belongs to a person under 18 years of age, such account will be immediately suspended or permanently terminated without prior notice. Any associated data may be retained solely for legal and compliance obligations.',
              ),
              const SizedBox(height: 20),

              // Section 1.3
              _buildSectionTitle('1.3 Account Registration and Security'),
              _buildParagraph(
                'To access Dhvani Cast, users must create an account using a valid and active email address. Each user is permitted to maintain only one account unless explicitly authorized by Dhvani Cast.',
              ),
              const SizedBox(height: 8),
              _buildParagraph('Users are solely responsible for:'),
              const SizedBox(height: 8),
              _buildBulletPoints([
                'Maintaining the confidentiality of their login credentials',
                'All activity conducted through their account',
                'Ensuring that their account is not accessed by unauthorized individuals',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast will not be responsible for losses arising from unauthorized access resulting from user negligence, including sharing login details or failing to secure email access.',
              ),
              const SizedBox(height: 20),

              // Section 1.4
              _buildSectionTitle(
                '1.4 User Responsibilities and Acceptable Use',
              ),
              _buildParagraph(
                'Users agree to use Dhvani Cast in a lawful, respectful, and responsible manner. Participation in frequencies requires adherence to community norms, platform rules, and applicable laws.',
              ),
              const SizedBox(height: 8),
              _buildParagraph('Users are responsible for:'),
              const SizedBox(height: 8),
              _buildBulletPoints([
                'Their spoken audio during live communication',
                'Messages sent through chat features',
                'Images shared within frequencies',
                'Conduct toward other users',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'Any misuse of the platform that disrupts communication, harms others, or violates legal standards may result in enforcement action.',
              ),
              const SizedBox(height: 20),

              // Section 1.5
              _buildSectionTitle('1.5 Prohibited Activities'),
              _buildParagraph(
                'To maintain platform integrity and user safety, Dhvani Cast strictly prohibits activities including but not limited to:',
              ),
              const SizedBox(height: 8),
              _buildBulletPoints([
                'Harassment, intimidation, threats, or abusive behavior',
                'Hate speech, discrimination, or demeaning language',
                'Sharing sexually explicit, obscene, or illegal content',
                'Recording, storing, or redistributing live conversations without consent',
                'Impersonation of other users or entities',
                'Automated usage, bots, scraping, or exploitation of platform vulnerabilities',
                'Misuse of private frequencies for illegal or harmful purposes',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'Violations may result in warnings, temporary restrictions, permanent account bans, and reporting to authorities where legally required.',
              ),
              const SizedBox(height: 20),

              // Section 1.6
              _buildSectionTitle('1.6 User Content and License'),
              _buildParagraph(
                'Users retain ownership of any content they create or share on Dhvani Cast. However, by using the Service, users grant Dhvani Cast a limited, non-exclusive, royalty-free license to transmit, host, and display such content solely for the purpose of operating and improving the Service.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'This license does not transfer ownership of user content to Dhvani Cast.',
              ),
              const SizedBox(height: 20),

              // Section 1.7
              _buildSectionTitle('1.7 Suspension and Termination'),
              _buildParagraph(
                'Dhvani Cast reserves the right to suspend or terminate user accounts at its sole discretion when necessary to:',
              ),
              const SizedBox(height: 8),
              _buildBulletPoints([
                'Enforce these Terms',
                'Protect platform safety',
                'Comply with legal obligations',
                'Address repeated or severe violations',
              ]),
              const SizedBox(height: 8),
              _buildParagraph(
                'Termination decisions may be final, especially in cases involving illegal activity or CSAE concerns.',
              ),
              const SizedBox(height: 20),

              // Section 1.8
              _buildSectionTitle('1.8 Disclaimer and Limitation of Liability'),
              _buildParagraph(
                'Dhvani Cast is provided on an "as-is" and "as-available" basis. The platform does not guarantee uninterrupted service, frequency availability, or error-free operation.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast is not liable for user-generated content, user conduct, or interactions between users.',
              ),
              const SizedBox(height: 20),

              // Section 1.9
              _buildSectionTitle('1.9 Governing Law'),
              _buildParagraph(
                'These Terms are governed by the laws of India, including the Information Technology Act, 2000.',
              ),
              const SizedBox(height: 20),

              // Section 1.10
              _buildSectionTitle('1.10 Changes to Terms'),
              _buildParagraph(
                'Dhvani Cast may modify these Terms periodically. Continued use of the platform after changes constitutes acceptance.',
              ),
              const SizedBox(height: 32),

              // Website URL Button at Bottom
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
          'Terms of Use',
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
        label: const Text('View Full Terms on Website'),
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
