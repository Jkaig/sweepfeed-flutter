import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A widget that displays a shimmer loading effect for the home screen.
class HomeScreenLoadingShimmer extends StatelessWidget {
  /// Creates a [HomeScreenLoadingShimmer].
  const HomeScreenLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer for DailyStatsCard
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: ShimmerBox(height: 150, width: double.infinity),
              ),
              // Shimmer for Section Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ShimmerBox(height: 24, width: 150),
              ),
              // Shimmer for Checklist
              const ShimmerListItem(),
              const ShimmerListItem(),
              const ShimmerListItem(),
              // Shimmer for Section Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ShimmerBox(height: 24, width: 200),
              ),
              // Shimmer for Featured Contests
              SizedBox(
                height: 310,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ShimmerBox(height: 310, width: 300),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// A box that displays a shimmer effect.
class ShimmerBox extends StatelessWidget {
  /// Creates a [ShimmerBox].
  const ShimmerBox({
    required this.height,
    required this.width,
    super.key,
  });

  /// The height of the box.
  final double height;

  /// The width of the box.
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      );
}

/// A list item that displays a shimmer effect.
class ShimmerListItem extends StatelessWidget {
  /// Creates a [ShimmerListItem].
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            ShimmerBox(height: 60, width: 60),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 20, width: double.infinity),
                  SizedBox(height: 8),
                  ShimmerBox(height: 16, width: 100),
                ],
              ),
            ),
          ],
        ),
      );
}
