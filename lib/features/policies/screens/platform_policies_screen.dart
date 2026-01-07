import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformPoliciesScreen extends StatelessWidget {
  const PlatformPoliciesScreen({super.key});

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://dhvanicast.com/platform-policies');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Platform Policies',
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildContactCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('5.1 Operational Monitoring'),
              _buildParagraph(
                'Dhvani Cast operates a real-time, frequency-based communication platform that requires continuous operational oversight to ensure reliability, security, and service quality. To achieve this, Dhvani Cast maintains ongoing monitoring of its technical infrastructure, application services, and usage patterns.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Operational monitoring includes, but is not limited to, tracking server uptime, network latency, system load, error rates, service availability, and abnormal traffic patterns. This monitoring enables Dhvani Cast to identify performance degradation, service outages, security threats, and misuse of platform resources at the earliest possible stage.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Monitoring activities are conducted strictly for operational, security, and safety purposes. They are designed to protect users from service disruption, prevent abuse of system resources, and maintain the overall stability of the platform. Operational monitoring does not involve listening to or recording live audio conversations and does not involve reviewing user content unless required for safety, abuse investigation, or legal compliance.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('5.2 Crash Analytics and Diagnostics'),
              _buildParagraph(
                'To maintain application stability and ensure a consistent user experience across different devices and operating systems, Dhvani Cast collects crash reports and diagnostic logs generated when the application encounters errors or failures.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'These diagnostic logs may include technical information such as device type, operating system version, application build number, error codes, timestamps, and system state at the time of failure. The purpose of collecting this data is strictly limited to identifying software defects, resolving technical issues, improving performance, and preventing recurring crashes.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Crash analytics data is not used to analyze the substance of user communications, including live audio, text messages, or shared images, beyond what is technically necessary to diagnose system errors. Dhvani Cast does not use diagnostic data for advertising, behavioral profiling, or content surveillance.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Access to crash analytics is restricted to authorized technical personnel and is governed by internal access controls and security policies.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(
                '5.3 Feature Evolution, Availability, and Maintenance',
              ),
              _buildParagraph(
                'Dhvani Cast is an evolving platform and may periodically introduce new features, modify existing functionality, or discontinue features to improve performance, enhance safety, comply with legal or regulatory requirements, or respond to technological changes.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Feature availability may vary based on factors such as device compatibility, operating system limitations, regional regulations, server capacity, or phased rollouts. Certain features may be offered on a trial or limited basis before being made generally available.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast also reserves the right to perform scheduled or emergency maintenance, during which some or all services may be temporarily unavailable. Where reasonably possible, advance notice of planned maintenance will be provided through in-app notifications or other communication channels.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Continued use of the platform following feature changes or updates constitutes acceptance of such changes.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('5.4 Abuse Prevention and Platform Integrity'),
              _buildParagraph(
                'Maintaining the integrity of Dhvani Cast is essential to ensuring a safe and fair environment for all users. The platform employs technical, procedural, and policy-based safeguards to prevent abuse, misuse, and exploitation of its systems.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'These safeguards include mechanisms to detect and limit spamming, automated or bot-driven activity, coordinated misuse, attempts to overload system resources, and efforts to circumvent platform restrictions. Dhvani Cast may impose rate limits, access restrictions, or automated blocks where suspicious or harmful activity is detected.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Any attempt to interfere with platform operations, bypass security controls, manipulate frequencies, exploit vulnerabilities, or disrupt the service may result in immediate enforcement action. Such action may include temporary restrictions, suspension, permanent account termination, and, where applicable, reporting to law enforcement or relevant authorities.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast reserves the right to take all necessary steps to protect its infrastructure, users, and services from harm, while ensuring that enforcement actions are proportionate, documented, and aligned with applicable laws and platform policies.',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00ff88).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00ff88).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.white70, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Effective Date: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '31 December 2025'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.white70, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Jurisdiction: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: 'India'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00ff88).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF00ff88), width: 1.5),
        borderRadius: BorderRadius.circular(10),
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

  Widget _buildWebsiteButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _launchWebsite,
        icon: const Icon(Icons.open_in_browser),
        label: const Text('View Full Platform Policies on Website'),
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
