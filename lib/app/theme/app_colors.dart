import 'package:flutter/material.dart';

/// Spy Imposter Game palette. Hex values match the theme brief.
class AppColors {
  static const background = Color(0xFF0B1020);
  static const night = Color(0xFF141B33);
  static const card = Color(0xFF1B2442);
  static const cardBorder = Color(0xFF2C3A66);
  static const cardRaised = Color(0xFF243055);
  static const primary = Color(0xFF22E4F5);
  static const primaryPressed = Color(0xFF12BFD0);
  static const accent = Color(0xFFFFB020);
  static const imposter = Color(0xFFFF3B4E);
  static const civilian = Color(0xFF34E0A1);
  static const paper = Color(0xFFF3E9D2);
  static const textPrimary = Color(0xFFF2F6FF);
  static const textSecondary = Color(0xFF9FB0D6);
  static const ink = Color(0xFF1A1F33);
  static const buttonInk = Color(0xFF071018);
}

class AppFonts {
  static const display = 'StardosStencil';
  static const dossier = 'CourierPrime';
  static const body = 'Nunito';
  static const numbers = 'Oswald';
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadii {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const pill = 999.0;
}

class AppTextStyles {
  static TextStyle display(Color c, {double size = 32}) => TextStyle(
    fontFamily: AppFonts.display,
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.05,
    color: c,
  );

  static TextStyle dossier(Color c, {double size = 14}) => TextStyle(
    fontFamily: AppFonts.dossier,
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    height: 1.3,
    color: c,
  );

  static TextStyle title(Color c) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: c,
  );

  static TextStyle body(Color c) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: c,
  );

  static TextStyle label(Color c) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: c,
  );

  static TextStyle number(Color c, {double size = 28}) => TextStyle(
    fontFamily: AppFonts.numbers,
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1,
    color: c,
  );
}
