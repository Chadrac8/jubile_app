import '../services/roles_firebase_service.dart';

class RoleInitializationService {
  static Future<void> initializeDefaultRoles() async {
    try {
      // Créer les rôles par défaut
      await RolesFirebaseService.createDefaultRoles();
      print('✅ Rôles par défaut créés avec succès');
    } catch (e) {
      print('⚠️ Erreur lors de la création des rôles par défaut: $e');
    }
  }
}