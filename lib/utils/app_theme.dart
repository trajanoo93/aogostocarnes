import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: AppColors.primary,
    fontFamily: GoogleFonts.poppins().fontFamily,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    cardColor: Colors.white,

    // === TEXT THEME COM ESTILOS PERSONALIZADOS ===
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      // TÍTULO PRINCIPAL (Meu Carrinho)
      displayLarge: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),

      // NOME DO PRODUTO
      titleLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ),

      // PREÇO DO ITEM
      headlineMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),

      // TOTAL
      headlineSmall: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),

      // SUBTÍTULOS (Subtotal, Taxa)
      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),

      // VALORES NORMAIS (R$ 21,90)
      bodyLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),

      // LEGENDAS (Seu carrinho está vazio - texto menor)
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),

      // BOTÃO "Continuar comprando"
      labelLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    ),
  );
}