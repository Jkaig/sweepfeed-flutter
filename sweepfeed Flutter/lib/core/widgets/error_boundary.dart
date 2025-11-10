import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// A comprehensive error boundary widget that catches and handles errors
/// gracefully while providing fallback UI and error reporting.
class ErrorBoundary extends ConsumerStatefulWidget {
  const ErrorBoundary({
    required this.child,
    super.key,
    this.fallback,
    this.errorMessage,
    this.onError,
    this.showErrorDetails = false,
    this.context = 'Unknown',
  });
  final Widget child;
  final Widget? fallback;
  final String? errorMessage;
  final Function(Object error, StackTrace stackTrace)? onError;
  final bool showErrorDetails;
  final String context;

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Set up error handling
    FlutterError.onError = (details) {
      _handleError(details.exception, details.stack);
    };
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
      _hasError = true;
    });

    // Log the error
    logger.e(
      'Error caught by ErrorBoundary in ${widget.context}',
      error: error,
      stackTrace: stackTrace,
    );

    // Report to analytics
    ref.read(performanceMonitorProvider).recordError(
          error,
          stackTrace,
          context: widget.context,
        );

    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace ?? StackTrace.current);
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildDefaultErrorWidget();
    }

    // Wrap child in ErrorWidget.builder override
    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (error, stackTrace) {
          _handleError(error, stackTrace);
          return widget.fallback ?? _buildDefaultErrorWidget();
        }
      },
    );
  }

  Widget _buildDefaultErrorWidget() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We apologize for the inconvenience. Please try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _resetError,
                  child: const Text('Try Again'),
                ),
                if (widget.showErrorDetails && kDebugMode) ...[
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _showErrorDetails(context),
                    child: const Text('Details'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Context: ${widget.context}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: ${_error.toString()}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              if (_stackTrace != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Stack Trace:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _stackTrace.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Specialized error boundary for async operations
class AsyncErrorBoundary extends ConsumerWidget {
  const AsyncErrorBoundary({
    required this.asyncValue,
    required this.builder,
    super.key,
    this.loadingWidget,
    this.errorWidget,
    this.context = 'AsyncOperation',
  });
  final AsyncValue asyncValue;
  final Widget Function() builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String context;

  @override
  Widget build(BuildContext context, WidgetRef ref) => asyncValue.when(
        data: (_) => ErrorBoundary(
          context: this.context,
          child: builder(),
        ),
        loading: () => loadingWidget ?? const CircularProgressIndicator(),
        error: (error, stackTrace) {
          // Log async error
          logger.e(
            'Async error in ${this.context}',
            error: error,
            stackTrace: stackTrace,
          );

          return errorWidget ?? _buildAsyncErrorWidget(error, stackTrace);
        },
      );

  Widget _buildAsyncErrorWidget(Object error, StackTrace? stackTrace) =>
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Colors.orange.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Trigger retry by invalidating the provider
                // This would need to be implemented based on the specific provider
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

/// Network-specific error boundary
class NetworkErrorBoundary extends StatelessWidget {
  const NetworkErrorBoundary({
    required this.child,
    super.key,
    this.onRetry,
  });
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ErrorBoundary(
        context: 'Network',
        fallback: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Connection Problem',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
        child: child,
      );
}

/// Provider for performance monitoring
final performanceMonitorProvider =
    Provider<PerformanceMonitor>((ref) => PerformanceMonitor());

/// Performance monitor for error tracking
class PerformanceMonitor {
  final List<ErrorReport> _errorReports = [];

  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    final report = ErrorReport(
      error: error,
      stackTrace: stackTrace,
      context: context ?? 'Unknown',
      timestamp: DateTime.now(),
    );

    _errorReports.add(report);

    // Keep only last 100 errors
    if (_errorReports.length > 100) {
      _errorReports.removeAt(0);
    }

    // Report to crash analytics service if available
    _reportToCrashlytics(report);
  }

  void _reportToCrashlytics(ErrorReport report) {
    // Implementation would depend on crash reporting service
    // e.g., Firebase Crashlytics, Sentry, etc.
    logger.e(
      'Error reported to crashlytics: ${report.context}',
      error: report.error,
      stackTrace: report.stackTrace,
    );
  }

  List<ErrorReport> getRecentErrors([int limit = 20]) {
    final recent = _errorReports.reversed.take(limit).toList();
    return recent;
  }

  int getErrorCount([Duration? period]) {
    if (period == null) return _errorReports.length;

    final cutoff = DateTime.now().subtract(period);
    return _errorReports
        .where((report) => report.timestamp.isAfter(cutoff))
        .length;
  }

  void clearErrors() {
    _errorReports.clear();
  }
}

/// Error report data structure
class ErrorReport {
  ErrorReport({
    required this.error,
    required this.context,
    required this.timestamp,
    this.stackTrace,
  });
  final Object error;
  final StackTrace? stackTrace;
  final String context;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'error': error.toString(),
        'stackTrace': stackTrace?.toString(),
        'context': context,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Global error handler setup
class GlobalErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (details) {
      logger.e(
        'Flutter Error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    // Handle async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.e(
        'Platform Error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }
}

/// Utility widget for consistent error display
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    required this.title,
    required this.message,
    super.key,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
  });
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: iconColor ?? Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      );
}
