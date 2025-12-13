import 'package:flutter/material.dart';
import '../models/enhanced_challenge.dart';

class ChallengeCategoryFilter extends StatelessWidget {
  const ChallengeCategoryFilter({
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });
  final ChallengeCategory? selectedCategory;
  final Function(ChallengeCategory?) onCategorySelected;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Category',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // All categories filter
                  _buildFilterChip(
                    label: 'All',
                    emoji: '📋',
                    isSelected: selectedCategory == null,
                    onTap: () => onCategorySelected(null),
                  ),

                  const SizedBox(width: 8),

                  // Individual category filters
                  ...ChallengeCategory.values.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: category.displayName,
                        emoji: category.emoji,
                        isSelected: selectedCategory == category,
                        onTap: () => onCategorySelected(category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF00E5FF),
                      Color(0xFF0288D1),
                    ],
                  )
                : null,
            color: isSelected ? null : const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : const Color(0xFF00E5FF).withValues(alpha: 0.3),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0A1929)
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}
