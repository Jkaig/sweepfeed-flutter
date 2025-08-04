import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String? bio;
  final String? profilePictureUrl;
  final List<String> interests;
  final List<String> favoriteBrands;
  final String? location;
  final String? referralCode;
  final String? referredByCode;
  final int referralCount;
  final int referralPoints;

  UserProfile({
    required this.id,
    required this.name,
    this.bio,
    this.profilePictureUrl,
    this.interests = const [],
    this.favoriteBrands = const [],
    this.location,
    this.referralCode,
    this.referredByCode,
    this.referralCount = 0,
    this.referralPoints = 0,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      bio: data['bio'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      interests: List<String>.from(data['interests'] ?? []),
      favoriteBrands: List<String>.from(data['favoriteBrands'] ?? []),
      location: data['location'] as String?,
      referralCode: data['referralCode'] as String?,
      referredByCode: data['referredByCode'] as String?,
      referralCount: data['referralCount'] as int? ?? 0,
      referralPoints: data['referralPoints'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'profilePictureUrl': profilePictureUrl,
      'interests': interests,
      'favoriteBrands': favoriteBrands,
      'location': location,
      'referralCode': referralCode,
      'referredByCode': referredByCode,
      'referralCount': referralCount,
      'referralPoints': referralPoints,
    };
  }
}
