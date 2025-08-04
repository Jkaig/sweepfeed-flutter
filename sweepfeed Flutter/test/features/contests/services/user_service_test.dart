import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sweeps_app/features/contests/services/user_service.dart';
                                                                           
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

class MockUser extends Mock implements User {}

void main() {
  late UserService userService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockUser mockUser;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockUser = MockUser();


    when(mockFirebaseFirestore.collection(any)).thenReturn(mockCollectionReference);
    when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);
    when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);


    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('testUserId');

    userService = UserService();
    userService._auth = mockFirebaseAuth;
    userService._firestore = mockFirebaseFirestore;
  });

  group('UserService', () {
    test('getCurrentUserData returns user data', () async {
       final mockData = {'name': 'Test User', 'isPro': true};
       when(mockDocumentSnapshot.data()).thenReturn(mockData);

      when(mockDocumentSnapshot.exists).thenReturn(true);

      final data = await userService.getCurrentUserData();

      expect(data, mockData);
      verify(mockDocumentReference.get()).called(1);
    });

    test('getCurrentUserData throws exception when user is not authenticated', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      expect(() => userService.getCurrentUserData(), throwsException);
    });

   test('getUserDataStream returns a stream of DocumentSnapshot', () {
      when(mockCollectionReference.snapshots()).thenAnswer((_) => Stream.fromIterable([mockDocumentSnapshot]));

      final stream = userService.getUserDataStream();

      expect(stream, emitsInOrder([mockDocumentSnapshot])); 
      verify(mockCollectionReference.snapshots()).called(1);
    });

     test('getUserDataStream throws an exception when user is not authenticated', () {
          when(mockFirebaseAuth.currentUser).thenReturn(null);

          expect(() => userService.getUserDataStream(), throwsException);
        });

    test('updateUserData updates user data', () async {
      final mockData = {'name': 'Updated User'};

      await userService.updateUserData(mockData);

      verify(mockDocumentReference.update(mockData)).called(1);
    });

     test('updateUserData throws exception when user is not authenticated', () async {
       when(mockFirebaseAuth.currentUser).thenReturn(null);

       expect(() => userService.updateUserData({'name': 'Updated User'}), throwsException);
      });
  });
}