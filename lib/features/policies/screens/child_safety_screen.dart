import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class ChildSafetyScreen extends StatelessWidget {
  const ChildSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00ff88)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Child Safety & CSAE Reporting',
          style: TextStyle(
            color: Color(0xFF00ff88),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back to Home link (styled as a button)
            Row(
              children: [
                Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.shield, color: Theme.of(context).colorScheme.primary, size: 40),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Child Safety & CSAE Reporting',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Zero Tolerance Notice
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.2),
                border: Border.all(color: Colors.red.shade500, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade500, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ZERO TOLERANCE NOTICE',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dhvani Cast maintains a zero-tolerance policy toward Child Sexual Abuse and Exploitation. Any violation results in permanent removal and reporting to authorities, regardless of user intent or account status.',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Contact Emails
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.2),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Official Contact Emails:',
                    style: TextStyle(
                      color: Color(0xFF00ff88),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.mail, color: Theme.of(context).colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('Child Safety & CSAE Reporting:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('mailto:csae@dhvanicast.com')),
                        child: Text('csae@dhvanicast.com', style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.mail, color: Theme.of(context).colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('General Support & Enquiries:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('mailto:support@dhvanicast.com')),
                        child: Text('support@dhvanicast.com', style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Policy Content
            ..._policySections(context),
            const SizedBox(height: 32),
            // Effective Date
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Effective Date', style: TextStyle(color: Color(0xFF00ff88), fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 6),
                  Text('31 December 2025', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('Jurisdiction: India', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  static List<Widget> _policySections(BuildContext context) {
    TextStyle heading = const TextStyle(color: Color(0xFF00ff88), fontWeight: FontWeight.bold, fontSize: 20);
    TextStyle subheading = const TextStyle(color: Color(0xFF00ff88), fontWeight: FontWeight.w600, fontSize: 16);
    TextStyle body = const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6);
    TextStyle bullet = const TextStyle(color: Colors.white70, fontSize: 15);
    TextStyle red = const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15);
    return [
      // 1. Commitment to Child Safety
      Text('1. Commitment to Child Safety', style: heading),
      const SizedBox(height: 8),
      Text('Dhvani Cast is committed to maintaining a safe digital environment and enforcing zero tolerance toward Child Sexual Abuse and Exploitation (CSAE).', style: body),
      const SizedBox(height: 8),
      Text('Although Dhvani Cast is a strictly 18+ platform, the company acknowledges its responsibility to prevent, detect, report, and remove any form of child sexual abuse material or grooming behavior that may appear on the platform, intentionally or unintentionally.', style: body),
      const SizedBox(height: 8),
      Text('Any CSAE-related content or behavior is treated as a serious criminal matter and handled with the highest priority.', style: body),
      const SizedBox(height: 24),
      // 2. Applicability of This Policy
      Text('2. Applicability of This Policy', style: heading),
      const SizedBox(height: 8),
      Text('This Child Safety & CSAE Policy applies to:', style: body),
      const SizedBox(height: 6),
      _bulletedList([
        'All users of Dhvani Cast',
        'All communication channels, including:',
        _bulletedList([
          'Live audio conversations',
          'Text chat',
          'Image sharing',
          'User profiles',
          'Private and public frequencies',
        ], indent: 24),
        'All reports submitted via:',
        _bulletedList([
          'In-app reporting tools',
          'Email communication',
          'Third-party notifications (including Google Play)',
        ], indent: 24),
      ], indent: 12),
      const SizedBox(height: 8),
      Text('This policy applies regardless of user age claims.', style: body),
      const SizedBox(height: 24),
      // 3. Strict Prohibition of CSAE Content
      Text('3. Strict Prohibition of CSAE Content', style: heading),
      const SizedBox(height: 8),
      Text('Dhvani Cast explicitly and permanently prohibits any form of Child Sexual Abuse or Exploitation, including but not limited to:', style: body),
      const SizedBox(height: 6),
      Text('3.1 Prohibited Content', style: subheading),
      _bulletedList([
        'Any sexual content involving a minor (under 18)',
        'Child Sexual Abuse Material (CSAM) in any format',
        'Nude or sexually suggestive images of minors',
        'Audio conversations describing sexual acts involving minors',
        'Requests, offers, or encouragement to share CSAM',
        'Links, references, or coded language used to distribute CSAM',
        'Grooming behavior, including attempts to build trust with a minor for sexual purposes',
        'Role-play, fantasy, or AI-generated content involving minors in a sexual context',
      ], indent: 12),
      const SizedBox(height: 8),
      Text('There are no exceptions, including fictional, artistic, or "joke" content.', style: red),
      const SizedBox(height: 24),
      // 4. Detection, Monitoring & Prevention Measures
      Text('4. Detection, Monitoring & Prevention Measures', style: heading),
      const SizedBox(height: 8),
      Text('Dhvani Cast uses a multi-layered safety approach to detect and prevent CSAE:', style: body),
      const SizedBox(height: 6),
      Text('4.1 Automated Detection', style: subheading),
      _bulletedList([
        'Automated scanning of text chats and shared images',
        'Pattern-based detection of grooming language',
        'Behavioral monitoring for repeated suspicious activity',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('4.2 Human Review', style: subheading),
      _bulletedList([
        'All CSAE reports are reviewed by trained moderators',
        'High-risk content is escalated immediately',
        'Content is reviewed regardless of whether it occurs in a public or private frequency',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('4.3 Platform Design Safeguards', style: subheading),
      _bulletedList([
        'No public discovery of private chats',
        'Limited image-sharing permissions',
        'Controlled frequency access',
        'Account-level enforcement tools',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('4.4 Hash-Based Detection', style: subheading),
      Text('Where technically feasible, Dhvani Cast uses industry-standard hash-based detection techniques to identify known Child Sexual Abuse Material (CSAM) across images and shared media.', style: body),
      const SizedBox(height: 4),
      Text('This enables rapid identification and removal of previously reported CSAM without requiring human viewing of illegal material.', style: body),
      const SizedBox(height: 24),
      // 5. In-App Reporting Mechanism
      Text('5. In-App Reporting Mechanism', style: heading),
      const SizedBox(height: 8),
      Text('Dhvani Cast provides a clear and accessible in-app mechanism for users to report CSAE concerns.', style: body),
      const SizedBox(height: 6),
      Text('5.1 How Users Can Report', style: subheading),
      Text('Users can report suspected CSAE by:', style: body),
      _bulletedList([
        'Navigating to Settings → Safety → Report CSAE',
        'Reporting a specific user, chat message, image, or frequency',
        'Submitting a report via email to csae@dhvanicast.com',
      ], indent: 12),
      const SizedBox(height: 4),
      Text('The reporting process is:', style: body),
      _bulletedList([
        'Simple',
        'Confidential',
        'Available at all times',
      ], indent: 12),
      const SizedBox(height: 24),
      // 6. Response & Enforcement Procedure
      Text('6. Response & Enforcement Procedure', style: heading),
      const SizedBox(height: 8),
      Text('When Dhvani Cast becomes aware of potential CSAE content (through user reports, automated systems, or third-party notifications), the following actions are taken:', style: body),
      const SizedBox(height: 6),
      Text('6.1 Immediate Actions', style: subheading),
      _bulletedList([
        'Content is restricted or removed immediately',
        'Associated accounts are temporarily suspended',
        'Access to affected frequencies may be frozen',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('6.2 Investigation', style: subheading),
      _bulletedList([
        'Evidence is preserved securely',
        'Internal safety team conducts expedited review',
        'False positives are minimized without delaying action',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('6.3 Enforcement', style: subheading),
      Text('If CSAE is confirmed:', style: body),
      _bulletedList([
        'Permanent account termination',
        'Device and account-level blocking',
        'Removal of all related content',
        'Zero possibility of reinstatement',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('6.4 Response Timelines', style: subheading),
      Text('Dhvani Cast follows strict response timelines for CSAE content:', style: body),
      _bulletedList([
        'Immediate automated restriction upon detection',
        'Human moderator review within 24 hours',
        'Permanent enforcement and reporting within 24–48 hours of confirmation',
      ], indent: 12),
      const SizedBox(height: 8),
      Text('No CSAE-related content is allowed to remain accessible once flagged.', style: red),
      const SizedBox(height: 24),
      // 7. Reporting to Authorities & Legal Compliance
      Text('7. Reporting to Authorities & Legal Compliance', style: heading),
      const SizedBox(height: 8),
      Text('Dhvani Cast complies with all applicable child safety laws and regulations, including:', style: body),
      _bulletedList([
        'Information Technology Act, 2000',
        'POCSO Act, 2012 (India)',
        'IT Rules, 2021',
        'Digital Personal Data Protection Act, 2023',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('7.1 Law Enforcement Reporting', style: subheading),
      Text('Confirmed CSAE cases are reported to:', style: body),
      _bulletedList([
        'Relevant Indian law enforcement agencies',
        'Cybercrime units',
        'Other legally mandated authorities',
      ], indent: 12),
      const SizedBox(height: 4),
      Text('Where applicable, Dhvani Cast cooperates with:', style: body),
      _bulletedList([
        'Government agencies',
        'Platform partners',
        'Regulatory bodies',
      ], indent: 12),
      const SizedBox(height: 8),
      Text('In addition to reporting to Indian law enforcement authorities, Dhvani Cast will report all confirmed instances of Child Sexual Abuse Material (CSAM) to the National Center for Missing & Exploited Children (NCMEC), as required under international child protection standards and Google Play Developer Program Policies.', style: body),
      const SizedBox(height: 4),
      Text('Reports submitted to NCMEC may include:', style: body),
      _bulletedList([
        'User identifiers',
        'Content identifiers',
        'IP addresses',
        'Timestamps',
        'Relevant metadata required for investigation',
      ], indent: 12),
      const SizedBox(height: 4),
      Text('Dhvani Cast cooperates fully with NCMEC, Google, and law enforcement agencies to support the identification, investigation, and prosecution of CSAE offenses.', style: body),
      const SizedBox(height: 24),
      // 8. Child Safety Point of Contact
      Text('8. Child Safety Point of Contact', style: heading),
      const SizedBox(height: 8),
      Text('Dhvani Cast has designated a Child Safety Point of Contact to receive and act on CSAE notifications, including those from Google Play.', style: body),
      Text('8.1 Designated Contact', style: subheading),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.mail, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Email:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('mailto:csae@dhvanicast.com')),
              child: Text('csae@dhvanicast.com', style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
      Text('This contact:', style: body),
      _bulletedList([
        'Receives CSAE alerts and reports',
        'Is authorized to take enforcement action',
        'Coordinates with law enforcement',
        'Responds to Google Play inquiries regarding CSAE compliance',
      ], indent: 12),
      const SizedBox(height: 6),
      Text('8.2 Google Play Coordination', style: subheading),
      Text('The designated Child Safety Point of Contact is authorized to respond to and act upon CSAE notifications received from Google Play, including emergency takedown requests, compliance inquiries, and policy audits.', style: body),
      const SizedBox(height: 24),
      // 9. User Responsibilities
      Text('9. User Responsibilities', style: heading),
      const SizedBox(height: 8),
      Text('All users are required to:', style: body),
      _bulletedList([
        'Immediately report suspected CSAE',
        'Not download, forward, screenshot, or redistribute CSAE content',
        'Avoid engaging with suspected offenders',
        'Cooperate with safety investigations when requested',
      ], indent: 12),
      const SizedBox(height: 8),
      Text('Failure to report or attempts to conceal CSAE content may result in account termination.', style: red),
      const SizedBox(height: 24),
      // 10. Confidentiality & Victim Protection
      Text('10. Confidentiality & Victim Protection', style: heading),
      const SizedBox(height: 8),
      Text('All CSAE reports are handled with:', style: body),
      _bulletedList([
        'Strict confidentiality',
        'Limited internal access',
        'Secure data handling',
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade900.withOpacity(0.2),
            border: Border.all(color: Colors.red.shade500, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Important Notice:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Private frequencies, paid rooms, or password-protected communication spaces are NOT exempt from CSAE detection, moderation, reporting, or enforcement.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 4),
              Text('Any CSAE-related activity detected in private frequencies will be treated with the same zero-tolerance enforcement as public spaces, including immediate removal, account termination, and mandatory reporting to authorities.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        'Sensitivity toward potential victims',
      ], indent: 12),
      const SizedBox(height: 8),
      Text('User identity is protected to the maximum extent permitted by law.', style: body),
      const SizedBox(height: 24),
      // 11. Policy Review & Updates
      Text('11. Policy Review & Updates', style: heading),
      const SizedBox(height: 8),
      Text('This Child Safety & CSAE Policy is:', style: body),
      _bulletedList([
        'Reviewed regularly',
        'Updated to reflect legal changes',
        'Published publicly and accessible to users',
      ], indent: 12),
      const SizedBox(height: 8),
      Text('Continued use of Dhvani Cast constitutes acceptance of this policy.', style: body),
    ];
  }

  static Widget _bulletedList(List items, {double indent = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((item) {
        if (item is Widget) return Padding(padding: EdgeInsets.only(left: indent), child: item);
        return Padding(
          padding: EdgeInsets.only(left: indent, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 15)),
              Expanded(child: Text(item.toString(), style: const TextStyle(color: Colors.white70, fontSize: 15))),
            ],
          ),
        );
      }).toList(),
    );
  }
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
