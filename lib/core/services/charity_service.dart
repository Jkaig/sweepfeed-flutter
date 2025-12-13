import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charity_model.dart';
import '../models/donation_model.dart';

class CharityService {
  CharityService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<Charity>> getAvailableCharities() async {
    final snapshot = await _firestore.collection('charities').get();
    return snapshot.docs.map((doc) => Charity.fromFirestore(doc)).toList();
  }

  Future<Charity?> getUserSelectedCharity(String userId) async {
    // Assuming the user's selected charity is stored in the user's document
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final selectedCharityId = userDoc.data()?['selectedCharityId'] as String?;
    if (selectedCharityId != null) {
      final charityDoc =
          await _firestore.collection('charities').doc(selectedCharityId).get();
      if (charityDoc.exists) {
        return Charity.fromFirestore(charityDoc);
      }
    }
    return null;
  }

  Future<void> makeDonation(
      String userId, String charityId, double amount) async {
    await _firestore.collection('donations').add({
      'userId': userId,
      'charityId': charityId,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Donation>> getDonationHistory(String userId) async {
    final snapshot = await _firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Donation(
        id: doc.id,
        userId: data['userId'],
        charityId: data['charityId'],
        amount: data['amount'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    }).toList();
  }
}
