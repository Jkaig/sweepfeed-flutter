import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/contest_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/webview_screen.dart';
import '../widgets/comment_section.dart';
import '../widgets/contest_share_dialog.dart';

/// Displays the details for a single contest.
class ContestDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [ContestDetailScreen].
  const ContestDetailScreen({
    required this.contestId,
    super.key,
  });

  /// The ID of the contest to display.
  final String contestId;

  @override
  ConsumerState<ContestDetailScreen> createState() =>
      _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen>
    with SingleTickerProviderStateMixin {
  Future<Contest?>? _contestFuture;
  late AnimationController _bookmarkAnimationController;
  late Animation<double> _bookmarkScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadContestDetails();
    _bookmarkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bookmarkScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _bookmarkAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  void _loadContestDetails() {
    _contestFuture =
        ref.read(sweepstakeServiceProvider).getContestById(widget.contestId);
  }

  Future<void> _openWebView(Contest contest) async {
    final entered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: contest.entryUrl,
          title: contest.title,
        ),
      ),
    );

    if (entered == true && mounted) {
      _showPostEntryDialog(contest);
    }
  }

  void _showPostEntryDialog(Contest contest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: AppColors.accent, size: 28),
            SizedBox(width: 12),
            Text('Success!', style: TextStyle(color: AppColors.textWhite)),
          ],
        ),
        content: const Text(
          'What would you like to do next?',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final userId = ref.read(firebaseServiceProvider).currentUser?.uid;
              if (userId != null) {
                ref
                    .read(entryServiceProvider)
                    .enterSweepstake(userId, contest.id, contest: contest);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Entered! Good luck!'),
                      ],
                    ),
                    backgroundColor: AppColors.successGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Mark as Entered',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showContestShareDialog(context, contest);
            },
            icon: const Icon(
              Icons.share,
              color: AppColors.electricBlue,
              size: 20,
            ),
            label: const Text(
              'Share Contest',
              style: TextStyle(color: AppColors.electricBlue),
            ),
          ),
          ..._generateReminderActions(contest),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateReminderActions(Contest contest) {
    final actions = <Widget>[];
    final reminderService = ref.read(reminderServiceProvider);

    void schedule(Duration duration, String message) {
      final reminderTime = DateTime.now().add(duration);
      reminderService.scheduleReminder(contest, reminderTime);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    switch (contest.entryFrequency) {
      case 'Daily':
        actions.add(
          TextButton(
            onPressed: () => schedule(
              const Duration(days: 1),
              'Reminder set for tomorrow!',
            ),
            child: const Text('Remind Me Tomorrow'),
          ),
        );
        break;
      case 'Weekly':
        actions.add(
          TextButton(
            onPressed: () => schedule(
              const Duration(days: 7),
              'Reminder set for next week!',
            ),
            child: const Text('Remind Me Next Week'),
          ),
        );
        break;
      case 'Monthly':
        actions.add(
          TextButton(
            onPressed: () => schedule(
              const Duration(days: 30),
              'Reminder set for next month!',
            ),
            child: const Text('Remind Me Next Month'),
          ),
        );
        break;
    }
    return actions;
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      return;
    }
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link: $urlString')),
        );
      }
    }
  }

  void _shareContest(String title, String contestId) {
    final contestUrl = 'https://yourapp.com/contest/$contestId';
    Share.share(
      'Check out this contest: $title! $contestUrl',
      subject: 'Awesome Contest: $title',
    );
    ref.read(analyticsServiceProvider).logShare(contestId: contestId);
  }

  void _copyContestLink(String contestId) {
    final contestUrl = 'https://yourapp.com/contest/$contestId';
    Clipboard.setData(ClipboardData(text: contestUrl));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Link copied to clipboard!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }

    ref.read(analyticsServiceProvider).logEvent(
        eventName: 'contest_link_copied',
        parameters: {'contest_id': contestId});
  }

  @override
  Widget build(BuildContext context) {
    ref
        .read(analyticsServiceProvider)
        .logScreenView(screenName: 'ContestDetailScreen');
    final savedService = ref.watch(savedSweepstakesServiceProvider);
    final isInitiallySaved = savedService.isSaved(widget.contestId);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'Contest Details',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primaryMedium,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        actions: [
          IconButton(
            icon: ScaleTransition(
              scale: _bookmarkScaleAnimation,
              child: Icon(
                isInitiallySaved ? Icons.bookmark : Icons.bookmark_border,
                color: AppColors.accent,
              ),
            ),
            tooltip: isInitiallySaved ? 'Unsave' : 'Save',
            onPressed: () {
              _bookmarkAnimationController
                  .forward()
                  .then((_) => _bookmarkAnimationController.reverse());
              ref.read(analyticsServiceProvider).logContestSaved(
                  contestId: widget.contestId, isSaved: !isInitiallySaved);
              ref
                  .read(savedSweepstakesServiceProvider)
                  .toggleSaved(widget.contestId);
            },
          ),
          FutureBuilder<Contest?>(
            future: _contestFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final contest = snapshot.data!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (Platform.isIOS &&
                        contest.endDate.difference(DateTime.now()).inHours < 24)
                      IconButton(
                        icon: const Icon(
                          Icons.timer_outlined,
                          color: AppColors.textWhite,
                        ),
                        tooltip: 'Start Countdown',
                        onPressed: () {
                          ref
                              .read(liveActivityServiceProvider)
                              .startLiveActivity(contest.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Live countdown started!'),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.textWhite),
                      tooltip: 'Copy Link',
                      onPressed: () => _copyContestLink(widget.contestId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: AppColors.textWhite),
                      tooltip: 'Share',
                      onPressed: () =>
                          showContestShareDialog(context, snapshot.data!),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Contest?>(
        future: _contestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.hasError
                      ? 'Error: ${snapshot.error}'
                      : 'Contest not found.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            );
          }

          final contest = snapshot.data!;
          final dateFormat = DateFormat('MMMM d, yyyy');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contest.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 12),
                Hero(
                  tag: 'contest-image-${contest.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: contest.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 220,
                        color: AppColors.primaryLight,
                        child: const Center(child: LoadingIndicator(size: 30)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: AppColors.primaryLight,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(context, [
                  if (contest.startDate != null)
                    _buildDetailItem(
                      Icons.event_available_outlined,
                      'Starts',
                      dateFormat.format(contest.startDate!),
                    ),
                  _buildDetailItem(
                    Icons.event_busy_outlined,
                    'Ends',
                    dateFormat.format(contest.endDate),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildDetailRow(context, [
                  _buildDetailItem(
                    Icons.emoji_events_outlined,
                    'Prize',
                    contest.prizeFormatted,
                  ),
                  _buildDetailItem(
                    Icons.repeat_on_outlined,
                    'Frequency',
                    contest.entryFrequency,
                  ),
                ]),
                const SizedBox(height: 12),
                _buildDetailRow(context, [
                  _buildDetailItem(
                    Icons.flag_outlined,
                    'Eligibility',
                    contest.eligibility,
                  ),
                  if (contest.sponsor.isNotEmpty)
                    _buildDetailItem(
                      Icons.business_center_outlined,
                      'Sponsor',
                      contest.sponsor,
                    ),
                ]),
                if (contest.rulesUrl != null &&
                    contest.rulesUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _launchURL(contest.rulesUrl),
                      icon: const Icon(Icons.gavel_outlined, size: 16),
                      label: const Text('View Official Rules'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Divider(color: AppColors.primaryLight.withAlpha(128)),
                const SizedBox(height: 12),
                if (contest.categories.isNotEmpty ||
                    contest.badges.isNotEmpty) ...[
                  Text(
                    'Tags & Info',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.textWhite),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...contest.categories.map(
                        (cat) => Chip(
                          label: Text(cat),
                          backgroundColor: AppColors.accent.withAlpha(38),
                          labelStyle: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                              color: AppColors.accent.withAlpha(77),
                            ),
                          ),
                        ),
                      ),
                      ...contest.badges.map(
                        (badge) => Chip(
                          label: Text(badge),
                          backgroundColor: AppColors.primaryLight.withAlpha(51),
                          labelStyle: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textLight),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                              color: AppColors.primaryLight.withAlpha(77),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (contest.entryUrl.isNotEmpty)
                  Center(
                    child: PrimaryButton(
                      text: 'Enter Sweepstakes',
                      onPressed: () => _openWebView(contest),
                    ),
                  ),
                const SizedBox(height: 32),
                CommentSection(contestId: contest.id),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .asMap()
            .entries
            .map(
              (entry) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: entry.key == 0 ? 0 : 8,
                    right: entry.key == children.length - 1 ? 0 : 8,
                  ),
                  child: entry.value,
                ),
              ),
            )
            .toList(),
      );

  Widget _buildDetailItem(IconData icon, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}
