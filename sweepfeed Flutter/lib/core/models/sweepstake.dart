import 'package:cloud_firestore/cloud_firestore.dart';

class Sweepstakes {
  Sweepstakes({
    required this.id,
    required this.title,
    required this.description,
    required this.prize,
    required this.imageUrl,
    required this.entryUrl,
    required this.rulesUrl,
    required this.sponsor,
    required this.source,
    required this.postedDate,
    required this.frequency,
    required this.value,
    required this.retrievedAt,
    required this.createdAt,
    this.sponsorWebsite,
    this.endDate,
    this.isActive = true,
    this.brandImageUrl,
    this.categories = const [],
    this.isDailyEntry = false,
  });

  factory Sweepstakes.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Sweepstakes(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      prize: data['prize'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      entryUrl: data['entryUrl'] ?? '',
      rulesUrl: data['rulesUrl'] ?? '',
      sponsor: data['sponsor'] ?? '',
      sponsorWebsite: data['sponsorWebsite'] ?? '',
      source: data['source'] ?? '',
      postedDate: data['postedDate'] ?? '',
      frequency: data['frequency'] ?? '',
      value: data['value'] ?? 0,
      retrievedAt: data['retrievedAt'].toDate(),
      createdAt: data['createdAt'].toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      categories: List<String>.from(data['categories'] ?? []),
      brandImageUrl: data['brandImageUrl'],
      isDailyEntry: data['isDailyEntry'] ?? false,
    );
  }
  final String id;
  final String title;
  final String description;
  final String prize;
  final String imageUrl;
  final String entryUrl;
  final String rulesUrl;
  final String sponsor;
  final String? sponsorWebsite;
  final String source;
  final String postedDate;
  final String frequency;
  final int value;
  final DateTime retrievedAt;
  final DateTime createdAt;
  final DateTime? endDate;
  final bool isActive;
  final List<String> categories;
  final String? brandImageUrl;
  final bool isDailyEntry;

  String get formattedPrizeValue => '\$${value.toString()}';

  String get frequencyText => frequency;

  int get daysRemaining {
    if (endDate == null) {
      return 0;
    }
    return endDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'description': description,
        'prize': prize,
        'imageUrl': imageUrl,
        'entryUrl': entryUrl,
        'rulesUrl': rulesUrl,
        'sponsor': sponsor,
        'sponsorWebsite': sponsorWebsite,
        'source': source,
        'postedDate': postedDate,
        'frequency': frequency,
        'value': value,
        'retrievedAt': Timestamp.fromDate(retrievedAt),
        'createdAt': Timestamp.fromDate(createdAt),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'isActive': isActive,
        'categories': categories,
        'brandImageUrl': brandImageUrl,
        'isDailyEntry': isDailyEntry,
      };
}
