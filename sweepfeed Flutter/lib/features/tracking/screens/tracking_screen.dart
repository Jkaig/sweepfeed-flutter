import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweepfeed_app/features/subscription/screens/subscription_screen.dart';
import 'package:sweepfeed_app/core/widgets/paywall_widget.dart';
import 'package:sweepfeed_app/features/subscription/services/subscription_service.dart';
import '../services/tracking_service.dart';
import '../../contests/models/contest_model.dart';
import '../../contests/widgets/sweepstakes_card.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Contest> _allSweepstakes = []; // TODO: Load from Firebase
  bool _isLoading = true;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Entries'), // Changed to title case
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active (${_allSweepstakes.where((s) => s.endDate.isAfter(DateTime.now())).length})'),
            Tab(text: 'Daily (${_allSweepstakes.where((s) => s.frequency.toLowerCase() == 'daily').length})'),
            Tab(text: 'Ending Soon (${_allSweepstakes.where((s) => s.endDate.isAfter(DateTime.now()) && s.endDate.difference(DateTime.now()).inDays <= 3).length})'),
          ],
        ),
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, service, _) {
          if (!service.isSubscribed) {
            return PaywallWidget(
              message: 'Subscribe to track unlimited sweepstakes!',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildEntriesList(context.watch<TrackingService>().filterTrackedSweepstakes(_allSweepstakes)),
              _buildEntriesList(context.watch<TrackingService>().getDailyEntries(_allSweepstakes)),
              _buildEntriesList(context.watch<TrackingService>().getEndingSoon(_allSweepstakes)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEntriesList(List<Contest> entries) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries found'),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final contest = entries[index];
        return Dismissible(
          key: Key(contest.id),
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
            context.read<TrackingService>().untrackEntry(contest.id);
          },
          child: ListTile(
            title: Text(contest.title),
            subtitle: Text(contest.prizeFormatted),
            onTap: () {
              // TODO: Implement entry action
            },
          ),
          /*child: SweepstakesCard(
            sweepstakes: sweepstakes,
            onTap: () {
              // TODO: Implement entry action
            },
          ),*/
        );
      },
    );
  }
} 