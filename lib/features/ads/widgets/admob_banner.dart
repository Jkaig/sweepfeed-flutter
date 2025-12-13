import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../services/admob_service.dart';

class AdMobBanner extends ConsumerStatefulWidget {
  const AdMobBanner({
    super.key,
    this.height = 50,
    this.showShimmer = true,
  });
  final double height;
  final bool showShimmer;

  @override
  ConsumerState<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends ConsumerState<AdMobBanner>
    with SingleTickerProviderStateMixin {
  final AdMobService _adMobService = AdMobService();
  late AnimationController _shimmerController;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Load ad after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAd();
    });
  }

  void _loadAd() {
    final bannerAd = _adMobService.getBannerAd();
    if (bannerAd != null) {
      setState(() {
        _isAdLoaded = true;
      });
    } else {
      // Try to load if not already loaded
      _adMobService.loadBannerAd();
      // Check again after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          final ad = _adMobService.getBannerAd();
          if (ad != null) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);

    // Don't show ads for premium users
    if (subscriptionService.isSubscribed) {
      return const SizedBox.shrink();
    }

    final bannerAd = _adMobService.getBannerAd();

    if (!_isAdLoaded || bannerAd == null) {
      // Show shimmer loading placeholder
      if (widget.showShimmer) {
        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryMedium,
            border: Border(
              top: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryMedium,
                    AppColors.primaryLight.withValues(alpha: 0.5),
                    AppColors.primaryMedium,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(-1.0 - 2 * _shimmerController.value, 0),
                  end: Alignment(1.0 - 2 * _shimmerController.value, 0),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.ad_units_rounded,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading Ad...',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms);
      } else {
        return const SizedBox.shrink();
      }
    }

    // Show actual ad
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        border: Border(
          top: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Native ad widget with custom styling
class AdMobNativeAd extends ConsumerStatefulWidget {
  const AdMobNativeAd({
    super.key,
    this.height = 250,
    this.padding = const EdgeInsets.all(16),
  });
  final double height;
  final EdgeInsets padding;

  @override
  ConsumerState<AdMobNativeAd> createState() => _AdMobNativeAdState();
}

class _AdMobNativeAdState extends ConsumerState<AdMobNativeAd> {
  final AdMobService _adMobService = AdMobService();
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _adMobService.loadNativeAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);

    // Don't show ads for premium users
    if (subscriptionService.isSubscribed) {
      return const SizedBox.shrink();
    }

    final nativeAd = _adMobService.getNativeAd();

    if (!_isAdLoaded || nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AdWidget(ad: nativeAd),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }
}
