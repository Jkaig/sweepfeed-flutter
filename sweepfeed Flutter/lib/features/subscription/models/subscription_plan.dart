enum SubscriptionTier {
  free,
  basic,
  premium,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String duration;
  final SubscriptionTier tier;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.tier,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      duration: json['duration'],
      tier: SubscriptionTier.values.firstWhere(
          (e) => e.toString() == 'SubscriptionTier.${json['tier']}'),
    );
  }
}
