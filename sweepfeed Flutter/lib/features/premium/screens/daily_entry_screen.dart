import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/contest_model.dart';
import '../../../core/providers/providers.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrackedContests();
    ref.read(analyticsServiceProvider).logScreenView('DailyEntryScreen');
  }

  Future<void> _loadTrackedContests() async {
    setState(() {
      _isLoading = true;
    });
    final contestService = ref.read(contestServiceProvider);
    try {
      final allContests = await contestService.getPremiumContests();
      if (mounted) {
        setState(() {
          _dailyContests = allContests
              .where((c) => c.frequency.toLowerCase() == 'daily')
              .toList();
          _monthlyContests = allContests
              .where((c) => c.frequency.toLowerCase() == 'monthly')
              .toList();
        });
      }
    } catch (e) {
      logger.e('Error loading tracked contests', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                        _buildContestList(_dailyContests),
                        _buildContestList(_monthlyContests),
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

  Widget _buildContestList(List<Contest> contests) {
    if (contests.isEmpty) {
      final frequency = _tabController?.index == 0 ? 'Daily' : 'Monthly';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No tracked sweepstakes marked for $frequency entry found.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: contests.length,
      itemBuilder: (context, index) {
        final contest = contests[index];
        const isCompleted = false; // Placeholder
        return ListTile(
          title: Text(
            contest.title,
            style: const TextStyle(
              decoration: TextDecoration.none,
            ),
          ),
          subtitle: Text(
            '${contest.prizeFormatted} - Ends ${DateFormat.yMd().format(contest.endDate)}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.info_outline),
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
            // Placeholder for marking as complete
          },
        );
      },
    );
  }
}
