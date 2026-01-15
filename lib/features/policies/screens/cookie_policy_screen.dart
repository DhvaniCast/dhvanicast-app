import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CookiePolicyScreen extends StatelessWidget {
  const CookiePolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cookie Policy',
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
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://dhvanicast.com/cookie-policy',
                    );
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
        '6. Cookie Policy',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        '6.1 Purpose and Necessity of Cookies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'DC Audio Rooms uses cookies and similar technologies to ensure the secure, reliable, and efficient operation of its platform. Cookies are small data files stored on a user\'s device that allow the application to recognize returning users, maintain authenticated sessions, and support essential security and operational functions.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Cookies are fundamental to enabling core platform features, including user authentication, session continuity, access control, and protection against unauthorized access. Without the use of cookies or equivalent technologies, DC Audio Rooms would be unable to reliably verify user identity, prevent session hijacking, or provide a seamless user experience during live communication.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Cookies are used strictly for operational, security, and functional purposes and are not employed in a manner that compromises user privacy.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '6.2 Types and Categories of Cookies Used',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'DC Audio Rooms uses the following categories of cookies and similar technologies:',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        '6.2.1 Essential Cookies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Essential cookies are required for the basic functioning of the platform. These cookies enable:',
        style: TextStyle(color: Colors.white70),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Secure user authentication and login persistence\n• Session management during live audio communication\n• Protection against unauthorized access and fraudulent activity\n• Enforcement of security controls and account integrity',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Disabling essential cookies may result in the inability to log in or use core features of the platform.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        '6.2.2 Performance and Analytics Cookies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Performance cookies are used to collect aggregated and anonymized information about how the platform is used. These cookies help DC Audio Rooms:',
        style: TextStyle(color: Colors.white70),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Monitor application performance and stability\n• Identify technical issues and error patterns\n• Understand feature usage trends at a non-individual level\n• Improve service reliability and user experience',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Performance cookies do not collect personally identifiable information and are not used to track users across third-party websites.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        '6.2.3 Functional Cookies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Functional cookies store user preferences and settings to enhance usability, such as:',
        style: TextStyle(color: Colors.white70),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Language preferences\n• Display and interface settings\n• Session-related user choices',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'These cookies allow DC Audio Rooms to provide a more consistent and personalized experience without compromising security or privacy.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        '6.2.4 No Advertising or Behavioral Tracking Cookies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'DC Audio Rooms does not use cookies for:',
        style: TextStyle(color: Colors.white70),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Targeted advertising\n• Behavioral profiling\n• Cross-site tracking\n• Third-party ad networks',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'The platform does not monetize user data through advertising cookies.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '6.3 User Control, Consent, and Limitations',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Users retain control over cookie usage through their device, browser, or application settings. Most devices and browsers allow users to manage, restrict, or delete cookies at any time.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Users should be aware that disabling or restricting cookies may:',
        style: TextStyle(color: Colors.white70),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Prevent successful login or session continuity\n• Limit access to live communication features\n• Affect platform security and stability\n• Reduce functionality or personalization',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'By continuing to use DC Audio Rooms without disabling cookies, users consent to the use of cookies as described in this policy.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '6.4 Data Protection and Security',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'All cookie-related data is handled in accordance with DC Audio Rooms\'s Privacy Policy and applicable data protection laws. Cookie data is:',
        style: TextStyle(color: Colors.white70),
      ),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Stored securely\n• Accessible only to authorized systems\n• Used solely for the purposes outlined in this policy',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'DC Audio Rooms regularly reviews its use of cookies to ensure compliance with legal and security standards.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '6.5 Updates to Cookie Policy',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'This Cookie Policy may be updated periodically to reflect changes in technology, legal requirements, or platform operations. Material updates will be communicated through the application or associated policy pages. Continued use of the platform constitutes acceptance of the updated Cookie Policy.',
        style: TextStyle(color: Colors.white70),
      ),
    ];
  }
}
