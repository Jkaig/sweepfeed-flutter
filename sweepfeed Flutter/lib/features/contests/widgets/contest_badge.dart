import 'package:flutter/material.dart';

class ContestBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final IconData? icon;
  final Color textColor;

  const ContestBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.icon,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
}
