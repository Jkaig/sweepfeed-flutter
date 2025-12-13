import '../../../core/models/reward_model.dart';

class RewardService {
  static final List<Reward> allRewards = [
    const Reward(
      id: 'extra_entries_1',
      name: '5 Extra Daily Entries',
      description: 'Get 5 bonus entries every day.',
      points: 500,
    ),
    const Reward(
      id: 'power_user_badge',
      name: 'Power User Badge',
      description: 'Show off your status with a special profile badge.',
      points: 1000,
    ),
  ];

  Future<List<Reward>> getRewards() async {
    // For now, returning the static list.
    // Later, this can be extended to fetch from Firestore
    return allRewards;
  }
}
