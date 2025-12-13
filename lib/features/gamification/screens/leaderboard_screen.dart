import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/dust_bunnies_service.dart'; // For LeaderboardEntry
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/loading_indicator.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  void _scrollToUserPosition(List<LeaderboardEntry> entries, String? currentUserId, int? userRank) {
    if (_hasScrolledToUser || currentUserId == null || userRank == null || userRank <= 0) {
      return;
    }
    
    // Only scroll if user is not in top 3
    final isInTop3 = entries.take(3).any((e) => e.userId == currentUserId);
    if (isInTop3) {
      _hasScrolledToUser = true;
      return;
    }
    
    // Find user's position in the list
    final userIndex = entries.indexWhere((e) => e.userId == currentUserId);
    if (userIndex > 3) {
      // Calculate approximate scroll position
      // Top 3 podium is ~260px, each entry is ~80px
      final scrollOffset = 140.0 + 260.0 + ((userIndex - 3) * 80.0) - 100.0;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && scrollOffset < _scrollController.position.maxScrollExtent) {
          _scrollController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
          _hasScrolledToUser = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: Assuming leaderboardProvider returns List<LeaderboardEntry>
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final currentUserId = currentUser?.uid;
    
    // Get user's rank if logged in
    final userRankAsync = currentUserId != null
        ? ref.watch(userRankProvider(currentUserId))
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Leaderboard',
          style: AppTextStyles.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                gradient: const LinearGradient(
                  colors: [AppColors.brandCyan, AppColors.electricBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandCyan.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textLight,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'All Time'),
                Tab(text: 'Monthly'),
                Tab(text: 'Weekly'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              Color(0xFF1A1A2E), // Deep purple-ish dark
              AppColors.primaryMedium,
            ],
          ),
        ),
        child: leaderboardAsync.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Failed to load leaderboard',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(
                child: Text(
                  'No entries yet!',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // Auto-scroll to user position if needed
            userRankAsync?.whenData((userRank) {
              _scrollToUserPosition(entries, currentUserId, userRank);
            });

            // Split top 3 and the rest
            final top3 = entries.take(3).toList();
            final rest = entries.skip(3).toList();

            return Stack(
              children: [
                // Animated background particles could go here

                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 140), // Space for AppBar + Tabs
                    ),
                    
                    // Top 3 Podium
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: _PodiumWidget(topEntries: top3),
                      ),
                    ),

                    // The Rest of the List
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = rest[index];
                            final rank = index + 4; // 1-based index + 3 top users
                            return _GlassLeaderboardTile(
                              entry: entry, 
                              rank: rank,
                              isCurrentUser: entry.userId == currentUserId,
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 50 * index))
                            .slideX(begin: 0.1, end: 0);
                          },
                          childCount: rest.length,
                        ),
                      ),
                    ),
                    
                    // User's Rank Card (if not in top 3)
                    if (currentUserId != null && userRankAsync != null)
                      SliverToBoxAdapter(
                        child: userRankAsync.when(
                          data: (userRank) {
                            // Check if user is already in the displayed list
                            final isInTop3 = top3.any((e) => e.userId == currentUserId);
                            final isInRest = rest.any((e) => e.userId == currentUserId);
                            
                            // Only show if user is not in top 3 and rank is valid
                            if (!isInTop3 && !isInRest && userRank > 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                                child: _YourRankCard(
                                  rank: userRank,
                                  currentUserId: currentUserId,
                                  scrollController: _scrollController,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntry> topEntries;

  const _PodiumWidget({required this.topEntries});

  @override
  Widget build(BuildContext context) {
    if (topEntries.isEmpty) return const SizedBox.shrink();

    // Reorder for podium visual: 2nd, 1st, 3rd
    LeaderboardEntry? first, second, third;
    if (topEntries.isNotEmpty) first = topEntries[0];
    if (topEntries.length > 1) second = topEntries[1];
    if (topEntries.length > 2) third = topEntries[2];

    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (second != null) 
            Expanded(child: _PodiumStep(entry: second, rank: 2, height: 180)),
          if (first != null) 
            Expanded(flex: 1, child: _PodiumStep(entry: first, rank: 1, height: 230, isFirst: true)),
          if (third != null) 
            Expanded(child: _PodiumStep(entry: third, rank: 3, height: 150)),
        ],
      ),
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final bool isFirst;

  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.height,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar with Badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRankColor(rank),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getRankColor(rank).withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: isFirst ? 40 : 32,
                backgroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(entry.photoUrl!)
                    : null,
                backgroundColor: AppColors.primaryLight,
                child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                    ? Text(
                        entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: isFirst ? 32 : 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            if (isFirst)
              Positioned(
                top: -24,
                child: Image.asset(
                  'assets/images/dustbunnies/dustbunny_excited.png', // Using rebranding asset
                  height: 40,
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: 0, end: -5, duration: 1.seconds),
              ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Name and Score
        Text(
          entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        
        // Podium Block
        const SizedBox(height: 8),
        Container(
          height: height - 80, // Subtract avatar space
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getRankColor(rank).withValues(alpha: 0.3),
                _getRankColor(rank).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              top: BorderSide(color: _getRankColor(rank).withValues(alpha: 0.5), width: 1),
              left: BorderSide(color: _getRankColor(rank).withValues(alpha: 0.3), width: 0.5),
              right: BorderSide(color: _getRankColor(rank).withValues(alpha: 0.3), width: 0.5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                _formatNumber(entry.totalDB),
                style: TextStyle(
                  color: _getRankColor(rank),
                  fontWeight: FontWeight.bold,
                  fontSize: isFirst ? 18 : 14,
                ),
              ),
              Text(
                'DB',
                style: TextStyle(
                  color: _getRankColor(rank).withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().scaleY(
          begin: 0, 
          end: 1, 
          alignment: Alignment.bottomCenter, 
          duration: 600.ms, 
          curve: Curves.easeOutBack,
          delay: Duration(milliseconds: rank * 100),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return AppColors.brandCyan;
    }
  }
}

class _GlassLeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const _GlassLeaderboardTile({
    required this.entry,
    required this.rank,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppColors.brandCyan.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrentUser 
                    ? AppColors.brandCyan.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: TextStyle( // Removed GoogleFonts dep for simplicity
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(entry.photoUrl!)
                      : null,
                  backgroundColor: AppColors.primaryLight,
                  child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                      ? Text(
                          entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        entry.rankTitle, // e.g. "Gold", "Diamond"
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.brandCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/dustbunnies/dustbunny_icon.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatNumber(entry.totalDB),
                        style: const TextStyle(
                          color: AppColors.brandCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
  if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}k';
  }
  return number.toString();
}

class _YourRankCard extends StatelessWidget {
  final int rank;
  final String currentUserId;
  final ScrollController scrollController;

  const _YourRankCard({
    required this.rank,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandCyan.withValues(alpha: 0.3),
                  AppColors.electricBlue.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.brandCyan.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandCyan.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: AppColors.brandCyan,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Rank',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#$rank',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.brandCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getRankMessage(rank),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 400.ms);
  }

  String _getRankMessage(int rank) {
    if (rank <= 10) {
      return 'Amazing! You\'re in the top 10! 🎉';
    } else if (rank <= 50) {
      return 'Great job! Keep climbing! 💪';
    } else if (rank <= 100) {
      return 'You\'re doing well! Keep it up! ⭐';
    } else {
      return 'Keep earning Dust Bunnies to climb higher! 🐰';
    }
  }
}
