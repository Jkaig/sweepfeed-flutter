/// Custom exceptions for onboarding flow
abstract class OnboardingException implements Exception {
  const OnboardingException(this.message);

  final String message;

  @override
  String toString() => 'OnboardingException: $message';
}

/// Thrown when network operations fail during onboarding
class NetworkException extends OnboardingException {
  const NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when authentication operations fail during onboarding
class AuthenticationException extends OnboardingException {
  const AuthenticationException(super.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Thrown when permission requests fail during onboarding
class PermissionException extends OnboardingException {
  const PermissionException(super.message);

  @override
  String toString() => 'PermissionException: $message';
}

/// Thrown when data validation fails during onboarding
class ValidationException extends OnboardingException {
  const ValidationException(super.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Thrown when data storage operations fail during onboarding
class StorageException extends OnboardingException {
  const StorageException(super.message);

  @override
  String toString() => 'StorageException: $message';
}

/// Thrown when onboarding configuration is invalid
class ConfigurationException extends OnboardingException {
  const ConfigurationException(super.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Utility methods for converting common errors to onboarding exceptions
class OnboardingExceptionHelper {
  /// Convert Firebase exceptions to onboarding exceptions
  static OnboardingException fromFirebaseException(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('unavailable') ||
        errorString.contains('timeout')) {
      return const NetworkException(
          'Network connection failed. Please check your internet connection.');
    }

    if (errorString.contains('unauthenticated') ||
        errorString.contains('permission-denied') ||
        errorString.contains('auth')) {
      return const AuthenticationException(
          'Authentication failed. Please try logging in again.');
    }

    if (errorString.contains('permission') || errorString.contains('denied')) {
      return const PermissionException(
          'Permission denied. Please ensure you have the necessary permissions.');
    }

    if (errorString.contains('invalid') || errorString.contains('malformed')) {
      return const ValidationException(
          'Invalid data provided. Please check your input.');
    }

    // Default to storage exception for unknown Firebase errors
    return const StorageException('Failed to save data. Please try again.');
  }

  /// Convert general exceptions to onboarding exceptions
  static OnboardingException fromException(dynamic error) {
    if (error is OnboardingException) {
      return error;
    }

    return fromFirebaseException(error);
  }
}
