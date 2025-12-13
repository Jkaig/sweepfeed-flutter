import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';

/// Ad banner widget that displays an ad only for free users
/// This is a placeholder that would be replaced with an actual ad network widget
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({
    super.key,
    this.showRemoveButton = true,
    this.height = 60.0,
    this.adType = 'banner',
  });
  final bool showRemoveButton;
  final double height;
  final String? adType;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  bool _isLoading = true;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    setState(() => _isLoading = true);

    // Simulate ad loading
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _adShown = true;
      });
    }
  }

  void _navigateToSubscription() {
    Navigator.of(context).pushNamed('/subscription');
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);

    // Don't show ads for premium users
    if (subscriptionService.isSubscribed) {
      return const SizedBox.shrink();
    }

    // Show ad container
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          : Stack(
              children: [
                // Ad content (placeholder)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ads_click,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Advertisement',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove ads button
                if (widget.showRemoveButton)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: TextButton(
                        onPressed: _navigateToSubscription,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Remove Ads',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// A widget that shows an ad at the bottom of a list
class ListBottomAdBanner extends StatelessWidget {
  const ListBottomAdBanner({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: AdBanner(
          height: 80,
          adType: 'native',
        ),
      );
}

/// A widget that shows an ad between list items
class InlineAdBanner extends StatefulWidget {
  const InlineAdBanner({super.key});

  @override
  State<InlineAdBanner> createState() => _InlineAdBannerState();
}

class _InlineAdBannerState extends State<InlineAdBanner> {
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: const Center(
          child: Text(
            'Advertisement',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
}
