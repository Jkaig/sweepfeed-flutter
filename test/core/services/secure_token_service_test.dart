import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sweepfeed/core/services/secure_token_service.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  FlutterSecureStorage,
  DocumentReference,
  DocumentSnapshot,
  CollectionReference,
])
import 'secure_token_service_test.mocks.dart';

// Helper function to create a typed 'any' matcher for non-nullable types
T _any<T>({String? named}) => (named != null ? anyNamed(named) : any) as T;

void main() {
  group('SecureTokenService Tests', () {
    late SecureTokenService secureTokenService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockFlutterSecureStorage mockStorage;
    late MockDocumentReference mockDocRef;
    late MockDocumentSnapshot mockDocSnapshot;
    late MockCollectionReference mockCollectionRef;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFlutterSecureStorage();
      mockDocRef = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();
      mockCollectionRef = MockCollectionReference();

      secureTokenService = SecureTokenService();

      // Setup default mocks
      when(mockFirestore.collection('users')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.set(_any<Map<String, dynamic>>())).thenAnswer((_) async {});
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
    });

    group('Input Validation', () {
      test('should reject invalid user IDs - path traversal', () async {
        // Test path traversal attempts
        final invalidUserIds = [
          '../admin',
          './root',
          'user/../admin',
          'user/./secret',
          '',
          'a' * 200, // Too long
          'user@email.com', // Invalid characters
          '123', // Too short
        ];

        for (final userId in invalidUserIds) {
          expect(
            () => secureTokenService.storeSecureToken(
              userId: userId,
              fcmToken:
                  'validToken123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678',
            ),
            throwsA(isA<ArgumentError>()),
            reason: 'Should reject invalid userId: $userId',
          );
        }
      });

      test('should accept valid user IDs', () async {
        final validUserIds = [
          'abcdefghij1234567890', // 20 chars
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890123456789012345678901234567890123456789012345678901234567890', // 128 chars
          'user1234567890123456',
          'FIREBASE_AUTH_UID_123',
        ];

        // Mock successful storage operations
        when(mockStorage.read(key: _any<String>(named: 'key')))
            .thenAnswer((_) async => null);
        when(mockStorage.write(key: _any<String>(named: 'key'), value: _any<String>(named: 'value')))
            .thenAnswer((_) async {});

        for (final userId in validUserIds) {
          // Should not throw for valid user IDs
          expect(
            () => secureTokenService.storeSecureToken(
              userId: userId,
              fcmToken:
                  'validToken123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678',
            ),
            returnsNormally,
            reason: 'Should accept valid userId: $userId',
          );
        }
      });

      test('should reject invalid FCM tokens', () async {
        final invalidTokens = [
          '', // Empty
          'abc', // Too short
          'a' * 200, // Too long but valid chars
          'invalid-chars!@#\$%', // Invalid characters
          'validlength' * 20, // Valid length but wrong pattern
        ];

        for (final token in invalidTokens) {
          expect(
            () => secureTokenService.storeSecureToken(
              userId: 'validUserId1234567890',
              fcmToken: token,
            ),
            throwsA(isA<ArgumentError>()),
            reason: 'Should reject invalid FCM token: $token',
          );
        }
      });

      test('should accept valid FCM tokens', () async {
        final validTokens = [
          // Simulated valid FCM token patterns
          'dGVzdEZjbVRva2VuMTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MA==',
        ];

        // Mock successful operations
        when(mockStorage.read(key: _any<String>(named: 'key')))
            .thenAnswer((_) async => null);
        when(mockStorage.write(key: _any<String>(named: 'key'), value: _any<String>(named: 'value')))
            .thenAnswer((_) async {});

        for (final token in validTokens) {
          expect(
            () => secureTokenService.storeSecureToken(
              userId: 'validUserId1234567890',
              fcmToken: token,
            ),
            returnsNormally,
            reason: 'Should accept valid FCM token',
          );
        }
      });
    });

    group('Encryption Security', () {
      test('should encrypt tokens before storage', () async {
        const userId = 'testUser1234567890123';
        const fcmToken =
            'testFcmToken123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678';

        // Mock encryption key generation
        when(mockStorage.read(key: 'fcm_encryption_key'))
            .thenAnswer((_) async => null);
        when(mockStorage.write(key: _any<String>(named: 'key'), value: _any<String>(named: 'value')))
            .thenAnswer((_) async {});

        final capturedData = <String, dynamic>{};
        when(mockDocRef.set(capturedArg(capturedData)))
            .thenAnswer((_) async {});

        await secureTokenService.storeSecureToken(
          userId: userId,
          fcmToken: fcmToken,
        );

        // Verify token is encrypted (should not match original)
        expect(capturedData.containsKey('encryptedFcmToken'), isTrue);
        expect(capturedData['encryptedFcmToken'], isNot(equals(fcmToken)));
        expect(capturedData.containsKey('fcmTokenHash'), isTrue);
        expect(capturedData.containsKey('encryptionVersion'), isTrue);
        expect(capturedData['encryptionVersion'], equals(1));
        expect(capturedData['tokenSecurityLevel'], equals('aes256'));
      });

      test('should generate unique hashes for different tokens', () async {
        const userId = 'testUser1234567890123';
        const token1 =
            'testFcmToken123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678';
        const token2 =
            'differentToken12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567';

        // Mock storage
        when(mockStorage.read(key: _any<String>(named: 'key')))
            .thenAnswer((_) async => null);
        when(mockStorage.write(key: _any<String>(named: 'key'), value: _any<String>(named: 'value')))
            .thenAnswer((_) async {});

        final capturedData1 = <String, dynamic>{};
        final capturedData2 = <String, dynamic>{};

        when(mockDocRef.set(capturedArg(capturedData1)))
            .thenAnswer((_) async {});

        await secureTokenService.storeSecureToken(
          userId: userId,
          fcmToken: token1,
        );

        when(mockDocRef.set(capturedArg(capturedData2)))
            .thenAnswer((_) async {});

        await secureTokenService.storeSecureToken(
          userId: userId,
          fcmToken: token2,
        );

        // Hashes should be different
        expect(
          capturedData1['fcmTokenHash'],
          isNot(equals(capturedData2['fcmTokenHash'])),
        );
      });
    });

    group('Error Handling', () {
      test('should handle Firestore errors gracefully', () async {
        const userId = 'testUser1234567890123';
        const fcmToken =
            'testFcmToken123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678';

        // Mock storage
        when(mockStorage.read(key: _any<String>(named: 'key')))
            .thenAnswer((_) async => null);
        when(mockStorage.write(key: _any<String>(named: 'key'), value: _any<String>(named: 'value')))
            .thenAnswer((_) async {});

        // Mock Firestore error
        when(mockDocRef.set(_any<Map<String, dynamic>>())).thenThrow(
          FirebaseException(
            plugin: 'firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        expect(
          () => secureTokenService.storeSecureToken(
            userId: userId,
            fcmToken: fcmToken,
          ),
          throwsA(isA<FirebaseException>()),
        );
      });

      test('should handle secure storage errors', () async {
        const userId = 'testUser1234567890123';
        const fcmToken =
            'testFcmToken123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678';

        // Mock secure storage error
        when(mockStorage.read(key: _any<String>(named: 'key')))
            .thenThrow(Exception('Storage error'));

        expect(
          () => secureTokenService.storeSecureToken(
            userId: userId,
            fcmToken: fcmToken,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Token Retrieval', () {
      test('should return null for non-existent tokens', () async {
        const userId = 'testUser1234567890123';

        when(mockDocSnapshot.data()).thenReturn(null);

        final result = await secureTokenService.getSecureToken(userId);
        expect(result, isNull);
      });

      test('should return null for invalid user IDs in retrieval', () async {
        const invalidUserId = '../admin';

        final result = await secureTokenService.getSecureToken(invalidUserId);
        expect(result, isNull);
      });
    });

    group('Migration Functionality', () {
      test('should identify users with plaintext tokens', () async {
        // Mock query results
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnapshot1 = MockDocumentSnapshot();
        final mockDocSnapshot2 = MockDocumentSnapshot();

        when(mockFirestore.collection('users')).thenReturn(mockCollectionRef);
        when(mockCollectionRef.where('fcmToken', isGreaterThan: ''))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs)
            .thenReturn([mockDocSnapshot1 as QueryDocumentSnapshot<Map<String, dynamic>>, mockDocSnapshot2 as QueryDocumentSnapshot<Map<String, dynamic>>]);

        when(mockDocSnapshot1.id).thenReturn('user1');
        when(mockDocSnapshot1.data()).thenReturn({
          'fcmToken':
              'plaintextToken123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678',
        });

        when(mockDocSnapshot2.id).thenReturn('user2');
        when(mockDocSnapshot2.data()).thenReturn({
          'fcmToken':
              'anotherToken1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789',
        });

        // Mock secure storage and Firestore operations for migration
        when(mockStorage.read(key: _any<String>(named: 'key')))
            .thenAnswer((_) async => null);
        when(mockStorage.write(key: _any<String>(named: 'key'), value: _any<String>(named: 'value')))
            .thenAnswer((_) async {});
        when(mockDocRef.set(_any<Map<String, dynamic>>())).thenAnswer((_) async {});
        when(mockDocRef.update(_any<Map<Object, Object?>>())).thenAnswer((_) async {});

        // Should not throw during migration
        expect(
          () => secureTokenService.migrateExistingTokens(),
          returnsNormally,
        );
      });
    });

    group('Security Statistics', () {
      test('should return meaningful security stats', () async {
        // Mock secure tokens query
        final mockSecureSnapshot = MockQuerySnapshot();
        final mockPlaintextSnapshot = MockQuerySnapshot();

        when(mockFirestore.collection('users')).thenReturn(mockCollectionRef);
        when(mockCollectionRef.where('encryptedFcmToken', isGreaterThan: ''))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.where('fcmToken', isGreaterThan: ''))
            .thenReturn(mockCollectionRef);
        when(mockCollectionRef.get())
            .thenAnswer((_) async => mockSecureSnapshot);

        when(mockSecureSnapshot.size).thenReturn(10);
        when(mockPlaintextSnapshot.size).thenReturn(5);

        final stats = await secureTokenService.getSecurityStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('encryptionAlgorithm'), isTrue);
        expect(stats['encryptionAlgorithm'], equals('AES-256-GCM'));
        expect(stats['securityLevel'], equals('high'));
      });
    });
  });
}

// Mock classes for testing
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}
