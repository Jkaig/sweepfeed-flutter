import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import firebase_auth

import 'package:sweep_feed/core/models/contest_model.dart';
import 'package:sweep_feed/features/contests/services/contest_service.dart';
import 'package:sweep_feed/features/saved/services/saved_sweepstakes_service.dart';
import 'package:sweep_feed/core/analytics/analytics_service.dart';
import 'package:sweep_feed/features/comments/widgets/comment_section.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';
import 'package:sweep_feed/core/widgets/loading_indicator.dart';
import 'package:sweep_feed/core/widgets/primary_button.dart';
import 'package:sweep_feed/features/reminders/services/reminder_service.dart'; // Import ReminderService

class ContestDetailScreen extends StatefulWidget {
  final String contestId;

  const ContestDetailScreen({super.key, required this.contestId});

  @override
  _ContestDetailScreenState createState() => _ContestDetailScreenState();
}

class _ContestDetailScreenState extends State<ContestDetailScreen> {
  Future<Contest?>? _contestFuture;
  final ReminderService _reminderService = ReminderService();
  bool _hasReminder = false;
  bool _isReminderLoading = true;
  User? _currentUser;
  Contest? _currentContest; 

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadContestDetails();
    context.read<AnalyticsService>().logScreenView('ContestDetailScreen');
  }

  void _loadContestDetails() {
    _contestFuture = context.read<ContestService>().getContestById(widget.contestId);
    _contestFuture!.then((contest) {
      if (contest != null && _currentUser != null) {
        _currentContest = contest; // Store the contest
        _checkReminderStatus();
      } else {
         if (mounted) setState(() => _isReminderLoading = false);
      }
    });
  }

  Future<void> _checkReminderStatus() async {
    if (_currentUser == null || _currentContest == null) return;
    if (!mounted) return; 
    setState(() => _isReminderLoading = true);
    bool reminderExists = await _reminderService.hasReminder(_currentUser!.uid, _currentContest!.id);
    if (mounted) { 
      setState(() {
        _hasReminder = reminderExists;
        _isReminderLoading = false;
      });
    }
  }

  Future<void> _toggleReminder() async {
    if (_currentUser == null || _currentContest == null) return;
    final userId = _currentUser!.uid;
    final contest = _currentContest!;

    if (_hasReminder) {
      await _reminderService.removeReminder(userId, contest.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder cancelled.', style: AppTextStyles.bodyMedium)));
    } else {
      DateTime contestEndDate = contest.endDate;
      DateTime initialReminderDate = contestEndDate.subtract(const Duration(days: 1));
      
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialReminderDate.isAfter(DateTime.now()) ? initialReminderDate : DateTime.now().add(const Duration(days:1)),
        firstDate: DateTime.now(),
        lastDate: contestEndDate,
        helpText: 'Select Reminder Date',
         // TODO: Theme the DatePicker if needed via MaterialApp theme or builder
      );

      if (pickedDate != null && mounted) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialReminderDate),
          helpText: 'Select Reminder Time',
          // TODO: Theme the TimePicker if needed
        );

        if (pickedTime != null) {
          final DateTime finalReminderDateTime = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
          await _reminderService.addReminder(userId, contest, finalReminderDateTime);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${DateFormat.yMd().add_jm().format(finalReminderDateTime)}', style: AppTextStyles.bodyMedium)));
        }
      }
    }
    _checkReminderStatus(); // Refresh reminder state
  }


  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link: $urlString', style: AppTextStyles.bodySmall)),
        );
      }
    }
  }

  void _shareContest(String title, String contestId) {
    // Assuming a base URL, replace with your actual domain/path
    final contestUrl = 'https://yourapp.com/contest/$contestId';
    Share.share(
      'Check out this contest: $title! $contestUrl',
      subject: 'Awesome Contest: $title',
    );
    context.read<AnalyticsService>().logShare('contest', contestId, 'button');
  }

  @override
  Widget build(BuildContext context) {
    final savedService = context.watch<SavedSweepstakesService>();
    final isInitiallySaved = savedService.isSaved(widget.contestId);

    return Scaffold(
      backgroundColor: AppColors.primaryDark, 
      appBar: AppBar(
        title: Text('Contest Details', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.primaryMedium, 
        iconTheme: const IconThemeData(color: AppColors.textWhite), 
        actions: [
          IconButton(
            icon: _isReminderLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite))
                : Icon(_hasReminder ? Icons.alarm_on : Icons.alarm_add, color: _hasReminder ? AppColors.accent : AppColors.textWhite),
            tooltip: _hasReminder ? 'Cancel Reminder' : 'Set Reminder',
            onPressed: _isReminderLoading ? null : _toggleReminder,
          ),
          IconButton(
            icon: Icon(isInitiallySaved ? Icons.bookmark : Icons.bookmark_border, color: AppColors.accent),
            tooltip: isInitiallySaved ? 'Unsave' : 'Save',
            onPressed: () {
              context.read<AnalyticsService>().logContestSaved(widget.contestId, !isInitiallySaved);
              context.read<SavedSweepstakesService>().toggleSaved(widget.contestId);
            },
          ),
          FutureBuilder<Contest?>( 
            future: _contestFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.share, color: AppColors.textWhite),
                  onPressed: () => _shareContest(snapshot.data!.title, widget.contestId),
                );
              }
              return const SizedBox.shrink(); 
            }
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
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  snapshot.hasError ? 'Error: ${snapshot.error}' : 'Contest not found.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.errorRed),
                ),
              ),
            );
          }

          final contest = snapshot.data!;
          final dateFormat = DateFormat('MMMM d, yyyy');
          final entryUrl = contest.source['url'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contest.title,
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textWhite),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners for image
                  child: CachedNetworkImage( // Using CachedNetworkImage
                    imageUrl: contest.imageUrl,
                    height: 220, // Slightly larger image
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
                      child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Key Details with new styling
                _buildDetailRow(context, [
                  _buildDetailItem(Icons.event_busy_outlined, 'Ends', dateFormat.format(contest.endDate)),
                  _buildDetailItem(Icons.emoji_events_outlined, 'Prize', contest.prizeFormatted),
                ]),
                const SizedBox(height: 12),
                _buildDetailRow(context, [
                  _buildDetailItem(Icons.repeat_on_outlined, 'Frequency', contest.entryFrequency),
                  _buildDetailItem(Icons.flag_outlined, 'Eligibility', contest.eligibility),
                ]),
                if(contest.sponsor != null && contest.sponsor!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                   _buildDetailRow(context, [
                    _buildDetailItem(Icons.business_center_outlined, 'Sponsor', contest.sponsor!),
                  ]),
                ],

                const SizedBox(height: 20),
                Divider(color: AppColors.primaryLight.withOpacity(0.5)),
                const SizedBox(height: 12),
                
                // Tags/Categories - styled
                if (contest.categories.isNotEmpty || contest.badges.isNotEmpty) ...[
                  Text('Tags & Info', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...contest.categories.map((cat) => Chip(
                          label: Text(cat),
                          backgroundColor: AppColors.accent.withOpacity(0.15),
                          labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: AppColors.accent.withOpacity(0.3))
                          ),
                        )),
                      ...contest.badges.map((badge) => Chip(
                          label: Text(badge),
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: AppColors.primaryLight.withOpacity(0.3))
                          ),
                        )),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Entry Button
                if (entryUrl != null && entryUrl.isNotEmpty)
                  Center(
                    child: PrimaryButton( // Using new PrimaryButton
                      text: 'Enter Sweepstakes',
                      onPressed: () => _launchURL(entryUrl),
                      // icon: Icons.launch, // PrimaryButton doesn't have icon param by default
                    ),
                  ),
                
                // Comment Section Integration
                const SizedBox(height: 24),
                Text(
                  'Comments',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
                ),
                Divider(height: 20, color: AppColors.primaryLight.withOpacity(0.5), thickness: 0.5), // Adjusted divider
                CommentSection(sweepstakeId: contest.id),
                const SizedBox(height: 24), // Padding at the end
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper for a row of detail items
  Widget _buildDetailRow(BuildContext context, List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((entry) {
        int idx = entry.key;
        Widget widget = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: idx == 0 ? 0 : 8, right: idx == children.length - 1 ? 0 : 8),
            child: widget,
          ),
        );
      }).toList(),
    );
  }

  // Helper widget for key details, now using new styles
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
