enum RecommendationType {
  explicitInterest,
  implicitInterest,
  trending,
  newContent,
  popular,
}

class RecommendationReason {
  RecommendationReason({
    required this.type,
    this.details,
  });

  final RecommendationType type;
  final String? details;

  String get explanation {
    switch (type) {
      case RecommendationType.explicitInterest:
        return "Because you're interested in ${details ?? 'this category'}.";
      case RecommendationType.implicitInterest:
        return 'Based on your activity in ${details ?? 'this category'}.';
      case RecommendationType.trending:
        return 'This contest is currently trending.';
      case RecommendationType.newContent:
        return 'Newly added to SweepFeed.';
      case RecommendationType.popular:
        return 'Popular with other users.';
      default:
        return 'You might like this!';
    }
  }
}
