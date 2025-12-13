import 'package:flutter/services.dart';

/// A service to manage iOS Live Activities.
///
/// This service communicates with the native iOS code to start, update,
/// and end Live Activities for contest countdowns.
class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('live_activity_service');

  /// Starts a Live Activity for the given contest.
  Future<void> startLiveActivity(String contestId, String contestName) async {
    try {
      await _channel.invokeMethod('startLiveActivity', {
        'contestId': contestId,
        'contestName': contestName,
      });
    } on PlatformException {
      // Handle error
    }
  }

  /// Ends the Live Activity for the given contest ID.
  Future<void> endLiveActivity(String contestId) async {
    try {
      await _channel.invokeMethod('endLiveActivity', {'contestId': contestId});
    } on PlatformException {
      // Handle error
    }
  }
}
