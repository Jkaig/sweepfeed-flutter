import 'package:flutter/material.dart';

import '../../../core/widgets/daily_checklist_item.dart';

class DailyChecklistCard extends StatelessWidget {
  static const double horizontalSpace = 16;
  const DailyChecklistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          SizedBox(width: horizontalSpace),
          DailyChecklistItem(
            imageUrl: "https://www.vectorlogo.zone/logos/7eleven/7eleven-icon.svg",
            title: "$10 gift card",
            subtitle: "Entered",
            buttonLabel: "Entered",
          ),
          SizedBox(width: 16),
           DailyChecklistItem(
            imageUrl: "https://www.vectorlogo.zone/logos/pepsico/pepsico-icon.svg",
            title: "Pepsi Sweepstakes",
            subtitle: "$5K trip giveaway",
            buttonLabel: "Enterer",
          ),
          SizedBox(width: 16),
          DailyChecklistItem(
            imageUrl: "https://www.vectorlogo.zone/logos/nike/nike-icon.svg",
            title: "Nike",
            subtitle: "Daily-Givaway",
            buttonLabel: "Re-enter",
          ),
          SizedBox(width: horizontalSpace),
        ],
      ),
    );
  }
}