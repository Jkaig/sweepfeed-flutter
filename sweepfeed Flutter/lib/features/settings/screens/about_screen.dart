import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = '1.0.0';
          _buildNumber = '1';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'SweepFeed',
      applicationVersion: _version,
      applicationLegalese: '© 2024 SweepFeed. All rights reserved.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: const CustomAppBar(
          title: 'About',
          leading: CustomBackButton(),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandCyan,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Info Header
                    Card(
                      color: AppColors.primaryMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.brandCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.brandCyan.withValues(alpha: 0.3),
                                    AppColors.brandCyan.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.brandCyan
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons
                                    .catching_pokemon_outlined, // Use app logo here
                                size: 64,
                                color: AppColors.brandCyan,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'SweepFeed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Discover amazing sweepstakes and win incredible prizes',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.brandCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.brandCyan
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'Version $_version ($_buildNumber)',
                                style: const TextStyle(
                                  color: AppColors.brandCyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Details Section
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outlined,
                                  color: AppColors.brandCyan,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'App Information',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoTile(
                              'Version',
                              '$_version ($_buildNumber)',
                              Icons.info_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoTile(
                              'Developer',
                              'SweepFeed Team',
                              Icons.code,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoTile(
                              'Release Date',
                              'December 2024',
                              Icons.calendar_today,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoTile(
                              'Platform',
                              'Android & iOS',
                              Icons.phone_android,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Legal & Privacy Section
                    Card(
                      color: AppColors.primaryMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.brandCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: AppColors.brandCyan,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Legal & Privacy',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildActionTile(
                              'Terms of Service',
                              'Read our terms and conditions',
                              Icons.description_outlined,
                              () => _launchURL('https://sweepfeed.com/terms'),
                            ),
                            Divider(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.5),
                              height: 1,
                            ),
                            _buildActionTile(
                              'Privacy Policy',
                              'Learn how we protect your privacy',
                              Icons.privacy_tip_outlined,
                              () => _launchURL('https://sweepfeed.com/privacy'),
                            ),
                            Divider(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.5),
                              height: 1,
                            ),
                            _buildActionTile(
                              'Open Source Licenses',
                              'View third-party licenses',
                              Icons.gavel_outlined,
                              _showLicenses,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contact & Support Section
                    Card(
                      color: AppColors.primaryMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.brandCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.contact_support,
                                    color: AppColors.brandCyan,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Contact & Support',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildActionTile(
                              'Website',
                              'Visit sweepfeed.com',
                              Icons.language,
                              () => _launchURL('https://sweepfeed.com'),
                            ),
                            Divider(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.5),
                              height: 1,
                            ),
                            _buildActionTile(
                              'Support Email',
                              'support@sweepfeed.com',
                              Icons.email_outlined,
                              () => _launchURL('mailto:support@sweepfeed.com'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Copyright Footer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brandCyan.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        '© 2024 SweepFeed. All rights reserved.\nMade with ❤️ for sweepstakes enthusiasts',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
      );

  Widget _buildInfoTile(String title, String value, IconData icon) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.brandCyan,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) =>
      ListTile(
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
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textLight,
          size: 16,
        ),
        onTap: onTap,
      );
}
