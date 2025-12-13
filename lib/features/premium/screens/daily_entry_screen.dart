import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/contest.dart';
import '../../../core/models/entry_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/paywall_widget.dart';
import '../../contests/screens/contest_detail_screen.dart';
import '../../subscription/screens/subscription_screen.dart';

class DailyEntryScreen extends ConsumerStatefulWidget {
  const DailyEntryScreen({super.key});

  @override
  DailyEntryScreenState createState() => DailyEntryScreenState();
}

class DailyEntryScreenState extends ConsumerState<DailyEntryScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<Contest> _dailyContests = [];
  List<Contest> _monthlyContests = [];
  bool _isLoading = true;
  bool _isEnteringAll = false;
  Map<String, bool> _entryStatusMap = {}; // contestId -> hasEnteredToday

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrackedContests();
    ref.read(analyticsServiceProvider).logScreenView(screenName: 'DailyEntryScreen');
  }

  Future<void> _loadTrackedContests() async {
    setState(() {
      _isLoading = true;
    });
    final contestService = ref.read(contestServiceProvider);
    final entryService = ref.read(entryManagementServiceProvider);
    final user = ref.read(firebaseAuthProvider).currentUser;
    
    try {
      final allContests = await contestService.getPremiumContests();
      if (mounted) {
        final daily = allContests
            .where((c) => c.frequency.toLowerCase() == 'daily')
            .toList();
        final monthly = allContests
            .where((c) => c.frequency.toLowerCase() == 'monthly')
            .toList();
        
        // Check entry status for each contest
        final statusMap = <String, bool>{};
        if (user != null) {
          for (final contest in daily) {
            try {
              final status = await entryService.getDailyEntryStatus(
                user.uid,
                contest.id,
              );
              statusMap[contest.id] = !status['canEnter'];
            } catch (e) {
              statusMap[contest.id] = false;
            }
          }
        }
        
        setState(() {
          _dailyContests = daily;
          _monthlyContests = monthly;
          _entryStatusMap = statusMap;
        });
      }
    } catch (e) {
      logger.e('Error loading tracked contests', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _enterAllDailies() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to enter contests'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    
    setState(() {
      _isEnteringAll = true;
    });
    
    final entryService = ref.read(entryManagementServiceProvider);
    final availableContests = _dailyContests
        .where((c) => !(_entryStatusMap[c.id] ?? false))
        .toList();
    
    if (availableContests.isEmpty) {
      setState(() {
        _isEnteringAll = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All daily contests have been entered today!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      return;
    }
    
    try {
      // Use Contest directly (Sweepstakes is just a type alias)
      final sweepstakes = availableContests;
      
      final entries = await entryService.submitBulkEntries(
        contests: sweepstakes,
        method: EntryMethod.website,
      );
      
      // Update entry status map
      for (final entry in entries) {
        _entryStatusMap[entry.contestId] = true;
      }
      
      if (mounted) {
        setState(() {
          _isEnteringAll = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully entered ${entries.length} contest${entries.length != 1 ? 's' : ''}!',
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Refresh the list
        await _loadTrackedContests();
      }
    } catch (e) {
      logger.e('Error entering all dailies', error: e);
      if (mounted) {
        setState(() {
          _isEnteringAll = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
  
  int get _remainingDailiesCount {
    return _dailyContests
        .where((c) => !(_entryStatusMap[c.id] ?? false))
        .length;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Entry Checklist'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Daily (${_dailyContests.length})'),
              Tab(text: 'Monthly (${_monthlyContests.length})'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh List',
              onPressed: _isLoading ? null : _loadTrackedContests,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Consumer(
                builder: (context, ref, _) {
                  final subscriptionService =
                      ref.watch(subscriptionServiceProvider);
                  if (subscriptionService.hasPremiumAccess) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDailyTab(),
                        _buildContestList(_monthlyContests, isDaily: false),
                      ],
                    );
                  } else {
                    return PaywallWidget(
                      message:
                          'Subscribe to Premium to access the daily entry checklist.',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
      );

  Widget _buildDailyTab() {
    return Column(
      children: [
        // Aggregated Status Widget
        _buildStatusCard(),
        // Enter All Button
        if (_remainingDailiesCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isEnteringAll ? null : _enterAllDailies,
                icon: _isEnteringAll
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flash_on),
                label: Text(
                  _isEnteringAll
                      ? 'Entering...'
                      : 'Enter All Dailies ($_remainingDailiesCount)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandCyan,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        // Contest List
        Expanded(
          child: _buildContestList(_dailyContests, isDaily: true),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final remaining = _remainingDailiesCount;
    final total = _dailyContests.length;
    final completed = total - remaining;
    final percentage = total > 0 ? (completed / total) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryMedium,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandCyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Entry Status',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: remaining > 0
                      ? AppColors.warningOrange.withOpacity(0.2)
                      : AppColors.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: remaining > 0
                        ? AppColors.warningOrange
                        : AppColors.successGreen,
                  ),
                ),
                child: Text(
                  '$remaining left',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: remaining > 0
                        ? AppColors.warningOrange
                        : AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage == 1.0
                    ? AppColors.successGreen
                    : AppColors.brandCyan,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Completed',
                '$completed',
                AppColors.successGreen,
                Icons.check_circle,
              ),
              _buildStatItem(
                'Remaining',
                '$remaining',
                AppColors.warningOrange,
                Icons.pending,
              ),
              _buildStatItem(
                'Total',
                '$total',
                AppColors.brandCyan,
                Icons.list,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildContestList(List<Contest> contests, {required bool isDaily}) {
    if (contests.isEmpty) {
      final frequency = isDaily ? 'Daily' : 'Monthly';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'All Caught Up!',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tracked contests marked for $frequency entry found.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: contests.length,
      itemBuilder: (context, index) {
        final contest = contests[index];
        final hasEntered = _entryStatusMap[contest.id] ?? false;
        return _buildContestTile(contest, hasEntered, isDaily);
      },
    );
  }

  Widget _buildContestTile(Contest contest, bool hasEntered, bool isDaily) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppColors.primaryMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasEntered
              ? AppColors.successGreen.withOpacity(0.3)
              : AppColors.primaryLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasEntered
                ? AppColors.successGreen.withOpacity(0.2)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasEntered
                  ? AppColors.successGreen
                  : AppColors.brandCyan.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            hasEntered ? Icons.check_circle : Icons.radio_button_unchecked,
            color: hasEntered ? AppColors.successGreen : AppColors.brandCyan,
            size: 28,
          ),
        ),
        title: Text(
          contest.title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
            decoration: hasEntered ? TextDecoration.lineThrough : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 14,
                  color: AppColors.brandCyan,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    contest.prizeFormatted,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.brandCyan,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ends ${DateFormat.yMd().format(contest.endDate)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            if (hasEntered && isDaily) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Entered today',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.successGreen,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          color: AppColors.brandCyan,
          tooltip: 'View Details',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContestDetailScreen(contestId: contest.id),
              ),
            );
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContestDetailScreen(contestId: contest.id),
            ),
          );
        },
      ),
    );
  }
}
