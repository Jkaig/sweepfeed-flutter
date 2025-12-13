import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/contest.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/page_transitions.dart';
import '../../saved/services/saved_contests_service.dart';
import '../screens/contest_detail_screen.dart';
import 'contest_badge.dart';
import 'countdown_timer.dart';
import 'enter_button.dart';
import 'favorite_button.dart';
import '../../../core/widgets/dustbunnies_display.dart';
import '../widgets/comment_section.dart';
import '../widgets/contest_share_dialog.dart';

enum CardStyle {
  detailed,
  compact,
  trending,
  simple,
  addictive,
  tiktok,
  swipeToEnter,
  full,
}

class UnifiedContestCard extends ConsumerStatefulWidget {
  const UnifiedContestCard({
    required this.contest,
    required this.style,
    super.key,
    this.onTap,
    this.onEnter,
    this.onSave,
    this.isSaved = false,
    this.index,
  });

  final Contest contest;
  final CardStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onEnter;
  final VoidCallback? onSave;
  final bool isSaved;
  final int? index;

  @override
  ConsumerState<UnifiedContestCard> createState() => _UnifiedContestCardState();
}

class _UnifiedContestCardState extends ConsumerState<UnifiedContestCard>
    with TickerProviderStateMixin {
  // State for AddictiveCard
  late AnimationController _addictiveShimmerController;
  late AnimationController _addictivePulseController;
  late AnimationController _addictiveCountdownController;
  late Timer _addictiveCountdownTimer;

  bool _addictiveIsPressed = false;
  Duration _addictiveTimeRemaining = const Duration();
  String _addictiveUrgencyLevel = 'normal';

  // State for SwipeToEnterCard
  late AnimationController _swipeController;
  late AnimationController _swipeCelebrationController;
  late AnimationController _swipePulseController;
  late ConfettiController _swipeConfettiController;

  double _swipeProgress = 0.0;
  bool _swipeIsEntered = false;
  bool _swipeIsSwipeActive = false;
  Timer? _swipeResetTimer;

  bool _swipeShowSuccess = false;
  int _swipeEntryNumber = 0;

  @override
  void initState() {
    super.initState();
    if (widget.style == CardStyle.addictive) {
      _addictiveShimmerController = AnimationController(
        duration: const Duration(seconds: 4),
        vsync: this,
      );

      _addictivePulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _addictiveCountdownController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );

      _addictiveInitializeCountdown();

      if (widget.contest.prizeValueAmount != null &&
          widget.contest.prizeValueAmount! > 1000) {
        _addictiveShimmerController.repeat();
      }
    }
    if (widget.style == CardStyle.swipeToEnter) {
      _swipeController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _swipeCelebrationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );

      _swipePulseController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      )..repeat(reverse: true);

      _swipeConfettiController = ConfettiController(
        duration: const Duration(seconds: 3),
      );

      _swipeEntryNumber = 1234 + Random().nextInt(8766);
    }
  }

  @override
  void dispose() {
    if (widget.style == CardStyle.addictive) {
      _addictiveShimmerController.dispose();
      _addictivePulseController.dispose();
      _addictiveCountdownController.dispose();
      _addictiveCountdownTimer.cancel();
    }
    if (widget.style == CardStyle.swipeToEnter) {
      _swipeController.dispose();
      _swipeCelebrationController.dispose();
      _swipePulseController.dispose();
      _swipeConfettiController.dispose();
      _swipeResetTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case CardStyle.detailed:
        return _buildDetailedCard(context, ref);
      case CardStyle.compact:
        return _buildCompactCard(context, ref);
      case CardStyle.trending:
        return _buildTrendingCard(context, ref);
      case CardStyle.simple:
        return _buildSimpleCard(context, ref);
      case CardStyle.addictive:
        return _buildAddictiveCard(context, ref);
      case CardStyle.tiktok:
        return _buildTikTokCard(context, ref);
      case CardStyle.swipeToEnter:
        return _buildSwipeToEnterCard(context, ref);
      case CardStyle.full:
        return _buildFullCard(context, ref);
      default:
        return _buildDetailedCard(context, ref);
    }
  }

  // Detailed Card Implementation
  Widget _buildDetailedCard(BuildContext context, WidgetRef ref) {
    final entryService = ref.watch(entryServiceProvider);
    final currentUser = ref.watch(firebaseServiceProvider).currentUser;

    final hasEnteredFuture = currentUser != null
        ? entryService.hasEntered(currentUser.uid, widget.contest.id)
        : Future.value(false);

    final isEndingSoon =
        widget.contest.endDate.difference(DateTime.now()).inDays < 3;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref
            .read(analyticsServiceProvider)
            .logContestView(contestId: widget.contest.id);
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          Navigator.push(
            context,
            PageTransitions.sharedAxisTransition(
              page: ContestDetailScreen(contestId: widget.contest.id),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEndingSoon
                ? AppColors.warningOrange.withOpacity(0.5)
                : AppColors.primaryLight.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailedImageHeader(context),
            _buildDetailedContestInfo(context),
            _buildDetailedActionFooter(context, ref, hasEnteredFuture),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedImageHeader(
    BuildContext context,
  ) =>
      Stack(
        children: [
          Hero(
            tag: 'contest-image-${widget.contest.id}',
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: widget.contest.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.primaryLight,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _buildDetailedBadges(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: FavoriteButton(
              isFavorite: widget.isSaved,
              onToggle: widget.onSave,
            ),
          ),
        ],
      );

  Widget _buildDetailedBadges() => Row(
        children: [
          if (widget.contest.isVetted)
            const ContestBadge(
              text: 'VETTED',
              icon: Icons.verified,
              backgroundColor: AppColors.successGreen,
              textColor: Colors.white,
            ),
          if (widget.contest.isPremium)
            const ContestBadge(
              text: 'PREMIUM',
              icon: Icons.diamond,
              backgroundColor: AppColors.electricBlue,
              textColor: Colors.white,
            ),
          if (widget.contest.isHot)
            const ContestBadge(
              text: 'HOT',
              icon: Icons.local_fire_department,
              backgroundColor: AppColors.errorRed,
              textColor: Colors.white,
            ),
        ],
      );

  Widget _buildDetailedContestInfo(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contest.title,
              style:
                  AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.contest.sponsor,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildDetailedActionFooter(
    BuildContext context,
    WidgetRef ref,
    Future<bool> hasEnteredFuture,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIME LEFT',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                CountdownTimer(endDate: widget.contest.endDate),
              ],
            ),
            FutureBuilder<bool>(
              future: hasEnteredFuture,
              builder: (context, snapshot) {
                final hasEntered = snapshot.data ?? false;
                return EnterButton(
                  contest: widget.contest,
                  hasEntered: hasEntered,
                );
              },
            ),
          ],
        ),
      );

  Widget _buildCompactCard(BuildContext context, WidgetRef ref) {
    return Container();
  }

  // Trending Card Implementation
  Widget _buildTrendingCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandCyan.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.accentGlow.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.contest.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: AppColors.primaryLight),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.image_not_supported,
                      color: AppColors.textMuted),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.contest.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.contest.prize,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple Card Implementation
  Widget _buildSimpleCard(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2F4B),
            Color(0xFF0F1F35),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  widget.contest.sponsor.isNotEmpty
                      ? widget.contest.sponsor[0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.contest.sponsor == 'Amazon' ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    fontStyle: widget.contest.sponsor == 'Amazon'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contest.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.contest.frequency,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                      if (widget.contest.status != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${widget.contest.status.value}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ends in ${widget.contest.daysRemaining} days',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.red.shade300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (widget.onEnter != null) {
                  widget.onEnter!();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Enter Now',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Addictive Card Implementation
  void _addictiveInitializeCountdown() {
    final endDate = widget.contest.endDate;
    _addictiveUpdateTimeRemaining(endDate);
    _addictiveStartCountdownTimer(endDate);
  }

  void _addictiveStartCountdownTimer(DateTime endDate) {
    _addictiveCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _addictiveUpdateTimeRemaining(endDate);
      }
    });
  }

  void _addictiveUpdateTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final remaining = endDate.difference(now);

    setState(() {
      _addictiveTimeRemaining = remaining.isNegative ? Duration.zero : remaining;

      final hoursLeft = _addictiveTimeRemaining.inHours;
      if (hoursLeft <= 24) {
        _addictiveUrgencyLevel = 'critical';
        _addictivePulseController.repeat(reverse: true);
      } else if (hoursLeft <= 72) {
        _addictiveUrgencyLevel = 'urgent';
        _addictivePulseController.repeat(reverse: true);
      } else {
        _addictiveUrgencyLevel = 'normal';
        _addictivePulseController.stop();
      }
    });

    _addictiveCountdownController.reset();
    _addictiveCountdownController.forward();
  }

  Color _addictiveGetUrgencyColor() {
    switch (_addictiveUrgencyLevel) {
      case 'critical':
        return AppColors.errorRed;
      case 'urgent':
        return AppColors.warningOrange;
      default:
        return AppColors.successGreen;
    }
  }

  String _addictiveFormatTimeRemaining() {
    if (_addictiveTimeRemaining.inDays > 0) {
      return '${_addictiveTimeRemaining.inDays}d ${_addictiveTimeRemaining.inHours % 24}h';
    } else if (_addictiveTimeRemaining.inHours > 0) {
      return '${_addictiveTimeRemaining.inHours}h ${_addictiveTimeRemaining.inMinutes % 60}m';
    } else if (_addictiveTimeRemaining.inMinutes > 0) {
      return '${_addictiveTimeRemaining.inMinutes}m ${_addictiveTimeRemaining.inSeconds % 60}s';
    } else {
      return 'ENDED';
    }
  }

  Widget _addictiveBuildShimmerOverlay() => Positioned.fill(
        child: Shimmer.fromColors(
          baseColor: Colors.transparent,
          highlightColor: AppColors.cyberYellow.withOpacity(0.3),
          period: const Duration(seconds: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.cyberYellow.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: const Alignment(-1.0, -1.0),
                end: const Alignment(1.0, 1.0),
              ),
            ),
          ),
        ),
      );

  Widget _addictiveBuildCountdownTimer() => AnimatedBuilder(
        animation: _addictiveCountdownController,
        builder: (context, child) => AnimatedBuilder(
          animation: _addictivePulseController,
          builder: (context, child) {
            final pulseValue = _addictiveUrgencyLevel != 'normal'
                ? (1.0 + (_addictivePulseController.value * 0.1))
                : 1.0;

            return Transform.scale(
              scale: pulseValue * (1.0 + (_addictiveCountdownController.value * 0.05)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _addictiveGetUrgencyColor().withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _addictiveGetUrgencyColor().withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _addictiveUrgencyLevel == 'critical'
                          ? Icons.timer_outlined
                          : Icons.schedule,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _addictiveFormatTimeRemaining(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _addictiveBuildPrizeValue() {
    final prizeValue = widget.contest.prizeValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.cyberYellow,
            AppColors.mangoTangoStart,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyberYellow.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '\$$prizeValue',
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _addictiveBuildActionButtons() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _addictiveBuildActionButton(
            icon: Icons.share,
            onTap: () {
              HapticFeedback.lightImpact();
              // widget.onShare!();
            },
          ),
          const SizedBox(width: 8),
          _addictiveBuildActionButton(
            icon: Icons.bookmark_border,
            onTap: () {
              HapticFeedback.mediumImpact();
              if (widget.onSave != null) {
                widget.onSave!();
              }
            },
          ),
        ],
      );

  Widget _addictiveBuildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryLight,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textLight,
            size: 16,
          ),
        ),
      );

  Widget _buildAddictiveCard(BuildContext context, WidgetRef ref) {
    final delay = Duration(milliseconds: (widget.index ?? 0) * 100);
    final isHighValue = widget.contest.prizeValueAmount != null &&
        widget.contest.prizeValueAmount! > 1000;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _addictiveIsPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _addictiveIsPressed = false);
        HapticFeedback.mediumImpact();
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onTapCancel: () {
        setState(() => _addictiveIsPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_addictiveIsPressed ? 0.95 : 1.0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                AppColors.primaryMedium,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isHighValue
                  ? AppColors.cyberYellow.withOpacity(0.5)
                  : AppColors.primaryLight,
              width: isHighValue ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHighValue
                    ? AppColors.cyberYellow.withOpacity(0.2)
                    : AppColors.primaryDark.withOpacity(0.3),
                blurRadius: isHighValue ? 15 : 10,
                spreadRadius: isHighValue ? 3 : 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isHighValue) _addictiveBuildShimmerOverlay(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _addictiveBuildCountdownTimer(),
                        _addictiveBuildActionButtons(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.contest.title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.contest.description ?? 'Win amazing prizes!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _addictiveBuildPrizeValue(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people,
                                color: AppColors.textLight,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.contest.entryCount ?? 0} entries',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
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
              if (isHighValue)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.errorRed, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.errorRed.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      'HOT 🔥',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      )
                      .then(delay: 200.ms)
                      .shake(hz: 2, curve: Curves.easeInOut),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideX(
          begin: 0.3,
          duration: Duration(milliseconds: 600 + (widget.index ?? 0) * 100),
          curve: Curves.easeOutBack,
        )
        .fadeIn(
          duration: Duration(milliseconds: 400 + (widget.index ?? 0) * 100),
        );
  }

  // TikTok Card Implementation
  Widget _buildTikTokCard(BuildContext context, WidgetRef ref) {
    final isEntered = false; // Replace with actual logic

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1929),
            Color(0xFF1E3A5F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TikTok Exclusive Giveaway!',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.contest.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Sponsor: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
                Text(
                  widget.contest.sponsor,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1929),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tiktokGetIconForCategory(widget.contest.category),
                    size: 60,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prize',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    widget.contest.prize,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Value',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    widget.contest.prizeValue,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _tiktokBuildTag('Category', widget.contest.category),
                const SizedBox(width: 8),
                _tiktokBuildTag('Frequency', widget.contest.frequency),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contest Details',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _tiktokBuildDetailRow(
                    'Start:', _tiktokFormatDate(widget.contest.startDate)),
                _tiktokBuildDetailRow(
                    'Ends:', _tiktokFormatDate(widget.contest.endDate)),
                _tiktokBuildDetailRow(
                    'Eligibility:', widget.contest.eligibility),
                _tiktokBuildDetailRow(
                    'Entry Method:', widget.contest.entryMethod ?? 'Online'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (widget.onEnter != null) {
                      widget.onEnter!();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isEntered
                          ? Colors.green
                          : const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isEntered
                                  ? Colors.green
                                  : const Color(0xFF0066FF))
                              .withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isEntered ? '✓ Already Entered' : 'Enter Contest',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: HapticFeedback.lightImpact,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'View Rules',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (widget.onSave != null) {
                          widget.onSave!();
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            widget.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save for later',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'Add a comment',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Center(
                            child: Text(
                              '2', // Replace with actual comment count
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  // SwipeToEnter Card Implementation
  void _swipeHandlePanUpdate(DragUpdateDetails details) {
    if (_swipeIsEntered) return;

    setState(() {
      _swipeIsSwipeActive = true;
      _swipeProgress =
          (_swipeProgress + details.primaryDelta! / 200).clamp(0.0, 1.0);
    });

    if (_swipeProgress > 0.3 && _swipeProgress < 0.35) {
      HapticFeedback.lightImpact();
    } else if (_swipeProgress > 0.6 && _swipeProgress < 0.65) {
      HapticFeedback.mediumImpact();
    } else if (_swipeProgress > 0.9 && _swipeProgress < 0.95) {
      HapticFeedback.heavyImpact();
    }

    if (_swipeProgress >= 1.0) {
      _swipeCompleteEntry();
    }
  }

  void _swipeHandlePanEnd(DragEndDetails details) {
    if (_swipeIsEntered) return;

    setState(() => _swipeIsSwipeActive = false);

    if (_swipeProgress < 1.0) {
      _swipeController.forward().then((_) {
        setState(() => _swipeProgress = 0.0);
        _swipeController.reset();
      });

      _swipeResetTimer?.cancel();
      _swipeResetTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted && _swipeProgress < 1.0) {
          setState(() => _swipeProgress = 0.0);
        }
      });
    }
  }

  Future<void> _swipeCompleteEntry() async {
    if (_swipeIsEntered) return;

    setState(() {
      _swipeIsEntered = true;
      _swipeShowSuccess = true;
    });

    HapticFeedback.heavyImpact();
    _swipeConfettiController.play();
    _swipeCelebrationController.forward();

    Future.delayed(
      const Duration(milliseconds: 100),
      HapticFeedback.mediumImpact,
    );
    Future.delayed(
      const Duration(milliseconds: 200),
      HapticFeedback.lightImpact,
    );
    Future.delayed(
      const Duration(milliseconds: 300),
      HapticFeedback.lightImpact,
    );

    if (widget.onEnter != null) {
      widget.onEnter!();
    }

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _swipeShowSuccess = false);
      }
    });
  }

  Widget _swipeBuildSwipeTrack() => Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight.withOpacity(0.3),
              AppColors.primaryMedium.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: (widget.contest.prizeValueAmount ?? 0) > 1000
                ? AppColors.cyberYellow
                : AppColors.primaryLight,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: MediaQuery.of(context).size.width * 0.8 * _swipeProgress,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cyberYellow,
                    AppColors.mangoTangoStart,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: (MediaQuery.of(context).size.width * 0.8 - 56) *
                  _swipeProgress,
              top: 2,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppColors.cyberYellow.withOpacity(0.9),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyberYellow.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _swipeProgress > 0.8 ? Icons.check : Icons.chevron_right,
                  color: AppColors.primaryDark,
                  size: 28,
                ),
              )
                  .animate(
                    target: _swipeIsSwipeActive ? 1 : 0,
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                    duration: 150.ms,
                  ),
            ),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _swipeProgress < 0.5 ? 1.0 : 0.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe to Enter',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _swipeProgress >= 0.5 ? 1.0 : 0.0,
                child: Text(
                  _swipeProgress >= 1.0 ? 'ENTERED!' : 'Keep Swiping...',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _swipeBuildSuccessOverlay() => AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        top: _swipeShowSuccess ? 0 : -100,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.successGreen,
                AppColors.cyberYellow,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.successGreen.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 40,
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(hz: 3, duration: 400.ms),
              const SizedBox(height: 12),
              Text(
                'ENTRY CONFIRMED!',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entry #$_swipeEntryNumber',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _swipeBuildStatChip('🎯', 'Entries Today: 3'),
                  _swipeBuildStatChip('🔥', '5-Day Streak!'),
                  _swipeBuildStatChipWithDB(50),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _swipeBuildStatChip(String emoji, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

  Widget _swipeBuildStatChipWithDB(int amount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CompactDustBunniesDisplay(
          amount: amount,
          showPlus: true,
          color: Colors.white,
          fontSize: 11,
        ),
      );

  Widget _buildSwipeToEnterCard(BuildContext context, WidgetRef ref) {
    final isHighValue = widget.contest.prizeValueAmount != null &&
        widget.contest.prizeValueAmount! > 1000;

    return Stack(
      children: [
        GestureDetector(
          onPanUpdate: _swipeHandlePanUpdate,
          onPanEnd: _swipeHandlePanEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  if (isHighValue)
                    AppColors.primaryMedium.withOpacity(0.9)
                  else
                    AppColors.primaryLight.withOpacity(0.8),
                  if (isHighValue)
                    AppColors.primaryDark
                  else
                    AppColors.primaryMedium,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHighValue
                    ? AppColors.cyberYellow.withOpacity(0.6)
                    : AppColors.primaryLight.withOpacity(0.4),
                width: isHighValue ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHighValue
                      ? AppColors.cyberYellow.withOpacity(0.3)
                      : AppColors.primaryDark.withOpacity(0.3),
                  blurRadius: isHighValue ? 20 : 15,
                  spreadRadius: isHighValue ? 4 : 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isHighValue) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.cyberYellow, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'HOT 🔥',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.contest.title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.cyberYellow,
                        AppColors.mangoTangoStart,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyberYellow.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.contest.prizeValue,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!_swipeIsEntered) _swipeBuildSwipeTrack(),
                if (_swipeIsEntered && !_swipeShowSuccess)
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.successGreen,
                          AppColors.cyberYellow,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        'ENTERED! Good luck! 🍀',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      )
                      .then()
                      .shimmer(
                        duration: 1000.ms,
                        color: Colors.white.withOpacity(0.5),
                      ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: ConfettiWidget(
            confettiController: _swipeConfettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              AppColors.cyberYellow,
              AppColors.successGreen,
              AppColors.mangoTangoStart,
              Colors.orange,
              Colors.purple,
            ],
            numberOfParticles: 150,
            gravity: 0.3,
          ),
        ),
        _swipeBuildSuccessOverlay(),
      ],
    );
  }

  // Full Card Implementation
  Widget _buildFullCard(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contest.title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.business,
                  size: 16,
                  color: AppColors.brandCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.contest.sponsor,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.brandCyan,
                  ),
                ),
                if (widget.contest.brand != null &&
                    widget.contest.brand != widget.contest.sponsor) ...[
                  Text(
                    ' • ${widget.contest.brand}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (widget.contest.isVetted) ...[
                  const SizedBox(width: 12),
                  const ContestBadge(
                    text: 'VETTED',
                    icon: Icons.verified,
                    backgroundColor: AppColors.successGreen,
                    textColor: Colors.white,
                  ),
                ],
              ],
            ),
            if (widget.contest.coSponsors != null && widget.contest.coSponsors!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'with ${widget.contest.coSponsors!.join(", ")}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (widget.contest.prizeImages != null && widget.contest.prizeImages!.isNotEmpty) ...[
               SizedBox(
                 height: 200,
                 child: ListView.builder(
                   scrollDirection: Axis.horizontal,
                   itemCount: widget.contest.prizeImages!.length,
                   itemBuilder: (context, index) {
                     return Padding(
                       padding: const EdgeInsets.only(right: 12.0),
                       child: ClipRRect(
                         borderRadius: BorderRadius.circular(12),
                         child: CachedNetworkImage(
                           imageUrl: widget.contest.prizeImages![index],
                           fit: BoxFit.cover,
                           width: 280,
                           placeholder: (context, url) => Container(color: AppColors.primaryLight),
                           errorWidget: (context, url, error) => const Icon(Icons.error),
                         ),
                       ),
                     );
                   },
                 ),
               ),
               const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryLight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          Icons.attach_money,
                          'Value',
                          widget.contest.prizeValue,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          Icons.calendar_today,
                          'Ends',
                          DateFormat('MMM d, yyyy')
                              .format(widget.contest.endDate),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.primaryLight),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          Icons.category,
                          'Category',
                          widget.contest.category,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          Icons.repeat,
                          'Frequency',
                          widget.contest.frequency,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prize Details',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.contest.prize,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            if (widget.contest.prizeDetails != null &&
                widget.contest.prizeDetails!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...widget.contest.prizeDetails!.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '• ${entry.key}: ${entry.value}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Eligibility & Rules',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryMedium.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.public,
                    'Location',
                    widget.contest.eligibilityLocation ??
                        widget.contest.eligibility,
                  ),
                  if (widget.contest.eligibilityAge != null)
                    _buildInfoRow(
                      Icons.person_outline,
                      'Age Requirement',
                      widget.contest.eligibilityAge!,
                    ),
                  if (widget.contest.entryRequirements != null)
                    _buildInfoRow(
                      Icons.rule,
                      'Entry Requirements',
                      widget.contest.entryRequirements!,
                    ),
                  if (widget.contest.winnerCount != null)
                    _buildInfoRow(
                      Icons.emoji_events_outlined,
                      'Winners',
                      widget.contest.winnerCount!,
                    ),
                  if (widget.contest.administrator != null)
                    _buildInfoRow(
                      Icons.admin_panel_settings_outlined,
                      'Administrator',
                      widget.contest.administrator!,
                    ),
                  if (widget.contest.requiresPurchase != null)
                    _buildInfoRow(
                      widget.contest.requiresPurchase!
                          ? Icons.shopping_cart
                          : Icons.money_off,
                      'Purchase Required',
                      widget.contest.requiresPurchase! ? 'Yes' : 'No',
                    ),
                  if (widget.contest.entryMethods != null &&
                      widget.contest.entryMethods!.isNotEmpty)
                    _buildInfoRow(
                      Icons.login,
                      'Entry Methods',
                      widget.contest.entryMethods!.join(', '),
                    ),
                ],
              ),
            ),
            if (widget.contest.legalDisclaimer != null ||
                widget.contest.rulesUrl != null || 
                widget.contest.rulesText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: AppColors.textMuted.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          'Official Information',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.contest.legalDisclaimer != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          widget.contest.legalDisclaimer!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (widget.contest.rulesUrl != null)
                      InkWell(
                        onTap: () => _launchRules(widget.contest.rulesUrl),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(
                                'Read Full Official Rules',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.brandCyan,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.open_in_new,
                                size: 12,
                                color: AppColors.brandCyan,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.contest.rulesText != null)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(
                            'Show Full Rules Text',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight, fontWeight: FontWeight.bold,),
                          ),
                          tilePadding: EdgeInsets.zero,
                          children: [
                            Text(
                              widget.contest.rulesText!,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted, fontSize: 10,),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            CommentSection(contestId: widget.contest.id),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.brandCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _launchRules(String? urlString) async {
    if (urlString == null) return;
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      //
    }
  }

  // Helper methods for TikTok Card
  Widget _tiktokBuildTag(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

  Widget _tiktokBuildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  String _tiktokFormatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _tiktokGetIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'cash':
        return Icons.attach_money;
      case 'travel':
        return Icons.flight;
      case 'cars':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'home':
        return Icons.home;
      case 'gift cards':
        return Icons.card_giftcard;
      default:
        return Icons.card_giftcard;
    }
  }
}
