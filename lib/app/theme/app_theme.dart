import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  /// Night mission. Light mode stays in the same spy palette, lifted one
  /// step, so the persisted theme setting still changes the scaffold.
  static ThemeData light() => _base(dark: false);

  static ThemeData dark() => _base(dark: true);

  static ThemeData _base({required bool dark}) {
    final bg = dark ? AppColors.background : AppColors.night;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.buttonInk,
      secondary: AppColors.accent,
      onSecondary: AppColors.buttonInk,
      tertiary: AppColors.imposter,
      onTertiary: AppColors.buttonInk,
      error: AppColors.imposter,
      onError: AppColors.textPrimary,
      surface: dark ? AppColors.card : AppColors.cardRaised,
      onSurface: AppColors.textPrimary,
    );
    final buttonText = AppTextStyles.display(
      AppColors.buttonInk,
      size: 18,
    ).copyWith(letterSpacing: 0.6);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: AppFonts.body,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        titleTextStyle: AppTextStyles.title(AppColors.textPrimary),
        contentTextStyle: AppTextStyles.body(AppColors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.display(AppColors.accent, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.buttonInk,
          disabledBackgroundColor: AppColors.cardRaised,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.display(AppColors.primary, size: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: AppTextStyles.label(AppColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.title(AppColors.ink.withValues(alpha: 0.35)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.buttonInk;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.cardRaised;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardRaised,
        selectedColor: AppColors.accent,
        disabledColor: AppColors.card,
        labelStyle: AppTextStyles.label(AppColors.textSecondary),
        secondaryLabelStyle: AppTextStyles.label(AppColors.buttonInk),
        side: const BorderSide(color: AppColors.cardBorder),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(AppColors.textPrimary),
        headlineMedium: AppTextStyles.display(AppColors.textPrimary, size: 26),
        titleLarge: AppTextStyles.title(AppColors.textPrimary),
        bodyLarge: AppTextStyles.body(AppColors.textPrimary),
        labelLarge: AppTextStyles.label(AppColors.textPrimary),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}
