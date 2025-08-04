import 'package:cloud_firestore/cloud_firestore.dart';

class Contest {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime endDate;
  final Map<String, dynamic> source;
  final String prize;
  final String frequency;
  final String eligibility;
  final List<String> categories;
  final List<String> badges;
  final bool isPremium;
  final String? platform;
  final DateTime createdAt;
  final String? sponsor;
  final String? entryMethod;
  final double? prizeValue;
  final bool isHot;

  Contest({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.endDate,
    required this.source,
    required this.prize,
    required this.frequency, // This is used as entryFrequency
    required this.eligibility,
    required this.categories,
    required this.badges,
    this.isPremium = false,
    this.platform,
    required this.createdAt,
    this.sponsor,
    this.entryMethod,
    this.prizeValue,
    this.isHot = false,
  });

  // Factory constructor to create a Contest from Firestore data
  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      endDate: (json['endDate'] as Timestamp).toDate(),
      source: json['source'] as Map<String, dynamic>,
      prize: json['prize'] as String,
      frequency: json['frequency'] as String, // Existing field for entry frequency
      eligibility: json['eligibility'] as String,
      categories: List<String>.from(json['categories'] as List<dynamic>),
      badges: List<String>.from(json['badges'] as List<dynamic>),
      isPremium: json['isPremium'] as bool? ?? false,
      platform: json['platform'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      sponsor: json['sponsor'] as String?,
      entryMethod: json['entryMethod'] as String?,
      prizeValue: (json['prizeValue'] as num?)?.toDouble(),
      isHot: json['isHot'] as bool? ?? false,
    );
  }

  // Method to convert Contest instance to JSON, useful for caching or sending to server
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'endDate': Timestamp.fromDate(endDate),
      'source': source,
      'prize': prize,
      'frequency': frequency, // Existing field for entry frequency
      'eligibility': eligibility,
      'categories': categories,
      'badges': badges,
      'isPremium': isPremium,
      'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
      'sponsor': sponsor,
      'entryMethod': entryMethod,
      'prizeValue': prizeValue,
      'isHot': isHot,
    };
  }

  factory Contest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Ensure 'id' is set from the document ID if not present in data
    data['id'] = doc.id; 
    return Contest.fromJson(data);
  }

  String get prizeFormatted => '\$$prize';
  // Renaming 'frequency' to 'entryFrequency' for clarity in the model, if desired,
  // would be a larger change affecting all usages. For now, we use 'frequency'.
  String get entryFrequency => frequency;

  int get daysLeft => endDate.isAfter(DateTime.now()) ? endDate.difference(DateTime.now()).inDays : 0;
}