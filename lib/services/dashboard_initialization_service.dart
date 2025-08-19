import 'dashboard_firebase_service.dart';
import '../auth/auth_service.dart';

class DashboardInitializationService {
  
  /// Initialise le dashboard pour un utilisateur admin
  static Future<void> initializeAdminDashboard({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) return;

      // Vérifier si l'utilisateur a déjà des widgets configurés
      final hasWidgets = await DashboardFirebaseService.hasConfiguredWidgets(userId: uid);
      
      if (!hasWidgets) {
        print('Initialisation du dashboard pour l\'utilisateur $uid');
        await DashboardFirebaseService.initializeDefaultWidgets(userId: uid);
        print('Dashboard initialisé avec succès');
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du dashboard: $e');
      // Ne pas bloquer l'application si l'initialisation échoue
    }
  }

  /// Vérifie et initialise les préférences par défaut
  static Future<void> ensureDefaultPreferences({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) return;

      final preferences = await DashboardFirebaseService.getDashboardPreferences(userId: uid);
      
      // Si aucune préférence n'existe, créer les préférences par défaut
      if (preferences.isEmpty || !preferences.containsKey('initialized')) {
        final defaultPreferences = {
          'refreshInterval': 300, // 5 minutes
          'showTrends': true,
          'compactView': false,
          'autoRefresh': true,
          'initialized': true,
          'version': '1.0.0',
        };
        
        await DashboardFirebaseService.saveDashboardPreferences(
          defaultPreferences,
          userId: uid,
        );
        
        print('Préférences par défaut du dashboard créées');
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des préférences du dashboard: $e');
    }
  }

  /// Initialise complètement le dashboard (widgets + préférences)
  static Future<void> initializeCompleteDashboard({String? userId}) async {
    await Future.wait([
      initializeAdminDashboard(userId: userId),
      ensureDefaultPreferences(userId: userId),
    ]);
  }

  /// Vérifie si le dashboard est configuré
  static Future<bool> isDashboardConfigured({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) return false;

      final hasWidgets = await DashboardFirebaseService.hasConfiguredWidgets(userId: uid);
      final preferences = await DashboardFirebaseService.getDashboardPreferences(userId: uid);
      
      return hasWidgets && preferences.containsKey('initialized');
    } catch (e) {
      print('Erreur lors de la vérification de la configuration du dashboard: $e');
      return false;
    }
  }

  /// Réinitialise complètement le dashboard
  static Future<void> resetDashboard({String? userId}) async {
    try {
      final uid = userId ?? AuthService.currentUser?.uid;
      if (uid == null) return;

      // Réinitialiser les widgets
      await DashboardFirebaseService.resetToDefaultWidgets(userId: uid);
      
      // Réinitialiser les préférences
      await ensureDefaultPreferences(userId: uid);
      
      print('Dashboard réinitialisé avec succès');
    } catch (e) {
      print('Erreur lors de la réinitialisation du dashboard: $e');
      rethrow;
    }
  }
}