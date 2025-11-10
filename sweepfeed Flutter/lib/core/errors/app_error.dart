import 'package:flutter/material.dart';

/// Categories of errors that can occur in the app
enum ErrorCategory {
  network, // Network connectivity issues, timeouts
  authentication, // Invalid credentials, session expired
  validation, // Invalid input data, data format errors
  payment, // Payment processing failures
  server, // Server-side errors (500, 503, etc.)
  firestore, // Firestore-specific errors
  storage, // Storage quota exceeded, upload failures
  permission, // Missing permissions, access denied
  unknown, // Catch-all for unexpected errors
}

/// Custom exception class for application errors
class AppError implements Exception {
  final String message;
  final ErrorCategory category;
  final dynamic rawError;
  final StackTrace? stackTrace;
  final String? context; // Additional context about where error occurred

  const AppError({
    required this.message,
    required this.category,
    this.rawError,
    this.stackTrace,
    this.context,
  });

  /// Creates an AppError from a generic exception
  factory AppError.fromException(
    dynamic error, {
    String? context,
    String? customMessage,
  }) {
    if (error is AppError) return error;

    final message = customMessage ?? _getMessageFromError(error);
    final category = _getCategoryFromError(error);

    return AppError(
      message: message,
      category: category,
      rawError: error,
      context: context,
    );
  }

  /// Gets user-friendly message based on error type
  static String _getMessageFromError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check your access rights.';
    }
    if (errorString.contains('quota') || errorString.contains('limit')) {
      return 'Service limit reached. Please try again later.';
    }
    if (errorString.contains('invalid') || errorString.contains('format')) {
      return 'Invalid data format. Please check your input.';
    }
    if (errorString.contains('not found')) {
      return 'Requested resource not found.';
    }
    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'Access denied. Please sign in again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Categorizes error based on error type
  static ErrorCategory _getCategoryFromError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return ErrorCategory.network;
    }
    if (errorString.contains('auth') ||
        errorString.contains('credential') ||
        errorString.contains('token') ||
        errorString.contains('unauthorized')) {
      return ErrorCategory.authentication;
    }
    if (errorString.contains('invalid') ||
        errorString.contains('format') ||
        errorString.contains('validation')) {
      return ErrorCategory.validation;
    }
    if (errorString.contains('payment') ||
        errorString.contains('billing') ||
        errorString.contains('subscription')) {
      return ErrorCategory.payment;
    }
    if (errorString.contains('firestore') || errorString.contains('firebase')) {
      return ErrorCategory.firestore;
    }
    if (errorString.contains('storage') || errorString.contains('quota')) {
      return ErrorCategory.storage;
    }
    if (errorString.contains('permission') || errorString.contains('access')) {
      return ErrorCategory.permission;
    }

    return ErrorCategory.unknown;
  }

  @override
  String toString() {
    return 'AppError: {Message: $message, Category: $category, Context: $context, RawError: $rawError}';
  }
}

/// Utility class for error handling operations
class ErrorHandler {
  /// Shows user-friendly error message via SnackBar
  static void showError(BuildContext context, AppError error) {
    if (!context.mounted) return;

    final backgroundColor = _getColorForCategory(error.category);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        action: error.category == ErrorCategory.network
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  // Could trigger a retry callback if provided
                },
              )
            : null,
      ),
    );
  }

  /// Gets appropriate color for error category
  static Color _getColorForCategory(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return Colors.orange;
      case ErrorCategory.authentication:
        return Colors.red;
      case ErrorCategory.validation:
        return Colors.amber;
      case ErrorCategory.payment:
        return Colors.red.shade700;
      case ErrorCategory.server:
      case ErrorCategory.firestore:
      case ErrorCategory.storage:
        return Colors.red.shade600;
      case ErrorCategory.permission:
        return Colors.red.shade800;
      case ErrorCategory.unknown:
        return Colors.grey.shade700;
    }
  }

  /// Determines if an error is retryable
  static bool isRetryable(AppError error) {
    switch (error.category) {
      case ErrorCategory.network:
      case ErrorCategory.server:
      case ErrorCategory.firestore:
        return true;
      case ErrorCategory.authentication:
      case ErrorCategory.validation:
      case ErrorCategory.payment:
      case ErrorCategory.storage:
      case ErrorCategory.permission:
      case ErrorCategory.unknown:
        return false;
    }
  }

  /// Gets recovery suggestions for different error types
  static String getRecoverySuggestion(AppError error) {
    switch (error.category) {
      case ErrorCategory.network:
        return 'Check your internet connection and try again.';
      case ErrorCategory.authentication:
        return 'Please sign in again to continue.';
      case ErrorCategory.validation:
        return 'Please check your input and correct any errors.';
      case ErrorCategory.payment:
        return 'Please check your payment method or contact support.';
      case ErrorCategory.server:
      case ErrorCategory.firestore:
        return 'Our servers are experiencing issues. Please try again later.';
      case ErrorCategory.storage:
        return 'Storage limit reached. Please free up space or upgrade your plan.';
      case ErrorCategory.permission:
        return 'You don\'t have permission for this action. Contact support if needed.';
      case ErrorCategory.unknown:
        return 'An unexpected error occurred. Please contact support if this persists.';
    }
  }
}

/// Custom exceptions for specific error scenarios
class NetworkError extends AppError {
  const NetworkError(String message, {dynamic rawError, String? context})
      : super(
          message: message,
          category: ErrorCategory.network,
          rawError: rawError,
          context: context,
        );
}

class AuthenticationError extends AppError {
  const AuthenticationError(String message, {dynamic rawError, String? context})
      : super(
          message: message,
          category: ErrorCategory.authentication,
          rawError: rawError,
          context: context,
        );
}

class ValidationError extends AppError {
  const ValidationError(String message, {dynamic rawError, String? context})
      : super(
          message: message,
          category: ErrorCategory.validation,
          rawError: rawError,
          context: context,
        );
}

class PaymentError extends AppError {
  const PaymentError(String message, {dynamic rawError, String? context})
      : super(
          message: message,
          category: ErrorCategory.payment,
          rawError: rawError,
          context: context,
        );
}

class FirestoreError extends AppError {
  const FirestoreError(String message, {dynamic rawError, String? context})
      : super(
          message: message,
          category: ErrorCategory.firestore,
          rawError: rawError,
          context: context,
        );
}
