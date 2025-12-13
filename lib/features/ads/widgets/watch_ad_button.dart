import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/theme/app_colors.dart';

class WatchAdButton extends ConsumerStatefulWidget {
  const WatchAdButton({
    super.key,
    this.label = 'Watch Ad to Donate',
    this.icon = Icons.play_circle_filled,
  });

  final String label;
  final IconData icon;

  @override
  ConsumerState<WatchAdButton> createState() => _WatchAdButtonState();
}

class _WatchAdButtonState extends ConsumerState<WatchAdButton> {
  final RewardedAdService _rewardedAdService = RewardedAdService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    await _rewardedAdService.loadRewardedAd();
  }

  Future<void> _showAd() async {
    final user = ref.read(firebaseServiceProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to watch ads and donate.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check limits
      final canShow = await _rewardedAdService.canShowAd(user.uid);
      if (!canShow) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily ad limit reached. Come back tomorrow!')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final adShown = await _rewardedAdService.showRewardedAd(
        userId: user.uid,
      );

      if (mounted) {
        if (adShown) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you! Donation processed to charity.'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          // Stats are refreshed automatically in the service
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load ad. Please try again later.')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
      onPressed: _isLoading ? null : _showAd,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(widget.icon),
      label: Text(_isLoading ? 'Loading...' : widget.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.successGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
}

