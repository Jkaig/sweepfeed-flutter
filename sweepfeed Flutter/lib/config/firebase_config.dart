import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class for Firebase platform-specific options.
class FirebaseConfig {
  /// Firebase options configured from environment variables.
  static FirebaseOptions get platformOptions => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      );
}
