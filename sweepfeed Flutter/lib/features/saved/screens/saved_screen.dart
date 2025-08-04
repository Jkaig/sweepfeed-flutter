import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/saved_sweepstakes_service.dart';
import '../../contests/services/contest_service.dart'; 
import '../../contests/models/contest_model.dart'; 
import '../../contests/widgets/contest_card.dart'; 
import '../../../core/analytics/analytics_service.dart';
import '../../../core/models/contest_model.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  _SavedScreenState createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  Future<List<Contest>>? _savedContestsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedContests();
  }

  void _loadSavedContests() {
    final savedService = context.read<SavedSweepstakesService>();
    final contestService = context.read<ContestService>(); 
    final savedIds = savedService.getSavedIds().toList();

    if (savedIds.isNotEmpty) {
      setState(() {
        _savedContestsFuture = contestService.fetchContestsByIds(savedIds);
      });
    } else {
      setState(() {
        _savedContestsFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedService = context.watch<SavedSweepstakesService>();
    final currentSavedIds = savedService.getSavedIds();
    if (_savedContestsFuture == null ||
        _savedContestsFuture is Future<List<Contest>> &&
            currentSavedIds.length !=
                (_savedContestsFuture as Future<List<Contest>>)
                    .then((list) => list.length)) {
      _loadSavedContests();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Sweepstakes'), 
      ),
      body: FutureBuilder<List<Contest>>(
        future: _savedContestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              (snapshot.data == null || snapshot.data!.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(
                'Error loading saved contests: ${snapshot.error}'); 
            return const Center(
                child: Text('Error loading saved contests. Please try again.'));
          }

          final savedContests = snapshot.data ?? [];

          if (savedContests.isEmpty) {
            return const Center(
                child: Text('You haven\'t saved any sweepstakes yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedContests.length,
            itemBuilder: (context, index) {
              final contest = savedContests[index];
              return Stack(
                children: [
                  ContestCard(contest: contest),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(
                            Icons.bookmark), 
                        color: Theme.of(context).primaryColor,
                        tooltip: 'Unsave',
                        onPressed: () async {
                          context
                              .read<AnalyticsService>()
                              .logContestSaved(contest.id, false);
                          await context
                              .read<SavedSweepstakesService>()
                              .toggleSaved(contest.id);
                          _loadSavedContests();
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
