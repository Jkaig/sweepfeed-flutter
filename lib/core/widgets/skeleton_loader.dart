import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// A skeleton loader widget for contest cards
class ContestCardSkeleton extends StatelessWidget {
  const ContestCardSkeleton({
    super.key,
    this.height = 200,
  });

  final double height;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      baseColor: AppColors.primaryMedium,
      highlightColor: AppColors.primaryLight,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
}

/// A skeleton loader for list items
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({
    super.key,
    this.height = 80,
  });

  final double height;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
      baseColor: AppColors.primaryMedium,
      highlightColor: AppColors.primaryLight,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
}

/// A skeleton loader for contest feed
class ContestFeedSkeleton extends StatelessWidget {
  const ContestFeedSkeleton({
    super.key,
    this.itemCount = 3,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: ContestCardSkeleton(),
      ),
    );
}

/// A skeleton loader for grid view
class ContestGridSkeleton extends StatelessWidget {
  const ContestGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  final int itemCount;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ContestCardSkeleton(),
    );
}

