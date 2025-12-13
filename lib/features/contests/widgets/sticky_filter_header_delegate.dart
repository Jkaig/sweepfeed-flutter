import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StickyFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  StickyFilterHeaderDelegate({
    required this.child,
    this.minHeight = 60.0,
    this.maxHeight = 60.0,
  });

  final Widget child;
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent,) => Container(
      color: AppColors.primaryDark,
      alignment: Alignment.center,
      child: child,
    );

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant StickyFilterHeaderDelegate oldDelegate) => oldDelegate.child != child;
}

