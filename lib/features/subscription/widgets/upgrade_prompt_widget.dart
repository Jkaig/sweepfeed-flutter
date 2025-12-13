import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../screens/paywall_screen.dart';
import '../services/upgrade_trigger_service.dart';

class UpgradePromptWidget extends ConsumerStatefulWidget {
  const UpgradePromptWidget({super.key});

  @override
  ConsumerState<UpgradePromptWidget> createState() => _UpgradePromptWidgetState();
}

class _UpgradePromptWidgetState extends ConsumerState<UpgradePromptWidget> {
  UpgradeTriggerResult? _triggerResult;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _checkForTrigger();
  }

  Future<void> _checkForTrigger() async {
    final service = ref.read(upgradeTriggerServiceProvider);
    final result = await service.checkForUpgradeTrigger();
    
    if (result != null && mounted) {
      setState(() {
        _triggerResult = result;
        _isVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _triggerResult == null) {
      return const SizedBox.shrink();
    }

    final message = ref
        .read(upgradeTriggerServiceProvider)
        .getPersonalizedUpgradeMessage(
            _triggerResult!.triggerType, _triggerResult!.targetTier,);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandGold,
            AppColors.brandGold.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: AppColors.primaryDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _getTriggerTitle(_triggerResult!.triggerType),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.primaryDark),
                onPressed: () {
                  setState(() {
                    _isVisible = false;
                  });
                  ref
                      .read(upgradeTriggerServiceProvider)
                      .recordUpgradePromptDismissed(
                          _triggerResult!.triggerType.name,);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(upgradeTriggerServiceProvider)
                    .recordUpgradePromptClicked(
                        _triggerResult!.triggerType.name,);
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upgrade Now'),
            ),
          ),
        ],
      ),
    );
  }

  String _getTriggerTitle(UpgradeTriggerType type) {
    switch (type) {
      case UpgradeTriggerType.usageThreshold:
        return 'Unlock Unlimited Entries';
      case UpgradeTriggerType.engagementLevel:
        return 'Level Up Your Experience';
      case UpgradeTriggerType.timeBased:
        return 'Become a Pro Sweeper';
      case UpgradeTriggerType.featureInterest:
        return 'Unlock Exclusive Features';
      case UpgradeTriggerType.valueDemonstration:
        return 'Maximize Your Winnings';
      case UpgradeTriggerType.social:
        return 'Join the Leaderboard';
    }
  }
}

