import 'dart:async';

/// A utility class for debouncing function calls
class Debouncer {
  Debouncer({
    this.duration = const Duration(milliseconds: 300),
  });

  final Duration duration;
  Timer? _timer;

  /// Debounces a function call
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any pending debounced calls
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes the debouncer
  void dispose() {
    cancel();
  }
}

