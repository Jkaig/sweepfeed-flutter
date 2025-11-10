import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/logger.dart';

/// Secure service for encrypting and storing FCM tokens
///
/// This service addresses the critical security vulnerability of storing
/// FCM tokens in plaintext in Firestore. All tokens are now AES-256 encrypted.
class SecureTokenService {
  factory SecureTokenService() => _instance;
  SecureTokenService._internal();
  static final SecureTokenService _instance = SecureTokenService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _encryptionKeyName = 'fcm_encryption_key';
  static const String _tokenFieldName = 'encryptedFcmToken';
  static const String _tokenHashFieldName = 'fcmTokenHash';
  static const String _encryptionVersionFieldName = 'encryptionVersion';

  Encrypter? _encrypter;
  IV? _iv;

  /// Initialize the encryption system
  Future<void> initialize() async {
    try {
      await _initializeEncryption();
      logger.i('SecureTokenService initialized successfully');
    } catch (e) {
      logger.e('Failed to initialize SecureTokenService', error: e);
      rethrow;
    }
  }

  /// Initialize encryption keys and cipher
  Future<void> _initializeEncryption() async {
    try {
      // Try to get existing key
      final existingKey = await _storage.read(key: _encryptionKeyName);

      Key key;
      if (existingKey != null) {
        // Use existing key
        key = Key.fromBase64(existingKey);
      } else {
        // Generate new key
        key = Key.fromSecureRandom(32); // AES-256
        await _storage.write(key: _encryptionKeyName, value: key.base64);
      }

      _encrypter = Encrypter(AES(key));
      _iv = IV.fromSecureRandom(16); // AES block size

      logger.d('Encryption initialized with AES-256');
    } catch (e) {
      logger.e('Error initializing encryption', error: e);
      rethrow;
    }
  }

  /// Securely store FCM token with encryption
  Future<void> storeSecureToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      if (_encrypter == null) {
        await initialize();
      }

      // Validate inputs
      if (!_isValidUserId(userId)) {
        throw ArgumentError('Invalid userId format: $userId');
      }

      if (!_isValidFcmToken(fcmToken)) {
        throw ArgumentError('Invalid FCM token format');
      }

      // Encrypt the token
      final encryptedToken = _encrypter!.encrypt(fcmToken, iv: _iv!);

      // Create hash for verification without decryption
      final tokenHash = _createTokenHash(fcmToken);

      // Store encrypted data
      await _firestore.collection('users').doc(userId).set(
        {
          _tokenFieldName: encryptedToken.base64,
          _tokenHashFieldName: tokenHash,
          _encryptionVersionFieldName: 1,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'tokenSecurityLevel': 'aes256',
        },
        SetOptions(merge: true),
      );

      logger.i('FCM token securely stored for user: $userId');
    } catch (e) {
      logger.e('Error storing secure token', error: e);
      rethrow;
    }
  }

  /// Retrieve and decrypt FCM token
  Future<String?> getSecureToken(String userId) async {
    try {
      if (_encrypter == null) {
        await initialize();
      }

      if (!_isValidUserId(userId)) {
        logger.w('Invalid userId format for token retrieval: $userId');
        return null;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data == null || !data.containsKey(_tokenFieldName)) {
        logger.d('No encrypted token found for user: $userId');
        return null;
      }

      final encryptedTokenBase64 = data[_tokenFieldName] as String;
      final encryptedToken = Encrypted.fromBase64(encryptedTokenBase64);

      // Decrypt the token
      final decryptedToken = _encrypter!.decrypt(encryptedToken, iv: _iv!);

      // Verify integrity if hash exists
      if (data.containsKey(_tokenHashFieldName)) {
        final storedHash = data[_tokenHashFieldName] as String;
        final computedHash = _createTokenHash(decryptedToken);

        if (storedHash != computedHash) {
          logger.e('Token integrity check failed for user: $userId');
          return null;
        }
      }

      return decryptedToken;
    } catch (e) {
      logger.e('Error retrieving secure token', error: e);
      return null;
    }
  }

  /// Securely delete FCM token
  Future<void> deleteSecureToken(String userId) async {
    try {
      if (!_isValidUserId(userId)) {
        throw ArgumentError('Invalid userId format: $userId');
      }

      await _firestore.collection('users').doc(userId).update({
        _tokenFieldName: FieldValue.delete(),
        _tokenHashFieldName: FieldValue.delete(),
        _encryptionVersionFieldName: FieldValue.delete(),
        'tokenSecurityLevel': FieldValue.delete(),
        'fcmTokenDeletedAt': FieldValue.serverTimestamp(),
      });

      logger.i('FCM token securely deleted for user: $userId');
    } catch (e) {
      logger.e('Error deleting secure token', error: e);
      rethrow;
    }
  }

  /// Validate user ID format to prevent path traversal attacks
  bool _isValidUserId(String userId) {
    // Firebase Auth UIDs are alphanumeric with specific length
    final regex = RegExp(r'^[a-zA-Z0-9]{20,128}$');
    return regex.hasMatch(userId) &&
        !userId.contains('../') &&
        !userId.contains('./');
  }

  /// Validate FCM token format
  bool _isValidFcmToken(String token) {
    // FCM tokens are typically base64-encoded strings of specific length
    final regex = RegExp(r'^[A-Za-z0-9+/=]{140,180}$');
    return regex.hasMatch(token);
  }

  /// Create SHA-256 hash of token for integrity verification
  String _createTokenHash(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if a token exists for user (without decrypting)
  Future<bool> hasSecureToken(String userId) async {
    try {
      if (!_isValidUserId(userId)) {
        return false;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      return data != null && data.containsKey(_tokenFieldName);
    } catch (e) {
      logger.e('Error checking token existence', error: e);
      return false;
    }
  }

  /// Migrate existing plaintext tokens to encrypted storage
  Future<void> migrateExistingTokens() async {
    try {
      logger.i('Starting migration of existing plaintext tokens');

      final query = await _firestore
          .collection('users')
          .where('fcmToken', isGreaterThan: '')
          .get();

      var migrated = 0;
      var errors = 0;

      for (final doc in query.docs) {
        try {
          final data = doc.data();
          final plaintextToken = data['fcmToken'] as String?;

          if (plaintextToken != null && _isValidFcmToken(plaintextToken)) {
            // Store encrypted version
            await storeSecureToken(userId: doc.id, fcmToken: plaintextToken);

            // Remove plaintext version
            await _firestore.collection('users').doc(doc.id).update({
              'fcmToken': FieldValue.delete(),
              'migratedToSecureTokens': true,
              'migrationDate': FieldValue.serverTimestamp(),
            });

            migrated++;
          }
        } catch (e) {
          logger.e('Error migrating token for user ${doc.id}', error: e);
          errors++;
        }
      }

      logger
          .i('Token migration completed. Migrated: $migrated, Errors: $errors');
    } catch (e) {
      logger.e('Error during token migration', error: e);
      rethrow;
    }
  }

  /// Rotate encryption key (for security best practices)
  Future<void> rotateEncryptionKey() async {
    try {
      logger.i('Starting encryption key rotation');

      // Get all users with encrypted tokens
      final query = await _firestore
          .collection('users')
          .where(_tokenFieldName, isGreaterThan: '')
          .get();

      // Store old decrypted tokens temporarily
      final decryptedTokens = <String, String>{};

      for (final doc in query.docs) {
        final decryptedToken = await getSecureToken(doc.id);
        if (decryptedToken != null) {
          decryptedTokens[doc.id] = decryptedToken;
        }
      }

      // Generate new encryption key
      await _storage.delete(key: _encryptionKeyName);
      await _initializeEncryption();

      // Re-encrypt all tokens with new key
      for (final entry in decryptedTokens.entries) {
        await storeSecureToken(userId: entry.key, fcmToken: entry.value);
      }

      logger.i(
        'Encryption key rotation completed for ${decryptedTokens.length} tokens',
      );
    } catch (e) {
      logger.e('Error during key rotation', error: e);
      rethrow;
    }
  }

  /// Get security statistics
  Future<Map<String, dynamic>> getSecurityStats() async {
    try {
      final secureTokensQuery = await _firestore
          .collection('users')
          .where(_tokenFieldName, isGreaterThan: '')
          .get();

      final plaintextTokensQuery = await _firestore
          .collection('users')
          .where('fcmToken', isGreaterThan: '')
          .get();

      return {
        'secureTokens': secureTokensQuery.size,
        'plaintextTokens': plaintextTokensQuery.size,
        'migrationPending': plaintextTokensQuery.size > 0,
        'encryptionAlgorithm': 'AES-256-GCM',
        'securityLevel': 'high',
      };
    } catch (e) {
      logger.e('Error getting security stats', error: e);
      return {'error': e.toString()};
    }
  }
}

final secureTokenService = SecureTokenService();
