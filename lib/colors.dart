import 'package:flutter/material.dart';

/// Palette de couleurs élégante : Rouge bordeaux + Or + Crème
/// Basée sur la couleur principale #850606
class AppColors {
  // === COULEURS PRINCIPALES ===
  
  /// Rouge bordeaux - Couleur de base (#850606)
  static const Color primary = Color(0xFF850606);
  
  /// Or - Couleur secondaire élégante (#D4AF37)
  static const Color secondary = Color(0xFFD4AF37);
  
  /// Brun doré - Couleur tertiaire (#8B4513)
  static const Color tertiary = Color(0xFF8B4513);
  
  // === COULEURS NEUTRES ===
  
  /// Blanc antique - Arrière-plan principal (#FFF8DC)
  static const Color background = Color(0xFFFFF8DC);
  
  /// Crème - Surface principale (#F5E6D3)
  static const Color surface = Color(0xFFF5E6D3);
  
  /// Brun très foncé - Texte principal (#2F1B14)
  static const Color textPrimary = Color(0xFF2F1B14);
  
  /// Brun doré - Texte secondaire (#8B4513)
  static const Color textSecondary = Color(0xFF8B4513);
  
  /// Rouge bordeaux - Texte d'accent (#850606)
  static const Color textAccent = Color(0xFF850606);
  
  // === COULEURS FONCTIONNELLES ===
  
  /// Rouge d'erreur
  static const Color error = Color(0xFFE53E3E);
  
  /// Vert de succès
  static const Color success = Color(0xFF38A169);
  
  /// Orange/Or d'avertissement
  static const Color warning = Color(0xFFD4AF37);
  
  /// Bleu d'information
  static const Color info = Color(0xFF3182CE);
  
  // === VARIATIONS DE LA COULEUR PRINCIPALE ===
  
  /// Rouge bordeaux clair
  static const Color primaryLight = Color(0xFFB30808);
  
  /// Rouge bordeaux foncé
  static const Color primaryDark = Color(0xFF5C0404);
  
  /// Rouge bordeaux très foncé
  static const Color primaryDarker = Color(0xFF2E0101);
  
  // === VARIATIONS DE L'OR ===
  
  /// Or clair
  static const Color goldLight = Color(0xFFE6C547);
  
  /// Or foncé
  static const Color goldDark = Color(0xFFB8941F);
  
  // === COULEURS POUR LE MODE SOMBRE ===
  
  /// Arrière-plan sombre
  static const Color darkBackground = Color(0xFF1A0E0A);
  
  /// Surface sombre
  static const Color darkSurface = Color(0xFF2F1B14);
  
  /// Texte clair pour mode sombre
  static const Color darkTextPrimary = Color(0xFFFFF8DC);
  
  /// Texte secondaire pour mode sombre
  static const Color darkTextSecondary = Color(0xFFF5E6D3);
  
  // === COULEURS DE STATUT ===
  
  /// Couleur pour les éléments en ligne/actifs
  static const Color online = Color(0xFF38A169);
  
  /// Couleur pour les éléments hors ligne/inactifs
  static const Color offline = Color(0xFF718096);
  
  /// Couleur pour les éléments en attente
  static const Color pending = Color(0xFFD4AF37);
  
  // === OPACITÉS UTILES ===
  
  /// Overlay léger (10% d'opacité)
  static const Color overlayLight = Color(0x1A850606);
  
  /// Overlay moyen (20% d'opacité)
  static const Color overlayMedium = Color(0x33850606);
  
  /// Overlay foncé (50% d'opacité)
  static const Color overlayDark = Color(0x80850606);
  
  // === MÉTHODES UTILITAIRES ===
  
  /// Retourne une couleur avec l'opacité spécifiée
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Retourne la couleur appropriée selon le rôle
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'member':
      case 'membre':
        return tertiary;
      case 'leader':
      case 'dirigeant':
        return secondary;
      case 'pastor':
      case 'pasteur':
        return primary;
      case 'admin':
      case 'administrateur':
        return primaryDark;
      default:
        return textSecondary;
    }
  }
  
  /// Retourne la couleur appropriée selon le type de groupe
  static Color getGroupTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'petit groupe':
        return tertiary;
      case 'prière':
      case 'prayer':
        return primary;
      case 'jeunesse':
      case 'youth':
        return secondary;
      case 'étude biblique':
      case 'bible study':
        return textPrimary;
      case 'louange':
      case 'worship':
        return primary;
      case 'leadership':
        return secondary;
      default:
        return textSecondary;
    }
  }
  
  /// Retourne la couleur appropriée selon le statut
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'brouillon':
      case 'draft':
        return warning;
      case 'publié':
      case 'published':
      case 'publie':
        return success;
      case 'archivé':
      case 'archived':
      case 'archive':
        return textSecondary;
      case 'annulé':
      case 'cancelled':
      case 'annule':
        return error;
      case 'en attente':
      case 'pending':
        return pending;
      default:
        return textSecondary;
    }
  }
}
