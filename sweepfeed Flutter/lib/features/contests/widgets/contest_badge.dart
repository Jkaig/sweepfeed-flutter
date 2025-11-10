import 'package:flutter/material.dart';

class ContestBadge extends StatelessWidget {
  const ContestBadge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    super.key,
    this.icon,
  });
  final String text;
  final Color backgroundColor;
  final IconData? icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: textColor,
                size: 12,
              ),
            if (icon != null) const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}
