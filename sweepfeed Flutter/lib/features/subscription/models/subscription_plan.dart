import 'package:in_app_purchase/in_app_purchase.dart';
import './subscription_tiers.dart';

class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.duration,
    required this.tier,
    this.productDetails,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: json['price'],
        rawPrice: json['rawPrice'],
        currencyCode: json['currencyCode'],
        duration: json['duration'],
        tier: SubscriptionTier.values.firstWhere(
          (e) => e.toString() == 'SubscriptionTier.${json['tier']}',
        ),
      );
  final String id;
  final String name;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  final String duration;
  final SubscriptionTier tier;
  final ProductDetails? productDetails;
}
