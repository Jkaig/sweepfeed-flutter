import 'package:flutter/material.dart';

/// Helper class for responsive design across iPhone, Android, and iPad
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Breakpoints for different device types
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if device is a phone
  static bool isPhone(BuildContext context) => MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if device is a tablet (iPad, Android tablet)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is desktop/large tablet
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    if (isTablet(context)) {
      return 48;
    } else if (isDesktop(context)) {
      return 64;
    }
    return 16;
  }

  /// Get responsive card width (for iPad grid layouts)
  static double getCardWidth(BuildContext context, {int columns = 2}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = getHorizontalPadding(context) * 2;
    final spacing = (columns - 1) * 16.0;
    return (screenWidth - padding - spacing) / columns;
  }

  /// Get responsive font scale
  static double getFontScale(BuildContext context) {
    if (isTablet(context)) {
      return 1.1;
    } else if (isDesktop(context)) {
      return 1.2;
    }
    return 1.0;
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    if (isTablet(context)) {
      return baseSize * 1.2;
    } else if (isDesktop(context)) {
      return baseSize * 1.4;
    }
    return baseSize;
  }

  /// Get responsive grid columns for lists
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 3;
    }
    return 1;
  }

  /// Get max content width (for centered layouts on tablets/desktop)
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200;
    } else if (isTablet(context)) {
      return 900;
    }
    return double.infinity;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) => MediaQuery.of(context).orientation == Orientation.landscape;

  /// Get responsive spacing multiplier
  static double getSpacingMultiplier(BuildContext context) {
    if (isTablet(context)) {
      return 1.25;
    } else if (isDesktop(context)) {
      return 1.5;
    }
    return 1.0;
  }
}

/// Responsive widget builder for different device types
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.phone,
    this.tablet,
    this.desktop,
    super.key,
  });
  final Widget Function(BuildContext) phone;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet!(context);
    }
    return phone(context);
  }
}

/// Responsive value selector
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.phone,
    this.tablet,
    this.desktop,
  });
  final T phone;
  final T? tablet;
  final T? desktop;

  T getValue(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return phone;
  }
}

