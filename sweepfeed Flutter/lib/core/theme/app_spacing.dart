/// Defines consistent spacing values for the app to eliminate magic numbers
/// and ensure a cohesive visual rhythm across all screens.
class AppSpacing {
  // Prevent instantiation
  const AppSpacing._();

  // Base spacing unit (8.0) - follows Material Design 8dp grid
  static const double _unit = 8.0;

  // Micro spacing for tight layouts
  static const double xs = _unit * 0.5; // 4.0

  // Small spacing for compact elements
  static const double small = _unit; // 8.0

  // Medium spacing for regular separation
  static const double medium = _unit * 2; // 16.0

  // Large spacing for significant separation
  static const double large = _unit * 3; // 24.0

  // Extra large spacing for major sections
  static const double xlarge = _unit * 4; // 32.0

  // Extra extra large spacing for page-level separation
  static const double xxlarge = _unit * 6; // 48.0

  // Common padding values
  static const double screenPadding =
      large; // 24.0 - Standard screen edge padding
  static const double cardPadding =
      medium; // 16.0 - Standard card content padding
  static const double buttonPadding = medium; // 16.0 - Standard button padding

  // Common margin values
  static const double sectionMargin = large; // 24.0 - Between major sections
  static const double itemMargin = small; // 8.0 - Between list items

  // Border radius values
  static const double radiusSmall = small; // 8.0
  static const double radiusMedium = medium; // 16.0
  static const double radiusLarge = large; // 24.0
}
