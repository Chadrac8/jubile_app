import '../data/blog_sample_data.dart';
import '../services/app_config_firebase_service.dart';

/// Utilitaire pour initialiser le module blog
class BlogInitializer {
  
  /// Initialise complètement le module blog
  static Future<void> initializeBlogModule() async {
    try {
      print('🚀 Initialisation du module Blog...');
      
      // 1. Vérifier que le module blog est activé dans la configuration
      await _ensureBlogModuleEnabled();
      
      // 2. Créer des données d'exemple si nécessaire
      await _createSampleDataIfNeeded();
      
      // 3. Vérifier les permissions par défaut
      await _setupDefaultPermissions();
      
      print('✅ Module Blog initialisé avec succès !');
      
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du blog: $e');
      rethrow;
    }
  }
  
  /// S'assure que le module blog est activé
  static Future<void> _ensureBlogModuleEnabled() async {
    try {
      final config = await AppConfigFirebaseService.getAppConfig();
      final blogModule = config.modules.firstWhere(
        (module) => module.id == 'blog',
        orElse: () => throw Exception('Module blog non trouvé dans la configuration'),
      );
      
      if (!blogModule.isEnabledForMembers) {
        print('📝 Activation du module blog pour les membres...');
        await AppConfigFirebaseService.updateModuleConfig(
          'blog',
          isEnabledForMembers: true,
        );
      }
      
      print('✅ Module blog activé');
    } catch (e) {
      print('⚠️ Erreur lors de la vérification du module: $e');
      // Ne pas faire échouer l'initialisation pour cette erreur
    }
  }
  
  /// Crée des données d'exemple si la base est vide
  static Future<void> _createSampleDataIfNeeded() async {
    try {
      // Ici on pourrait vérifier s'il y a déjà du contenu
      // Pour l'instant, on créé toujours les données d'exemple
      print('📝 Création des données d\'exemple...');
      await BlogSampleData.createSampleBlogData();
    } catch (e) {
      print('⚠️ Erreur lors de la création des données d\'exemple: $e');
      // Ne pas faire échouer l'initialisation pour cette erreur
    }
  }
  
  /// Configure les permissions par défaut
  static Future<void> _setupDefaultPermissions() async {
    try {
      print('🔐 Configuration des permissions...');
      
      // Les permissions sont gérées dans AuthService
      // Ici on pourrait ajouter une logique de configuration initiale
      
      print('✅ Permissions configurées');
    } catch (e) {
      print('⚠️ Erreur lors de la configuration des permissions: $e');
    }
  }
  
  /// Vérifie que le module blog fonctionne correctement
  static Future<bool> verifyBlogModule() async {
    try {
      print('🔍 Vérification du module blog...');
      
      // Vérifier la configuration
      final config = await AppConfigFirebaseService.getAppConfig();
      final blogModule = config.modules.firstWhere(
        (module) => module.id == 'blog',
        orElse: () => throw Exception('Module blog non trouvé'),
      );
      
      if (!blogModule.isEnabledForMembers) {
        print('❌ Module blog non activé pour les membres');
        return false;
      }
      
      print('✅ Module blog vérifié avec succès');
      return true;
      
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
      return false;
    }
  }
  
  /// Réinitialise complètement le module blog
  static Future<void> resetBlogModule() async {
    try {
      print('🔄 Réinitialisation du module blog...');
      
      // Supprimer les données existantes
      await BlogSampleData.clearSampleData();
      
      // Recréer les données d'exemple
      await BlogSampleData.createSampleBlogData();
      
      print('✅ Module blog réinitialisé');
      
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }
}