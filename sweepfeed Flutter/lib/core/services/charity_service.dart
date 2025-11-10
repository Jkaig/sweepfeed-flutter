import '../models/charity_model.dart';

class CharityService {
  // In a real app, this would be fetched from a remote server/database.
  static final List<Charity> _charities = [
    const Charity(
      id: 'clean_water_fund',
      name: 'Clean Water Fund',
      description:
          'Dedicated to providing clean and safe water to communities in need.',
      emblemUrl:
          'https://example.com/clean_water_emblem.png', // Placeholder URL
    ),
    const Charity(
      id: 'rainforest_alliance',
      name: 'Rainforest Alliance',
      description:
          'Working to conserve biodiversity and ensure sustainable livelihoods.',
      emblemUrl:
          'https://example.com/rainforest_alliance_emblem.png', // Placeholder URL
    ),
    const Charity(
      id: 'doctors_without_borders',
      name: 'Doctors Without Borders',
      description:
          'Provides humanitarian medical care in conflict zones and countries affected by endemic diseases.',
      emblemUrl: 'https://example.com/msf_emblem.png', // Placeholder URL
    ),
    const Charity(
      id: 'world_wildlife_fund',
      name: 'World Wildlife Fund',
      description:
          'An international non-governmental organization for wilderness preservation and the reduction of human impact on the environment.',
      emblemUrl: 'https://example.com/wwf_emblem.png', // Placeholder URL
    ),
  ];

  Future<List<Charity>> getAvailableCharities() async {
    // Simulate a network call
    await Future.delayed(const Duration(milliseconds: 500));
    return _charities;
  }
}
