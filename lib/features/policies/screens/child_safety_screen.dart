import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChildSafetyScreen extends StatelessWidget {
  const ChildSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Child Safety & CSAE Policy',
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
              _buildTitle('Child Safety & CSAE Policy'),
              const SizedBox(height: 12),
              _buildMetaInfo(
                'Effective Date: 31 December 2025\nJurisdiction: India',
              ),
              const SizedBox(height: 20),

              _buildContactBox(context),
              const SizedBox(height: 20),

              _buildZeroToleranceBox(),
              const SizedBox(height: 30),

              _buildSectionTitle('10.1 Zero-Tolerance Policy'),
              _buildParagraph(
                'Dhvani Cast maintains an absolute zero-tolerance stance against Child Sexual Abuse and Exploitation (CSAE) in any form. This policy applies to all users, all frequencies (public and private), all communication methods (audio, text, images), and all forms of interaction on the platform.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'The platform prohibits the creation, distribution, solicitation, or possession of any content that sexualizes, exploits, or endangers minors. This includes visual, textual, audio, or implied content depicting or facilitating child abuse or exploitation.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.2 Definitions and Scope'),
              _buildParagraph('For the purposes of this policy:'),
              const SizedBox(height: 8),
              _buildParagraph(
                '• "Minor" or "Child" refers to any individual under the age of 18 years.\n\n'
                '• "CSAE" includes child sexual abuse material (CSAM), grooming, solicitation, sextortion, trafficking-related communication, and any conduct or content that sexualizes or endangers minors.\n\n'
                '• "Content" includes images, text messages, audio communication, user profiles, and any other data transmitted or stored on the platform.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.3 Platform Age Restrictions'),
              _buildParagraph(
                'Dhvani Cast is strictly an 18+ platform. Use of the platform by individuals under 18 years of age is expressly prohibited and constitutes a violation of the Terms of Use.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'While Dhvani Cast enforces this restriction through account registration controls, the platform acknowledges that technical enforcement alone is not sufficient to prevent all unauthorized access by minors. Therefore, the platform also maintains detection, monitoring, and reporting mechanisms to identify and respond to any presence of minors or CSAE-related activity.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.4 Detection and Monitoring Technologies'),
              _buildSubsectionTitle('10.4.1 Image Scanning'),
              _buildParagraph(
                'All images uploaded or shared on Dhvani Cast are scanned using automated CSAE detection systems. These systems employ machine learning models trained to identify known and unknown CSAE content, including sexually explicit depictions of minors, grooming-related imagery, and related violations.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Detection systems operate in real time and apply equally to all frequencies, including private paid frequencies. Detection does not require human review of content unless a positive match or suspicious pattern is identified.',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.4.2 Text and Metadata Analysis'),
              _buildParagraph(
                'Dhvani Cast uses automated text analysis and pattern recognition to detect language, phrases, or behavioral indicators commonly associated with grooming, solicitation, sextortion, or CSAE-related communication.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Metadata associated with shared content, including file properties, timestamps, and user interaction patterns, may also be analyzed to identify risks or violations.',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.4.3 Behavioral Monitoring'),
              _buildParagraph(
                'The platform monitors for behavioral patterns that may indicate CSAE-related risk, including:\n\n'
                '• Repeated attempts to share flagged or suspicious content\n'
                '• Creation of multiple accounts following enforcement action\n'
                '• Communication patterns consistent with grooming or solicitation\n'
                '• Coordination with known offenders or flagged accounts',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.4.4 Hash-Based Detection'),
              _buildParagraph(
                'Dhvani Cast uses industry-standard hash-matching technology to compare uploaded images against databases of known CSAE content maintained by organizations such as the National Center for Missing & Exploited Children (NCMEC) and the Internet Watch Foundation (IWF).',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Hash-based detection enables rapid identification of previously identified illegal content without requiring manual review or re-exposure to harmful material.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.5 Reporting and Account Actions'),
              _buildSubsectionTitle('10.5.1 Immediate Removal'),
              _buildParagraph(
                'Any content identified as violating this policy is immediately removed from the platform. Removal occurs automatically upon detection or following human review and does not require user notification or consent.',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle(
                '10.5.2 Account Suspension and Termination',
              ),
              _buildParagraph(
                'Accounts associated with CSAE violations are subject to:\n\n'
                '• Immediate suspension pending investigation\n'
                '• Permanent termination without prior warning\n'
                '• Restriction from creating new accounts\n'
                '• Reporting to law enforcement and relevant authorities',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Terminated accounts are not eligible for appeal, reinstatement, or refund of any kind.',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.5.3 Device and IP Restrictions'),
              _buildParagraph(
                'Dhvani Cast may implement device-level or IP-level restrictions to prevent repeat violations by the same individual using different accounts. These restrictions are applied based on technical identifiers and behavioral fingerprints associated with prior violations.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.6 User Reporting Mechanisms'),
              _buildSubsectionTitle('10.6.1 In-App Reporting'),
              _buildParagraph(
                'Dhvani Cast provides an in-app reporting tool that allows users to report suspected CSAE content, grooming behavior, or any activity that may endanger minors. Reports are reviewed with the highest priority.',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.6.2 Dedicated CSAE Reporting Email'),
              _buildParagraph(
                'Users may also report CSAE-related concerns directly via email to:',
              ),
              const SizedBox(height: 8),
              _buildHighlightedEmail('csae@dhvanicast.com'),
              const SizedBox(height: 8),
              _buildParagraph(
                'This inbox is monitored continuously and is designated exclusively for child safety matters.',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.6.3 Anonymity and Confidentiality'),
              _buildParagraph(
                'Users may report concerns anonymously. Dhvani Cast does not retaliate against users who submit reports in good faith and takes steps to protect the identity of reporters where legally permissible.',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.6.4 Response Timelines'),
              _buildParagraph(
                'CSAE-related reports are prioritized as follows:\n\n'
                '• Critical threats involving imminent harm or active abuse: Immediate response and escalation\n'
                '• Confirmed CSAE content: Removal and reporting within 24 hours\n'
                '• Suspected violations requiring further review: Investigation within 48 hours',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.7 Cooperation with Authorities'),
              _buildParagraph(
                'Dhvani Cast cooperates fully with law enforcement agencies, child protection organizations, and regulatory authorities to combat CSAE. This cooperation includes, but is not limited to:',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                '• Reporting verified or suspected CSAE content to the National Center for Missing & Exploited Children (NCMEC) via CyberTipline, as required under applicable law\n'
                '• Providing account information, metadata, and evidence to law enforcement upon lawful request\n'
                '• Participating in coordinated investigations and threat intelligence sharing\n'
                '• Implementing technical measures requested by authorities to prevent further harm',
              ),
              const SizedBox(height: 12),
              _buildParagraph(
                'In addition to reporting to Indian law enforcement authorities, Dhvani Cast will report all confirmed instances of Child Sexual Abuse Material (CSAM) to the National Center for Missing & Exploited Children (NCMEC), as required under international child protection standards and Google Play Developer Program Policies.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Reports submitted to NCMEC may include:\n'
                '• User identifiers\n'
                '• Content identifiers\n'
                '• IP addresses\n'
                '• Timestamps\n'
                '• Relevant metadata required for investigation',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast cooperates fully with NCMEC, Google, and law enforcement agencies to support the identification, investigation, and prosecution of CSAE offenses.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'All reports submitted to NCMEC include:\n'
                '• Description of the violation\n'
                '• Hash values of flagged images (where applicable)\n'
                '• Account identifiers and metadata\n'
                '• Timestamps and context of detection\n'
                '• Any additional information necessary for investigation',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Dhvani Cast may also disclose information to authorities without user consent where required by law or where disclosure is necessary to prevent imminent harm to a child.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.8 Compliance and Policy Alignment'),
              _buildSubsectionTitle('10.8.1 Legal and Regulatory Compliance'),
              _buildParagraph(
                'This policy is designed to comply with applicable laws and regulations, including:\n\n'
                '• The Information Technology Act, 2000 (India)\n'
                '• The Protection of Children from Sexual Offences (POCSO) Act, 2012 (India)\n'
                '• International standards for online child safety\n'
                '• Google Play and Apple App Store child safety requirements',
              ),
              const SizedBox(height: 16),

              _buildSubsectionTitle('10.8.2 Google Play Coordination'),
              _buildParagraph(
                'As part of compliance with Google Play\'s child safety policies, Dhvani Cast:\n\n'
                '• Promptly responds to takedown requests related to CSAE content\n'
                '• Cooperates with Google\'s Trust & Safety team during investigations\n'
                '• Implements recommended technical and policy enhancements\n'
                '• Maintains transparency in reporting and enforcement practices',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.9 Training and Internal Controls'),
              _buildParagraph(
                'Dhvani Cast maintains internal policies and training protocols to ensure that employees, moderators, and contractors involved in content review or platform safety are:\n\n'
                '• Trained to recognize CSAE content and grooming behavior\n'
                '• Equipped with appropriate psychological support and wellness resources\n'
                '• Subject to strict confidentiality and data protection requirements\n'
                '• Authorized to escalate concerns immediately to leadership and legal teams',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Access to flagged content, user data, and investigation materials is restricted to authorized personnel only and is logged for audit purposes.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('10.10 Private Frequency Enforcement'),
              _buildParagraph(
                'Private frequencies, paid rooms, or password-protected communication spaces are NOT exempt from CSAE detection, moderation, reporting, or enforcement.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Any CSAE-related activity detected in private frequencies will be treated with the same zero-tolerance enforcement as public spaces, including immediate removal, account termination, and mandatory reporting to authorities.',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Users who purchase private frequencies are reminded that privacy does not extend to illegal activity and that Dhvani Cast prioritizes child safety above all other considerations.',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(
                '10.11 User Responsibilities and Community Role',
              ),
              _buildParagraph(
                'All users share responsibility for maintaining a safe environment. Users are encouraged to:\n\n'
                '• Report any suspected CSAE content or behavior immediately\n'
                '• Refrain from engaging with or sharing suspicious content\n'
                '• Educate themselves on the signs of grooming and exploitation\n'
                '• Understand that participation on the platform requires adherence to the highest standards of conduct',
              ),
              const SizedBox(height: 8),
              _buildParagraph(
                'Failure to report known violations or attempts to obstruct enforcement actions may result in account suspension or termination.',
              ),
              const SizedBox(height: 30),

              Center(
                child: GestureDetector(
                  onTap: () => _launchWebsite(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ff88).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00ff88),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.open_in_new,
                          color: Color(0xFF00ff88),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'View Complete Policy',
                          style: TextStyle(
                            color: Color(0xFF00ff88),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildMetaInfo(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
    );
  }

  Widget _buildContactBox(BuildContext context) {
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

  Widget _buildZeroToleranceBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFff4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFff4444), width: 2),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_rounded, color: Color(0xFFff4444), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ZERO TOLERANCE: Any CSAE content results in immediate account termination and law enforcement reporting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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

  Widget _buildHighlightedEmail(String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00ff88).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        email,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF00ff88),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _launchWebsite() async {
    final url = Uri.parse('https://dhvanicast.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
