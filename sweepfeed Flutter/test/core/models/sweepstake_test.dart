import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:sweeps_app/core/models/sweepstake.dart';
import 'package:sweeps_app/core/utils/constants.dart';

void main() {
  group('Sweepstake', () {
    late FakeFirebaseFirestore firestore;
    test('fromFirestore should correctly map data to a Sweepstake object', () {
      final firestore = FakeFirebaseFirestore();
      final docId = 'test-sweepstake-id';
      final data = {
        'id': docId,
        'title': 'Test Sweepstake',
        'prize': '\$100 Gift Card',
        'imageUrl': 'http://example.com/image.jpg',
        'entryUrl': 'http://example.com/enter',
        'rulesUrl': 'http://example.com/rules',
        'sponsor': 'Test Sponsor',
        'sponsorWebsite': 'http://testsponsor.com',
        'source': 'Test Source',
        'postedDate': '2023-01-01',
        'frequency': 'daily',
        'value': 100,
        'retrievedAt': Timestamp.fromDate(DateTime(2023, 1, 2)),
        'createdAt': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'endDate': Timestamp.fromDate(DateTime(2023, 1, 31)),
        'isActive': true,
        'categories': ['category1', 'category2'],
      };
      final docRef = firestore.collection(AppConstants.sweepstakesCollection).doc(docId);
      
      docRef.set(data);
      final doc = docRef.get();

      final sweepstake = Sweepstake.fromFirestore(doc as DocumentSnapshot);

      expect(sweepstake.id, docId);
      expect(sweepstake.title, 'Test Sweepstake');
      expect(sweepstake.prize, '\$100 Gift Card');
      expect(sweepstake.imageUrl, 'http://example.com/image.jpg');
      expect(sweepstake.entryUrl, 'http://example.com/enter');
      expect(sweepstake.rulesUrl, 'http://example.com/rules');
      expect(sweepstake.sponsor, 'Test Sponsor');
      expect(sweepstake.sponsorWebsite, 'http://testsponsor.com');
      expect(sweepstake.source, 'Test Source');
      expect(sweepstake.postedDate, '2023-01-01');
      expect(sweepstake.frequency, 'daily');
      expect(sweepstake.value, 100);
      expect(sweepstake.retrievedAt, DateTime(2023, 1, 2));
      expect(sweepstake.createdAt, DateTime(2023, 1, 1));
      expect(sweepstake.endDate, DateTime(2023, 1, 31));
      expect(sweepstake.isActive, true);
      expect(sweepstake.categories, ['category1', 'category2']);
    });

    test('fromFirestore should handle null values', () {
      final firestore = FakeFirebaseFirestore();
      final docId = 'test-sweepstake-id';
      final data = {
        'id': docId, 
        'title': 'Test Sweepstake',
        'prize': '\$100 Gift Card',
        'imageUrl': 'http://example.com/image.jpg',
        'entryUrl': 'http://example.com/enter',
        'rulesUrl': 'http://example.com/rules',
          'retrievedAt': Timestamp.fromDate(DateTime(2023, 1, 2)),
        'createdAt': Timestamp.fromDate(DateTime(2023, 1, 1)),
      };
       final docRef = firestore.collection(AppConstants.sweepstakesCollection).doc(docId);
       docRef.set(data);
       final doc = docRef.get();
      
      final sweepstake = Sweepstake.fromFirestore(doc as DocumentSnapshot);

      expect(sweepstake.sponsor, '');
      expect(sweepstake.sponsorWebsite, '');
      expect(sweepstake.source, '');
      expect(sweepstake.postedDate, '');
      expect(sweepstake.frequency, '');
      expect(sweepstake.value, 0);
      expect(sweepstake.endDate, null);
      expect(sweepstake.isActive, true);
      expect(sweepstake.categories, []);
    });

    test('toFirestore should correctly map Sweepstake object to Firestore data', () async {
      // Arrange
        final firestore = FakeFirebaseFirestore();
      final sweepstake = Sweepstake(
        id: 'test-sweepstake-id',
        title: 'Test Sweepstake',
        prize: '\$100 Gift Card',
        imageUrl: 'http://example.com/image.jpg',
        entryUrl: 'http://example.com/enter',
        rulesUrl: 'http://example.com/rules',
        sponsor: 'Test Sponsor',
        sponsorWebsite: 'http://testsponsor.com',
        source: 'Test Source',
        postedDate: '2023-01-01',
        frequency: 'daily',
        value: 100,
        retrievedAt: DateTime(2023, 1, 2),
        createdAt: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 31),
        isActive: true,
        categories: ['category1', 'category2'],
      );

      // Act
      final firestoreData = sweepstake.toFirestore();
      await firestore.collection(AppConstants.sweepstakesCollection).doc(sweepstake.id).set(firestoreData);

      // Assert
      final docSnapshot = await firestore.collection(AppConstants.sweepstakesCollection).doc(sweepstake.id).get();
      final docData = docSnapshot.data()!;

      expect(docData['title'], 'Test Sweepstake');
      expect(docData['prize'], '\$100 Gift Card');
       expect(docData['imageUrl'], 'http://example.com/image.jpg');
      expect(docData['entryUrl'], 'http://example.com/enter');
       expect(docData['rulesUrl'], 'http://example.com/rules');
    });
  });
}