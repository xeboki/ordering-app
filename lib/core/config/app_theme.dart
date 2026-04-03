import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand_config.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build({required BrandColors colors, required BrandTypography typo, bool dark = false}) {
    final colorScheme = dark
        ? _darkScheme(colors)
        : _lightScheme(colors);

    final textTheme = _buildTextTheme(typo, colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? colorScheme.surfaceContainerHighest : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.8,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        backgroundColor: colorScheme.inverseSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        dividerColor: colorScheme.outlineVariant,
      ),
    );
  }

  // ── Color schemes ───────────────────────────────────────────────────────────

  static ColorScheme _lightScheme(BrandColors c) => ColorScheme(
        brightness: Brightness.light,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.secondary,
        onSecondary: c.onSecondary,
        error: c.error,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.onSurface,
        surfaceContainerHighest: const Color(0xFFF3F4F6),
        onSurfaceVariant: const Color(0xFF6B7280),
        outline: const Color(0xFFD1D5DB),
        outlineVariant: const Color(0xFFE5E7EB),
        inverseSurface: const Color(0xFF1F2937),
        onInverseSurface: Colors.white,
        inversePrimary: c.primary.withValues(alpha: 0.7),
        shadow: Colors.black.withValues(alpha: 0.08),
        scrim: Colors.black.withValues(alpha: 0.4),
        surfaceTint: c.primary.withValues(alpha: 0.05),
      );

  static ColorScheme _darkScheme(BrandColors c) => ColorScheme(
        brightness: Brightness.dark,
        primary: c.primary.withValues(alpha: 0.9),
        onPrimary: c.onPrimary,
        secondary: c.secondary,
        onSecondary: c.onSecondary,
        error: c.error,
        onError: Colors.white,
        surface: const Color(0xFF111827),
        onSurface: const Color(0xFFF9FAFB),
        surfaceContainerHighest: const Color(0xFF1F2937),
        onSurfaceVariant: const Color(0xFF9CA3AF),
        outline: const Color(0xFF374151),
        outlineVariant: const Color(0xFF1F2937),
        inverseSurface: const Color(0xFFF9FAFB),
        onInverseSurface: const Color(0xFF111827),
        inversePrimary: c.primary.withValues(alpha: 0.7),
        shadow: Colors.black.withValues(alpha: 0.3),
        scrim: Colors.black.withValues(alpha: 0.6),
        surfaceTint: c.primary.withValues(alpha: 0.08),
      );

  // ── Text theme ──────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(BrandTypography typo, Color color) {
    TextTheme base;
    try {
      base = GoogleFonts.getTextTheme(typo.fontFamily);
    } catch (_) {
      base = GoogleFonts.interTextTheme();
    }
    return base.apply(bodyColor: color, displayColor: color);
  }
}
