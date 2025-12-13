import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

/// Screen displaying algorithm transparency and compliance information
/// Required for App Store Connect and regulatory compliance
class AlgorithmTransparencyScreen extends StatelessWidget {
  const AlgorithmTransparencyScreen({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(
        title: 'Algorithm Transparency',
        leading: CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brandCyan.withValues(alpha: 0.3),
                            AppColors.brandCyan.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        size: 48,
                        color: AppColors.brandCyan,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How Our Algorithms Work',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transparent information about our personalization systems',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Algorithm Overview
            _buildSection(
              'Algorithm Purpose',
              Icons.auto_awesome,
              [
                _buildBulletPoint(
                  'SweepFeed uses algorithmic systems to personalize contest recommendations and improve your experience.',
                ),
                _buildBulletPoint(
                  'Our algorithms help you discover contests that match your interests and preferences.',
                ),
                _buildBulletPoint(
                  'All algorithms are designed to enhance your experience while respecting your privacy and choices.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // How It Works
            _buildSection(
              'How It Works',
              Icons.settings,
              [
                _buildSubsection(
                  'Collaborative Filtering',
                  'Recommends contests based on what users with similar interests have liked',
                ),
                _buildSubsection(
                  'Content-Based Filtering',
                  'Matches contests to your selected categories and prize preferences',
                ),
                _buildSubsection(
                  'Hybrid System',
                  'Combines both methods (60% collaborative, 40% content-based) for balanced recommendations',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data Used
            _buildSection(
              'Data Used',
              Icons.data_usage,
              [
                _buildBulletPoint(
                  'Your explicit category selections and preferences',
                ),
                _buildBulletPoint(
                  'Contest viewing, saving, and entry history',
                ),
                _buildBulletPoint(
                  'Category click frequency and engagement patterns',
                ),
                _buildBulletPoint(
                  'Prize value range preferences',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.brandCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.brandCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We do not use location, payment, or sensitive personal data for recommendations.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.brandCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // User Controls
            _buildSection(
              'Your Controls',
              Icons.tune,
              [
                _buildBulletPoint(
                  'Disable personalization in Settings → Privacy Settings',
                ),
                _buildBulletPoint(
                  'Update your category preferences anytime',
                ),
                _buildBulletPoint(
                  "Dismiss contests you don't like (negative feedback)",
                ),
                _buildBulletPoint(
                  'Clear your interest profile or delete your account',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Impact
            _buildSection(
              'Impact on Your Experience',
              Icons.trending_up,
              [
                _buildSubsection(
                  'Positive',
                  '• See contests relevant to your interests\n• Save time with personalized filtering\n• Discover new contests through similar users',
                ),
                const SizedBox(height: 8),
                _buildSubsection(
                  'Limitations',
                  '• New users may see less personalized recommendations\n• May create "filter bubbles" if you only engage with limited categories\n• Popular contests may dominate recommendations',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Compliance
            _buildSection(
              'Compliance',
              Icons.verified,
              [
                _buildBulletPoint(
                  'GDPR Compliant: You can access, modify, or delete your data',
                ),
                _buildBulletPoint(
                  'CCPA Compliant: You can opt-out and request data deletion',
                ),
                _buildBulletPoint(
                  'App Store Compliant: Full algorithm disclosure provided',
                ),
                _buildBulletPoint(
                  'EU Digital Services Act: Algorithm transparency requirements met',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Full Documentation Link
            Card(
              color: AppColors.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                ),
              ),
              child: InkWell(
                onTap: () => _launchURL('https://sweepfeed.com/algorithm-transparency'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brandCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppColors.brandCyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Full Documentation',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View complete algorithm documentation',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.brandCyan,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.help_outline,
                        color: AppColors.brandCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Questions?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For algorithm questions or data rights requests:\n• Email: support@sweepfeed.app\n• Subject: "Algorithm Transparency Inquiry"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );

  Widget _buildSection(String title, IconData icon, List<Widget> children) => Card(
      color: AppColors.primaryMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.brandCyan.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.brandCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );

  Widget _buildBulletPoint(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.brandCyan,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildSubsection(String title, String content) => Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
}
