import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

/// Comprehensive Contest Details Modal with 3 pages
class ContestDetailsModal extends StatefulWidget {
  const ContestDetailsModal({
    required this.contest,
    super.key,
  });
  final Map<String, dynamic> contest;

  @override
  State<ContestDetailsModal> createState() => _ContestDetailsModalState();
}

class _ContestDetailsModalState extends State<ContestDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  bool _isEntered = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final contest = widget.contest;
    final isHighValue =
        (int.tryParse(contest['prizeValue']?.toString() ?? '0') ?? 0) >= 5000;
    final bool isExpiringSoon = (contest['daysLeft'] ?? 30) <= 3;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: isHighValue ? AppColors.brandCyan : AppColors.electricBlue,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with contest info
              _buildHeader(contest, isHighValue, isExpiringSoon),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.brandCyan,
                  indicatorWeight: 3,
                  labelColor: AppColors.brandCyan,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(
                      text: 'Details',
                      icon: Icon(Icons.info_outline, size: 18),
                    ),
                    Tab(text: 'Rules', icon: Icon(Icons.rule, size: 18)),
                    Tab(
                      text: 'How to Enter',
                      icon: Icon(Icons.login, size: 18),
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(contest, scrollController),
                    _buildRulesTab(contest, scrollController),
                    _buildHowToEnterTab(contest, scrollController),
                  ],
                ),
              ),

              // Bottom action bar
              _buildBottomActionBar(contest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> contest,
    bool isHighValue,
    bool isExpiringSoon,
  ) =>
      Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Prize value with animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 32,
                  color: AppColors.brandCyan,
                ).animate().scale(duration: 500.ms).fadeIn(),
                Text(
                  contest['prizeValue'] ?? '1,000',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandCyan,
                  ),
                )
                    .animate()
                    .slideX(begin: 0.2, end: 0, duration: 500.ms)
                    .fadeIn(),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              contest['title'] ?? 'Amazing Contest',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Sponsor
            if (contest['sponsor'] != null)
              Text(
                'Sponsored by ${contest['sponsor']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),

            const SizedBox(height: 12),

            // Status badges
            Wrap(
              spacing: 8,
              children: [
                if (contest['isFeatured'] == true)
                  _buildBadge('FEATURED', AppColors.brandCyan, Icons.star),
                if (isExpiringSoon)
                  _buildBadge('ENDING SOON', Colors.red, Icons.timer),
                if (isHighValue)
                  _buildBadge('HIGH VALUE', AppColors.neonGreen, Icons.diamond),
                if (_isEntered)
                  _buildBadge(
                      'ENTERED', AppColors.neonGreen, Icons.check_circle),
              ],
            ),

            const SizedBox(height: 12),

            // Timer and entry count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: isExpiringSoon ? Colors.red : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ends in ${contest['daysLeft'] ?? 7} days',
                  style: TextStyle(
                    color: isExpiringSoon ? Colors.red : Colors.white70,
                  ),
                ),
                if (contest['entryCount'] != null) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${contest['entryCount']} entries',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  Widget _buildDetailsTab(
    Map<String, dynamic> contest,
    ScrollController scrollController,
  ) =>
      ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            'Description',
            Icons.description,
            contest['description'] ??
                "Enter this amazing sweepstakes for your chance to win! This is an incredible opportunity to win valuable prizes. Don't miss out on this exciting contest.",
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Prize Details',
            Icons.card_giftcard,
            null,
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Prize Value',
                  '\$${contest['prizeValue'] ?? '1,000'}',
                ),
                _buildDetailRow('Prize Type', contest['prizeType'] ?? 'Cash'),
                _buildDetailRow(
                  'Number of Winners',
                  contest['winnerCount']?.toString() ?? '1',
                ),
                _buildDetailRow(
                    'Drawing Date', contest['drawingDate'] ?? 'TBD'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Contest Information',
            Icons.info,
            null,
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Entry Frequency',
                  contest['entryFrequency'] ?? 'Once Daily',
                ),
                _buildDetailRow(
                  'Entry Method',
                  contest['entryMethod'] ?? 'Website Form',
                ),
                _buildDetailRow(
                  'Eligibility',
                  contest['eligibility'] ?? 'US Residents 18+',
                ),
                _buildDetailRow(
                  'Start Date',
                  contest['startDate'] ?? 'Active Now',
                ),
                _buildDetailRow('End Date', contest['endDate'] ?? 'See Timer'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Sponsor Information',
            Icons.business,
            null,
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Company',
                  contest['sponsor'] ?? 'Sweepstakes Co.',
                ),
                _buildDetailRow('Category', contest['category'] ?? 'General'),
                if (contest['sponsorWebsite'] != null)
                  InkWell(
                    onTap: () => _launchUrl(contest['sponsorWebsite']),
                    child: _buildDetailRow(
                      'Website',
                      contest['sponsorWebsite'],
                      isLink: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);

  Widget _buildRulesTab(
    Map<String, dynamic> contest,
    ScrollController scrollController,
  ) {
    final rules = contest['rules'] as List<String>? ??
        [
          'Must be 18 years or older to enter',
          'Legal residents of the United States only',
          'One entry per person per day',
          'No purchase necessary to enter or win',
          'Void where prohibited by law',
          'Winners will be selected at random',
          'Winners will be notified by email',
          'Prize must be claimed within 30 days',
          'Employees and family members are not eligible',
          'All federal, state, and local taxes are the responsibility of the winner',
        ];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection(
          'Official Rules',
          Icons.gavel,
          null,
          customContent: Column(
            children: [
              ...rules.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.brandCyan,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
              if (contest['rulesUrl'] != null)
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(contest['rulesUrl']),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Complete Rules'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildHowToEnterTab(
    Map<String, dynamic> contest,
    ScrollController scrollController,
  ) {
    final steps = contest['entrySteps'] as List<Map<String, String>>? ??
        [
          {
            'icon': 'web',
            'title': 'Visit Website',
            'description': 'Go to the contest website',
          },
          {
            'icon': 'form',
            'title': 'Fill Form',
            'description': 'Complete the entry form with your details',
          },
          {
            'icon': 'verify',
            'title': 'Verify Email',
            'description': 'Confirm your email address',
          },
          {
            'icon': 'done',
            'title': "You're Entered!",
            'description': 'Wait for the drawing date',
          },
        ];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection(
          'How to Enter',
          Icons.login,
          null,
          customContent: Column(
            children: [
              ...steps.asMap().entries.map((entry) {
                final step = entry.value;
                final isLast = entry.key == steps.length - 1;

                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.brandCyan.withValues(alpha: 0.8),
                                AppColors.brandCyan,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getStepIcon(step['icon'] ?? 'web'),
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${entry.key + 1}: ${step['title'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step['description'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Container(
                        margin:
                            const EdgeInsets.only(left: 30, top: 8, bottom: 8),
                        height: 30,
                        width: 2,
                        color: AppColors.brandCyan.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.brandCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.brandCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        contest['entryTip'] ??
                            'Pro Tip: Enter daily to maximize your chances of winning!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (contest['entryUrl'] != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isEntered = true);
                    HapticFeedback.heavyImpact();
                    _launchUrl(contest['entryUrl']);
                  },
                  icon: const Icon(Icons.launch),
                  label: const Text('Enter Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBottomActionBar(Map<String, dynamic> contest) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          border: Border(
            top: BorderSide(
              color: AppColors.brandCyan.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Save button
              IconButton(
                onPressed: () {
                  setState(() => _isSaved = !_isSaved);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isSaved ? 'Saved!' : 'Removed from saved'),
                      backgroundColor:
                          _isSaved ? AppColors.neonGreen : Colors.grey,
                    ),
                  );
                },
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? AppColors.brandCyan : Colors.white70,
                ),
                tooltip: 'Save',
              ),

              // Share button
              const IconButton(
                onPressed: HapticFeedback.lightImpact,
                icon: Icon(Icons.share, color: Colors.white70),
                tooltip: 'Share',
              ),

              const Spacer(),

              // Entry status or enter button
              if (_isEntered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neonGreen),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.neonGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Entered',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isEntered = true);
                    HapticFeedback.heavyImpact();
                    if (contest['entryUrl'] != null) {
                      _launchUrl(contest['entryUrl']);
                    }
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Quick Enter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildSection(
    String title,
    IconData icon,
    String? content, {
    Widget? customContent,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.electricBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.brandCyan, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (content != null)
              Text(
                content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            if (customContent != null) customContent,
          ],
        ),
      );

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: isLink ? AppColors.brandCyan : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBadge(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  IconData _getStepIcon(String iconName) {
    switch (iconName) {
      case 'web':
        return Icons.language;
      case 'form':
        return Icons.edit_note;
      case 'verify':
        return Icons.verified;
      case 'done':
        return Icons.celebration;
      default:
        return Icons.circle;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
