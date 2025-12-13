import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/sweepstake.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/paywall_widget.dart';
import '../../subscription/screens/subscription_screen.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackedContests = ref.watch(trackingServiceProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('My Entries'), // Changed to title case
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text:
                    'Active (${trackedContests.where((s) => s.endDate.isAfter(DateTime.now())).length})',
              ),
              Tab(
                text:
                    'Daily (${trackedContests.where((s) => s.frequency.toLowerCase() == 'daily').length})',
              ),
              Tab(
                text:
                    'Ending Soon (${trackedContests.where((s) => s.endDate.isAfter(DateTime.now()) && s.endDate.difference(DateTime.now()).inDays <= 3).length})',
              ),
            ],
          ),
        ),
        body: Consumer(
          builder: (context, ref, _) {
            final subscriptionService = ref.watch(subscriptionServiceProvider);
            if (!subscriptionService.isSubscribed) {
              return PaywallWidget(
                message: 'Subscribe to track unlimited contests',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),),
                  );
                },
              );
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildEntriesList(
                  ref
                      .watch(trackingServiceProvider.notifier)
                      .filterTrackedSweepstakes(),
                ),
                _buildEntriesList(
                  ref.watch(trackingServiceProvider.notifier).getDailyEntries(),
                ),
                _buildEntriesList(
                  ref.watch(trackingServiceProvider.notifier).getEndingSoon(),
                ),
              ],
            );
          },
        ),
      );
  }

  Widget _buildEntriesList(List<Sweepstakes> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries found'),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final sweepstakes = entries[index];
        return Dismissible(
          key: Key(sweepstakes.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            ref
                .read(trackingServiceProvider.notifier)
                .untrackEntry(sweepstakes.id);
          },
          child: ListTile(
            title: Text(sweepstakes.title),
            subtitle: Text(sweepstakes.prize),
            onTap: () async {
              if (await canLaunch(sweepstakes.entryUrl)) {
                await launch(sweepstakes.entryUrl);
              }
            },
          ),
        );
      },
    );
  }
}
