import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:your_app/features/contests/services/contest_service.dart'; // Replace with your actual import
import 'package:firebase_auth/firebase_auth.dart';

// Mock Firestore and other dependencies as needed
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockQuery extends Mock implements Query {}

class MockFirebaseAuth extends Mock implements FirebaseAuth{}
void main() {
  late ContestService contestService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockDocumentSnapshot mockDocumentSnapshot;
    late MockFirebaseAuth mockFirebaseAuth;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    mockDocumentSnapshot = MockDocumentSnapshot();
        mockFirebaseAuth = MockFirebaseAuth();
    contestService = ContestService();
    // Initialize your service with the mock Firestore
     contestService.firebaseAuth = mockFirebaseAuth;
    contestService.firestore = mockFirestore;
  });

  group('ContestService', () {
    test('getPopularSweepstakes returns a list of Sweepstake', () async {
      // Arrange
      when(mockFirestore.collection('sweepstakes')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.orderBy('value', descending: true)).thenReturn(mockQuery);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      when(mockQuerySnapshot.docs).thenReturn([
        mockDocumentSnapshot,
        mockDocumentSnapshot,
      ]);

      when(mockDocumentSnapshot.data()).thenReturn({
        'id': '1',
        'title': 'Test Sweepstake 1',
        'prize': '\$100',
        'imageUrl': 'image1.jpg',
        'entryUrl': 'entry1.com',
        'rulesUrl': 'rules1.com',
        'sponsor': 'Test Sponsor 1',
        'source': 'Test Source 1',
        'postedDate': '2024-01-01',
        'frequency': 'Daily',
        'value': 100,
        'retrievedAt': Timestamp.fromDate(DateTime.now()),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Act
      final sweepstakes = await contestService.getPopularSweepstakes();

      // Assert
      expect(sweepstakes.length, 2);
      expect(sweepstakes[0].id, '1');
      expect(sweepstakes[0].title, 'Test Sweepstake 1');
    });

    test('getDailyChecklistSweepstakes returns a list of Sweepstake', () async {
      // Arrange
      when(mockFirestore.collection('sweepstakes')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.where('frequency', isEqualTo: 'Daily')).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      when(mockQuerySnapshot.docs).thenReturn([
        mockDocumentSnapshot,
      ]);

      when(mockDocumentSnapshot.data()).thenReturn({
        'id': '2',
        'title': 'Test Sweepstake 2',
        'prize': '\$200',
        'imageUrl': 'image2.jpg',
        'entryUrl': 'entry2.com',
        'rulesUrl': 'rules2.com',
        'sponsor': 'Test Sponsor 2',
        'source': 'Test Source 2',
        'postedDate': '2024-01-01',
        'frequency': 'Daily',
        'value': 200,
        'retrievedAt': Timestamp.fromDate(DateTime.now()),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Act
      final sweepstakes = await contestService.getDailyChecklistSweepstakes();

      // Assert
      expect(sweepstakes.length, 1);
      expect(sweepstakes[0].id, '2');
      expect(sweepstakes[0].title, 'Test Sweepstake 2');
    });

    test('getUserEntryStats returns a map with entry data', () async {
      // Arrange
      final expectedTodayCount = 5;
      final expectedStreakTarget = 10;
      
      // Simulate getting user data
      final mockUserData = {'dailyEntries': expectedTodayCount};
      when(mockFirebaseAuth.currentUser).thenReturn(MockUser(uid: 'testUserId'));
      when(mockFirestore.collection('users')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('testUserId')).thenReturn(MockDocumentReference());
      when(mockFirestore.collection('users').doc('testUserId').get()).thenAnswer((_) async => mockDocumentSnapshot);
       when(mockDocumentSnapshot.data()).thenReturn(mockUserData);

      // Act
      final stats = await contestService.getUserEntryStats();

      // Assert
      expect(stats['todayCount'], expectedTodayCount);
      expect(stats['streakTarget'], expectedStreakTarget);
    });

    // ... Add more tests for other methods ...
  });
}