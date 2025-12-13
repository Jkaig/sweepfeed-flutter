import 'package:flutter/material.dart';

import '../../../core/widgets/glassmorphic_container.dart';

class GlassmorphicTabBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassmorphicTabBar({
    required this.tabs, super.key,
    this.controller,
  });

  final List<Widget> tabs;
  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 0,
      blur: 15,
      colors: [
        Theme.of(context).colorScheme.background.withOpacity(0.5),
        Theme.of(context).colorScheme.background.withOpacity(0.5),
      ],
      child: TabBar(
        controller: controller,
        tabs: tabs,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
