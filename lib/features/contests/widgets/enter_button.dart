import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/contest.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class EnterButton extends ConsumerWidget {
  const EnterButton({
    required this.contest,
    this.hasEntered = false,
    this.isFullWidth = false,
    super.key,
  });

  final Contest contest;
  final bool hasEntered;
  final bool isFullWidth;

  Future<void> _handleEnter(BuildContext context, WidgetRef ref) async {
    // Logic remains the same
    final tierService = ref.read(tierManagementServiceProvider);
    final canEnter = await tierService.canEnterContest();

    if (!canEnter) {
      // Show upgrade dialog
      return;
    }

    ref.read(analyticsServiceProvider).logEvent(
      eventName: 'click_enter_contest',
      parameters: {'contest_id': contest.id, 'title': contest.title},
    );

    final url = Uri.parse(contest.entryUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open contest link')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hasEntered) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: () => _handleEnter(context, ref),
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: Text(
            'ENTERED',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.successGreen,
            side: const BorderSide(color: AppColors.successGreen, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: () => _handleEnter(context, ref),
        icon: const Icon(Icons.arrow_forward, size: 20),
        label: Text(
          'ENTER NOW',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyberYellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: AppColors.cyberYellow.withAlpha(100),
        ),
      ),
    );
  }
}

