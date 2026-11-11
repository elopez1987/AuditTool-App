import 'package:flutter/material.dart';

class AppColors {
  // Marca (del ícono)
  static const blue = Color(0xFF17408B);
  static const blueDark = Color(0xFF0F2D63);
  static const red = Color(0xFFD61016);

  // Neutros de interfaz
  static const ink = Color(0xFF1F2124);
  static const muted = Color(0xFF6B6F73);
  static const border = Color(0xFFE3E5E7);
  static const background = Color(0xFFF5F6F7);
  static const surface = Color(0xFFFFFFFF);

  // Estados de auditoría
  static const pass = Color(0xFF2E9E5B);
  static const fail = Color(0xFFC62828);
  static const na = Color(0xFF6D6E71);
  static const pending = Color(0xFFB7791F);
}

class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.blue,
          onPrimary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          outline: AppColors.border,
          error: AppColors.fail,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: AppColors.border,
      ),
    );
  }
}
