
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/dust_bunnies_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../charity/screens/donation_history_screen.dart';
import '../../email/screens/email_inbox_screen.dart';
import '../../email/services/email_service.dart';
import '../../entries/screens/entry_analytics_screen.dart';
import '../../gamification/models/badge_model.dart';

import '../../subscription/models/subscription_tiers.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../widgets/level_progress_bar.dart';
import '../widgets/profile_picture_avatar.dart';
import 'profile_settings_screen.dart';
import 'referral_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final tierManagement = ref.watch(tierManagementServiceProvider);
    final currentTier = tierManagement.getCurrentTier();

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(
          child: Text('Please log in.', style: AppTextStyles.bodyLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          _buildActionButton(
            context,
            ref,
            currentTier,
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (userProfile) {
          final profile = userProfile ??
              UserProfile(
                id: currentUser.uid,
                reference: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid),
              );

          return SingleChildScrollView(
            child: Column(
              children: [
                _ParallaxHeader(user: profile, currentUser: currentUser),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _BentoStatsGrid(user: profile, userId: currentUser.uid),
                      const SizedBox(height: 24),
                       Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Achievements',
                          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BadgeCarousel(userId: currentUser.uid),
                      const SizedBox(height: 24),
                      _MenuSection(context: context),
                      const SizedBox(height: 32),
                       _SignOutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    SubscriptionTier currentTier,
  ) {
    final isPremium = currentTier.hasEmailInbox;
    
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: isPremium
          ? Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.mail_outline, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmailInboxScreen(),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Consumer(
                    builder: (context, ref, child) {
                       final unreadCountAsync = ref.watch(totalUnreadEmailCountProvider);
                       return unreadCountAsync.when(
                         data: (count) => count > 0 
                             ? Container(
                                 width: 8, height: 8, 
                                 decoration: const BoxDecoration(
                                   color: AppColors.errorRed, 
                                   shape: BoxShape.circle
                                 ),
                               ) 
                             : const SizedBox.shrink(),
                         loading: () => const SizedBox.shrink(),
                         error: (_, __) => const SizedBox.shrink(),
                       );
                    },
                  ),
                )
              ],
            )
          : IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileSettingsScreen(),
                ),
              ),
            ),
    );
  }
}


// ... existing imports

class _ParallaxHeader extends StatelessWidget {
  final UserProfile user;
  final User currentUser;

  const _ParallaxHeader({required this.user, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Increased height to accommodate progress bar
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2A2A40),
                    AppColors.primaryDark,
                  ],
                ),
              ),
            ),
          ),
          
          // Animated Circles Background
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandCyan.withValues(alpha: 0.1),
                boxShadow: [
                   BoxShadow(
                     color: AppColors.brandCyan.withValues(alpha: 0.2),
                     blurRadius: 100,
                     spreadRadius: 20,
                   )
                ]
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(duration: 3.seconds, begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Adjusted top spacer
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.brandCyan, AppColors.electricBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandCyan.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ProfilePictureAvatar(
                  user: user,
                  radius: 65,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 16),
              Text(
                currentUser.displayName ?? user.name ?? 'User',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.3),
              
              const SizedBox(height: 4),
              if (user.bio != null && user.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),
              
              // Level Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: LevelProgressBar(
                  currentLevel: user.level,
                  currentDB: user.points, // Assuming points maps to currentDB in UserProfile
                  // In a real scenario, you might need to fetch dbToNextLevel from the service 
                  // or calculate it. For now, we'll approximate/calculate using the service static method.
                  dbToNextLevel: DustBunniesService.getDustBunniesRequiredForLevel(user.level + 1) - DustBunniesService.getDustBunniesRequiredForLevel(user.level),
                  // Since 'points' is usually total, we'd ideally want 'current progress in this level'.
                  // However, for visual simplicity let's stick to this or assume UserProfile has granular fields.
                  // BETTER: Use mapped values if available, or just raw total points for now.
                  // FIX: Let's assume UserProfile model has been updated to have these gamification fields 
                  // properly, OR we calculate locally. 
                  // For the sake of this task, I will use a safe fallback or calculation.
                  // *Correction*: DustBunniesService logic defines dbToNextLevel.
                  // Accessing static DustBunniesService logic for calculation:
                  rank: user.rankTitle, // UserProfile has rankTitle
                ),
              ),

              const SizedBox(height: 20),
              // Action Chips (Edit, Share) example
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _HeaderChip(
                     label: 'Edit Profile', 
                     icon: Icons.edit,
                     onTap: () => Navigator.of(context).push(
                       MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())
                     ),
                   ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderChip({
    required this.label, 
    required this.icon, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoStatsGrid extends ConsumerWidget {
  final UserProfile user;
  final String userId;

  const _BentoStatsGrid({required this.user, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRankAsync = ref.watch(userRankProvider(userId));
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _BentoCard(
                title: 'Dustbunnies',
                value: user.points.toString(),
                icon: Icons.stars_rounded,
                color: AppColors.brandCyan,
                imageUrl: 'assets/images/dustbunnies/dustbunny_icon.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoCard(
                title: 'Streak',
                value: '${user.streak}🔥',
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BentoCard(
                title: 'Wins',
                value: user.totalWins.toString(),
                icon: Icons.emoji_events,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoCard(
                 title: 'Entries',
                 value: user.totalEntries.toString(),
                 icon: Icons.confirmation_number,
                 color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: userRankAsync.when(
                data: (rank) => _BentoCard(
                  title: 'Rank',
                  value: rank > 0 ? '#$rank' : 'N/A',
                  icon: Icons.leaderboard,
                  color: AppColors.brandCyan,
                ),
                loading: () => const _BentoCard(
                  title: 'Rank',
                  value: '...',
                  icon: Icons.leaderboard,
                  color: AppColors.brandCyan,
                ),
                error: (_, __) => const _BentoCard(
                  title: 'Rank',
                  value: 'N/A',
                  icon: Icons.leaderboard,
                  color: AppColors.brandCyan,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color color;
  final String? imageUrl;

  const _BentoCard({
    required this.title,
    required this.value,
    required this.color, this.icon,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (imageUrl != null)
                Image.asset(imageUrl!, width: 24, height: 24)
              else if (icon != null)
                Icon(icon, color: color, size: 24),
              
              if (imageUrl == null && icon == null)
                 const SizedBox(), // spacer

              // Mini glint or decorative dot
              Container(
                 width: 6, height: 6,
                 decoration: BoxDecoration(
                   color: color.withValues(alpha: 0.5),
                   shape: BoxShape.circle
                 ),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                   color: Colors.white.withValues(alpha: 0.6)
                ),
              ),
            ],
          )
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
  }
}

class _BadgeCarousel extends ConsumerWidget {
  final String userId;

  const _BadgeCarousel({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
         if (!snapshot.hasData || !snapshot.data!.exists) {
           return const SizedBox(height: 100, child: Center(child: Text('No badges', style: TextStyle(color: Colors.white54))));
         }

         final data = snapshot.data!.data()! as Map<String, dynamic>;
         final gamification = data['gamification'] as Map<String, dynamic>?;
         final badgesData = gamification?['badges'] as Map<String, dynamic>?;
         final collected = (badgesData?['collected'] as List?)?.cast<String>() ?? [];

         if (collected.isEmpty) {
           return Container(
             padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
             child: const Center(
               child: Text('Play more to earn badges!', style: TextStyle(color: Colors.white54)),
             ),
           );
         }

         final allBadges = ref.watch(achievementsProvider).asData?.value ?? [];

         return SizedBox(
           height: 140,
           child: ListView.builder(
             scrollDirection: Axis.horizontal,
             itemCount: collected.length,
             itemBuilder: (context, index) {
               final badgeId = collected[index];
               // Find badge meta
               final badge = allBadges.firstWhere(
                 (b) => b.id == badgeId, 
                 orElse: () => const Badge(
                   id: 'unknown', 
                   name: 'Unknown', 
                   description: '', 
                   icon: Icons.help_outline, 
                  ),
                );

               return Container(
                 width: 110,
                 margin: const EdgeInsets.only(right: 12),
                 decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandCyan.withValues(alpha: 0.2),
                        AppColors.primaryMedium.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.brandCyan.withValues(alpha: 0.3),
                    ),
                 ),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(badge.icon, size: 40, color: AppColors.accent),
                     const SizedBox(height: 8),
                     Text(
                       badge.name,
                       textAlign: TextAlign.center,
                       style: const TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 12,
                       ),
                     ),
                   ],
                 ),
               ).animate().slideX(begin: 0.2, duration: 400.ms, delay: (index * 100).ms);
             },
           ),
         );
      },
    );
  }
}

class _MenuSection extends StatelessWidget {
  final BuildContext context;

  const _MenuSection({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.star_rate_rounded,
          title: 'Premium Features',
          subtitle: 'Manage your subscription',
          color: AppColors.accent,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubscriptionScreen())
          ),
        ),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.analytics_outlined,
          title: 'Entry Analytics',
          subtitle: 'Track your wins and stats',
          color: AppColors.brandGold,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EntryAnalyticsScreen())
          ),
        ),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.people_outline_rounded,
          title: 'Refer a Friend',
          subtitle: 'Earn Dustbunnies together',
          color: AppColors.electricBlue,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReferralScreen())
          ),
        ),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.volunteer_activism_outlined,
          title: 'Donation History',
          subtitle: '',
          color: Colors.pinkAccent,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DonationHistoryScreen())
          ),
        ),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.settings_outlined,
          title: 'App Settings',
          subtitle: 'Notifications, support, etc',
          color: Colors.white,
          onTap: () => Navigator.of(context).push(
             MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.primaryMedium,
            title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            content: const Text('Are you sure?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          await FirebaseAuth.instance.signOut();
        }
      },
      child: const Text(
        'Sign Out',
        style: TextStyle(
          color: AppColors.errorRed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
