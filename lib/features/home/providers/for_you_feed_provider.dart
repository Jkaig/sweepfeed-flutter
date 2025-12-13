import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final forYouFeedProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('contests')
        .orderBy('createdAt', descending: true)
        .limit(15)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  } catch (error) {
    throw Exception('Failed to load personalized feed: $error');
  }
});
