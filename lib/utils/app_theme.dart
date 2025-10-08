import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aogosto_carnes_flutter/utils/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    // Branco em tudo
    scaffoldBackgroundColor: Colors.white,
    primaryColor: AppColors.primary,
    fontFamily: GoogleFonts.poppins().fontFamily,
    textTheme: GoogleFonts.poppinsTextTheme(),
    useMaterial3: true, // pode manter M3, mas tiramos o surfaceTint
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent, // <- remove “bege” do overlay
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
  );
}
