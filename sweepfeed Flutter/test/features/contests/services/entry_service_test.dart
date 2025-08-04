import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sweestakes/features/contests/services/entry_service.dart';

// Import the EntryService class you want to test
// import 'package:your_app/features/contests/services/entry_service.dart';

// Mock Firestore
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  group('EntryService', () {
    late MockFirebaseFirestore mockFirestore;
    late EntryService entryService; // Create an instance of your EntryService

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      entryService = EntryService(firestore: mockFirestore); // Initialize your EntryService with the mock Firestore
    });

    // Test cases for EntryService methods go here

    test('addEntry adds an entry to Firestore', () async {
      final mockCollectionReference = MockCollectionReference();
      final mockDocumentReference = MockDocumentReference();

      when(mockFirestore.collection(any)).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.set(any)).thenAnswer((_) async {});

      await entryService.addEntry('contestId', 'userId');

      verify(mockFirestore.collection('entries')).called(1);
      verify(mockCollectionReference.doc('contestId_userId')).called(1);
      verify(mockDocumentReference.set({'contestId': 'contestId', 'userId': 'userId'})).called(1);
    });

    test('getEntryCount returns the correct entry count', () async {
      final mockCollectionReference = MockCollectionReference();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockQuery = MockQuery();
      
      when(mockFirestore.collection(any)).thenReturn(mockCollectionReference);
      when(mockCollectionReference.where(any, isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([MockDocumentSnapshot(), MockDocumentSnapshot(), MockDocumentSnapshot()]);

      final entryCount = await entryService.getEntryCount('contestId');

      expect(entryCount, 3);
      verify(mockCollectionReference.where('contestId', isEqualTo: 'contestId')).called(1);
    });

    test('deleteEntry deletes an entry from Firestore', () async {
      final mockCollectionReference = MockCollectionReference();
      final mockDocumentReference = MockDocumentReference();
      
      when(mockFirestore.collection(any)).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.delete()).thenAnswer((_) async {});

      await entryService.deleteEntry('contestId', 'userId');

      verify(mockCollectionReference.doc('contestId_userId')).called(1);
      verify(mockDocumentReference.delete()).called(1);
    });
  });
}