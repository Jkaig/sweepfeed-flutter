import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/providers/contest_providers.dart';
import '../../../core/providers/gamification_provider.dart';

class ContestListScreen extends ConsumerStatefulWidget {
  const ContestListScreen({super.key});

  @override
  ConsumerState<ContestListScreen> createState() => _ContestListScreenState();
}

class _ContestListScreenState extends ConsumerState<ContestListScreen> {
  String? selectedCategory;
  String sortBy = 'endDate';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contestsAsync = ref.watch(
      activeContestsFutureProvider(
        ContestQueryParams(
          category: selectedCategory,
          sortBy: sortBy,
        ),
      ),
    );

    final categoriesAsync = ref.watch(availableCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        leading: Semantics(
          label: 'Back to home',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'All Contests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Semantics(
            label: 'Filter and sort contests',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Color(0xFF00E5FF)),
              onPressed: () => _showFilterBottomSheet(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (selectedCategory != null) ...[
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Semantics(
                    label: 'Active filter: $selectedCategory',
                    child: Chip(
                      label: Text(
                        selectedCategory!,
                        style: const TextStyle(color: Color(0xFF0A1929)),
                      ),
                      backgroundColor: const Color(0xFF00E5FF),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF0A1929),
                      ),
                      onDeleted: () {
                        setState(() {
                          selectedCategory = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Contest list
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF1E3A5F),
              onRefresh: () async {
                ref.invalidate(activeContestsFutureProvider);
              },
              child: contestsAsync.when(
                data: (contests) {
                  if (contests.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: contests.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildContestCard(contests[index]),
                    ),
                  );
                },
                loading: _buildLoadingState,
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestCard(Contest contest) {
    final timeRemaining = contest.daysRemaining == 0
        ? 'Ends today'
        : 'Ends in ${contest.daysRemaining} day${contest.daysRemaining > 1 ? 's' : ''}';

    final isUrgent = contest.daysRemaining <= 3;

    return Semantics(
      label:
          'Contest: ${contest.title} by ${contest.sponsor}, prize ${contest.value}, $timeRemaining',
      button: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent
                ? const Color(0xFFFF9800).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: isUrgent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    contest.category,
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Prize value
                Text(
                  contest.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contest title
            Text(
              contest.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Sponsor
            Text(
              contest.sponsor,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            // Bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time remaining
                Row(
                  children: [
                    Icon(
                      isUrgent ? Icons.warning : Icons.access_time,
                      color:
                          isUrgent ? const Color(0xFFFF9800) : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeRemaining,
                      style: TextStyle(
                        color:
                            isUrgent ? const Color(0xFFFF9800) : Colors.white70,
                        fontSize: 12,
                        fontWeight:
                            isUrgent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                // Enter button
                Semantics(
                  label: 'Enter ${contest.title} contest',
                  button: true,
                  child: ElevatedButton(
                    onPressed: () => _enterContest(contest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text(
                      'Enter',
                      style: TextStyle(
                        color: Color(0xFF0A1929),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading contests...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white.withValues(alpha: 0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              selectedCategory != null
                  ? 'No contests found in $selectedCategory'
                  : 'No contests available',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            if (selectedCategory != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                ),
                child: const Text(
                  'Show All Contests',
                  style: TextStyle(color: Color(0xFF0A1929)),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withValues(alpha: 0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load contests',
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(activeContestsFutureProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  void _showFilterBottomSheet(BuildContext context) {
    final categoriesAsync = ref.read(availableCategoriesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E3A5F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter & Sort',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Categories
            const Text(
              'Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // All categories chip
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedCategory = null;
                        });
                        Navigator.pop(context);
                      }
                    },
                    selectedColor: const Color(0xFF00E5FF),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: selectedCategory == null
                          ? const Color(0xFF0A1929)
                          : Colors.white,
                    ),
                  ),
                  ...categories.map(
                    (category) => ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                          Navigator.pop(context);
                        }
                      },
                      selectedColor: const Color(0xFF00E5FF),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: selectedCategory == category
                            ? const Color(0xFF0A1929)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Failed to load categories'),
            ),

            const SizedBox(height: 24),

            // Sort options
            const Text(
              'Sort by',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                RadioListTile<String>(
                  title: const Text(
                    'Ending Soon',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: 'endDate',
                  groupValue: sortBy,
                  activeColor: const Color(0xFF00E5FF),
                  onChanged: (value) {
                    setState(() {
                      sortBy = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text(
                    'Highest Value',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: 'value',
                  groupValue: sortBy,
                  activeColor: const Color(0xFF00E5FF),
                  onChanged: (value) {
                    setState(() {
                      sortBy = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text(
                    'Recently Added',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: 'createdAt',
                  groupValue: sortBy,
                  activeColor: const Color(0xFF00E5FF),
                  onChanged: (value) {
                    setState(() {
                      sortBy = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enterContest(Contest contest) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
        ),
      ),
    );

    try {
      // Enter contest (mock for now)
      await enterContest(contest.id ?? '');

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully entered ${contest.title}!'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enter contest: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
