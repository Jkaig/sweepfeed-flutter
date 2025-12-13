import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../screens/subscription_screen.dart';
import '../services/upgrade_trigger_service.dart';

/// Smart upgrade prompt dialog that shows contextual upgrade suggestions
class UpgradePromptDialog extends ConsumerWidget {
  const UpgradePromptDialog({
    required this.triggerResult,
    super.key,
  });

  final UpgradeTriggerResult triggerResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradeTriggerService = ref.read(upgradeTriggerServiceProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    triggerResult.targetTier.color,
                    triggerResult.targetTier.color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getIconForTrigger(triggerResult.triggerType),
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getTitleForTrigger(triggerResult.triggerType),
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personalized message
                  Text(
                    upgradeTriggerService.getPersonalizedUpgradeMessage(
                      triggerResult.triggerType,
                      triggerResult.targetTier,
                    ),
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Key benefits for target tier
                  _buildBenefitsSection(),

                  const SizedBox(height: 20),

                  // Context-specific value proposition
                  _buildValueProposition(),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = _getBenefitsForTrigger();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'With ${triggerResult.targetTier.displayName}:',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: triggerResult.targetTier.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),),
      ],
    );
  }

  Widget _buildValueProposition() {
    final targetTier = triggerResult.targetTier;
    final dailyPrice = targetTier.price / 30;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: targetTier.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: targetTier.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.savings,
                size: 16,
                color: targetTier.color,
              ),
              const SizedBox(width: 6),
              Text(
                'Just \$${dailyPrice.toStringAsFixed(2)} per day',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: targetTier.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getValuePropositionForTrigger(),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) => Column(
      children: [
        // Primary action (Upgrade)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleUpgradePressed(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: triggerResult.targetTier.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Upgrade to ${triggerResult.targetTier.displayName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary actions
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _handleMaybeLaterPressed(context, ref),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _handleDismissPressed(context, ref),
                child: Text(
                  'Not Interested',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

  List<String> _getBenefitsForTrigger() {
    switch (triggerResult.triggerType) {
      case UpgradeTriggerType.usageThreshold:
        return triggerResult.targetTier == SubscriptionTier.basic
            ? [
                'Unlimited daily entries',
                'No more daily limits',
                'Ad-free experience',
              ]
            : [
                'Auto-entry scheduling',
                'Exclusive contests',
                'Advanced analytics',
              ];

      case UpgradeTriggerType.engagementLevel:
        return triggerResult.targetTier == SubscriptionTier.basic
            ? [
                'Leaderboard access',
                'Social challenges',
                '2x SweepCoins earning',
              ]
            : [
                'Premium achievements',
                'Contest win analytics',
                'Priority support',
              ];

      case UpgradeTriggerType.featureInterest:
        return triggerResult.targetTier == SubscriptionTier.basic
            ? ['Advanced filtering', 'Save more contests', 'Remove all ads']
            : [
                'Auto-entry feature',
                'Exclusive partner contests',
                'Win probability insights',
              ];

      case UpgradeTriggerType.valueDemonstration:
        return triggerResult.targetTier == SubscriptionTier.basic
            ? [
                'Increase your winning potential',
                'More entries = more chances',
                'Better organization tools',
              ]
            : [
                'Maximize your ROI',
                'Auto-entry saves time',
                'Analytics improve strategy',
              ];

      case UpgradeTriggerType.timeBased:
      case UpgradeTriggerType.social:
        return triggerResult.targetTier.features
            .where((f) => f.included)
            .take(3)
            .map((f) => f.title)
            .toList();
    }
  }

  String _getValuePropositionForTrigger() {
    switch (triggerResult.triggerType) {
      case UpgradeTriggerType.usageThreshold:
        return 'Never hit entry limits again - enter every contest you want!';

      case UpgradeTriggerType.engagementLevel:
        return 'Take your sweepstaking to the next level with pro features';

      case UpgradeTriggerType.featureInterest:
        return 'Unlock the feature you want plus get unlimited access to everything';

      case UpgradeTriggerType.valueDemonstration:
        return 'Invest in your winning potential - see bigger returns on your time';

      case UpgradeTriggerType.timeBased:
        return "You're clearly enjoying SweepFeed - unlock its full potential!";

      case UpgradeTriggerType.social:
        return 'Join the top performers and dominate the leaderboards';
    }
  }

  String _getTitleForTrigger(UpgradeTriggerType triggerType) {
    switch (triggerType) {
      case UpgradeTriggerType.usageThreshold:
        return "You're a Power User!";
      case UpgradeTriggerType.engagementLevel:
        return 'Ready to Level Up?';
      case UpgradeTriggerType.featureInterest:
        return 'Unlock This Feature';
      case UpgradeTriggerType.valueDemonstration:
        return 'Maximize Your Wins';
      case UpgradeTriggerType.timeBased:
        return 'Loving SweepFeed?';
      case UpgradeTriggerType.social:
        return 'Climb the Leaderboard';
    }
  }

  IconData _getIconForTrigger(UpgradeTriggerType triggerType) {
    switch (triggerType) {
      case UpgradeTriggerType.usageThreshold:
        return Icons.trending_up;
      case UpgradeTriggerType.engagementLevel:
        return Icons.emoji_events;
      case UpgradeTriggerType.featureInterest:
        return Icons.lock_open;
      case UpgradeTriggerType.valueDemonstration:
        return Icons.savings;
      case UpgradeTriggerType.timeBased:
        return Icons.favorite;
      case UpgradeTriggerType.social:
        return Icons.leaderboard;
    }
  }

  Future<void> _handleUpgradePressed(
      BuildContext context, WidgetRef ref,) async {
    final upgradeTriggerService = ref.read(upgradeTriggerServiceProvider);
    await upgradeTriggerService
        .recordUpgradePromptClicked(triggerResult.triggerType.name);

    if (context.mounted) {
      Navigator.of(context).pop();

      // Navigate to subscription screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SubscriptionScreen(),
        ),
      );
    }
  }

  Future<void> _handleMaybeLaterPressed(
      BuildContext context, WidgetRef ref,) async {
    Navigator.of(context).pop();

    // Don't set cooldown for "maybe later" - shorter delay
    // This allows showing prompts again sooner for engaged users
  }

  Future<void> _handleDismissPressed(
      BuildContext context, WidgetRef ref,) async {
    final upgradeTriggerService = ref.read(upgradeTriggerServiceProvider);
    await upgradeTriggerService
        .recordUpgradePromptDismissed(triggerResult.triggerType.name);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Static method to show the upgrade prompt if conditions are met
  static Future<void> showIfTriggered(
      BuildContext context, WidgetRef ref,) async {
    final upgradeTriggerService = ref.read(upgradeTriggerServiceProvider);
    final triggerResult = await upgradeTriggerService.checkForUpgradeTrigger();

    if (triggerResult != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => UpgradePromptDialog(triggerResult: triggerResult),
      );
    }
  }
}
