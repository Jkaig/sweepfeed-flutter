import 'package:flutter/material.dart';

/// Represents the available subscription tiers in the app
enum SubscriptionTier {
  free,
  basic,
  premium,
}

/// Extension with methods to get details about each subscription tier
extension SubscriptionTierExtension on SubscriptionTier {
  String get name {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.premium:
        return 'Premium';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionTier.free:
        return 'Limited access with advertisements';
      case SubscriptionTier.basic:
        return 'Core features without ads';
      case SubscriptionTier.premium:
        return 'All features & priority access';
    }
  }

  String get price {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return '\$4.99/month';
      case SubscriptionTier.premium:
        return '\$9.99/month';
    }
  }

  String get annualPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return '\$49.99/year';
      case SubscriptionTier.premium:
        return '\$99.99/year';
    }
  }

  Color get color {
    switch (this) {
      case SubscriptionTier.free:
        return Colors.grey.shade700;
      case SubscriptionTier.basic:
        return Colors.blue;
      case SubscriptionTier.premium:
        return Colors.purple;
    }
  }

  int get maxSweepstakesPerDay {
    switch (this) {
      case SubscriptionTier.free:
        return 15;
      case SubscriptionTier.basic:
        return 100;
      case SubscriptionTier.premium:
        return -1; // Unlimited
    }
  }

  int get maxSavedSweepstakes {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.basic:
        return 50;
      case SubscriptionTier.premium:
        return -1; // Unlimited
    }
  }

  bool get hasAds {
    switch (this) {
      case SubscriptionTier.free:
        return true;
      case SubscriptionTier.basic:
      case SubscriptionTier.premium:
        return false;
    }
  }

  List<FeatureItem> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          const FeatureItem(
            title: 'Browse up to 15 sweepstakes daily',
            included: true,
          ),
          const FeatureItem(
            title: 'Save up to 5 sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Basic sweepstakes filtering',
            included: true,
          ),
          const FeatureItem(
            title: 'Ad-free experience',
            included: false,
          ),
          const FeatureItem(
            title: 'Advanced filters & sorting',
            included: false,
          ),
          const FeatureItem(
            title: 'Access to high-value sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Early notification for new sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Premium-only sweepstakes',
            included: false,
          ),
        ];
      case SubscriptionTier.basic:
        return [
          const FeatureItem(
            title: 'Browse up to 100 sweepstakes daily',
            included: true,
          ),
          const FeatureItem(
            title: 'Save up to 50 sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Ad-free experience',
            included: true,
          ),
          const FeatureItem(
            title: 'Basic sweepstakes filtering',
            included: true,
          ),
          const FeatureItem(
            title: 'Advanced filters & sorting',
            included: true,
          ),
          const FeatureItem(
            title: 'Access to high-value sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Early notification for new sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Premium-only sweepstakes',
            included: false,
          ),
        ];
      case SubscriptionTier.premium:
        return [
          const FeatureItem(
            title: 'Unlimited sweepstakes browsing',
            included: true,
          ),
          const FeatureItem(
            title: 'Unlimited saved sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Ad-free experience',
            included: true,
          ),
          const FeatureItem(
            title: 'Basic sweepstakes filtering',
            included: true,
          ),
          const FeatureItem(
            title: 'Advanced filters & sorting',
            included: true,
          ),
          const FeatureItem(
            title: 'Access to high-value sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Early notification for new sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Premium-only sweepstakes',
            included: true,
          ),
        ];
    }
  }
}

/// Represents a feature item for display in subscription tiers
class FeatureItem {
  final String title;
  final bool included;
  final String? details;

  const FeatureItem({
    required this.title,
    required this.included,
    this.details,
  });
}