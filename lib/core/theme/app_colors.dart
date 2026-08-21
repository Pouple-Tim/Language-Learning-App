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

  // Couleurs de surface
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF2C2C2C);
  
  static const Color textPrimaryLight = Colors.black87;
  static const Color textPrimaryDark = Colors.white;
  
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);

  static const Color shadowLight = Color(0x14000000); 
  static const Color shadowDark = Color(0x4D000000); 
  
  // Couleurs de classement (Nouveau)
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // Couleurs de la roue
  static const List<Color> wheelColors = [
    Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7),
    Color(0xFF3F51B5), Color(0xFF2196F3), Color(0xFF00BCD4),
    Color(0xFF009688), Color(0xFF4CAF50), Color(0xFFFF9800),
    Color(0xFFFF5722),
  ];
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}