// Compatibility bridge for AppTheme colors
// This file provides backward compatibility for Perfect 13 modules

import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs de base compatibles avec Perfect 13
  static const Color primaryColor = Colors.blue;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color surfaceColor = Colors.white;
  static const Color textTertiaryColor = Colors.grey;
  
  // Méthodes de compatibilité
  static Color get primaryLightColor => primaryColor.withOpacity(0.1);
  static Color get errorLightColor => errorColor.withOpacity(0.1);
  static Color get successLightColor => successColor.withOpacity(0.1);
  static Color get warningLightColor => warningColor.withOpacity(0.1);
  
  // Bridge vers le nouveau système de thème
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
  
  // Couleurs étendues pour Perfect 13
  static const Map<String, Color> extendedColors = {
    'primary': primaryColor,
    'error': errorColor,
    'success': successColor,
    'warning': warningColor,
    'surface': surfaceColor,
    'textTertiary': textTertiaryColor,
  };
}
