import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://dhvanicast.com/community-guidelines');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Guidelines',
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
              // Removed duplicate heading from body
              _buildContactCard(),
              const SizedBox(height: 24),
              // ...existing code...
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff88),
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final url = Uri.parse('https://dhvanicast.com/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visit dhvanicast.com'),
                ),
              ),
              const SizedBox(height: 16),
              _buildParagraph(
                'Users are required to behave in a manner that is respectful, lawful, and considerate of others at all times. This applies equally to spoken audio, written messages, shared images, and any other form of interaction available on the platform.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Acceptable conduct includes engaging in conversations respectfully, allowing others to express themselves without intimidation, and refraining from language or behavior that could reasonably be perceived as abusive, threatening, or degrading. Users must recognize that real-time communication amplifies the impact of harmful speech and that spoken words carry the same accountability as written content.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('3.3 Harassment, Abuse, and Hate Speech'),
              _buildParagraph(
                'DC Audio Rooms strictly prohibits harassment, bullying, intimidation, or abuse of any kind. This includes persistent unwanted communication, verbal attacks, threats, humiliation, or coordinated targeting of individuals or groups.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Hate speech and discriminatory behavior are expressly forbidden. Content or conduct that promotes hatred, violence, or exclusion based on race, religion, caste, gender, sexual orientation, nationality, disability, or any protected characteristic will result in immediate enforcement action.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('3.4 Sexual, Violent, and Illegal Content'),
              _buildParagraph(
                'Users must not create, share, or promote sexually explicit, obscene, or pornographic material. This applies to audio discussions, text messages, images, or any indirect references designed to bypass moderation.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Violent, graphic, or disturbing content, including threats of violence or glorification of harm, is prohibited. Similarly, content that promotes or facilitates illegal activities, including drugs, fraud, or cybercrime, is not permitted.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(
                '3.5 Media and Image Sharing Responsibilities',
              ),
              _buildParagraph(
                'Images shared on DC Audio Rooms must comply with community standards and applicable law. Users are responsible for ensuring that any media they share does not violate privacy, intellectual property rights, or platform rules.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Images involving nudity, sexual activity, minors, graphic violence, or personal data of others will be removed and may result in account suspension or termination.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('3.6 Reporting, Enforcement, and Escalation'),
              _buildParagraph(
                'DC Audio Rooms provides in-app tools for reporting violations. Reports are reviewed using a combination of automated systems and human moderation.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Depending on severity and frequency, enforcement actions may include warnings, temporary restrictions, muting, removal from frequencies, suspension, or permanent account termination. Severe violations may be escalated directly to permanent enforcement without prior warning.',
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
          'Community Guidelines',
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
                  text: 'Support@dcaudiorooms.com',
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
                  text: 'csae@dcaudiorooms.com',
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
        color: Color(0xFF00ff88),
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

  Widget _buildWebsiteButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _launchWebsite,
        icon: const Icon(Icons.open_in_browser),
        label: const Text('View Full Community Guidelines on Website'),
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
