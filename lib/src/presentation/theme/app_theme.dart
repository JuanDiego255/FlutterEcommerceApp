// lib/src/presentation/theme/app_theme.dart
//
// Oscuro Premium — Design tokens + ThemeData
// Generated from the HTML prototype at /Marketplace Redesign.html
// Use Theme.of(context).colorScheme.* and Theme.of(context).extension<AppTokens>()
// instead of hardcoded constants like _kAccent, _kPrimary, _kBg.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// Raw tokens (single source of truth)
// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bg          = Color(0xFF0E0E10);
  static const Color surface     = Color(0xFF17171A);
  static const Color surfaceAlt  = Color(0xFF1F1F23);
  static const Color elevated    = Color(0xFF202024);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textMuted   = Color(0xFFA0A09A);
  static const Color textSubtle  = Color(0xFF6B6B66);
  static const Color onAccent    = Color(0xFF0E0E10);

  // Borders
  static const Color borderSubtle  = Color(0xFF202024);
  static const Color border        = Color(0xFF28282D);
  static const Color borderStrong  = Color(0xFF3A3A40);

  // Accent (gold)
  static const Color accent        = Color(0xFFC9A961);
  static const Color accentHover   = Color(0xFFD4B673);
  static const Color accentPressed = Color(0xFFB89853);

  // Feedback
  static const Color success = Color(0xFF7AAE8C);
  static const Color danger  = Color(0xFFE07A6B);
  static const Color warning = Color(0xFFD4B673);
}

class AppRadius {
  AppRadius._();
  static const double sm   = 4;
  static const double md   = 6;
  static const double lg   = 10;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

// ─────────────────────────────────────────────────────────────
// ThemeExtension — exposes tokens that don't fit ColorScheme
// Access via: Theme.of(context).extension<AppTokens>()!
// ─────────────────────────────────────────────────────────────
class AppTokens extends ThemeExtension<AppTokens> {
  final Color surfaceAlt;
  final Color textMuted;
  final Color textSubtle;
  final Color borderSubtle;
  final Color borderStrong;
  final Color success;
  final Color warning;

  const AppTokens({
    required this.surfaceAlt,
    required this.textMuted,
    required this.textSubtle,
    required this.borderSubtle,
    required this.borderStrong,
    required this.success,
    required this.warning,
  });

  @override
  AppTokens copyWith({
    Color? surfaceAlt,
    Color? textMuted,
    Color? textSubtle,
    Color? borderSubtle,
    Color? borderStrong,
    Color? success,
    Color? warning,
  }) =>
      AppTokens(
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        textMuted: textMuted ?? this.textMuted,
        textSubtle: textSubtle ?? this.textSubtle,
        borderSubtle: borderSubtle ?? this.borderSubtle,
        borderStrong: borderStrong ?? this.borderStrong,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ThemeData
// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32, fontWeight: FontWeight.w500, letterSpacing: -0.64,
        color: AppColors.textPrimary, height: 1.15,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.48,
        color: AppColors.textPrimary, height: 1.2,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.4,
        color: AppColors.textPrimary, height: 1.25,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -0.34,
        color: AppColors.textPrimary, height: 1.3,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.45,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6,
        color: AppColors.textMuted, height: 1.3,
      ),
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.accent,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.bg,
        onBackground: AppColors.textPrimary,
        error: AppColors.danger,
        onError: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      textTheme: textTheme,
      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.textSubtle, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),

      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        modalBarrierColor: Color(0xB3000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 0,
        showDragHandle: true,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accent,
        labelStyle: GoogleFonts.inter(
          color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      extensions: const <ThemeExtension<dynamic>>[
        AppTokens(
          surfaceAlt:   AppColors.surfaceAlt,
          textMuted:    AppColors.textMuted,
          textSubtle:   AppColors.textSubtle,
          borderSubtle: AppColors.borderSubtle,
          borderStrong: AppColors.borderStrong,
          success:      AppColors.success,
          warning:      AppColors.warning,
        ),
      ],
    );
  }
}
