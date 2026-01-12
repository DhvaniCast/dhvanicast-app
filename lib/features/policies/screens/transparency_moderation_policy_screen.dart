import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TransparencyModerationPolicyScreen extends StatelessWidget {
  const TransparencyModerationPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transparency and Moderation Policy',
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
              _contactBox(),
              const SizedBox(height: 20),
              ..._policyContent(),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff88),
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final url = Uri.parse('https://dhvanicast.com/transparency-and-moderation-policy');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visit dhvanicast.com'),
                ),
              ),
              const SizedBox(height: 16),
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

  Widget _buildMetaInfo(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
    );
  }

  Widget _contactBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00ff88).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF00ff88)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Official Contact Emails',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00ff88),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'General Support & Enquiries: support@dhvanicast.com',
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            'Child Safety & CSAE Reporting: csae@dhvanicast.com',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  List<Widget> _policyContent() {
    return const [
      SizedBox(height: 10),
      Text(
        '7.1 Moderation Framework',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Dhvani Cast is committed to maintaining a safe, lawful, and respectful environment across all frequencies and platform features. To achieve this, the platform operates a hybrid moderation framework that combines automated detection technologies with human review by trained moderation personnel.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Automated systems are used to identify potential policy violations at scale, including patterns associated with abuse, spamming, coordinated misuse, illegal activity, and CSAE-related risks. These systems are designed to act as early-warning mechanisms and to prioritize content or accounts for further review.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Human moderators provide contextual judgment that automated systems alone cannot achieve. Moderators review reported content, flagged activity, and edge cases to ensure that enforcement decisions are proportionate, accurate, and aligned with platform policies and applicable laws.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Moderation applies uniformly to public frequencies, private paid frequencies, chat messages, images, and user profiles.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'The moderation framework is continuously evaluated and refined to balance user safety, freedom of expression, operational feasibility, and legal compliance.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '7.2 Transparency, Accountability, and Record-Keeping',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'To ensure accountability and consistency, Dhvani Cast maintains internal records of moderation actions taken on the platform. These records may include information such as the nature of the violation, the type of enforcement action applied, timestamps, and reference identifiers.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Moderation logs are maintained for the following purposes:',
        style: TextStyle(color: Colors.white70),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Ensuring consistent application of platform rules\n• Supporting internal audits and quality reviews\n• Responding to user inquiries or appeals\n• Complying with legal, regulatory, or law enforcement requirements',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Access to moderation records is restricted to authorized personnel only and is governed by internal access controls and data protection policies. Logs are retained only for as long as necessary to meet operational, legal, or compliance obligations.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Dhvani Cast may disclose moderation-related information to authorities when legally required or to protect the safety and integrity of the platform and its users.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '7.3 User Notifications, Appeals, and Finality',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Where appropriate and feasible, users may be notified of significant moderation actions affecting their accounts, such as suspensions or permanent bans. Notification may be provided through in-app messages, email communication, or account status updates.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Users may contact support@dhvanicast.com to request a review of certain moderation actions. Appeals are reviewed by Dhvani Cast on a case-by-case basis, taking into account platform rules, user history, available evidence, and safety considerations.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Dhvani Cast reserves the right to make final determinations regarding moderation outcomes. In cases involving serious violations, illegal activity, CSAE concerns, or repeated abuse, enforcement decisions may be final and not subject to appeal, in order to protect platform integrity and user safety.',
        style: TextStyle(color: Colors.white70),
      ),
    ];
  }
}
