import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/greeting_utils.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../ads/widgets/admob_banner.dart';
import '../../navigation/widgets/side_drawer.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/contest_filter.dart';
import '../widgets/advanced_filter_sheet.dart';
import '../widgets/contest_feed_list.dart';
import '../widgets/daily_reentry_tracker.dart';
import '../widgets/filter_chip.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/popular_sweepstakes_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final aiGreetingService = ref.watch(aiGreetingServiceProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: const SideDrawer(),
      backgroundColor: AppColors.primaryDark,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 0) {
            scaffoldKey.currentState?.openDrawer();
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                child: userProfile.when(
                  data: (user) {
                    final userName = user?.name ?? 'User';
                    final profilePictureUrl = user?.profilePictureUrl;
                    final streak = user?.streak ?? 0;
                    final tier = user?.tier ?? 'Rookie';
                    final points = user?.points ?? 0;

                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(userProfileProvider.future),
                      child: Column(
                        children: [
                          // Header with user greeting, tier, and streak
                          Container(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding,
                              AppSpacing.medium,
                              AppSpacing.screenPadding,
                              AppSpacing.small,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left side: Menu + Greeting + Streak
                                    Expanded(
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.menu,
                                              color: AppColors.textWhite,
                                              size: 28,
                                            ),
                                            onPressed: () {
                                              scaffoldKey.currentState
                                                  ?.openDrawer();
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FutureBuilder<String>(
                                                  future: aiGreetingService
                                                      .getPersonalizedGreeting(
                                                          user),
                                                  builder: (context, snapshot) {
                                                    final greeting = snapshot
                                                            .data ??
                                                        getTimeBasedGreeting();
                                                    final fullText =
                                                        '$greeting, $userName!';
                                                    final fontSize = fullText
                                                                .length >
                                                            20
                                                        ? 18.0
                                                        : fullText.length > 15
                                                            ? 20.0
                                                            : 24.0;
                                                    return Text(
                                                      fullText,
                                                      style: AppTextStyles
                                                          .headlineMedium
                                                          .copyWith(
                                                        color:
                                                            AppColors.textWhite,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: fontSize,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: false,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                          colors: [
                                                            AppColors.brandCyan,
                                                            AppColors
                                                                .brandCyanDark,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          16,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppColors
                                                                .brandCyan
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.stars_rounded,
                                                            color: AppColors
                                                                .textWhite,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '$points Points',
                                                            style: AppTextStyles
                                                                .bodySmall
                                                                .copyWith(
                                                              color: AppColors
                                                                  .textWhite,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                          colors: [
                                                            AppColors
                                                                .warningOrange,
                                                            AppColors.errorRed,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          16,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppColors
                                                                .warningOrange
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .local_fire_department,
                                                            color: AppColors
                                                                .textWhite,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '$streak Day Streak',
                                                            style: AppTextStyles
                                                                .bodySmall
                                                                .copyWith(
                                                              color: AppColors
                                                                  .textWhite,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Right side: Profile + Rank Badge
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProfileScreen(),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.brandCyan
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 32,
                                              backgroundColor:
                                                  AppColors.primary,
                                              backgroundImage:
                                                  profilePictureUrl != null
                                                      ? CachedNetworkImageProvider(
                                                          profilePictureUrl,
                                                        )
                                                      : const AssetImage(
                                                          'assets/icon/appicon.png',
                                                        ) as ImageProvider,
                                              onBackgroundImageError:
                                                  (exception, stackTrace) {
                                                print(
                                                  'Failed to load profile image: $exception',
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            top: -4,
                                            left: -8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    AppColors.primary,
                                                    AppColors.primaryDark,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.person,
                                                    color: AppColors.textWhite,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tier.toUpperCase(),
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                      color:
                                                          AppColors.textWhite,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 9,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Main content area
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                                vertical: AppSpacing.small,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Search and filter section
                                  HomeSearchBar(
                                    onChanged: (query) {
                                      ref
                                          .read(searchQueryProvider.notifier)
                                          .state = query;
                                    },
                                    onFilterPressed: () {
                                      _showFilterBottomSheet(context, ref);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  SizedBox(
                                    height: 40,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: ContestFilter.values
                                          .map(
                                            (filter) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Consumer(
                                                builder: (context, ref, _) {
                                                  final activeFilter =
                                                      ref.watch(
                                                    activeContestFilterProvider,
                                                  );
                                                  final isSelected =
                                                      activeFilter ==
                                                          filter.name;

                                                  return CustomFilterChip(
                                                    label:
                                                        _getFilterLabel(filter),
                                                    isSelected: isSelected,
                                                    onSelected: () {
                                                      ref
                                                          .read(
                                                            activeContestFilterProvider
                                                                .notifier,
                                                          )
                                                          .state = filter.name;
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.large),

                                  // Daily Re-Entry Tracker
                                  const DailyReentryTracker(),

                                  const SizedBox(height: AppSpacing.xlarge),

                                  // Popular Sweepstakes Section
                                  Text(
                                    'Popular Sweepstakes',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  const PopularSweepstakesList(),

                                  const SizedBox(height: AppSpacing.xlarge),

                                  // Main Feed Section
                                  Text(
                                    'Latest Sweepstakes',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  const ContestFeedList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (err, stack) =>
                      const Center(child: Text('Could not load user data')),
                ),
              ),
            ),
            // Ad banner at bottom where bottom nav was
            const AdMobBanner(),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(ContestFilter filter) => filter.label;

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark.withValues(alpha: 0.0),
      isScrollControlled: true,
      builder: (context) => AdvancedFilterSheet(
        onApply: (filter) {
          ref.read(advancedFilterProvider.notifier).state = filter;
        },
      ),
    );
  }

  IconData _getFilterIcon(ContestFilter filter) {
    switch (filter) {
      case ContestFilter.highValue:
        return Icons.diamond;
      case ContestFilter.endingSoon:
        return Icons.schedule;
      case ContestFilter.dailyEntry:
        return Icons.calendar_today;
      case ContestFilter.easyEntry:
        return Icons.flash_on;
      case ContestFilter.trending:
        return Icons.trending_up;
      case ContestFilter.newToday:
        return Icons.new_releases;
    }
  }
}
