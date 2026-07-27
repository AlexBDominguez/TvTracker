import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary), // Título principal
    displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary), // Título de pantalla
    displaySmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary), // Encabezado de sección
    headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary), // Título de tarjeta
    bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary), // Texto principal
    bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary), // Texto secundario
    labelLarge: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary), // Etiquetas
    bodySmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary), // Información auxiliar
  );
}