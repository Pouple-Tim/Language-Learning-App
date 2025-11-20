import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF6200EA);
  static const Color secondary = Color(0xFF03DAC6);
  
  // Couleurs de feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE91E63);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Couleurs de la roue
  static const List<Color> wheelColors = [
    Color(0xFFE91E63), // Rose
    Color(0xFF9C27B0), // Violet
    Color(0xFF673AB7), // Violet foncé
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Bleu
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Vert
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Rouge-orange
  ];
  
  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}