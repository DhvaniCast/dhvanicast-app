import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformOperationsPolicyScreen extends StatelessWidget {
  const PlatformOperationsPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Platform Operations Policy',
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
                      'https://dhvanicast.com/platform-operations-policy',
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
        '5.1 Operational Monitoring',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'DC Audio Rooms operates a real-time, frequency-based communication platform that requires continuous operational oversight to ensure reliability, security, and service quality. To achieve this, DC Audio Rooms maintains ongoing monitoring of its technical infrastructure, application services, and usage patterns.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Operational monitoring includes, but is not limited to, tracking server uptime, network latency, system load, error rates, service availability, and abnormal traffic patterns. This monitoring enables DC Audio Rooms to identify performance degradation, service outages, security threats, and misuse of platform resources at the earliest possible stage.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Monitoring activities are conducted strictly for operational, security, and safety purposes. They are designed to protect users from service disruption, prevent abuse of system resources, and maintain the overall stability of the platform. Operational monitoring does not involve listening to or recording live audio conversations and does not involve reviewing user content unless required for safety, abuse investigation, or legal compliance.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '5.2 Crash Analytics and Diagnostics',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'To maintain application stability and ensure a consistent user experience across different devices and operating systems, DC Audio Rooms collects crash reports and diagnostic logs generated when the application encounters errors or failures.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'These diagnostic logs may include technical information such as device type, operating system version, application build number, error codes, timestamps, and system state at the time of failure. The purpose of collecting this data is strictly limited to identifying software defects, resolving technical issues, improving performance, and preventing recurring crashes.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Crash analytics data is not used to analyze the substance of user communications, including live audio, text messages, or shared images, beyond what is technically necessary to diagnose system errors. DC Audio Rooms does not use diagnostic data for advertising, behavioral profiling, or content surveillance.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Access to crash analytics is restricted to authorized technical personnel and is governed by internal access controls and security policies.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '5.3 Feature Evolution, Availability, and Maintenance',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'DC Audio Rooms is an evolving platform and may periodically introduce new features, modify existing functionality, or discontinue features to improve performance, enhance safety, comply with legal or regulatory requirements, or respond to technological changes.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Feature availability may vary based on factors such as device compatibility, operating system limitations, regional regulations, server capacity, or phased rollouts. Certain features may be offered on a trial or limited basis before being made generally available.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'DC Audio Rooms also reserves the right to perform scheduled or emergency maintenance, during which some or all services may be temporarily unavailable. Where reasonably possible, advance notice of planned maintenance will be provided through in-app notifications or other communication channels.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Continued use of the platform following feature changes or updates constitutes acceptance of such changes.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      Text(
        '5.4 Abuse Prevention and Platform Integrity',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Maintaining the integrity of DC Audio Rooms is essential to ensuring a safe and fair environment for all users. The platform employs technical, procedural, and policy-based safeguards to prevent abuse, misuse, and exploitation of its systems.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'These safeguards include mechanisms to detect and limit spamming, automated or bot-driven activity, coordinated misuse, attempts to overload system resources, and efforts to circumvent platform restrictions. DC Audio Rooms may impose rate limits, access restrictions, or automated blocks where suspicious or harmful activity is detected.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'Any attempt to interfere with platform operations, bypass security controls, manipulate frequencies, exploit vulnerabilities, or disrupt the service may result in immediate enforcement action. Such action may include temporary restrictions, suspension, permanent account termination, and, where applicable, reporting to law enforcement or relevant authorities.',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 10),
      Text(
        'DC Audio Rooms reserves the right to take all necessary steps to protect its infrastructure, users, and services from harm, while ensuring that enforcement actions are proportionate, documented, and aligned with applicable laws and platform policies.',
        style: TextStyle(color: Colors.white70),
      ),
    ];
  }
}
