import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/recent_searches_provider.dart';
import '../widgets/search_result_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  List<Contest> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debouncer.call(() {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    // Check if search is unlocked
    final unlockService = ref.read(featureUnlockServiceProvider);
    final hasUnlockedSearch = await unlockService.hasUnlockedFeature('tool_search_pro');

    if (!hasUnlockedSearch && query.isNotEmpty) {
      if (mounted) {
        _showUnlockSearchDialog();
      }
      return;
    }

    final contestService = ref.read(contestServiceProvider);

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

    // Call the new Firestore search method
    final results = await contestService.searchContests(query);

    // Save to recent searches
    ref.read(recentSearchesProvider.notifier).addSearch(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _showUnlockSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          'Search Pro Locked',
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.warningOrange,
            ),
            const SizedBox(height: 16),
            Text(
              'Search is a premium feature!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Purchase "Search Pro" in the shop to unlock advanced search and find contests by title, sponsor, prize, and more!',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to shop - you'll need to add this navigation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
            ),
            child: const Text(
              'Go to Shop',
              style: TextStyle(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search contests...',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              // Search is triggered automatically via _onSearchChanged listener
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
            ),
          ],
        ),
        body: _buildSearchResults(),
      );

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const ContestFeedSkeleton(itemCount: 5);
    }

    if (_searchQuery.isEmpty) {
      return _buildSuggestionsView();
    }

    if (_searchQuery.length < 3) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'Search Term Too Short',
        message: 'Please enter at least 3 characters to search.',
        useDustBunny: true,
        dustBunnyImage: 'assets/images/dustbunnies/dustbunny_icon.png',
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No Results Found',
        message: 'No contests found for "$_searchQuery".\nTry a different search term.',
        useDustBunny: true,
        dustBunnyImage: 'assets/images/dustbunnies/dustbunny_sad.png',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _performSearch(_searchQuery);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        cacheExtent: 300,
        itemBuilder: (context, index) {
          final contest = _searchResults[index];
          return Padding(
            key: ValueKey('search_contest_${contest.id}'),
            padding: const EdgeInsets.only(bottom: 10),
            child: SearchResultTile(contest: contest),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsView() {
    final recentSearches = ref.watch(recentSearchesProvider);
    final popularSearches = ref.watch(popularSearchesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent Searches Section
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Searches',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ref.read(recentSearchesProvider.notifier).clearAll();
                },
                child: Text(
                  'Clear',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.brandCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((search) => _buildSearchChip(
              search,
              onTap: () => _selectSuggestion(search),
              onDelete: () {
                ref.read(recentSearchesProvider.notifier).removeSearch(search);
              },
            ),).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Popular Searches Section
        Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.brandCyan, size: 18),
            const SizedBox(width: 8),
            Text(
              'Popular Searches',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularSearches.map((search) => _buildSearchChip(
            search,
            onTap: () => _selectSuggestion(search),
            isPopular: true,
          ),).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchChip(
    String text, {
    required VoidCallback onTap,
    VoidCallback? onDelete,
    bool isPopular = false,
  }) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.only(
            left: 14,
            right: onDelete != null ? 4 : 14,
            top: 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: isPopular
                ? AppColors.brandCyan.withValues(alpha: 0.15)
                : AppColors.primaryMedium,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPopular
                  ? AppColors.brandCyan.withValues(alpha: 0.4)
                  : AppColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isPopular ? AppColors.brandCyan : AppColors.textLight,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
}
