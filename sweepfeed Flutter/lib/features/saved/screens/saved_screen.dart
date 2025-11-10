import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contest_model.dart';
import '../../../core/providers/providers.dart';
import '../../contests/widgets/contest_card.dart';
import '../widgets/contest_history_list.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  _SavedScreenState createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Contests'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Saved'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            SavedContestsList(),
            ContestHistoryList(),
          ],
        ),
      );
}

class SavedContestsList extends ConsumerStatefulWidget {
  const SavedContestsList({super.key});

  @override
  _SavedContestsListState createState() => _SavedContestsListState();
}

class _SavedContestsListState extends ConsumerState<SavedContestsList> {
  Future<List<Contest>>? _savedContestsFuture;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure ref is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedContests();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedContests();
  }

  void _loadSavedContests() {
    // No need to check for mounted here as this is managed by the widget lifecycle.
    final savedService = ref.read(savedSweepstakesServiceProvider);
    final contestService = ref.read(contestServiceProvider);
    final savedIds = savedService.getSavedIds().toList();

    if (savedIds.isNotEmpty) {
      if (mounted) {
        setState(() {
          _savedContestsFuture = contestService.fetchContestsByIds(savedIds);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _savedContestsFuture = Future.value([]);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-watch the provider to trigger rebuilds on change.
    ref.watch(savedSweepstakesServiceProvider);

    return FutureBuilder<List<Contest>>(
      future: _savedContestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading saved contests. Please try again.'),
          );
        }

        final savedContests = snapshot.data ?? [];

        if (savedContests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Saved Contests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Save contests to quickly access them later! Tap the bookmark icon on any contest card.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: savedContests.length,
          itemBuilder: (context, index) {
            final contest = savedContests[index];
            return ContestCard(contest: contest);
          },
        );
      },
    );
  }
}
