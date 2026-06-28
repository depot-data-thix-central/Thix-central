import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double sm2 = 12.0;
  static const double md = 16.0;
  static const double md2 = 20.0;
  static const double lg = 24.0;
  static const double lg2 = 28.0;
  static const double xl = 32.0;
  static const double xxl = 32.0;

  // Spec-specific spacing that appears in the brief.
  static const double gridGutter = 14.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  static const double button = 14.0;
  static const double serviceCard = 18.0;
  static const double mainCard = 22.0;
  static const double search = 24.0;
  static const double bottomNav = 30.0;
  static const double qrContainer = 16.0;
}

// =============================================================================
// TEXT STYLE EXTENSIONS
// =============================================================================

/// Extension to add text style utilities to BuildContext
/// Access via context.textStyles
extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Helper methods for common text style modifications
extension TextStyleExtensions on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text normal weight
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Add custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// COLORS
// =============================================================================

class AppColors {
  // Exact palette from the brief.
  static const Color primaryBlue = Color(0xFF003BFF);
  static const Color darkNavy = Color(0xFF02134F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrayBackground = Color(0xFFF5F6FA);
  static const Color textPrimary = Color(0xFF0B1028);
  static const Color textSecondary = Color(0xFF7B8190);
  static const Color cardBorder = Color(0xFFE9ECF3);
  static const Color goldBadge = Color(0xFFF7C948);
  static const Color successGreen = Color(0xFF1BC47D);
  static const Color dangerRed = Color(0xFFFF3B30);

  // THIX ID accents
  static const Color thixCyanGlow = Color(0xFF2EF2FF);
  static const Color thixPurpleGlow = Color(0xFF8B5CFF);

  static const LinearGradient thixIdDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050714),
      Color(0xFF070B1A),
      Color(0xFF0B1028),
    ],
  );

  static const LinearGradient thixIdCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2EF2FF),
      Color(0xFF3A7BFF),
      Color(0xFF8B5CFF),
    ],
  );

  // Accent colors used by service tiles (kept centralized to avoid scattered hex usage).
  static const Color accentPurple = Color(0xFF6D5CFF);
  static const Color accentOrange = Color(0xFFFF9F0A);
  static const Color accentBlue2 = Color(0xFF1C64F2);
  static const Color accentGreen2 = Color(0xFF2AC670);
  static const Color accentBlue3 = Color(0xFF2563EB);

  // THIX Market
  static const Color marketBannerBlue = Color(0xFF0B1B3A);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF02134F),
      Color(0xFF041D73),
    ],
  );

  static const LinearGradient primaryBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF003BFF),
      Color(0xFF2A63FF),
    ],
  );

  static const LinearGradient promoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF02134F),
      Color(0xFF003BFF),
    ],
  );
}

class AppShadows {
  static const BoxShadow main = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static const BoxShadow secondary = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
}

/// Font size constants
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// =============================================================================
// THEMES
// =============================================================================

/// Light theme with modern, neutral aesthetic
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryBlue,
    onPrimary: AppColors.white,
    secondary: AppColors.primaryBlue,
    onSecondary: AppColors.white,
    error: AppColors.dangerRed,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.darkNavy,
    outline: AppColors.cardBorder,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightGrayBackground,
  fontFamily: _sfProFamilyOrFallback(),
  fontFamilyFallback: const ['SF Pro Display', 'Inter', 'Roboto'],
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.darkNavy,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.mainCard),
      side: const BorderSide(color: AppColors.cardBorder, width: 1),
    ),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.cardBorder, thickness: 1),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md2, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.3),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 0, highlightElevation: 0),
  textTheme: _buildTextTheme(Brightness.light),
);

/// Dark theme with good contrast and readability
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryBlue,
    onPrimary: AppColors.white,
    secondary: AppColors.primaryBlue,
    onSecondary: AppColors.white,
    error: AppColors.dangerRed,
    onError: AppColors.white,
    surface: Color(0xFF0B1028),
    onSurface: Color(0xFFF3F4F8),
    outline: Color(0xFF24304F),
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF070B1A),
  fontFamily: _sfProFamilyOrFallback(),
  fontFamilyFallback: const ['SF Pro Display', 'Inter', 'Roboto'],
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFF3F4F8),
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.mainCard),
      side: const BorderSide(color: Color(0xFF24304F), width: 1),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF24304F), thickness: 1),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: const Color(0xFF111A3A),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md2, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: const BorderSide(color: Color(0xFF24304F)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: const BorderSide(color: Color(0xFF24304F)),
    ),
    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.3)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 0, highlightElevation: 0),
  textTheme: _buildTextTheme(Brightness.dark),
);

String? _sfProFamilyOrFallback() {
  // On iOS/macOS, SF Pro is available system-wide. On other platforms it may not.
  // We still set the family to honor the brief whenever possible.
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
    return 'SF Pro Display';
  }
  return GoogleFonts.inter().fontFamily;
}

/// Build text theme using SF Pro Display (system on iOS), with Inter fallback.
TextTheme _buildTextTheme(Brightness brightness) {
  final base = GoogleFonts.interTextTheme();
  const tracking = -0.2;
  return base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(fontSize: 36, fontWeight: FontWeight.w700, height: 42 / 36, letterSpacing: tracking),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: tracking),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: tracking),
    titleLarge: base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: tracking),
    labelSmall: base.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: tracking),
  );
}
