import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/permission_manager.dart';
import '../../../../core/services/unified_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class NotificationPermissionStepScreen extends ConsumerStatefulWidget {
  const NotificationPermissionStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  ConsumerState<NotificationPermissionStepScreen> createState() =>
      _NotificationPermissionStepScreenState();
}

class _NotificationPermissionStepScreenState
    extends ConsumerState<NotificationPermissionStepScreen> {
  bool _isLoading = false;

  Future<void> _handlePermissionRequest() async {
    setState(() => _isLoading = true);

    try {
      final status = await permissionManager.request();

      if (!mounted) return;

      if (status == NotificationPermissionStatus.granted) {
        // Permission granted, proceed
        widget.onNext();
      } else if (status == NotificationPermissionStatus.permanentlyDenied) {
        // Permission permanently denied, show settings dialog
        // Using permission_handler's openAppSettings is handled in the dialog action
        _showSettingsDialog();
      } else {
         // Denied (softly), just proceed or show explanation.
         // For now, let's proceed but maybe with a snackbar or just proceed
         // as user can re-enable later. 
         // Strategy: If user explicitly taps "Enable", and they deny it, 
         // we should probably respect that decision and move on, OR ask again?
         // Convention is usually: Deny -> Move on.
         widget.onNext();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          'Permission Required',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Notifications are disabled. To receive updates about your wins, please enable them in your device settings.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // User cancelled, maybe proceed anyway? 
              // Let's decide to proceed if they cancel.
              widget.onNext(); 
            },
            child: Text(
              'Skip',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
              // After returning, ideally we'd check again, but user needs to manually NAV back.
              // For simplicity in onboarding, we assume they fixed it or will fix it.
              // We could verify on return, but that requires WidgetsBinding observer.
              // Let's just proceed for flow smoothness.
              widget.onNext();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OnboardingTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Stay Updated',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Get notified about new contests and when you win!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _isLoading
              ? const CircularProgressIndicator(color: AppColors.brandCyan)
              : OnboardingButton(
                  text: 'Enable Notifications',
                  onPressed: _handlePermissionRequest,
                ),
          if (widget.onSkip != null && !_isLoading) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Maybe Later',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
}
