import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: const CustomAppBar(
          title: 'Terms of Service',
          leading: CustomBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSection(
                '1. Acceptance of Terms',
                '''
By downloading, installing, or using SweepFeed, you agree to be bound by these Terms of Service.

If you do not agree to these terms, please do not use the application.

These terms constitute a legally binding agreement between you and SweepFeed regarding your use of our services.''',
                Icons.handshake,
              ),
              _buildSection(
                '2. Eligibility',
                '''
To use SweepFeed, you must:

- Be at least 18 years of age
- Be a legal resident of a jurisdiction where contests participation is permitted
- Have the legal capacity to enter into contracts
- Not be prohibited from using our services under applicable law

Individual contests may have additional eligibility requirements set by their sponsors.''',
                Icons.person_outline,
              ),
              _buildSection(
                '3. Account Registration',
                '''
When you create an account, you agree to:

- Provide accurate and complete information
- Maintain the security of your account credentials
- Promptly update your information if it changes
- Accept responsibility for all activities under your account
- Not create multiple accounts or share account access

We reserve the right to suspend or terminate accounts that violate these terms.''',
                Icons.account_circle,
              ),
              _buildSection(
                '4. Contests Entries',
                '''
SweepFeed provides information about third-party contests. By using our service:

- You acknowledge that contests are operated by third parties
- Entry requirements and rules are set by each sponsor
- SweepFeed is not responsible for the conduct of contests
- Winners are selected by sponsors, not SweepFeed
- You must comply with each contests' official rules

SweepFeed does not guarantee that you will win any contests.''',
                Icons.card_giftcard,
              ),
              _buildSection(
                '5. Subscription Services',
                '''
SweepFeed offers subscription tiers with different features:

- Free tier: Limited features with advertising
- Basic tier: Enhanced features, daily digest
- Premium tier: Full access, instant notifications, premium email

Subscriptions auto-renew unless cancelled. You can manage subscriptions through your device's app store. Refunds are subject to app store policies.''',
                Icons.star,
              ),
              _buildSection(
                '6. User Conduct',
                '''
You agree not to:

- Violate any laws or regulations
- Infringe on others' intellectual property rights
- Submit false or misleading information
- Attempt to manipulate or game the system
- Use automated tools or bots
- Harass, abuse, or harm other users
- Interfere with the proper functioning of the app
- Attempt to access accounts or data belonging to others''',
                Icons.rule,
              ),
              _buildSection(
                '7. Content and Intellectual Property',
                '''
All content in SweepFeed, including text, graphics, logos, and software, is owned by SweepFeed or its licensors.

You may not:
- Copy, modify, or distribute our content
- Use our trademarks without permission
- Reverse engineer the application
- Remove any copyright or proprietary notices

User-generated content remains your property, but you grant us a license to use it for service operation.''',
                Icons.copyright,
              ),
              _buildSection(
                '8. Privacy',
                '''
Your use of SweepFeed is also governed by our Privacy Policy, which explains how we collect, use, and protect your information.

By using our services, you consent to our data practices as described in the Privacy Policy.''',
                Icons.privacy_tip,
              ),
              _buildSection(
                '9. Disclaimers',
                '''
SweepFeed is provided "as is" without warranties of any kind.

We do not guarantee:
- Uninterrupted or error-free service
- Accuracy of contests information
- Success in any contests
- Compatibility with all devices

We are not responsible for actions of third-party contests sponsors.''',
                Icons.warning_amber,
              ),
              _buildSection(
                '10. Limitation of Liability',
                '''
To the maximum extent permitted by law, SweepFeed shall not be liable for:

- Indirect, incidental, or consequential damages
- Loss of profits, data, or goodwill
- Damages arising from third-party contests
- Damages exceeding the amount you paid us in the past 12 months

Some jurisdictions do not allow certain limitations, so these may not apply to you.''',
                Icons.shield,
              ),
              _buildSection(
                '11. Account Termination',
                '''
We may suspend or terminate your account if you:

- Violate these Terms of Service
- Engage in fraudulent activity
- Abuse our services or other users
- Request account deletion

You may delete your account at any time through the app settings. Account deletion is processed within 7 days, with a grace period to cancel.''',
                Icons.block,
              ),
              _buildSection(
                '12. Changes to Terms',
                '''
We may update these Terms of Service periodically.

- Material changes will be notified in advance
- Continued use constitutes acceptance
- You can review the current terms at any time
- Previous versions are available upon request''',
                Icons.update,
              ),
              _buildSection(
                '13. Governing Law',
                '''
These Terms shall be governed by and construed in accordance with the laws of the State of Delaware, United States.

Any disputes shall be resolved through binding arbitration, except where prohibited by law.''',
                Icons.gavel,
              ),
              _buildSection(
                '14. Contact Information',
                '''
For questions about these Terms of Service:

Email: legal@sweepfeed.com
Website: https://sweepfeed.com/terms

We aim to respond to all inquiries within 30 days.''',
                Icons.email,
              ),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Card(
        color: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.brandCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: AppColors.brandCyan,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Last Updated: December 2024',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please read these terms carefully before using SweepFeed. By using our service, you agree to be bound by these terms.',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildSection(String title, String content, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Card(
          color: AppColors.primaryMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.brandCyan,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            iconColor: AppColors.brandCyan,
            collapsedIconColor: AppColors.textLight,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFooter() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.brandCyan.withValues(alpha: 0.2),
          ),
        ),
        child: const Column(
          children: [
            Text(
              'SweepFeed Terms of Service',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Version 1.0 - Effective December 2024',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
