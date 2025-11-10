import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../contests/widgets/addictive_contest_card.dart';
// Removed infinite_scroll_pagination - using standard ListView instead

class ForYouFeed extends ConsumerStatefulWidget {
  const ForYouFeed({super.key});

  @override
  ConsumerState<ForYouFeed> createState() => _ForYouFeedState();
}

class _ForYouFeedState extends ConsumerState<ForYouFeed>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _filterController;
  late AnimationController _refreshController;

  List<Map<String, dynamic>> _personalizedContests = [];
  List<String> _userPreferences = [];
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

    _loadUserPreferences();
    _loadPersonalizedContests();
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()!.containsKey('preferences')) {
        setState(() {
          _userPreferences =
              List<String>.from(userDoc.data()!['preferences'] ?? []);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadPersonalizedContests() async {
    setState(() => _isLoading = true);

    try {
      // Generate personalized contests based on preferences
      final contests = await _generatePersonalizedContests();

      setState(() {
        _personalizedContests = contests;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _generatePersonalizedContests() async {
    // Mock personalized contest data based on user preferences
    final baseContests = _generateMockContests();

    // If user has preferences, prioritize those categories
    if (_userPreferences.isNotEmpty) {
      final prioritized = <Map<String, dynamic>>[];
      final others = <Map<String, dynamic>>[];

      for (final contest in baseContests) {
        if (_userPreferences.contains(contest['category'])) {
          prioritized.add(contest);
        } else {
          others.add(contest);
        }
      }

      // Mix prioritized and others for variety
      final result = [...prioritized];
      result.addAll(others.take(5)); // Add some variety
      result.shuffle();

      return result;
    }

    return baseContests;
  }

  List<Map<String, dynamic>> _generateMockContests() {
    final random = Random();
    final mockContests = <Map<String, dynamic>>[];

    final contestTemplates = [
      {
        'title': 'Win \$50,000 Cash Prize',
        'description':
            'Enter now for your chance to win fifty thousand dollars in cash!',
        'category': 'Cash Prizes',
        'prizeValue': '50000',
        'isHighValue': true,
      },
      {
        'title': 'iPhone 15 Pro Max Giveaway',
        'description': 'Get the latest iPhone with all the premium features.',
        'category': 'Electronics',
        'prizeValue': '1199',
        'isHighValue': true,
      },
      {
        'title': 'Amazon Gift Card Bundle',
        'description': 'Win \$500 in Amazon gift cards to shop for anything!',
        'category': 'Gift Cards',
        'prizeValue': '500',
        'isHighValue': false,
      },
      {
        'title': 'Tesla Model 3 Sweepstakes',
        'description': 'Drive away in a brand new Tesla Model 3!',
        'category': 'Luxury Cars',
        'prizeValue': '45000',
        'isHighValue': true,
      },
      {
        'title': 'Hawaii Vacation Package',
        'description': 'All-expenses-paid trip to paradise for two people.',
        'category': 'Travel & Vacations',
        'prizeValue': '8000',
        'isHighValue': true,
      },
      {
        'title': 'Gaming Setup Ultimate',
        'description':
            'Complete gaming setup with RTX 4080, monitors, and accessories.',
        'category': 'Gaming & Entertainment',
        'prizeValue': '3500',
        'isHighValue': false,
      },
      {
        'title': 'Weekly Cash Drop',
        'description': 'Win \$1,000 every week for the next 10 weeks!',
        'category': 'Cash Prizes',
        'prizeValue': '10000',
        'isHighValue': true,
      },
      {
        'title': 'Smart Home Bundle',
        'description':
            'Complete smart home setup with Alexa, cameras, and more.',
        'category': 'Electronics',
        'prizeValue': '2500',
        'isHighValue': false,
      },
    ];

    for (var i = 0; i < contestTemplates.length; i++) {
      final template = contestTemplates[i];
      final contest = Map<String, dynamic>.from(template);

      // Add dynamic fields
      contest['id'] = 'contest_$i';
      contest['entryCount'] = 1000 + random.nextInt(9000);
      contest['endDate'] = DateTime.now().add(
        Duration(
          days: 1 + random.nextInt(30),
          hours: random.nextInt(24),
        ),
      );
      contest['imageUrl'] = 'https://picsum.photos/400/200?random=$i';

      mockContests.add(contest);
    }

    return mockContests;
  }

  List<Map<String, dynamic>> _getFilteredContests() {
    if (_activeFilter == 'All') return _personalizedContests;

    return _personalizedContests
        .where((contest) => contest['category'] == _activeFilter)
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
        const Duration(milliseconds: 100), HapticFeedback.selectionClick);
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _refreshController.reset();
    _refreshController.forward();

    // Satisfying haptic feedback
    HapticFeedback.mediumImpact();

    // Reload data
    await _loadPersonalizedContests();

    setState(() => _isRefreshing = false);

    // Success feedback
    HapticFeedback.lightImpact();
  }

  Widget _buildPersonalizedHeader() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryMedium.withValues(alpha: 0.8),
              AppColors.primaryDark.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.cyberYellow.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyberYellow, AppColors.mangoTangoStart],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For You',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _userPreferences.isEmpty
                        ? 'Contests picked just for you!'
                        : 'Based on your preferences: ${_userPreferences.take(2).join(", ")}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: AppColors.cyberYellow,
                      size: 20,
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

  Widget _buildContestsList() => ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _personalizedContests.length,
        itemBuilder: (context, index) {
          final contest = _personalizedContests[index];
          final isHighValue = contest['isHighValue'] == true;
          return AddictiveContestCard(
            contest: contest,
            isHighValue: isHighValue,
            index: index,
            onTap: HapticFeedback.mediumImpact,
            onBookmark: HapticFeedback.lightImpact,
            onShare: HapticFeedback.lightImpact,
          );
        },
      );

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyberYellow),
        ),
      );
    }

    return Column(
      children: [
        _buildPersonalizedHeader(),
        _buildFilterBar(),
        const SizedBox(height: 16),
        _buildContestsList(),
      ],
    );
  }
}
