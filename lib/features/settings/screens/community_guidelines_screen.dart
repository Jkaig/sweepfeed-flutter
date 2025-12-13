import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: const CustomAppBar(
          title: 'Community Guidelines',
          leading: CustomBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCoreValueCard(
                'Be Respectful',
                "Treat all community members with kindness and respect. We're all here to discover great opportunities together.",
                Icons.favorite,
                AppColors.brandCyan,
              ),
              _buildCoreValueCard(
                'Be Helpful',
                'Share tips, celebrate wins, and support fellow sweepers on their journey.',
                Icons.handshake,
                Colors.green,
              ),
              _buildCoreValueCard(
                'Be Honest',
                "Share accurate information and genuine experiences. Don't mislead others.",
                Icons.verified,
                Colors.amber,
              ),
              const SizedBox(height: 16),
              _buildSection(
                'Comment Etiquette',
                '''
When commenting on contests or interacting with others:

DO:
- Share helpful tips and experiences
- Ask genuine questions
- Congratulate winners
- Report issues constructively
- Use appropriate language

DON'T:
- Post spam or self-promotion
- Share referral codes without permission
- Use offensive or hateful language
- Harass or bully other users
- Post false information about contests''',
                Icons.chat_bubble_outline,
              ),
              _buildSection(
                'Prohibited Content',
                '''
The following content is not allowed:

- Hate speech or discrimination
- Harassment or bullying
- Explicit or adult content
- Violence or threats
- Personal information sharing (doxxing)
- Spam, scams, or fraudulent content
- Illegal activities
- Copyright infringement
- Impersonation of others''',
                Icons.block,
              ),
              _buildSection(
                'Contests Integrity',
                '''
To maintain fair competition:

- Don't create multiple accounts
- Don't use bots or automated entries
- Don't share login credentials
- Don't attempt to manipulate results
- Follow each contest's official rules
- Report suspicious activity

Violations may result in disqualification and account suspension.''',
                Icons.security,
              ),
              _buildSection(
                'Sharing Wins',
                '''
We love celebrating wins! When sharing:

- Be genuine about your experience
- Don't exaggerate prize values
- Respect sponsor privacy if requested
- Include helpful entry tips
- Be gracious whether you win or not

Remember: luck can change, so stay positive!''',
                Icons.emoji_events,
              ),
              _buildSection(
                'Reporting Violations',
                '''
If you see content that violates these guidelines:

1. Tap the report button on the content
2. Select the appropriate violation type
3. Add details if helpful
4. Submit the report

Our team reviews reports within 24 hours. False reports may result in consequences for the reporter.''',
                Icons.flag,
              ),
              _buildSection(
                'Consequences',
                '''
Violating community guidelines may result in:

- Content removal
- Warning notification
- Temporary suspension
- Permanent account ban
- Legal action (for severe violations)

Severity depends on the nature and frequency of violations.''',
                Icons.warning_amber,
              ),
              _buildSection(
                'Appeals',
                '''
If you believe action was taken against your account in error:

1. Go to Settings > Help & Support
2. Select "Appeal a Decision"
3. Provide your account details
4. Explain why you believe the decision was incorrect
5. Submit your appeal

Appeals are reviewed within 7 days.''',
                Icons.gavel,
              ),
              const SizedBox(height: 24),
              _buildTipsCard(),
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
                  Icons.people,
                  color: AppColors.brandCyan,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Community Guidelines',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comment Etiquette & Code of Conduct',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Our community thrives when everyone treats each other with respect. These guidelines help ensure SweepFeed remains a positive, helpful space for all contests enthusiasts.',
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

  Widget _buildCoreValueCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Card(
          color: AppColors.primaryMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildTipsCard() => Card(
        color: AppColors.brandCyan.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.brandCyan.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandCyan.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: AppColors.brandCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pro Tips',
                    style: TextStyle(
                      color: AppColors.brandCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTipItem('Engage genuinely with the community'),
              _buildTipItem('Share your wins AND losses - both teach!'),
              _buildTipItem('Help newcomers learn the ropes'),
              _buildTipItem("Report issues, don't retaliate"),
              _buildTipItem('Remember: everyone started somewhere'),
            ],
          ),
        ),
      );

  Widget _buildTipItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.brandCyan,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
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
              'SweepFeed Community Guidelines',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Version 1.0 - Last Updated December 2024',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Thank you for being part of our community!',
              style: TextStyle(
                color: AppColors.brandCyan,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}
