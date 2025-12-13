import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contest.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../contests/widgets/unified_contest_card.dart';

class SwipeFeed extends ConsumerStatefulWidget {
  const SwipeFeed({super.key});

  @override
  ConsumerState<SwipeFeed> createState() => _SwipeFeedState();
}

class _SwipeFeedState extends ConsumerState<SwipeFeed>
    with TickerProviderStateMixin {
  late AnimationController _filterController;
  late AnimationController _refreshController;

  List<Contest> _swipeContests = [];
  final List<String> _userPreferences = ['Cash Prizes', 'Electronics'];
  String _activeFilter = 'All';
  bool _isLoading = true;
  bool _isRefreshing = false;

  final List<String> _filterOptions = [
    'All',
    'Cash Prizes',
    'Gift Cards',
    'Electronics',
    'Luxury Cars',
    'Travel & Vacations',
    'Gaming & Entertainment',
  ];

  @override
  void initState() {
    super.initState();

    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadSwipeContests();
  }

  Future<void> _loadSwipeContests() async {
    setState(() => _isLoading = true);

    try {
      // Generate swipe-ready contests
      final contests = await _generateSwipeContests();

      setState(() {
        _swipeContests = contests;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        // Success feedback
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<List<Contest>> _generateSwipeContests() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate loading

    final random = Random();
    final mockContests = <Contest>[];

    final contestTemplates = [
      {
        'title': 'Swipe to Win \$100K!',
        'description': 'Life-changing cash prize waiting for you!',
        'category': 'Cash Prizes',
        'prizeValue': '100000',
        'isHighValue': true,
      },
      {
        'title': 'iPhone 15 Pro Max',
        'description': 'Latest iPhone with premium features.',
        'category': 'Electronics',
        'prizeValue': '1199',
        'isHighValue': true,
      },
      {
        'title': 'Tesla Model S Plaid',
        'description': 'The fastest production car ever made!',
        'category': 'Luxury Cars',
        'prizeValue': '125000',
        'isHighValue': true,
      },
      {
        'title': '\$5,000 Shopping Spree',
        'description': 'Amazon gift cards for unlimited shopping!',
        'category': 'Gift Cards',
        'prizeValue': '5000',
        'isHighValue': false,
      },
      {
        'title': 'Hawaii Dream Vacation',
        'description': 'All-expenses-paid paradise getaway for two.',
        'category': 'Travel & Vacations',
        'prizeValue': '12000',
        'isHighValue': true,
      },
      {
        'title': 'Gaming Paradise Setup',
        'description': 'RTX 4090, OLED monitors, premium peripherals.',
        'category': 'Gaming & Entertainment',
        'prizeValue': '8500',
        'isHighValue': false,
      },
      {
        'title': 'Weekly \$2K Drops',
        'description': 'Win \$2,000 every week for 6 months!',
        'category': 'Cash Prizes',
        'prizeValue': '48000',
        'isHighValue': true,
      },
    ];

    for (var i = 0; i < contestTemplates.length; i++) {
      final template = contestTemplates[i];
      final contest = Contest.fromMap(template, 'swipe_contest_$i');

      // Add dynamic fields for swipe experience
      final updatedContest = contest.copyWith(
        entryCount: 5000 + random.nextInt(15000),
        endDate: DateTime.now().add(
          Duration(
            days: 1 + random.nextInt(30),
            hours: random.nextInt(24),
          ),
        ),
      );

      mockContests.add(updatedContest);
    }

    // Prioritize user preferences
    final prioritized = <Contest>[];
    final others = <Contest>[];

    for (final contest in mockContests) {
      if (_userPreferences.contains(contest.category)) {
        prioritized.add(contest);
      } else {
        others.add(contest);
      }
    }

    // Mix prioritized and others for variety
    final result = [...prioritized, ...others];
    result.shuffle();

    return result;
  }

  List<Contest> _getFilteredContests() {
    if (_activeFilter == 'All') return _swipeContests;

    return _swipeContests
        .where((contest) => contest.category == _activeFilter)
        .toList();
  }

  Widget _buildFilterChip(String filter, int index) {
    final isActive = _activeFilter == filter;
    final delay = Duration(milliseconds: index * 50);

    return GestureDetector(
      onTap: () {
        _setActiveFilter(filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.cyberYellow, AppColors.mangoTangoStart],
                )
              : null,
          color:
              isActive ? null : AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive
                ? AppColors.cyberYellow
                : AppColors.primaryLight.withValues(alpha: 0.5),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.cyberYellow.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryDark,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              filter,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? AppColors.primaryDark : AppColors.textLight,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideX(
          begin: 0.2,
          duration: Duration(milliseconds: 400 + delay.inMilliseconds),
          curve: Curves.easeOutBack,
        )
        .fadeIn(
          duration: Duration(milliseconds: 300 + delay.inMilliseconds),
        );
  }

  void _setActiveFilter(String filter) {
    if (_activeFilter == filter) return;

    setState(() {
      _activeFilter = filter;
    });

    // Epic haptic feedback sequence
    HapticFeedback.lightImpact();

    // Animate filter change
    _filterController.reset();
    _filterController.forward();

    // Bounce animation for filter icon
    Future.delayed(
        const Duration(milliseconds: 100), HapticFeedback.selectionClick,);
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _refreshController.reset();
    _refreshController.forward();

    // Satisfying haptic feedback
    HapticFeedback.mediumImpact();

    // Reload data
    await _loadSwipeContests();

    setState(() => _isRefreshing = false);

    // Success feedback
    HapticFeedback.lightImpact();
  }

  Widget _buildSwipeFeedHeader() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryMedium.withValues(alpha: 0.9),
              AppColors.primaryDark.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.cyberYellow.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyberYellow.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyberYellow, AppColors.mangoTangoStart],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swipe,
                color: Colors.white,
                size: 32,
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),)
                .rotate(begin: -0.1, end: 0.1, duration: 1500.ms),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swipe to Enter',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New thrilling way to enter contests! Swipe right to confirm your entries.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _buildStatBadge('🎯', 'Entries: 12'),
                      const SizedBox(width: 8),
                      _buildStatBadge('🔥', '7-Day Streak'),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _refreshFeed,
              child: AnimatedBuilder(
                animation: _refreshController,
                builder: (context, child) => Transform.rotate(
                  angle: _refreshController.value * 2 * pi,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cyberYellow.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: AppColors.cyberYellow,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .slideY(
            begin: -0.3,
            duration: 600.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 400.ms);

  Widget _buildStatBadge(String emoji, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cyberYellow.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cyberYellow.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.cyberYellow,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterBar() => SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filterOptions.length,
          itemBuilder: (context, index) =>
              _buildFilterChip(_filterOptions[index], index),
        ),
      );

  Widget _buildSwipeContestsList() {
    final filteredContests = _getFilteredContests();

    if (filteredContests.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swipe_outlined,
                  color: AppColors.textLight,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No swipe contests found',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or check back later!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredContests.length,
      itemBuilder: (context, index) {
        final contest = filteredContests[index];

        return UnifiedContestCard(
          contest: contest,
          style: CardStyle.swipeToEnter,
          onEnter: () {
            HapticFeedback.heavyImpact();
            // Handle successful entry
            // setState(() {
            //   contest['swipeCompleted'] = true;
            //   contest['timesSwiped'] = (contest['timesSwiped'] ?? 0) + 1;
            // });
          },
        )
            .animate()
            .slideX(
              begin: 0.3,
              duration: Duration(milliseconds: 600 + (index * 150)),
              curve: Curves.easeOutBack,
            )
            .fadeIn(
              duration: Duration(milliseconds: 400 + (index * 100)),
            );
      },
    );
  }

  @override
  void dispose() {
    _filterController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyberYellow, AppColors.mangoTangoStart],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swipe,
                color: Colors.white,
                size: 32,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 800.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(0.8, 0.8),
                  duration: 800.ms,
                ),
            const SizedBox(height: 20),
            Text(
              'Loading swipe contests...',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSwipeFeedHeader(),
        _buildFilterBar(),
        const SizedBox(height: 16),
        _buildSwipeContestsList(),
      ],
    );
  }
}
