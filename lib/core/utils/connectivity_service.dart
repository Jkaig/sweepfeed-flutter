import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../utils/logger.dart';

/// Service for checking network connectivity
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;
  final _onConnectivityChanged = StreamController<bool>.broadcast();

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _onConnectivityChanged.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);

      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          logger.e('Connectivity error: $error');
        },
      );
    } catch (e) {
      logger.e('Failed to initialize connectivity: $e');
      // Assume connected if we can't check
      _isConnected = true;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    if (wasConnected != _isConnected) {
      logger.i('Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}');
      _onConnectivityChanged.add(_isConnected);
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isConnected;
    } catch (e) {
      logger.e('Failed to check connectivity: $e');
      return true; // Assume connected on error
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _onConnectivityChanged.close();
  }
}

