import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../subscription/screens/premium_subscription_screen.dart';
import '../models/notification.dart' as app_notification;

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final trialEligibleAsync = ref.watch(trialEligibilityProvider);

    return Stack(
      children: [
        const Positioned.fill(child: AnimatedGradientBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Notifications',
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const CustomBackButton(),
          ),
          body: notificationsAsync.when(
            data: (notifications) {
              final showActiveTrialNotification = subscriptionService.isInTrialPeriod;
              
              return trialEligibleAsync.when(
                data: (isTrialEligible) {
                  final showTrialNotification = !subscriptionService.isSubscribed &&
                      !subscriptionService.isInTrialPeriod &&
                      isTrialEligible;
                  final showUpgradeNotification = !subscriptionService.isSubscribed &&
                      !subscriptionService.isInTrialPeriod &&
                      !isTrialEligible;
                  
                  // Calculate total items count
                  final headerItemsCount = (showTrialNotification ? 1 : 0) +
                      (showUpgradeNotification ? 1 : 0) +
                      (showActiveTrialNotification ? 1 : 0);
                  
                  // If no notifications and no upgrade/trial notification, show empty state
                  if (notifications.isEmpty && headerItemsCount == 0) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/dustbunnies/dustbunny_icon.png',
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.notifications_off_outlined,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.5),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "You're all caught up!",
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: headerItemsCount + notifications.length,
                    itemBuilder: (context, index) {
                      // Handle header items (trial/upgrade notifications)
                      if (index == 0 && showTrialNotification) {
                        return _buildTrialNotification(context);
                      }
                      
                      if (index == (showTrialNotification ? 1 : 0) && showUpgradeNotification) {
                        return _buildUpgradeNotification(context);
                      }
                      
                      final activeTrialIndex = (showTrialNotification ? 1 : 0) + (showUpgradeNotification ? 1 : 0);
                      if (index == activeTrialIndex && showActiveTrialNotification) {
                        return _buildActiveTrialNotification(subscriptionService);
                      }
                      
                      // Regular notifications
                      final notificationIndex = index - headerItemsCount;
                      final notification = notifications[notificationIndex];
                      return _buildNotificationItem(context, ref, notification, notificationIndex);
                    },
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (_, __) {
                  // If we can't determine eligibility, show upgrade notification as fallback
                  final showUpgradeNotification = !subscriptionService.isSubscribed &&
                      !subscriptionService.isInTrialPeriod;
                  final showActiveTrialNotification = subscriptionService.isInTrialPeriod;
                  
                  if (notifications.isEmpty && !showActiveTrialNotification && !showUpgradeNotification) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/dustbunnies/dustbunny_icon.png',
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.notifications_off_outlined,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.5),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "You're all caught up!",
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final headerItemsCount = (showUpgradeNotification ? 1 : 0) +
                      (showActiveTrialNotification ? 1 : 0);
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: headerItemsCount + notifications.length,
                    itemBuilder: (context, index) {
                      if (index == 0 && showUpgradeNotification) {
                        return _buildUpgradeNotification(context);
                      }
                      if (index == (showUpgradeNotification ? 1 : 0) && showActiveTrialNotification) {
                        return _buildActiveTrialNotification(subscriptionService);
                      }
                      final notificationIndex = index - headerItemsCount;
                      final notification = notifications[notificationIndex];
                      return _buildNotificationItem(context, ref, notification, notificationIndex);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error loading notifications',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTrialNotification(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PremiumSubscriptionScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.diamond_outlined,
                    color: AppColors.brandCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unlock Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start your free trial today!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to start',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.brandCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.brandCyan,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
  
  Widget _buildUpgradeNotification(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PremiumSubscriptionScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: AppColors.brandCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to Remove Ads',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enjoy an ad-free experience with Premium',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upgrade',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.brandCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.brandCyan,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
  
  Widget _buildActiveTrialNotification(dynamic subscriptionService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trial Active',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subscriptionService.trialTimeRemaining} remaining',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
  
  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    app_notification.Notification notification,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        child: InkWell(
          onTap: () {
            ref
                .read(notificationServiceProvider)
                .markAsRead(notification.id);
            ref.refresh(notificationsProvider);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.isRead
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.brandCyan.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.isRead
                        ? Icons.mark_email_read
                        : Icons.mark_email_unread,
                    color: notification.isRead
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.brandCyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Just now',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brandCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (50 * index).ms)
        .slideX(begin: 0.1, end: 0);
  }
}

final notificationsProvider = FutureProvider<List<app_notification.Notification>>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getNotifications();
});

/// Provider to check if user is eligible for a free trial
final trialEligibilityProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.isTrialEligible();
});
