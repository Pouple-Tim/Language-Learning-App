import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // THÈME CLAIR (Light Mode)
  // ---------------------------------------------------------------------------
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto', 

    // 1. Couleurs principales
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Colors.white,       // Couleur de fond des Cards
      onSurface: Colors.black87,   // Couleur du texte sur les Cards
      error: AppColors.error,
      // background: retiré car obsolète (géré par surface et scaffoldBackgroundColor)
    ),

    scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Gris très clair

    // 2. Textes 
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      titleMedium: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Color(0xFF757575)), 
    ),

    // 3. AppBar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87, 
      iconTheme: IconThemeData(color: Colors.black87),
    ),

    // 4. Cartes (Cards)
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // 5. Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // 6. Inputs (Champs de texte)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    ),

    // 7. Icones
    iconTheme: const IconThemeData(
      color: Colors.black87,
    ),
  );

  // ---------------------------------------------------------------------------
  // THÈME SOMBRE (Dark Mode)
  // ---------------------------------------------------------------------------
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',

    // 1. Couleurs principales
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Color(0xFF2C2C2C),  // Gris foncé pour les cartes
      onSurface: Colors.white,     // Texte blanc sur les cartes
      error: AppColors.error,
      // background: retiré car obsolète
    ),

    scaffoldBackgroundColor: Colors.black,

    // 2. Textes
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFFBDBDBD)), 
    ),

    // 3. AppBar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // 4. Cartes
    cardTheme: CardThemeData(
      color: const Color(0xFF2C2C2C), 
      elevation: 4,
      shadowColor: Colors.black45, 
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // 5. Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // 6. Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),

    // 7. Icones
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
  );
}