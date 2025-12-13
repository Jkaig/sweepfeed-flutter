import 'package:cloud_firestore/cloud_firestore.dart';

class Brand {
  Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.website,
    this.description,
    this.contestCount = 0,
    this.createdAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json, [String? providedId]) =>
      Brand(
        id: providedId ?? json['id'] ?? '',
        name: json['name'] ?? json['sponsor'] ?? '',
        logoUrl: json['logoUrl'] ?? json['logo_url'] ?? json['image_url'],
        website: json['website'] ?? json['sponsorWebsite'],
        description: json['description'],
        contestCount: json['contestCount'] ?? json['contest_count'] ?? 0,
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] is Timestamp
                ? (json['createdAt'] as Timestamp).toDate()
                : DateTime.parse(json['createdAt']))
            : null,
      );

  factory Brand.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Brand.fromJson(data, doc.id);
  }
  final String id;
  final String name;
  final String? logoUrl;
  final String? website;
  final String? description;
  final int contestCount;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'website': website,
        'description': description,
        'contestCount': contestCount,
        'createdAt': createdAt?.toIso8601String(),
      };

  Brand copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? website,
    String? description,
    int? contestCount,
    DateTime? createdAt,
  }) =>
      Brand(
        id: id ?? this.id,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        website: website ?? this.website,
        description: description ?? this.description,
        contestCount: contestCount ?? this.contestCount,
        createdAt: createdAt ?? this.createdAt,
      );
}
