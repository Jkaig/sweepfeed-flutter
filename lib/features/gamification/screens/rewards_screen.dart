import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/reward_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/loading_indicator.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Rewards Store',
        leading: CustomBackButton(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              Color(0xFF151525),
            ],
          ),
        ),
        child: userProfileAsync.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (user) {
             if (user == null) return const Center(child: Text('Please log in'));
             
             // Get DustBunnies from dustBunniesSystem using FutureBuilder
             return FutureBuilder<Map<String, dynamic>>(
               future: ref.read(dustBunniesServiceProvider).getUserDustBunniesData(user.id),
               builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: LoadingIndicator());
                 }
                 
                 final dustBunniesData = snapshot.data ?? {};
                 final userDustBunnies = (dustBunniesData['currentDB'] as int?) ?? 0;

             return rewardsAsync.when(
               loading: () => const Center(child: LoadingIndicator()),
               error: (e, s) => Center(child: Text('Error loading rewards: $e')),
               data: (rewards) {
                 return CustomScrollView(
                   slivers: [
                     const SliverToBoxAdapter(child: SizedBox(height: 100)), // AppBar space
                     
                     // Balance Header
                     SliverToBoxAdapter(
                       child: _BalanceHeader(dustBunnies: userDustBunnies)
                           .animate().fadeIn().slideY(begin: -0.2),
                     ),

                     const SliverToBoxAdapter(child: SizedBox(height: 24)),

                     // Rewards Grid
                     SliverPadding(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                       sliver: SliverGrid(
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                           crossAxisCount: 2,
                           childAspectRatio: 0.75,
                           crossAxisSpacing: 16,
                           mainAxisSpacing: 16,
                         ),
                         delegate: SliverChildBuilderDelegate(
                           (context, index) {
                             final reward = rewards[index];
                             final isUnlocked = user.claimedRewards.contains(reward.id) ?? false;
                             final canAfford = userDustBunnies >= reward.points;
                             
                             return _HolographicRewardCard(
                               reward: reward,
                               isUnlocked: isUnlocked,
                               canAfford: canAfford,
                               onClaim: () => _claimReward(context, ref, reward),
                             ).animate().scale(delay: (index * 100).ms, duration: 400.ms);
                           },
                           childCount: rewards.length,
                         ),
                       ),
                     ),
                     
                     const SliverToBoxAdapter(child: SizedBox(height: 40)),
                   ],
                 );
               },
             );
               },
             );
          },
        ),
      ),
    );
  }

  Future<void> _claimReward(BuildContext context, WidgetRef ref, Reward reward) async {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) return;

    // Haptic feedback could go here

    try {
      final dustBunniesService = ref.read(dustBunniesServiceProvider);
      final success = await dustBunniesService.redeemReward(
        userId,
        reward.id,
        reward.points,
      );

      if (context.mounted) {
        if (success) {
          ref.read(confettiProvider).play();
          
          showDialog(
            context: context, 
            barrierDismissible: false,
            builder: (context) => _SuccessDialog(reward: reward),
          );

          ref.invalidate(userProfileProvider);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient Dustbunnies!'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
      }
    }
  }
}

class _BalanceHeader extends StatelessWidget {
  final int dustBunnies;

  const _BalanceHeader({required this.dustBunnies});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandCyan, AppColors.electricBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandCyan.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR BALANCE',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    dustBunnies.toString(),
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'DB',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.white.withValues(alpha: 0.2),
               borderRadius: BorderRadius.circular(20),
             ),
             child: Image.asset(
               'assets/images/dustbunnies/dustbunny_happy.png',
               width: 60,
               height: 60,
             ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
        ],
      ),
    );
  }
}

class _HolographicRewardCard extends StatefulWidget {
  final Reward reward;
  final bool isUnlocked;
  final bool canAfford;
  final VoidCallback onClaim;

  const _HolographicRewardCard({
    required this.reward,
    required this.isUnlocked,
    required this.canAfford,
    required this.onClaim,
  });

  @override
  State<_HolographicRewardCard> createState() => _HolographicRewardCardState();
}

class _HolographicRewardCardState extends State<_HolographicRewardCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canClaim = !widget.isUnlocked && widget.canAfford;

    return GestureDetector(
      onTap: canClaim ? widget.onClaim : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                 // Base Background
                 Container(
                   decoration: BoxDecoration(
                     color: widget.isUnlocked 
                         ? AppColors.primaryMedium.withValues(alpha: 0.3)
                         : AppColors.primaryMedium,
                     borderRadius: BorderRadius.circular(24),
                     border: Border.all(
                       color: widget.isUnlocked 
                          ? AppColors.successGreen.withValues(alpha: 0.3)
                          : (canClaim 
                              ? AppColors.brandCyan.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1)),
                     ),
                   ),
                 ),

                 // Holographic Gradient overlay (animated)
                 if (canClaim && !widget.isUnlocked)
                   Positioned.fill(
                     child: Container(
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                           transform: GradientRotation(_controller.value * 2 * 3.14159),
                           colors: [
                              Colors.transparent,
                              AppColors.brandCyan.withValues(alpha: 0.1),
                              Colors.transparent,
                           ],
                           stops: const [0.0, 0.5, 1.0],
                         ),
                       ),
                     ),
                   ),

                 // Content
                 Padding(
                   padding: const EdgeInsets.all(16),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Icon
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: widget.isUnlocked 
                              ? AppColors.successGreen.withValues(alpha: 0.2)
                              : AppColors.primaryDark.withValues(alpha: 0.5),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Icon(
                           widget.isUnlocked ? Icons.check : Icons.star, 
                           color: widget.isUnlocked ? AppColors.successGreen : AppColors.brandCyan
                         ),
                       ),
                       
                       const Spacer(),
                       
                       Text(
                         widget.reward.name,
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                         style: const TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                           fontSize: 14,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         '${widget.reward.points} DB',
                         style: TextStyle(
                           color: canClaim ? AppColors.accent : AppColors.textLight,
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       ),
                       
                       if (widget.isUnlocked)
                         Padding(
                           padding: const EdgeInsets.only(top: 8),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: AppColors.successGreen.withValues(alpha: 0.2),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: const Text(
                               'OWNED',
                               style: TextStyle(
                                 color: AppColors.successGreen,
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold
                               ),
                             ),
                           ),
                         ),
                     ],
                   ),
                 ),
                 
                 // Locked Overlay
                 if (!widget.canAfford && !widget.isUnlocked)
                   Container(
                     color: Colors.black.withValues(alpha: 0.5),
                     child: const Center(
                       child: Icon(Icons.lock_outline, color: Colors.white24, size: 32),
                     ),
                   ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final Reward reward;

  const _SuccessDialog({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Dialog(
       backgroundColor: Colors.transparent,
       child: Container(
         padding: const EdgeInsets.all(24),
         decoration: BoxDecoration(
           color: AppColors.primaryDark,
           borderRadius: BorderRadius.circular(24),
           border: Border.all(color: AppColors.brandCyan),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Icon(Icons.check_circle, color: AppColors.successGreen, size: 60)
                 .animate().scale(curve: Curves.elasticOut, duration: 800.ms),
             const SizedBox(height: 16),
             const Text(
               'Reward Claimed!',
               style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             Text(
               'You have received ${reward.name}.',
               textAlign: TextAlign.center,
               style: const TextStyle(color: Colors.white70),
             ),
             const SizedBox(height: 24),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () => Navigator.pop(context),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.brandCyan,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: const Text('Awesome!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
               ),
             )
           ],
         ),
       ),
    );
  }
}
