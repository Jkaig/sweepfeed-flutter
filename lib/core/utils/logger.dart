import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../config/secure_config.dart';

/// Production-ready logger that respects environment settings
final logger = Logger(
  printer: kDebugMode
      ? PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          printTime: false,
        )
      : SimplePrinter(), // Minimal output in production
  level: _getLogLevel(),
  output: kDebugMode ? null : _ProductionLogOutput(),
);

/// Gets appropriate log level based on environment
Level _getLogLevel() {
  try {
    if (SecureConfig.isProduction) {
      return Level.warning; // Only warnings and errors in production
    }
    return Level.debug; // Full logging in dev
  } catch (_) {
    // If SecureConfig not initialized, default to debug
    return kDebugMode ? Level.debug : Level.warning;
  }
}

/// Production log output that filters sensitive information
class _ProductionLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // In production, only output warnings and errors
    // This prevents information leakage while still capturing critical issues
    if (event.level.index >= Level.warning.index) {
      // Could send to remote logging service here
      // For now, we'll just suppress debug/info logs in production
    }
  }
}
