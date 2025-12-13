import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/responsive_helper.dart';
import 'filter_chip.dart';

class ContestFilterBar extends ConsumerWidget {
  const ContestFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(activeContestFilterProvider);

    final filters = [
      {'id': 'all', 'label': 'All', 'icon': Icons.grid_view},
      {'id': 'new', 'label': 'Newest', 'icon': Icons.new_releases},
      {'id': 'ending_soon', 'label': 'Ending Soon', 'icon': Icons.timer},
      {'id': 'cash', 'label': 'Cash', 'icon': Icons.attach_money},
      {'id': 'tech', 'label': 'Tech', 'icon': Icons.devices},
      {'id': 'travel', 'label': 'Travel', 'icon': Icons.flight},
      {'id': 'cars', 'label': 'Cars', 'icon': Icons.directions_car},
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalPadding(context),
        ),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final id = filter['id']! as String;
          final isActive = activeFilter == id;

          return ContestFilterChip(
            label: filter['label']! as String,
            icon: filter['icon']! as IconData,
            isActive: isActive,
            onTap: () {
              ref.read(activeContestFilterProvider.notifier).state = id;
              // Add simple vibration or sound feedback here if desired
            },
          );
        },
      ),
    );
  }
}

