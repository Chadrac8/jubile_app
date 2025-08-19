import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_config_model.dart';
import '../models/page_model.dart';
import 'pages_firebase_service.dart';

class AppConfigFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String appConfigCollection = 'app_config';
  static const String configDocumentId = 'main_config';

  // Get app configuration
  static Future<AppConfigModel> getAppConfig() async {
    try {
      final doc = await _firestore
          .collection(appConfigCollection)
          .doc(configDocumentId)
          .get();

      if (doc.exists) {
        return AppConfigModel.fromFirestore(doc);
      } else {
        // Create default configuration
        final defaultConfig = _createDefaultConfig();
        await updateAppConfig(defaultConfig);
        return defaultConfig;
      }
    } catch (e) {
      // Return default config in case of error
      return _createDefaultConfig();
    }
  }

  // Stream app configuration
  static Stream<AppConfigModel> getAppConfigStream() {
    return _firestore
        .collection(appConfigCollection)
        .doc(configDocumentId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return AppConfigModel.fromFirestore(doc);
      } else {
        return _createDefaultConfig();
      }
    });
  }

  // Update app configuration
  static Future<void> updateAppConfig(AppConfigModel config) async {
    final currentUser = _auth.currentUser;
    final updatedConfig = AppConfigModel(
      id: config.id,
      modules: config.modules,
      customPages: config.customPages,
      generalSettings: config.generalSettings,
      lastUpdated: DateTime.now(),
      lastUpdatedBy: currentUser?.uid,
    );

    await _firestore
        .collection(appConfigCollection)
        .doc(configDocumentId)
        .set(updatedConfig.toFirestore());
  }

  // Update module configuration
  static Future<void> updateModuleConfig(String moduleId, {
    bool? isEnabledForMembers,
    bool? isPrimaryInBottomNav,
    int? order,
  }) async {
    final config = await getAppConfig();
    final modules = config.modules.map((module) {
      if (module.id == moduleId) {
        return module.copyWith(
          isEnabledForMembers: isEnabledForMembers,
          isPrimaryInBottomNav: isPrimaryInBottomNav,
          order: order,
        );
      }
      return module;
    }).toList();

    final updatedConfig = AppConfigModel(
      id: config.id,
      modules: modules,
      customPages: config.customPages,
      generalSettings: config.generalSettings,
      lastUpdated: DateTime.now(),
      lastUpdatedBy: _auth.currentUser?.uid,
    );

    await updateAppConfig(updatedConfig);
  }

  // Set primary bottom nav modules
  static Future<void> setPrimaryBottomNavModules(List<String> moduleIds) async {
    final config = await getAppConfig();
    final modules = config.modules.map((module) {
      final isPrimary = moduleIds.contains(module.id);
      final order = isPrimary ? moduleIds.indexOf(module.id) : module.order;
      
      return module.copyWith(
        isPrimaryInBottomNav: isPrimary,
        order: order,
      );
    }).toList();

    final updatedConfig = AppConfigModel(
      id: config.id,
      modules: modules,
      customPages: config.customPages,
      generalSettings: config.generalSettings,
      lastUpdated: DateTime.now(),
      lastUpdatedBy: _auth.currentUser?.uid,
    );

    await updateAppConfig(updatedConfig);
  }

  // Toggle module for members
  static Future<void> toggleModuleForMembers(String moduleId, bool isEnabled) async {
    await updateModuleConfig(
      moduleId,
      isEnabledForMembers: isEnabled,
    );
  }

  // Get enabled modules for members
  static Future<List<ModuleConfig>> getEnabledModulesForMembers() async {
    final config = await getAppConfig();
    return config.enabledModulesForMembers;
  }

  // Get primary bottom nav modules
  static Future<List<ModuleConfig>> getPrimaryBottomNavModules() async {
    final config = await getAppConfig();
    return config.primaryBottomNavModules;
  }

  // Get secondary modules (for "Plus" menu)
  static Future<List<ModuleConfig>> getSecondaryModules() async {
    final config = await getAppConfig();
    return config.secondaryModules;
  }

  // Initialize default configuration
  static Future<void> initializeDefaultConfig() async {
    final doc = await _firestore
        .collection(appConfigCollection)
        .doc(configDocumentId)
        .get();

    if (!doc.exists) {
      final defaultConfig = _createDefaultConfig();
      await updateAppConfig(defaultConfig);
    }
  }

  // Create default configuration
  static AppConfigModel _createDefaultConfig() {
    return AppConfigModel(
      id: configDocumentId,
      modules: _getDefaultModules(),
      customPages: [], // Will be populated by syncCustomPages
      generalSettings: {
        'churchName': 'Mon Église',
        'primaryColor': '#6F61EF',
        'allowMemberRegistration': true,
        'defaultLanguage': 'fr',
      },
      lastUpdated: DateTime.now(),
    );
  }

  // Get default modules
  static List<ModuleConfig> _getDefaultModules() {
    return [
      ModuleConfig(
        id: 'dashboard',
        name: 'Accueil',
        description: 'Vue d\'ensemble et actualités',
        iconName: 'dashboard',
        route: 'dashboard',
        category: 'core',
        isPrimaryInBottomNav: true,
        order: 0,
      ),

      ModuleConfig(
        id: 'groups',
        name: 'Mes Groupes',
        description: 'Groupes et communautés',
        iconName: 'groups',
        route: 'groups',
        category: 'ministry',
        isPrimaryInBottomNav: true,
        order: 1,
      ),
      ModuleConfig(
        id: 'events',
        name: 'Événements',
        description: 'Événements à venir',
        iconName: 'event',
        route: 'events',
        category: 'core',
        isPrimaryInBottomNav: true,
        order: 2,
      ),

      ModuleConfig(
        id: 'services',
        name: 'Services',
        description: 'Affectations et planning',
        iconName: 'church',
        route: 'services',
        category: 'ministry',
        isPrimaryInBottomNav: false,
        order: 5,
      ),
      ModuleConfig(
        id: 'forms',
        name: 'Formulaires',
        description: 'Formulaires à remplir',
        iconName: 'assignment',
        route: 'forms',
        category: 'tools',
        isPrimaryInBottomNav: false,
        order: 6,
      ),
      ModuleConfig(
        id: 'tasks',
        name: 'Tâches',
        description: 'Tâches assignées et listes',
        iconName: 'task_alt',
        route: 'tasks',
        category: 'management',
        isPrimaryInBottomNav: false,
        order: 7,
      ),
      ModuleConfig(
        id: 'appointments',
        name: 'Rendez-vous',
        description: 'Prendre et gérer mes RDV',
        iconName: 'event_available',
        route: 'appointments',
        category: 'core',
        isPrimaryInBottomNav: false,
        order: 9,
      ),
      ModuleConfig(
        id: 'prayers',
        name: 'Mur de Prière',
        description: 'Partager des prières et témoignages',
        iconName: 'prayer_hands',
        route: 'prayers',
        category: 'ministry',
        isPrimaryInBottomNav: true,
        order: 3,
      ),
      ModuleConfig(
        id: 'reports',
        name: 'Rapports',
        description: 'Analyses et statistiques',
        iconName: 'bar_chart',
        route: 'reports',
        category: 'management',
        isPrimaryInBottomNav: true,
        order: 4,
      ),
      ModuleConfig(
        id: 'blog',
        name: 'Blog',
        description: 'Articles et actualités',
        iconName: 'article',
        route: 'blog',
        category: 'communication',
        isPrimaryInBottomNav: false,
        isEnabledForMembers: true,
        order: 13,
      ),
      ModuleConfig(
        id: 'calendar',
        name: 'Calendrier',
        description: 'Mon agenda personnel',
        iconName: 'calendar_today',
        route: 'calendar',
        category: 'tools',
        isPrimaryInBottomNav: false,
        order: 8,
      ),
      ModuleConfig(
        id: 'pages',
        name: 'Pages',
        description: 'Contenus personnalisés',
        iconName: 'web',
        route: 'pages',
        category: 'tools',
        isPrimaryInBottomNav: false,
        order: 10,
      ),
      ModuleConfig(
        id: 'notifications',
        name: 'Notifications',
        description: 'Centre de notifications',
        iconName: 'notifications',
        route: 'notifications',
        category: 'tools',
        isPrimaryInBottomNav: false,
        order: 11,
      ),
      ModuleConfig(
        id: 'settings',
        name: 'Paramètres',
        description: 'Paramètres personnels',
        iconName: 'settings',
        route: 'settings',
        category: 'tools',
        isPrimaryInBottomNav: false,
        order: 12,
      ),
      ModuleConfig(
        id: 'dynamic_lists',
        name: 'Listes Dynamiques',
        description: 'Créer et gérer des listes personnalisées',
        iconName: 'list_alt',
        route: 'dynamic_lists',
        category: 'tools',
        isPrimaryInBottomNav: false,
        order: 13,
      ),
    ];
  }

  // Sync custom pages from page builder
  static Future<void> syncCustomPages() async {
    try {
      final config = await getAppConfig();
      final customPages = await PagesFirebaseService.getAllPages();
      
      print('🔄 syncCustomPages - Début synchronisation');
      print('📄 Pages trouvées dans DB: ${customPages.length}');
      
      // Inclure toutes les pages non archivées (brouillons et publiées)
      final filteredPages = customPages.where((page) => page.status != 'archived').toList();
      print('📄 Pages non archivées: ${filteredPages.length}');
      
      // Conserver les configurations existantes si elles existent
      final existingPages = config.customPages;
      print('📄 Pages existantes dans config: ${existingPages.length}');
      
      final pageConfigs = filteredPages.map((page) {
        // Chercher si cette page existe déjà dans la configuration
        final existingPage = existingPages.firstWhere(
          (p) => p.id == page.id,
          orElse: () => PageConfig(
            id: '',
            title: '',
            description: '',
            iconName: 'web',
            route: '',
            slug: '',
          ),
        );
        
        // Si la page existe déjà, conserver ses paramètres, sinon utiliser les valeurs par défaut
        final isEnabledForMembers = existingPage.id.isNotEmpty ? existingPage.isEnabledForMembers : false;
        final isPrimaryInBottomNav = existingPage.id.isNotEmpty ? existingPage.isPrimaryInBottomNav : false;
        final order = existingPage.id.isNotEmpty ? existingPage.order : page.displayOrder;
        
        print('📄 Page "${page.title}": enabled=$isEnabledForMembers, primary=$isPrimaryInBottomNav, order=$order');
        
        return PageConfig(
          id: page.id,
          title: page.title,
          description: page.description,
          iconName: page.iconName ?? 'web',
          route: 'custom_page/${page.slug}',
          slug: page.slug,
          visibility: page.visibility,
          visibilityTargets: page.visibilityTargets,
          isEnabledForMembers: isEnabledForMembers,
          isPrimaryInBottomNav: isPrimaryInBottomNav,
          order: order,
        );
      }).toList();

      print('📄 PageConfigs créées: ${pageConfigs.length}');
      
      final updatedConfig = AppConfigModel(
        id: config.id,
        modules: config.modules,
        customPages: pageConfigs,
        generalSettings: config.generalSettings,
        lastUpdated: DateTime.now(),
        lastUpdatedBy: _auth.currentUser?.uid,
      );

      await updateAppConfig(updatedConfig);
      print('✅ syncCustomPages - Synchronisation terminée avec succès');
    } catch (e) {
      print('❌ syncCustomPages - Erreur: $e');
      throw Exception('Erreur lors de la synchronisation des pages: $e');
    }
  }

  // Update page configuration
  static Future<void> updatePageConfig(String pageId, {
    bool? isEnabledForMembers,
    bool? isPrimaryInBottomNav,
    int? order,
  }) async {
    final config = await getAppConfig();
    final pages = config.customPages.map((page) {
      if (page.id == pageId) {
        return page.copyWith(
          isEnabledForMembers: isEnabledForMembers,
          isPrimaryInBottomNav: isPrimaryInBottomNav,
          order: order,
        );
      }
      return page;
    }).toList();

    final updatedConfig = AppConfigModel(
      id: config.id,
      modules: config.modules,
      customPages: pages,
      generalSettings: config.generalSettings,
      lastUpdated: DateTime.now(),
      lastUpdatedBy: _auth.currentUser?.uid,
    );

    await updateAppConfig(updatedConfig);
  }

  // Reset to default configuration
  static Future<void> resetToDefault() async {
    final defaultConfig = _createDefaultConfig();
    // Sync custom pages after reset
    await updateAppConfig(defaultConfig);
    await syncCustomPages();
  }

  // Export configuration
  static Future<Map<String, dynamic>> exportConfiguration() async {
    final config = await getAppConfig();
    return config.toFirestore();
  }

  // Import configuration
  static Future<void> importConfiguration(Map<String, dynamic> configData) async {
    await _firestore
        .collection(appConfigCollection)
        .doc(configDocumentId)
        .set({
      ...configData,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
      'lastUpdatedBy': _auth.currentUser?.uid,
    });
  }

  // Validate configuration
  static Future<bool> validateConfiguration(Map<String, dynamic> configData) async {
    try {
      // Basic validation
      if (!configData.containsKey('modules')) return false;
      
      final modules = configData['modules'] as List?;
      if (modules == null || modules.isEmpty) return false;

      // Check required modules exist
      final moduleIds = modules.map((m) => m['id']).toList();
      final requiredModules = ['profile', 'groups', 'events'];
      
      for (final required in requiredModules) {
        if (!moduleIds.contains(required)) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}