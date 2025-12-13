import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/logger.dart';

/// Service for automated encryption key rotation
/// Provides enhanced security for sensitive notification data
class KeyRotationService {
  KeyRotationService._internal();
  static const String _keyPrefix = 'notification_key_';
  static const String _currentKeyId = 'current_key_id';
  static const String _keyMetadataCollection = 'key_metadata';
  static const Duration _defaultRotationInterval = Duration(days: 30);
  static const int _keyRetentionDays = 90;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final KeyRotationService _instance = KeyRotationService._internal();
  static KeyRotationService get instance => _instance;

  Timer? _rotationTimer;
  bool _initialized = false;

  /// Initialize the key rotation service
  Future<void> initialize({Duration? rotationInterval}) async {
    if (_initialized) return;

    try {
      // Ensure we have a current key
      await _ensureCurrentKey();

      // Setup automatic rotation
      _setupAutomaticRotation(rotationInterval ?? _defaultRotationInterval);

      // Clean up old keys
      await _cleanupOldKeys();

      _initialized = true;
      logger.i('Key rotation service initialized');
    } catch (e) {
      logger.e('Error initializing key rotation service', error: e);
      rethrow;
    }
  }

  /// Generate a new encryption key and rotate to it
  Future<String> rotateKey({String? reason}) async {
    try {
      logger.i('Starting key rotation. Reason: ${reason ?? 'scheduled'}');

      // Generate new key
      final newKeyId = _generateKeyId();
      final newKey = _generateEncryptionKey();

      // Store new key securely
      await _secureStorage.write(
        key: '$_keyPrefix$newKeyId',
        value: base64Encode(newKey),
      );

      // Update current key ID
      await _secureStorage.write(key: _currentKeyId, value: newKeyId);

      // Store key metadata
      await _storeKeyMetadata(newKeyId, reason);

      // Log rotation event
      await _logKeyRotation(newKeyId, reason);

      logger.i('Key rotation completed. New key ID: $newKeyId');
      return newKeyId;
    } catch (e) {
      logger.e('Error during key rotation', error: e);
      rethrow;
    }
  }

  /// Get the current encryption key
  Future<Uint8List> getCurrentKey() async {
    try {
      final keyId = await getCurrentKeyId();
      if (keyId == null) {
        // No current key, generate one
        await rotateKey(reason: 'initial_setup');
        return getCurrentKey();
      }

      final keyString = await _secureStorage.read(key: '$_keyPrefix$keyId');
      if (keyString == null) {
        throw Exception('Current key not found in secure storage');
      }

      return base64Decode(keyString);
    } catch (e) {
      logger.e('Error getting current key', error: e);
      rethrow;
    }
  }

  /// Get the current key ID
  Future<String?> getCurrentKeyId() async {
    try {
      return await _secureStorage.read(key: _currentKeyId);
    } catch (e) {
      logger.e('Error getting current key ID', error: e);
      return null;
    }
  }

  /// Get a specific key by ID (for decryption of old data)
  Future<Uint8List?> getKeyById(String keyId) async {
    try {
      final keyString = await _secureStorage.read(key: '$_keyPrefix$keyId');
      if (keyString == null) {
        logger.w('Key not found: $keyId');
        return null;
      }

      return base64Decode(keyString);
    } catch (e) {
      logger.e('Error getting key by ID: $keyId', error: e);
      return null;
    }
  }

  /// Encrypt data with the current key
  Future<EncryptedData> encryptData(String data) async {
    try {
      final key = await getCurrentKey();
      final keyId = await getCurrentKeyId();

      if (keyId == null) {
        throw Exception('No current key available');
      }

      // Generate random IV
      final iv = _generateIV();

      // Encrypt data (simplified - in production use proper AES encryption)
      final dataBytes = utf8.encode(data);
      final encryptedBytes = _simpleEncrypt(dataBytes, key, iv);

      return EncryptedData(
        keyId: keyId,
        iv: base64Encode(iv),
        data: base64Encode(encryptedBytes),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      logger.e('Error encrypting data', error: e);
      rethrow;
    }
  }

  /// Decrypt data using the specified key
  Future<String> decryptData(EncryptedData encryptedData) async {
    try {
      final key = await getKeyById(encryptedData.keyId);
      if (key == null) {
        throw Exception('Decryption key not found: ${encryptedData.keyId}');
      }

      final iv = base64Decode(encryptedData.iv);
      final encryptedBytes = base64Decode(encryptedData.data);

      // Decrypt data (simplified - in production use proper AES decryption)
      final decryptedBytes = _simpleDecrypt(encryptedBytes, key, iv);

      return utf8.decode(decryptedBytes);
    } catch (e) {
      logger.e('Error decrypting data', error: e);
      rethrow;
    }
  }

  /// Force immediate key rotation
  Future<String> forceRotation({required String reason}) async =>
      rotateKey(reason: 'forced_$reason');

  /// Get key rotation history
  Future<List<KeyMetadata>> getRotationHistory({int limit = 10}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_keyMetadataCollection)
          .orderBy('rotationTime', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => KeyMetadata.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      logger.e('Error getting rotation history', error: e);
      return [];
    }
  }

  /// Check if key rotation is due
  Future<bool> isRotationDue() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final keyId = await getCurrentKeyId();
      if (keyId == null) return true;

      final metadataDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_keyMetadataCollection)
          .doc(keyId)
          .get();

      if (!metadataDoc.exists) return true;

      final metadata = KeyMetadata.fromFirestore(metadataDoc.data()!);
      final daysSinceRotation =
          DateTime.now().difference(metadata.rotationTime).inDays;

      return daysSinceRotation >= _defaultRotationInterval.inDays;
    } catch (e) {
      logger.e('Error checking if rotation is due', error: e);
      return false;
    }
  }

  /// Get key statistics
  Future<KeyRotationStats> getStats() async {
    try {
      final history = await getRotationHistory(limit: 100);
      final currentKeyId = await getCurrentKeyId();
      final isRotationDue = await this.isRotationDue();

      return KeyRotationStats(
        currentKeyId: currentKeyId,
        totalRotations: history.length,
        lastRotationTime:
            history.isNotEmpty ? history.first.rotationTime : null,
        isRotationDue: isRotationDue,
        averageRotationInterval: _calculateAverageInterval(history),
        rotationReasons: _categorizeRotationReasons(history),
      );
    } catch (e) {
      logger.e('Error getting key rotation stats', error: e);
      return const KeyRotationStats(
        currentKeyId: null,
        totalRotations: 0,
        lastRotationTime: null,
        isRotationDue: true,
        averageRotationInterval: Duration.zero,
        rotationReasons: {},
      );
    }
  }

  // Private methods
  Future<void> _ensureCurrentKey() async {
    final keyId = await getCurrentKeyId();
    if (keyId == null) {
      await rotateKey(reason: 'initial_setup');
    }
  }

  void _setupAutomaticRotation(Duration interval) {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      try {
        if (await isRotationDue()) {
          await rotateKey(reason: 'scheduled');
        }
      } catch (e) {
        logger.e('Error in automatic rotation check', error: e);
      }
    });
  }

  Future<void> _cleanupOldKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final cutoffDate =
          DateTime.now().subtract(const Duration(days: _keyRetentionDays));

      for (final entry in allKeys.entries) {
        if (entry.key.startsWith(_keyPrefix)) {
          final keyId = entry.key.substring(_keyPrefix.length);
          final metadata = await _getKeyMetadata(keyId);

          if (metadata != null && metadata.rotationTime.isBefore(cutoffDate)) {
            await _secureStorage.delete(key: entry.key);
            await _deleteKeyMetadata(keyId);
            logger.i('Cleaned up old key: $keyId');
          }
        }
      }
    } catch (e) {
      logger.e('Error cleaning up old keys', error: e);
    }
  }

  String _generateKeyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000).toString().padLeft(3, '0');
    return 'key_${timestamp}_$random';
  }

  Uint8List _generateEncryptionKey() {
    final random = Random.secure();
    final key = Uint8List(32); // 256-bit key
    for (var i = 0; i < key.length; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  Uint8List _generateIV() {
    final random = Random.secure();
    final iv = Uint8List(16); // 128-bit IV
    for (var i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  // Simplified encryption/decryption (use proper AES in production)
  Uint8List _simpleEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final result = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    return result;
  }

  Uint8List _simpleDecrypt(
    Uint8List encryptedData,
    Uint8List key,
    Uint8List iv,
  ) {
    return _simpleEncrypt(encryptedData, key, iv); // XOR is symmetric
  }

  Future<void> _storeKeyMetadata(String keyId, String? reason) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final metadata = KeyMetadata(
        keyId: keyId,
        rotationTime: DateTime.now(),
        reason: reason ?? 'unknown',
        userId: userId,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_keyMetadataCollection)
          .doc(keyId)
          .set(metadata.toFirestore());
    } catch (e) {
      logger.e('Error storing key metadata', error: e);
    }
  }

  Future<KeyMetadata?> _getKeyMetadata(String keyId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_keyMetadataCollection)
          .doc(keyId)
          .get();

      if (!doc.exists) return null;

      return KeyMetadata.fromFirestore(doc.data()!);
    } catch (e) {
      logger.e('Error getting key metadata', error: e);
      return null;
    }
  }

  Future<void> _deleteKeyMetadata(String keyId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_keyMetadataCollection)
          .doc(keyId)
          .delete();
    } catch (e) {
      logger.e('Error deleting key metadata', error: e);
    }
  }

  Future<void> _logKeyRotation(String keyId, String? reason) async {
    try {
      await _firestore.collection('security_audit_log').add({
        'event': 'key_rotation',
        'keyId': keyId,
        'reason': reason ?? 'unknown',
        'userId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': 'mobile',
          'app': 'sweepfeed',
        },
      });
    } catch (e) {
      logger.e('Error logging key rotation', error: e);
    }
  }

  Duration _calculateAverageInterval(List<KeyMetadata> history) {
    if (history.length < 2) return Duration.zero;

    var totalDays = 0;
    for (var i = 0; i < history.length - 1; i++) {
      totalDays += history[i]
          .rotationTime
          .difference(history[i + 1].rotationTime)
          .inDays;
    }

    return Duration(days: totalDays ~/ (history.length - 1));
  }

  Map<String, int> _categorizeRotationReasons(List<KeyMetadata> history) {
    final reasons = <String, int>{};
    for (final metadata in history) {
      reasons[metadata.reason] = (reasons[metadata.reason] ?? 0) + 1;
    }
    return reasons;
  }

  /// Dispose of the service
  void dispose() {
    _rotationTimer?.cancel();
    _initialized = false;
  }
}

/// Data model for encrypted data
class EncryptedData {
  const EncryptedData({
    required this.keyId,
    required this.iv,
    required this.data,
    required this.timestamp,
  });

  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
        keyId: json['keyId'],
        iv: json['iv'],
        data: json['data'],
        timestamp: DateTime.parse(json['timestamp']),
      );
  final String keyId;
  final String iv;
  final String data;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'keyId': keyId,
        'iv': iv,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Data model for key metadata
class KeyMetadata {
  const KeyMetadata({
    required this.keyId,
    required this.rotationTime,
    required this.reason,
    required this.userId,
  });

  factory KeyMetadata.fromFirestore(Map<String, dynamic> data) => KeyMetadata(
        keyId: data['keyId'],
        rotationTime: (data['rotationTime'] as Timestamp).toDate(),
        reason: data['reason'],
        userId: data['userId'],
      );
  final String keyId;
  final DateTime rotationTime;
  final String reason;
  final String userId;

  Map<String, dynamic> toFirestore() => {
        'keyId': keyId,
        'rotationTime': Timestamp.fromDate(rotationTime),
        'reason': reason,
        'userId': userId,
      };
}

/// Data model for key rotation statistics
class KeyRotationStats {
  const KeyRotationStats({
    required this.currentKeyId,
    required this.totalRotations,
    required this.lastRotationTime,
    required this.isRotationDue,
    required this.averageRotationInterval,
    required this.rotationReasons,
  });
  final String? currentKeyId;
  final int totalRotations;
  final DateTime? lastRotationTime;
  final bool isRotationDue;
  final Duration averageRotationInterval;
  final Map<String, int> rotationReasons;
}

/// Global instance
final keyRotationService = KeyRotationService.instance;
