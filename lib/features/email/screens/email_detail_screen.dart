import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../models/email_message.dart';

class EmailDetailScreen extends StatelessWidget {
  const EmailDetailScreen({required this.email, super.key});

  final EmailMessage email;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(
        title: email.subject,
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryMedium,
                  child: Icon(Icons.person, color: AppColors.textWhite),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.from,
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textWhite),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'to me',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat.yMMMd().add_jm().format(email.timestamp),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              email.body,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
}
