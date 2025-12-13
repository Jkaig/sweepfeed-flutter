import '../../constants/app_constants.dart';
import '../models/contest.dart';
import '../utils/logger.dart';

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(
    List<String> errors, [
    List<String> warnings = const [],
  ]) =>
      ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  @override
  String toString() {
    if (isValid) return 'Valid';
    return 'Invalid: ${errors.join(", ")}${warnings.isNotEmpty ? " | Warnings: ${warnings.join(", ")}" : ""}';
  }
}

class ContestValidator {
  static const int maxTitleLength = ValidationConstants.kMaxTitleLength;
  static const int maxDescriptionLength =
      ValidationConstants.kMaxDescriptionLength;
  static const int maxUrlLength = ValidationConstants.kMaxUrlLength;
  static const int minPrizeValue = ValidationConstants.kMinPrizeValue;
  static const int maxPrizeValue = ValidationConstants.kMaxPrizeValue;

  static ValidationResult validate(Contest contest) {
    final errors = <String>[];
    final warnings = <String>[];

    _validateTitle(contest.title, errors, warnings);
    _validateSponsor(contest.sponsor, errors, warnings);
    _validatePrize(
      contest.prize,
      contest.value?.toString() ?? contest.prizeValue,
      errors,
      warnings,
    );
    if (contest.startDate != null) {
      _validateDates(contest.startDate!, contest.endDate, errors, warnings);
    }
    _validateUrls(contest, errors, warnings);
    if (contest.entryMethods != null) {
      _validateEntryMethods(contest.entryMethods!, errors, warnings);
    }
    _validateEligibility(
      contest.eligibilityAge ?? '',
      contest.eligibilityLocation ?? '',
      errors,
      warnings,
    );

    if (errors.isNotEmpty) {
      logger.w('Contest validation failed: ${errors.join(", ")}');
      return ValidationResult.invalid(errors, warnings);
    }

    if (warnings.isNotEmpty) {
      logger.d('Contest validation warnings: ${warnings.join(", ")}');
    }

    return const ValidationResult(isValid: true);
  }

  static void _validateTitle(
    String title,
    List<String> errors,
    List<String> warnings,
  ) {
    if (title.trim().isEmpty) {
      errors.add('Title cannot be empty');
      return;
    }

    if (title.length > maxTitleLength) {
      errors.add('Title exceeds maximum length of $maxTitleLength characters');
    }

    if (title.length < 5) {
      warnings.add('Title is very short (${title.length} characters)');
    }

    if (_containsSuspiciousContent(title)) {
      warnings.add('Title contains potentially suspicious content');
    }
  }

  static void _validateSponsor(
    String sponsor,
    List<String> errors,
    List<String> warnings,
  ) {
    if (sponsor.trim().isEmpty || sponsor == 'Unknown Sponsor') {
      warnings.add('Sponsor is unknown or empty');
    }

    if (sponsor.length > 100) {
      warnings.add('Sponsor name is unusually long');
    }
  }

  static void _validatePrize(
    String prize,
    String value,
    List<String> errors,
    List<String> warnings,
  ) {
    if (prize.trim().isEmpty || prize == 'Prize TBA') {
      warnings.add('Prize description is missing');
    }

    if (value.trim().isEmpty || value == '0') {
      warnings.add('Prize value is zero or unspecified');
      return;
    }

    final prizeValueMatch = RegExp(r'[\d,]+(?:\.\d+)?').firstMatch(value);
    if (prizeValueMatch != null) {
      final cleanValue = prizeValueMatch.group(0)!.replaceAll(',', '');
      final numericValue = double.tryParse(cleanValue);

      if (numericValue != null) {
        if (numericValue < minPrizeValue) {
          errors.add('Prize value cannot be negative');
        }

        if (numericValue > maxPrizeValue) {
          warnings.add(
            'Prize value exceeds typical maximum (\$${maxPrizeValue.toString()})',
          );
        }

        if (numericValue < 10) {
          warnings.add('Prize value is unusually low');
        }
      }
    } else {
      warnings.add('Prize value format could not be parsed');
    }
  }

  static void _validateDates(
    DateTime startDate,
    DateTime endDate,
    List<String> errors,
    List<String> warnings,
  ) {
    final now = DateTime.now();

    if (endDate.isBefore(startDate)) {
      errors.add('End date cannot be before start date');
      return;
    }

    if (endDate.isBefore(now)) {
      warnings.add('Contest has already ended');
    }

    final duration = endDate.difference(startDate);
    if (duration.inDays > 365) {
      warnings.add('Contest duration exceeds 1 year');
    }

    if (duration.inDays < 1) {
      warnings.add('Contest duration is less than 1 day');
    }

    if (startDate.isAfter(now.add(const Duration(days: 365)))) {
      warnings.add('Contest starts more than 1 year in the future');
    }
  }

  static void _validateUrls(
    Contest contest,
    List<String> errors,
    List<String> warnings,
  ) {
    final urlFields = {
      'entry_url': contest.entryUrl,
      'sponsor_website': contest.sponsorWebsite ?? '',
      'sponsor_logo': contest.sponsorLogoUrl ?? '',
      'prize_image': contest.imageUrl,
      'terms_url': contest.rulesUrl ?? '',
    };

    for (final entry in urlFields.entries) {
      final url = entry.value;
      if (url.isEmpty) {
        if (entry.key == 'entry_url') {
          errors.add('Entry URL is required');
        }
        continue;
      }

      if (url.length > maxUrlLength) {
        errors.add('${entry.key} exceeds maximum URL length');
      }

      if (!_isValidUrl(url)) {
        if (entry.key == 'entry_url' || entry.key == 'terms_url') {
          errors.add('Invalid ${entry.key} format');
        } else {
          warnings.add('${entry.key} may have invalid format');
        }
      }
    }
  }

  static void _validateEntryMethods(
    List<String> entryMethods,
    List<String> errors,
    List<String> warnings,
  ) {
    if (entryMethods.isEmpty) {
      warnings.add('No entry methods specified');
      return;
    }

    if (entryMethods.length > 20) {
      warnings.add('Unusually high number of entry methods');
    }

    for (final method in entryMethods) {
      if (method.trim().isEmpty) {
        warnings.add('Empty entry method found');
      }
    }
  }

  static void _validateEligibility(
    String eligibilityAge,
    String eligibilityLocation,
    List<String> errors,
    List<String> warnings,
  ) {
    if (eligibilityAge.isEmpty || eligibilityAge == '18+') {
      if (eligibilityAge.isEmpty) {
        warnings.add('Age eligibility not specified');
      }
    }

    final ageMatch = RegExp(r'(\d+)').firstMatch(eligibilityAge);
    if (ageMatch != null) {
      final age = int.tryParse(ageMatch.group(1)!);
      if (age != null && (age < 13 || age > 100)) {
        warnings.add('Unusual age requirement: $age');
      }
    }

    if (eligibilityLocation.isEmpty || eligibilityLocation == 'US') {
      if (eligibilityLocation.isEmpty) {
        warnings.add('Location eligibility not specified');
      }
    }
  }

  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  static bool _containsSuspiciousContent(String text) {
    final suspiciousPatterns = [
      RegExp(r'click\s*here', caseSensitive: false),
      RegExp(r'free\s*money', caseSensitive: false),
      RegExp(r'100%\s*guaranteed', caseSensitive: false),
      RegExp(r'act\s*now', caseSensitive: false),
      RegExp(r'limited\s*time\s*only', caseSensitive: false),
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(text));
  }

  static List<Contest> filterValidContests(
    List<Contest> contests, {
    bool includeWarnings = true,
  }) {
    final validContests = <Contest>[];

    for (final contest in contests) {
      final result = validate(contest);

      if (result.isValid) {
        validContests.add(contest);
      } else if (includeWarnings && result.errors.isEmpty) {
        validContests.add(contest);
      }
    }

    logger.d(
      'Filtered ${contests.length} contests to ${validContests.length} valid contests',
    );

    return validContests;
  }
}
