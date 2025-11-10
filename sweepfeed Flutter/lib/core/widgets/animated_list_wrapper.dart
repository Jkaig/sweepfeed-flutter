import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Wrapper widget that adds staggered animations to list items
class AnimatedListWrapper extends StatelessWidget {
  const AnimatedListWrapper({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.controller,
    this.itemExtent,
    this.animationDuration = const Duration(milliseconds: 375),
    this.verticalOffset = 50.0,
    this.horizontalOffset = 0.0,
    this.delay = 0.05,
  });
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollController? controller;
  final double? itemExtent;
  final Duration animationDuration;
  final double verticalOffset;
  final double horizontalOffset;
  final double delay;

  @override
  Widget build(BuildContext context) => AnimationLimiter(
        child: ListView.builder(
          controller: controller,
          itemCount: itemCount,
          scrollDirection: scrollDirection,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          itemExtent: itemExtent,
          itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
            position: index,
            duration: animationDuration,
            delay: Duration(milliseconds: (delay * 1000).round()),
            child: SlideAnimation(
              verticalOffset:
                  scrollDirection == Axis.vertical ? verticalOffset : 0,
              horizontalOffset:
                  scrollDirection == Axis.horizontal ? horizontalOffset : 0,
              child: FadeInAnimation(
                child: itemBuilder(context, index),
              ),
            ),
          ),
        ),
      );
}

/// Grid version of the animated wrapper
class AnimatedGridWrapper extends StatelessWidget {
  const AnimatedGridWrapper({
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.controller,
    this.animationDuration = const Duration(milliseconds: 375),
    this.delay = 0.05,
  });
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollController? controller;
  final Duration animationDuration;
  final double delay;

  @override
  Widget build(BuildContext context) => AnimationLimiter(
        child: GridView.builder(
          controller: controller,
          itemCount: itemCount,
          gridDelegate: gridDelegate,
          scrollDirection: scrollDirection,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          itemBuilder: (context, index) => AnimationConfiguration.staggeredGrid(
            position: index,
            duration: animationDuration,
            delay: Duration(milliseconds: (delay * 1000).round()),
            columnCount: gridDelegate
                    is SliverGridDelegateWithFixedCrossAxisCount
                ? (gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
                    .crossAxisCount
                : 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: itemBuilder(context, index),
              ),
            ),
          ),
        ),
      );
}

/// Sliver version for use in CustomScrollView
class AnimatedSliverList extends StatelessWidget {
  const AnimatedSliverList({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.animationDuration = const Duration(milliseconds: 375),
    this.verticalOffset = 50.0,
    this.delay = 0.05,
  });
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration animationDuration;
  final double verticalOffset;
  final double delay;

  @override
  Widget build(BuildContext context) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => AnimationConfiguration.staggeredList(
            position: index,
            duration: animationDuration,
            delay: Duration(milliseconds: (delay * 1000).round()),
            child: SlideAnimation(
              verticalOffset: verticalOffset,
              child: FadeInAnimation(
                child: itemBuilder(context, index),
              ),
            ),
          ),
          childCount: itemCount,
        ),
      );
}
