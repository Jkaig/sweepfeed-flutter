import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/models/contest.dart';
import '../../../core/providers/contest_providers.dart';
import '../providers/paginated_contests_provider.dart';
import '../widgets/unified_contest_card.dart';

class ContestListScreen extends ConsumerStatefulWidget {
  const ContestListScreen({super.key});

  @override
  ConsumerState<ContestListScreen> createState() => _ContestListScreenState();
}

class _ContestListScreenState extends ConsumerState<ContestListScreen> {
  String? selectedCategory;
  String sortBy = 'endDate';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final queryParams = ContestQueryParams(
      category: selectedCategory,
      sortBy: sortBy,
    );
    final paginatedContestNotifier =
        ref.watch(paginatedContestProvider(queryParams).notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'All Contests',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.filter_list, color: colorScheme.primary),
                onPressed: () => _showFilterBottomSheet(context),
              ),
            ],
          ),
          
          // Enhanced Filter Section (Horizontal Scroll)
          SliverToBoxAdapter(
            child: _buildFilterSection(context),
          ),

          // Paged List
          PagedSliverList<DocumentSnapshot?, Contest>(
            pagingController: paginatedContestNotifier.pagingController,
            builderDelegate: PagedChildBuilderDelegate<Contest>(
              animateTransitions: true,
              transitionDuration: const Duration(milliseconds: 500),
              itemBuilder: (context, item, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: UnifiedContestCard(
                    style: CardStyle.detailed, contest: item),
              ),
              firstPageErrorIndicatorBuilder: (context) => Center(
                child: Text('Something went wrong', style: textTheme.bodyMedium),
              ),
              noItemsFoundIndicatorBuilder: (context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No contests found', style: textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final categoriesAsync = ref.watch(availableCategoriesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return categoriesAsync.when(
      data: (categories) {
        final allCategories = ['All', ...categories];
        return Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final category = allCategories[index];
              final isSelected = category == 'All' 
                  ? selectedCategory == null 
                  : selectedCategory == category;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (category == 'All') {
                        selectedCategory = null;
                      } else {
                        selectedCategory = selected ? category : null;
                      }
                    });
                  },
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final categoriesAsync = ref.read(availableCategoriesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter & Sort', style: textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Category', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => selectedCategory = null);
                        Navigator.pop(context);
                      }
                    },
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: selectedCategory == null
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  ...categories.map(
                    (category) => ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedCategory = category);
                          Navigator.pop(context);
                        }
                      },
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceVariant,
                      labelStyle: TextStyle(
                        color: selectedCategory == category
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Failed to load categories'),
            ),
            const SizedBox(height: 24),
            Text('Sort by', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            Column(
              children: [
                RadioListTile<String>(
                  title: Text('Ending Soon', style: textTheme.bodyLarge),
                  value: 'endDate',
                  groupValue: sortBy,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    setState(() => sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text('Highest Value', style: textTheme.bodyLarge),
                  value: 'value',
                  groupValue: sortBy,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    setState(() => sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text('Recently Added', style: textTheme.bodyLarge),
                  value: 'createdAt',
                  groupValue: sortBy,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    setState(() => sortBy = value!);
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
}
