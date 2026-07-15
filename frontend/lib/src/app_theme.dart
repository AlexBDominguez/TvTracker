import 'package:flutter/material.dart';

/// Defines the color palette for the TvTracker application.
///
/// Based on the design specification:
/// - Fondo principal: #11131C
/// - Fondo secundario: #1A1D29
/// - Tarjetas: #24293A
/// - Color principal: #8B5CF6
/// - Color secundario: #22D3EE
/// - Color destacado: #FF5D8F
/// - Texto principal: #F8FAFC
/// - Texto secundario: #9CA3AF
/// - Éxito: #4ADE80
/// - Advertencia: #FBBF24
/// - Error: #F43F5E
class AppColors {
  static const Color primaryBackground = Color(0xFF11131C);
  static const Color secondaryBackground = Color(0xFF1A1D29);
  static const Color card = Color(0xFF24293A);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFF22D3EE);
  static const Color accent = Color(0xFFFF5D8F);
  static const Color primaryText = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF43F5E);
}

/// Defines the application's theme.
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.primaryBackground,
        surface: AppColors.card,
        error: AppColors.error,
        onPrimary: AppColors.primaryText,
        onSecondary: AppColors.primaryText,
        onBackground: AppColors.primaryText,
        onSurface: AppColors.primaryText,
        onError: AppColors.primaryText,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.primaryText),
        displayMedium: TextStyle(color: AppColors.primaryText),
        displaySmall: TextStyle(color: AppColors.primaryText),
        headlineMedium: TextStyle(color: AppColors.primaryText),
        headlineSmall: TextStyle(color: AppColors.primaryText),
        titleLarge: TextStyle(color: AppColors.primaryText),
        titleMedium: TextStyle(color: AppColors.primaryText),
        titleSmall: TextStyle(color: AppColors.primaryText),
        bodyLarge: TextStyle(color: AppColors.primaryText),
        bodyMedium: TextStyle(color: AppColors.secondaryText),
        labelLarge: TextStyle(color: AppColors.primaryText),
        labelSmall: TextStyle(color: AppColors.secondaryText),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}