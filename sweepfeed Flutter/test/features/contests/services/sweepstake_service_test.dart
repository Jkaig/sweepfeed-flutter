import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:your_app/features/contests/services/sweepstake_service.dart';
import 'package:your_app/core/models/sweepstake.dart'; 
 
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String,dynamic>> {}
class MockDocumentChange extends Mock implements DocumentChange<Map<String,dynamic>>{}
class MockStream extends Mock implements Stream<QuerySnapshot>{}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  late SweepstakeService sweepstakeService;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockQueryDocumentSnapshot mockQueryDocumentSnapshot;
  late MockDocumentSnapshot mockDocumentSnapshot;

  setUp(() {
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

    mockDocumentSnapshot = MockDocumentSnapshot();
    sweepstakeService = SweepstakeService(firestore: mockFirebaseFirestore);

    when(mockFirebaseFirestore.collection(any))
        .thenReturn(mockCollectionReference);
  });

  group('SweepstakeService', () {
    final sweepstakeData = {
      'id': '1',
      'title': 'Test Sweepstake',
      'prize': '\$100',
      'imageUrl': 'test.jpg',
      'entryUrl': 'test.com',
      'rulesUrl': 'test.com',
      'sponsor': 'Test Sponsor',
      'source': 'Test Source',
      'postedDate': '2023-01-01',
      'frequency': 'daily',
      'value': 100,
      'retrievedAt': Timestamp.now(),
      'createdAt': Timestamp.now(),
       'isActive': true,
       'categories': []
    };

     final sweepstake = Sweepstake.fromFirestore(mockQueryDocumentSnapshot);

    test('getPopularSweepstakes returns a list of Sweepstakes', () async{
      when(mockCollectionReference.get())
          .thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.data()).thenReturn(sweepstakeData);
      final result = await sweepstakeService.getPopularSweepstakes();
      expect(result, isA<List<Sweepstake>>());
      expect(result.length, 1);
      expect(result[0].title, sweepstakeData['title']);
      expect(result[0].prize, sweepstakeData['prize']);
       
    });

    test('getDailyChecklistSweepstakes returns a list of Sweepstakes', () async {
       when(mockCollectionReference.get())
          .thenAnswer((_) async => mockQuerySnapshot);
       when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
         when(mockQueryDocumentSnapshot.data()).thenReturn(sweepstakeData);
      

      final result = await sweepstakeService.getDailyChecklistSweepstakes();
      expect(result, isA<List<Sweepstake>>());
      expect(result.length, 1);
      expect(result[0].title, sweepstakeData['title']);
      expect(result[0].prize, sweepstakeData['prize']);
    });

     test('getSweepstakeById returns a Sweepstake', () async {
        final mockDocumentReference = MockDocumentReference();
      when(mockCollectionReference.doc('1')).thenReturn(mockDocumentReference);
      when(mockCollectionReference.doc('1').get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.data()).thenReturn(sweepstakeData);
      when(mockDocumentSnapshot.exists).thenReturn(true);

      final result = await sweepstakeService.getSweepstakeById('1');
      expect(result, isA<Sweepstake>());
       expect(result.title, sweepstakeData['title']);
       expect(result.prize, sweepstakeData['prize']);
       expect(result.imageUrl, sweepstakeData['imageUrl']);
    });
     test('getPopularSweepstakes handles empty data', () async {
    when(mockCollectionReference.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(mockQuerySnapshot.docs).thenReturn([]); 

    final result = await sweepstakeService.getPopularSweepstakes();
    expect(result, isA<List<Sweepstake>>());
    expect(result.length, 0);
  });

  test('getDailyChecklistSweepstakes handles empty data', () async {
    when(mockCollectionReference.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(mockQuerySnapshot.docs).thenReturn([]);

    final result = await sweepstakeService.getDailyChecklistSweepstakes();
    expect(result, isA<List<Sweepstake>>());
    expect(result.length, 0);
  });

  test('getSweepstakeById handles non-existent document', () async {
    final mockDocumentReference = MockDocumentReference();
    when(mockCollectionReference.doc('nonExistentId')).thenReturn(mockDocumentReference);
    when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
    when(mockDocumentSnapshot.exists).thenReturn(false);

    final result = await sweepstakeService.getSweepstakeById('nonExistentId');
    expect(result, isNull);
  });

  test('getPopularSweepstakes throws an error if Firebase returns an error', () async {
    when(mockCollectionReference.get()).thenThrow(Exception('Firebase Error'));

    expect(() async => await sweepstakeService.getPopularSweepstakes(), throwsException);
  });

  test('getDailyChecklistSweepstakes throws an error if Firebase returns an error', () async {
    when(mockCollectionReference.get()).thenThrow(Exception('Firebase Error'));

    expect(() async => await sweepstakeService.getDailyChecklistSweepstakes(), throwsException);
  });
    test('getSweepstakeById throws an error if Firebase returns an error', () async {
      when(mockCollectionReference.doc(any)).thenThrow(Exception('Firebase Error'));

    expect(() async => await sweepstakeService.getSweepstakeById('any'), throwsException);
  });
  });
}