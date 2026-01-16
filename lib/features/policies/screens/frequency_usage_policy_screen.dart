import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FrequencyUsagePolicyScreen extends StatelessWidget {
  const FrequencyUsagePolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Frequency Usage Policy',
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
                      'https://dhvanicast.com/frequency-usage-policy',
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
            'General Support & Enquiries: Support@dcaudiorooms.com',
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            'Child Safety & CSAE Reporting: csae@dcaudiorooms.com',
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
        '4.1 Frequency-Based Communication Model',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'DC Audio Rooms operates on a frequency-based model inspired by radio communication, where each frequency represents a shared communication channel accessible by multiple users simultaneously. Frequencies are communal spaces and should be treated as such.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Users must understand that joining a frequency means entering a shared environment where interactions are public to other participants in that frequency.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '4.2 Public Frequencies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Public frequencies are available to all eligible users and allow unrestricted participation subject to platform rules. Because these frequencies are open, they are subject to moderation to ensure safety, legality, and compliance with community standards.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'DC Audio Rooms reserves the right to temporarily restrict, mute, or close public frequencies if misuse or safety risks are identified.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '4.3 Private Paid Frequencies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Private frequencies are optional paid features that provide exclusive, password-protected access for a limited duration. When a user purchases a private frequency, they receive temporary control over access to that frequency.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text('Private frequencies:', style: TextStyle(color: Colors.white70)),
      Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text(
          '• Are active for 12 hours only\n• Automatically expire without extension\n• Are not transferable or refundable once activated',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Private status does not exempt the frequency from moderation or legal oversight.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '4.4 Responsibility and Liability',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'The purchaser of a private frequency bears full responsibility for how access is managed, including password sharing and participant selection. DC Audio Rooms is not responsible for misuse arising from user negligence or intentional sharing of access credentials.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '4.5 Expiry and System Reassignment',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Upon expiration, the private frequency is automatically deactivated and returned to the public frequency pool. All ongoing communications are terminated, and the frequency cannot be recovered or restored.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '4.6 Moderation of Frequencies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'All frequencies, including private ones, may be reviewed or restricted if violations, illegal activity, or CSAE concerns are suspected. DC Audio Rooms prioritizes safety and legal compliance over frequency privacy.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '4.7 Private frequencies, paid rooms, or password-protected communication spaces are NOT exempt from CSAE detection, moderation, reporting, or enforcement.',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Any CSAE-related activity detected in private frequencies will be treated with the same zero-tolerance enforcement as public spaces, including immediate removal, account termination, and mandatory reporting to authorities.',
        style: TextStyle(color: Colors.white70),
      ),
    ];
  }
}
