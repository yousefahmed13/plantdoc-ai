import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PD {
  static const bg = Color(0xFF080E13);
  static const surface = Color(0xFF111920);
  static const card = Color(0xFF141E27);
  static const border = Color(0xFF1E2E3D);

  static const green = Color(0xFF22C55E);
  static const greenDark = Color(0xFF16A34A);
  static const teal = Color(0xFF14B8A6);
  static const blue = Color(0xFF3B82F6);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const grape = Color(0xFF8B5CF6);

  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF475569);

  static Color modeColor(String mode) {
    switch (mode) {
      case 'grape':
        return grape;
      case 'weather':
        return blue;
      case 'insect':
        return amber;
      default:
        return green;
    }
  }

  static String modeEmoji(String mode) {
    switch (mode) {
      case 'grape':
        return '🍇';
      case 'weather':
        return '🌡️';
      case 'insect':
        return '🐛';
      default:
        return '🌿';
    }
  }

  static String modeLabel(String mode, bool isAr) {
    switch (mode) {
      case 'grape':
        return isAr ? 'نمو العنب' : 'Grape Stage';
      case 'weather':
        return isAr ? 'الري الذكي' : 'Irrigation';
      case 'insect':
        return isAr ? 'تعرّف الحشرات' : 'Insect ID';
      default:
        return isAr ? 'أمراض النبات' : 'Plant Disease';
    }
  }

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: green,
        secondary: teal,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}

TextStyle pdFont(bool isAr, {
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = PD.textPrimary,
  double height = 1.5,
}) {
  return isAr
      ? GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color, height: height)
      : GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height);
}
