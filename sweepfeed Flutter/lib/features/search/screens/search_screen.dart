import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../contests/services/contest_service.dart';
import '../../contests/models/contest_model.dart';
import '../../contests/widgets/contest_card.dart';
import '../../saved/services/saved_sweepstakes_service.dart';
import '../../../core/analytics/analytics_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contest> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final analyticsService = context.read<AnalyticsService>(); // Get service
    final contestService = context.read<ContestService>();

    if (query.isEmpty || query.length < 3) {
      setState(() {
        _searchResults = [];
        _searchQuery = query;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    // Log search event
    analyticsService.logSearch(query);

    // Call the new Firestore search method
    final results = await contestService.searchContests(query);

    // No artificial delay needed now

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedService = context.watch<SavedSweepstakesService>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search sweepstakes...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            // Optional: Trigger search dynamically as user types (debounce needed)
          },
          onSubmitted: _performSearch, // Trigger search on submit
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear search',
            onPressed: () {
              _searchController.clear();
              _performSearch(''); // Clear results
            },
          )
        ],
      ),
      body: _buildSearchResults(savedService),
    );
  }

  Widget _buildSearchResults(SavedSweepstakesService savedService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return const Center(
          child: Text('Enter a search term (3+ chars) to begin.'));
    }

    if (_searchResults.isEmpty && _searchQuery.length >= 3) {
      return Center(
        child: Text('No results found for "$_searchQuery"'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final contest = _searchResults[index];
        final isSaved = savedService.isSaved(contest.id);
        // Use Stack and ContestCard similar to HomeScreen
        return Stack(
          children: [
            ContestCard(contest: contest),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        isSaved ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  tooltip: isSaved ? 'Unsave' : 'Save',
                  onPressed: () {
                    // Use read here as we are in a callback
                    context
                        .read<SavedSweepstakesService>()
                        .toggleSaved(contest.id);
                    // No need to force rebuild here, Consumer/Watch handles it
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
