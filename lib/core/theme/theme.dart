import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Badar Tyres design system — "Traction Industrial".
///
/// A high-performance dark theme engineered for the automotive service
/// industry. Hierarchy is built through tonal layering (color luminosity)
/// rather than shadows, anchored by a "Garage Charcoal" surface and bold,
/// high-visibility red accents.
///
/// Source of truth: `needs/DESIGN.md`.

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

/// Raw color tokens from the design spec. Prefer reading colors from
/// `Theme.of(context).colorScheme` in widgets; use these only when a token
/// has no direct ColorScheme slot (e.g. tonal elevation surfaces).
abstract final class AppColors {
  const AppColors._();

  // Surfaces / backgrounds (tonal elevation ladder).
  static const Color surface = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceVariant = Color(0xFF353534);
  static const Color background = Color(0xFF131313);

  // Content colors.
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFE0BFBC);
  static const Color onBackground = Color(0xFFE5E2E1);
  static const Color inverseSurface = Color(0xFFE5E2E1);
  static const Color inverseOnSurface = Color(0xFF313030);

  // Outlines.
  static const Color outline = Color(0xFFA78A88);
  static const Color outlineVariant = Color(0xFF59413F);

  // Primary (industrial red).
  static const Color primary = Color(0xFFFFB3AE);
  static const Color onPrimary = Color(0xFF68000D);
  static const Color primaryContainer = Color(0xFFC94242);
  static const Color onPrimaryContainer = Color(0xFFFFF6F5);
  static const Color inversePrimary = Color(0xFFAE2F31);
  static const Color surfaceTint = Color(0xFFFFB3AE);

  // Secondary.
  static const Color secondary = Color(0xFFC8C6C6);
  static const Color onSecondary = Color(0xFF303030);
  static const Color secondaryContainer = Color(0xFF474747);
  static const Color onSecondaryContainer = Color(0xFFB6B5B4);

  // Tertiary.
  static const Color tertiary = Color(0xFFC8C6C6);
  static const Color onTertiary = Color(0xFF303030);
  static const Color tertiaryContainer = Color(0xFF727272);
  static const Color onTertiaryContainer = Color(0xFFFAF8F7);

  // Error.
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Fixed tones.
  static const Color primaryFixed = Color(0xFFFFDAD7);
  static const Color primaryFixedDim = Color(0xFFFFB3AE);
  static const Color onPrimaryFixed = Color(0xFF410005);
  static const Color onPrimaryFixedVariant = Color(0xFF8D141C);
  static const Color secondaryFixed = Color(0xFFE4E2E1);
  static const Color secondaryFixedDim = Color(0xFFC8C6C6);
  static const Color onSecondaryFixed = Color(0xFF1B1C1C);
  static const Color onSecondaryFixedVariant = Color(0xFF474747);
  static const Color tertiaryFixed = Color(0xFFE4E2E2);
  static const Color tertiaryFixedDim = Color(0xFFC8C6C6);
  static const Color onTertiaryFixed = Color(0xFF1B1C1C);
  static const Color onTertiaryFixedVariant = Color(0xFF474747);

  // Convenience semantic aliases used across the app.
  static const Color placeholder = Color(0xFFA0A0A0);

  /// Tonal elevation ladder — depth is communicated by luminosity, not shadow.
  static const Color level0 = surface; // Background.
  static const Color level1 = surfaceContainerHigh; // Cards / inputs.
  static const Color level2 = surfaceBright; // Popups / active states.
}

abstract final class AppLightColors {
  const AppLightColors._();

  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFE9ECEF);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F9FA);
  static const Color surfaceContainer = Color(0xFFF1F3F5);
  static const Color surfaceContainerHigh = Color(0xFFFFFFFF); // White cards
  static const Color surfaceContainerHighest = Color(0xFFDEE2E6);
  static const Color surfaceVariant = Color(0xFFE9ECEF);
  static const Color background = Color(0xFFF8F9FA);

  static const Color onSurface = Color(0xFF212529);
  static const Color onSurfaceVariant = Color(0xFF495057);
  static const Color onBackground = Color(0xFF212529);
  static const Color inverseSurface = Color(0xFF343A40);
  static const Color inverseOnSurface = Color(0xFFF8F9FA);

  static const Color outline = Color(0xFFADB5BD);
  static const Color outlineVariant = Color(0xFFDEE2E6);

  // Red
  static const Color primary = Color(0xFFC94242);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE5484D);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color inversePrimary = Color(0xFFFFB3AE);
  static const Color surfaceTint = Color(0xFFC94242);

  static const Color secondary = Color(0xFF6C757D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDEE2E6);
  static const Color onSecondaryContainer = Color(0xFF343A40);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color placeholder = Color(0xFFADB5BD);
}

/// Semantic status / metric accent colors. These sit outside the core red
/// palette and are used for job statuses and dashboard metric highlights
/// (e.g. "Running" green, "Completed" blue, "Delayed" red).
abstract final class AppStatusColors {
  const AppStatusColors._();

  static const Color total = Color(0xFF7C5CFC); // Total jobs — violet.
  static const Color running = Color(0xFF2FA84F); // In progress — green.
  static const Color completed = Color(0xFF2D7FF9); // Done — blue.
  static const Color delayed = Color(0xFFE5484D); // Behind schedule — red.
  static const Color pending = Color(0xFFF5A623); // Queued — amber.

  /// Soft translucent fill for icon backings / pills over dark surfaces.
  static Color tint(Color c) => c.withValues(alpha: 0.16);
}

// ---------------------------------------------------------------------------
// Spacing (8px base unit)
// ---------------------------------------------------------------------------

abstract final class AppSpacing {
  const AppSpacing._();

  static const double base = 8;
  static const double containerPadding = 20;
  static const double gutter = 12;
  static const double stackSm = 4;
  static const double stackMd = 16;
  static const double stackLg = 32;
}

// ---------------------------------------------------------------------------
// Radii
// ---------------------------------------------------------------------------

abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 4; // 0.25rem
  static const double base = 8; // 0.5rem — buttons, inputs.
  static const double md = 12; // 0.75rem
  static const double lg = 16; // 1rem — cards, job previews.
  static const double xl = 24; // 1.5rem
  static const double full = 9999; // pills, FAB.

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brBase = BorderRadius.all(Radius.circular(base));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}

// ---------------------------------------------------------------------------
// Typography (Hanken Grotesk)
// ---------------------------------------------------------------------------

abstract final class AppTypography {
  const AppTypography._();

  static const double _lh40 = 40 / 32;
  static const double _lh32 = 32 / 24;
  static const double _lh24t = 24 / 18;
  static const double _lh24b = 24 / 16;
  static const double _lh16 = 16 / 12;
  static const double _lh36 = 36 / 28;

  static TextStyle _base(TextStyle style) =>
      GoogleFonts.hankenGrotesk(textStyle: style);

  /// display-lg — 32 / 700, tight tracking. Hero headings.
  static TextStyle get displayLg => _base(const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: _lh40,
        letterSpacing: -0.64, // -0.02em * 32
        color: AppColors.onSurface,
      ));

  /// display-lg-mobile — 28 / 700.
  static TextStyle get displayLgMobile => _base(const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: _lh36,
        color: AppColors.onSurface,
      ));

  /// headline-md — 24 / 600.
  static TextStyle get headlineMd => _base(const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: _lh32,
        color: AppColors.onSurface,
      ));

  /// title-sm — 18 / 600.
  static TextStyle get titleSm => _base(const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: _lh24t,
        color: AppColors.onSurface,
      ));

  /// body-md — 16 / 400, generous line height for readability.
  static TextStyle get bodyMd => _base(const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: _lh24b,
        color: AppColors.onSurface,
      ));

  /// label-sm — 12 / 500, wide tracking. Uppercase metadata / categories.
  static TextStyle get labelSm => _base(const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: _lh16,
        letterSpacing: 0.6, // 0.05em * 12
        color: AppColors.onSurfaceVariant,
      ));

  /// Maps the design tokens onto Flutter's [TextTheme] slots.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLg,
        displayMedium: displayLg,
        displaySmall: headlineMd,
        headlineLarge: headlineMd,
        headlineMedium: headlineMd,
        headlineSmall: titleSm,
        titleLarge: titleSm,
        titleMedium: titleSm,
        titleSmall: titleSm.copyWith(fontSize: 16),
        bodyLarge: bodyMd,
        bodyMedium: bodyMd,
        bodySmall: bodyMd.copyWith(fontSize: 14, height: 20 / 14),
        labelLarge: labelSm.copyWith(fontSize: 14, color: AppColors.onSurface),
        labelMedium: labelSm,
        labelSmall: labelSm,
      );
}

// ---------------------------------------------------------------------------
// ColorScheme
// ---------------------------------------------------------------------------

const ColorScheme _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  primaryFixed: AppColors.primaryFixed,
  primaryFixedDim: AppColors.primaryFixedDim,
  onPrimaryFixed: AppColors.onPrimaryFixed,
  onPrimaryFixedVariant: AppColors.onPrimaryFixedVariant,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,
  secondaryFixed: AppColors.secondaryFixed,
  secondaryFixedDim: AppColors.secondaryFixedDim,
  onSecondaryFixed: AppColors.onSecondaryFixed,
  onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
  tertiary: AppColors.tertiary,
  onTertiary: AppColors.onTertiary,
  tertiaryContainer: AppColors.tertiaryContainer,
  onTertiaryContainer: AppColors.onTertiaryContainer,
  tertiaryFixed: AppColors.tertiaryFixed,
  tertiaryFixedDim: AppColors.tertiaryFixedDim,
  onTertiaryFixed: AppColors.onTertiaryFixed,
  onTertiaryFixedVariant: AppColors.onTertiaryFixedVariant,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  surfaceDim: AppColors.surfaceDim,
  surfaceBright: AppColors.surfaceBright,
  surfaceContainerLowest: AppColors.surfaceContainerLowest,
  surfaceContainerLow: AppColors.surfaceContainerLow,
  surfaceContainer: AppColors.surfaceContainer,
  surfaceContainerHigh: AppColors.surfaceContainerHigh,
  surfaceContainerHighest: AppColors.surfaceContainerHighest,
  onSurfaceVariant: AppColors.onSurfaceVariant,
  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
  inverseSurface: AppColors.inverseSurface,
  onInverseSurface: AppColors.inverseOnSurface,
  inversePrimary: AppColors.inversePrimary,
  surfaceTint: AppColors.surfaceTint,
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

const ColorScheme _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppLightColors.primary,
  onPrimary: AppLightColors.onPrimary,
  primaryContainer: AppLightColors.primaryContainer,
  onPrimaryContainer: AppLightColors.onPrimaryContainer,
  secondary: AppLightColors.secondary,
  onSecondary: AppLightColors.onSecondary,
  secondaryContainer: AppLightColors.secondaryContainer,
  onSecondaryContainer: AppLightColors.onSecondaryContainer,
  error: AppLightColors.error,
  onError: AppLightColors.onError,
  errorContainer: AppLightColors.errorContainer,
  onErrorContainer: AppLightColors.onErrorContainer,
  surface: AppLightColors.surface,
  onSurface: AppLightColors.onSurface,
  surfaceDim: AppLightColors.surfaceDim,
  surfaceBright: AppLightColors.surfaceBright,
  surfaceContainerLowest: AppLightColors.surfaceContainerLowest,
  surfaceContainerLow: AppLightColors.surfaceContainerLow,
  surfaceContainer: AppLightColors.surfaceContainer,
  surfaceContainerHigh: AppLightColors.surfaceContainerHigh,
  surfaceContainerHighest: AppLightColors.surfaceContainerHighest,
  onSurfaceVariant: AppLightColors.onSurfaceVariant,
  outline: AppLightColors.outline,
  outlineVariant: AppLightColors.outlineVariant,
  inverseSurface: AppLightColors.inverseSurface,
  onInverseSurface: AppLightColors.inverseOnSurface,
  inversePrimary: AppLightColors.inversePrimary,
  surfaceTint: AppLightColors.surfaceTint,
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  const AppTheme._();

  static ColorScheme get colorScheme => _darkColorScheme;

  /// The single source-of-truth dark theme for Badar Tyres.
  static ThemeData get dark {
    final cs = _darkColorScheme;
    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      splashColor: AppColors.primary.withValues(alpha: 0.10),
      highlightColor: AppColors.primary.withValues(alpha: 0.06),
      textTheme: textTheme,
      primaryColor: cs.primary,
      iconTheme: const IconThemeData(color: AppColors.onSurface, size: 24),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBright, // Level 2 charcoal dividers.
        thickness: 1,
        space: 1,
      ),

      // App bar — flat, tonal, no heavy shadow.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleSm.copyWith(fontSize: 20),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Cards — Level 1 charcoal, 16px radius.
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        clipBehavior: Clip.antiAlias,
      ),

      // Primary buttons — solid industrial red, uppercase, 8px radius.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          disabledBackgroundColor:
              AppColors.primaryContainer.withValues(alpha: 0.45),
          disabledForegroundColor:
              AppColors.onPrimaryContainer.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
          textStyle: AppTypography.labelSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ).copyWith(
          textStyle: WidgetStatePropertyAll(
            AppTypography.labelSm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),

      // Secondary buttons — outlined, 1.5px red stroke, transparent fill.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          backgroundColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
          textStyle: AppTypography.labelSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // Tertiary / ghost buttons — red text, no fill.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Floating action button — pill / circular promoted "Create Job".
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        sizeConstraints: BoxConstraints.tightFor(width: 60, height: 60),
      ),

      // Input fields — Level 1 charcoal, muted placeholder, 2px red focus glow.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.placeholder),
        labelStyle:
            AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        floatingLabelStyle:
            AppTypography.labelSm.copyWith(color: AppColors.primary),
        prefixIconColor: AppColors.onSurfaceVariant,
        suffixIconColor: AppColors.onSurfaceVariant,
        iconColor: AppColors.onSurfaceVariant,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: AppTypography.labelSm.copyWith(color: AppColors.error),
      ),

      // Bottom navigation — solid dark, active red.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedLabelStyle: AppTypography.labelSm,
        unselectedLabelStyle: AppTypography.labelSm,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.labelSm.copyWith(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          );
        }),
      ),

      // Status tags / chips — pill shaped.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        disabledColor: AppColors.surfaceContainer,
        selectedColor: AppColors.primaryContainer,
        labelStyle: AppTypography.labelSm.copyWith(color: AppColors.onSurface),
        secondaryLabelStyle:
            AppTypography.labelSm.copyWith(color: AppColors.onPrimaryContainer),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Dialogs / popups — Level 2 surface.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        titleTextStyle: AppTypography.headlineMd,
        contentTextStyle: AppTypography.bodyMd,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceBright,
        contentTextStyle:
            AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.onSurfaceVariant,
        textColor: AppColors.onSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Selection controls accented in primary red.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primaryContainer
                : AppColors.surfaceBright),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.outline),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceBright,
        circularTrackColor: AppColors.surfaceBright,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: AppRadius.brBase,
        ),
        textStyle: AppTypography.labelSm.copyWith(color: AppColors.onSurface),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// The light theme for Badar Tyres.
  static ThemeData get light {
    final cs = _lightColorScheme;
    
    // Create a light text theme from the dark one
    final textTheme = AppTypography.textTheme.copyWith(
      displayLarge: AppTypography.displayLg.copyWith(color: AppLightColors.onSurface),
      displayMedium: AppTypography.displayLg.copyWith(color: AppLightColors.onSurface),
      displaySmall: AppTypography.headlineMd.copyWith(color: AppLightColors.onSurface),
      headlineLarge: AppTypography.headlineMd.copyWith(color: AppLightColors.onSurface),
      headlineMedium: AppTypography.headlineMd.copyWith(color: AppLightColors.onSurface),
      headlineSmall: AppTypography.titleSm.copyWith(color: AppLightColors.onSurface),
      titleLarge: AppTypography.titleSm.copyWith(color: AppLightColors.onSurface),
      titleMedium: AppTypography.titleSm.copyWith(color: AppLightColors.onSurface),
      titleSmall: AppTypography.titleSm.copyWith(color: AppLightColors.onSurface, fontSize: 16),
      bodyLarge: AppTypography.bodyMd.copyWith(color: AppLightColors.onSurface),
      bodyMedium: AppTypography.bodyMd.copyWith(color: AppLightColors.onSurface),
      bodySmall: AppTypography.bodyMd.copyWith(color: AppLightColors.onSurface, fontSize: 14, height: 20 / 14),
      labelLarge: AppTypography.labelSm.copyWith(color: AppLightColors.onSurface, fontSize: 14),
      labelMedium: AppTypography.labelSm.copyWith(color: AppLightColors.onSurfaceVariant),
      labelSmall: AppTypography.labelSm.copyWith(color: AppLightColors.onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: AppLightColors.background,
      canvasColor: AppLightColors.surface,
      splashColor: AppLightColors.primary.withValues(alpha: 0.10),
      highlightColor: AppLightColors.primary.withValues(alpha: 0.06),
      textTheme: textTheme,
      primaryColor: cs.primary,
      iconTheme: const IconThemeData(color: AppLightColors.onSurface, size: 24),
      dividerTheme: const DividerThemeData(
        color: AppLightColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppLightColors.surface,
        foregroundColor: AppLightColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleSm.copyWith(color: AppLightColors.onSurface, fontSize: 20),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: AppLightColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: const BorderSide(color: AppLightColors.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppLightColors.primaryContainer,
          foregroundColor: AppLightColors.onPrimaryContainer,
          disabledBackgroundColor: AppLightColors.primaryContainer.withValues(alpha: 0.45),
          disabledForegroundColor: AppLightColors.onPrimaryContainer.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
          textStyle: AppTypography.labelSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ).copyWith(
          textStyle: WidgetStatePropertyAll(
            AppTypography.labelSm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppLightColors.primaryContainer,
          backgroundColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppLightColors.primaryContainer, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
          textStyle: AppTypography.labelSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppLightColors.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppLightColors.primaryContainer),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppLightColors.primaryContainer,
        foregroundColor: AppLightColors.onPrimaryContainer,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        sizeConstraints: BoxConstraints.tightFor(width: 60, height: 60),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppLightColors.surfaceContainerLowest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMd.copyWith(color: AppLightColors.placeholder),
        labelStyle: AppTypography.bodyMd.copyWith(color: AppLightColors.onSurfaceVariant),
        floatingLabelStyle: AppTypography.labelSm.copyWith(color: AppLightColors.primary),
        prefixIconColor: AppLightColors.onSurfaceVariant,
        suffixIconColor: AppLightColors.onSurfaceVariant,
        iconColor: AppLightColors.onSurfaceVariant,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppLightColors.outlineVariant, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppLightColors.outlineVariant, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppLightColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppLightColors.error, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brBase,
          borderSide: BorderSide(color: AppLightColors.error, width: 2),
        ),
        errorStyle: AppTypography.labelSm.copyWith(color: AppLightColors.error),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppLightColors.surfaceContainerLowest,
        selectedItemColor: AppLightColors.primary,
        unselectedItemColor: AppLightColors.onSurfaceVariant,
        selectedLabelStyle: AppTypography.labelSm.copyWith(color: AppLightColors.primary),
        unselectedLabelStyle: AppTypography.labelSm.copyWith(color: AppLightColors.onSurfaceVariant),
        type: BottomNavigationBarType.fixed,
        elevation: 1,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppLightColors.surfaceContainerLowest,
        indicatorColor: AppLightColors.primary.withValues(alpha: 0.16),
        elevation: 1,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.labelSm.copyWith(
            color: selected ? AppLightColors.primary : AppLightColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppLightColors.primary : AppLightColors.onSurfaceVariant,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppLightColors.surfaceContainer,
        disabledColor: AppLightColors.surfaceContainerLowest,
        selectedColor: AppLightColors.primaryContainer,
        labelStyle: AppTypography.labelSm.copyWith(color: AppLightColors.onSurface),
        secondaryLabelStyle: AppTypography.labelSm.copyWith(color: AppLightColors.onPrimaryContainer),
        side: const BorderSide(color: AppLightColors.outlineVariant, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppLightColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: const BorderSide(color: AppLightColors.outlineVariant, width: 1),
        ),
        titleTextStyle: AppTypography.headlineMd.copyWith(color: AppLightColors.onSurface),
        contentTextStyle: AppTypography.bodyMd.copyWith(color: AppLightColors.onSurface),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppLightColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppLightColors.surfaceContainerHighest,
        contentTextStyle: AppTypography.bodyMd.copyWith(color: AppLightColors.onSurface),
        actionTextColor: AppLightColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brBase),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppLightColors.onSurfaceVariant,
        textColor: AppLightColors.onSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppLightColors.primary
                : AppLightColors.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppLightColors.primaryContainer.withValues(alpha: 0.3)
                : AppLightColors.surfaceVariant),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppLightColors.primary
                : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppLightColors.onPrimary),
        side: const BorderSide(color: AppLightColors.outline, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppLightColors.primary
                : AppLightColors.outline),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppLightColors.primary,
        linearTrackColor: AppLightColors.surfaceVariant,
        circularTrackColor: AppLightColors.surfaceVariant,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppLightColors.surfaceContainerHighest,
          borderRadius: AppRadius.brBase,
        ),
        textStyle: AppTypography.labelSm.copyWith(color: AppLightColors.onSurface),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

class AppTypographyData {
  final BuildContext context;
  AppTypographyData(this.context);

  TextStyle get displayLg => AppTypography.displayLg.copyWith(color: context.colors.onSurface);
  TextStyle get displayLgMobile => AppTypography.displayLgMobile.copyWith(color: context.colors.onSurface);
  TextStyle get headlineMd => AppTypography.headlineMd.copyWith(color: context.colors.onSurface);
  TextStyle get titleSm => AppTypography.titleSm.copyWith(color: context.colors.onSurface);
  TextStyle get bodyMd => AppTypography.bodyMd.copyWith(color: context.colors.onSurface);
  TextStyle get labelSm => AppTypography.labelSm.copyWith(color: context.colors.onSurfaceVariant);
}

extension ThemeExt on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppTypographyData get typography => AppTypographyData(this);
}
