import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ListTileItem extends StatelessWidget {
  const ListTileItem({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.textLight),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge
              .copyWith(color: titleColor ?? AppColors.textWhite),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              )
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: onTap,
      );
}
