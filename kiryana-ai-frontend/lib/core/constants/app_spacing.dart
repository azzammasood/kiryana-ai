/// KiryanaAI Spacing System
/// Use these constants everywhere — never raw pixel values for spacing.
abstract class AppSpacing {
  // Base unit: 4px
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Page padding
  static const double pagePadding = 24.0;
  static const double pagePaddingSmall = 16.0;

  // Card padding
  static const double cardPadding = 20.0;
  static const double cardPaddingSmall = 12.0;

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Max content width for web/desktop
  static const double maxContentWidth = 480.0;
  static const double maxTabletWidth = 720.0;
}
