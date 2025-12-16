import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/models/recommendation_reason.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/greeting_utils.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/animated_gradient_background.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../gamification/screens/rewards_screen.dart';
import '../../gamification/widgets/daily_challenge_card.dart';
import '../../navigation/widgets/side_drawer.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../subscription/screens/premium_subscription_screen.dart';
import '../providers/contest_providers.dart';
import '../providers/filter_providers.dart';
import '../providers/home_search_provider.dart';
import '../widgets/contest_feed_skeleton.dart';
import '../widgets/empty_contest_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../../core/widgets/glassmorphic_tab_bar.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/popular_sweepstakes_list.dart';
import '../widgets/search_suggestions.dart';
import '../widgets/unified_contest_card.dart';
import 'contest_detail_screen.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;
  bool _isSearching = false;
  Contest? _lastVisitedContest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lastVisitedContest != null) {
      final entryService = ref.read(entryServiceProvider);
      final currentUser = ref.read(firebaseServiceProvider).currentUser;
      if (currentUser != null) {
        entryService
            .hasEntered(currentUser.uid, _lastVisitedContest!.id)
            .then((hasEntered) {
          if (!hasEntered) {
            _showSaveForLaterPrompt(_lastVisitedContest!);
          }
          _lastVisitedContest = null;
        });
      }
    }
  }

  void _showSaveForLaterPrompt(Contest contest) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Did you want to save "${contest.title}" for later?'),
        action: SnackBarAction(
          label: 'Save',
          onPressed: () {
            final usageLimits = ref.read(usageLimitsServiceProvider);
            if (!usageLimits.hasReachedSavedItemsLimit) {
              ref.read(savedContestsServiceProvider).saveContest(contest);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "You've reached your saved contests limit. Upgrade to save more!",
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text;
      ref.read(homeSearchQueryProvider.notifier).state = query;
      setState(() {
        _isSearching = query.isNotEmpty;
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(contestFeedProvider.notifier).fetchNextPage();
    }
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    // Check if filter feature is unlocked
    final unlockService = ref.read(featureUnlockServiceProvider);
    final hasUnlockedFilter = await unlockService.hasUnlockedFeature('tool_filter_pro');
    
    if (!hasUnlockedFilter) {
      // Show unlock dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.primaryMedium,
          title: const Text(
            'Unlock Filters',
            style: TextStyle(color: AppColors.textWhite),
          ),
          content: const Text(
            'Purchase "Filter Pro" in the shop to unlock advanced filtering options',
            style: TextStyle(color: AppColors.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RewardsScreen(),
                  ),
                );
              },
              child: const Text('Go to Shop'),
            ),
          ],
        ),
      );
      return;
    }
    
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => const FilterBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final contestFeedState = ref.watch(contestFeedProvider);
    final personalizedFeedAsync = ref.watch(personalizedContestFeedProvider);

    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          Scaffold(
            key: _scaffoldKey,
            drawer: const SideDrawer(),
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent, // Let gradient show through
                floating: true,
                pinned: true,
                snap: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.textWhite),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                title: userProfileAsync.when(
                  data: (user) => Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: user?.profilePictureUrl != null
                              ? CachedNetworkImageProvider(
                                  user!.profilePictureUrl!,
                                )
                              : const AssetImage(
                                      'assets/images/default_avatar.png',
                                    )
                                  as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              GreetingUtils.getGreeting(),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              user?.name ?? 'User',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                actions: [
                  userProfileAsync.when(
                    data: (user) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RewardsScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/dustbunnies/dustbunny_icon.png',
                              width: 28,
                              height: 28,
                            )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2000.ms, delay: 5000.ms),
                            const SizedBox(width: 8),
                            ref.watch(userDustBunniesBalanceProvider(user!.id)).when(
                              data: (balance) => Text(
                                '$balance',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.brandCyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.brandCyan.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              loading: () => const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brandCyan,
                                ),
                              ),
                              error: (_, __) => const Text(
                                '0',
                                style: TextStyle(color: AppColors.brandCyan),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textWhite,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationCenterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: GlassmorphicTabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'For You'),
                    Tab(text: 'Trending'),
                    Tab(text: 'Latest'),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getHorizontalPadding(context),
                    vertical: 12,
                  ),
                  child: HomeSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      // Handled by _onSearchChanged listener
                    },
                    onSubmitted: (value) {
                      if (value.isEmpty) {
                        setState(() => _isSearching = false);
                      }
                    },
                    onFilterPressed: () => _showFilterSheet(context),
                    activeFilterCount: ref.watch(activeFilterCountProvider),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, child) {
                    final challengesAsync = ref.watch(dailyChallengesProvider);
                    
                    return challengesAsync.when(
                      data: (challenges) {
                        if (challenges.isEmpty) return const SizedBox.shrink();
                        
                        // Find first incomplete or first claimable challenge
                        final activeChallenge = challenges.firstWhere(
                          (c) => !c.userChallenge.completed || c.canClaim,
                          orElse: () => challenges.first,
                        );
                        
                        // If all completed and claimed, maybe don't show or show a "All done!" card?
                        // For now, only show if there is something to do or claim
                        if (activeChallenge.userChallenge.completed && !activeChallenge.canClaim) {
                           return const SizedBox.shrink(); 
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getHorizontalPadding(context),
                          ),
                          child: DailyChallengeCard(challenge: activeChallenge),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
              SliverFillRemaining(
                child: Stack(
                  children: [
                    if (_isSearching) _buildSearchResults() else TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPersonalizedFeed(personalizedFeedAsync),
                              _buildTrendingFeed(),
                              _buildLatestFeed(contestFeedState),
                            ],
                          ),
                    if (_isSearching)
                      SearchSuggestions(
                        query: _searchController.text,
                        onSuggestionSelected: (suggestion) {
                          _searchController.text = suggestion;
                        },
                      ),
                  ],
                ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedFeed(
          AsyncValue<List<(Contest, RecommendationReason?)>>
              personalizedFeedAsync) {
    final savedContestsService = ref.watch(savedContestsServiceProvider);
    
    return personalizedFeedAsync.when(
      data: (contests) {
        if (contests.isEmpty) {
          return EmptyContestState(
            onReset: () => ref.refresh(personalizedContestFeedProvider),
          );
        }
        return GlassmorphicContainer(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getHorizontalPadding(context),
              vertical: 16,
            ),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index].$1;
              final isSaved = savedContestsService.isSaved(contest.id);
              
              return UnifiedContestCard(
                style: CardStyle.detailed,
                contest: contest,
                isSaved: isSaved,
                onSave: () async {
                  if (isSaved) {
                    savedContestsService.unsaveContest(contest.id);
                  } else {
                    // Check usage limits before saving
                    final usageLimits = ref.read(usageLimitsServiceProvider);
                    if (usageLimits.hasReachedSavedItemsLimit) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "You've reached your saved contests limit (${usageLimits.maxSavedContests}). Upgrade to save more!",
                            ),
                            action: SnackBarAction(
                              label: 'Upgrade',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PremiumSubscriptionScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    savedContestsService.saveContest(contest);
                  }
                },
                onTap: () {
                  setState(() {
                    _lastVisitedContest = contest;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ContestDetailScreen(contestId: contest.id),
                    ),
                  );
                },
              ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
            },
          ),
        );
      },
      loading: () => const ContestFeedSkeleton(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $error', style: const TextStyle(color: AppColors.errorRed)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(personalizedContestFeedProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingFeed() => const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: GlassmorphicContainer(
          child: PopularContestsList(),
        ),
      );

  Widget _buildLatestFeed(ContestFeedState contestFeedState) {
    final savedContestsService = ref.watch(savedContestsServiceProvider);
    
    if (contestFeedState.isLoading && contestFeedState.contests.isEmpty) {
      return const ContestFeedSkeleton();
    }

    if (contestFeedState.contests.isEmpty) {
      return EmptyContestState(
        onReset: () => ref.read(contestFeedProvider.notifier).refresh(),
      );
    }

    return GlassmorphicContainer(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getHorizontalPadding(context),
          vertical: 16,
        ),
        itemCount: contestFeedState.contests.length + 1,
        itemBuilder: (context, index) {
          if (index == contestFeedState.contests.length) {
            return contestFeedState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
          final contest = contestFeedState.contests[index];
          final isSaved = savedContestsService.isSaved(contest.id);
          
          return UnifiedContestCard(
            style: CardStyle.detailed,
            contest: contest,
            isSaved: isSaved,
            onSave: () {
              if (isSaved) {
                savedContestsService.unsaveContest(contest.id);
              } else {
                savedContestsService.saveContest(contest);
              }
            },
            onTap: () {
              setState(() {
                _lastVisitedContest = contest;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ContestDetailScreen(contestId: contest.id),
                ),
              );
            },
          ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchResultsAsync = ref.watch(homeSearchResultsProvider);
    final savedContestsService = ref.watch(savedContestsServiceProvider);

    return searchResultsAsync.when(
      data: (results) {
        if (results.isEmpty && _searchController.text.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No contests found',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return Animate(
          effects: const [FadeEffect(), SlideEffect()],
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getHorizontalPadding(context),
              vertical: 16,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final contest = results[index];
              final isSaved = savedContestsService.isSaved(contest.id);
              
              return UnifiedContestCard(
                style: CardStyle.detailed,
                contest: contest,
                isSaved: isSaved,
                onSave: () async {
                  if (isSaved) {
                    savedContestsService.unsaveContest(contest.id);
                  } else {
                    // Check usage limits before saving
                    final usageLimits = ref.read(usageLimitsServiceProvider);
                    if (usageLimits.hasReachedSavedItemsLimit) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "You've reached your saved contests limit (${usageLimits.maxSavedContests}). Upgrade to save more!",
                            ),
                            action: SnackBarAction(
                              label: 'Upgrade',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PremiumSubscriptionScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    savedContestsService.saveContest(contest);
                  }
                },
                onTap: () {
                  setState(() {
                    _lastVisitedContest = contest;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ContestDetailScreen(contestId: contest.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const ContestFeedSkeleton(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Search error',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.refresh(homeSearchResultsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
