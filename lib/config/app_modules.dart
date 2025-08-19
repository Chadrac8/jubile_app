/// Configuration centrale des modules de l'application ChurchFlow
/// 
/// Ce fichier permet d'activer/désactiver dynamiquement les modules
/// et de configurer leurs permissions d'accès.

enum ModulePermission {
  admin,
  member,
  public,
}

class ModuleConfig {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isEnabled;
  final List<ModulePermission> permissions;
  final String? memberRoute;
  final String? adminRoute;
  final Map<String, dynamic>? customConfig;

  const ModuleConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isEnabled = true,
    this.permissions = const [ModulePermission.admin],
    this.memberRoute,
    this.adminRoute,
    this.customConfig,
  });

  bool hasPermission(ModulePermission permission) {
    return permissions.contains(permission);
  }
}

/// Configuration de tous les modules de l'application
class AppModulesConfig {
  /// Liste de tous les modules disponibles
  static const List<ModuleConfig> modules = [
    // Module Personnes
    ModuleConfig(
      id: 'people',
      name: 'Personnes',
      description: 'Gestion des membres et profils',
      icon: 'people',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/people',
      adminRoute: '/admin/people',
    ),

    // Module Groupes
    ModuleConfig(
      id: 'groups',
      name: 'Groupes',
      description: 'Gestion des groupes et réunions',
      icon: 'group',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/groups',
      adminRoute: '/admin/groups',
    ),

    // Module Événements
    ModuleConfig(
      id: 'events',
      name: 'Événements',
      description: 'Planification et gestion d\'événements',
      icon: 'event',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/events',
      adminRoute: '/admin/events',
    ),

    // Module Services
    ModuleConfig(
      id: 'services',
      name: 'Services',
      description: 'Gestion des services et cultes',
      icon: 'church',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/services',
      adminRoute: '/admin/services',
    ),

    // Module Formulaires
    ModuleConfig(
      id: 'forms',
      name: 'Formulaires',
      description: 'Création et gestion de formulaires',
      icon: 'form_select',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member, ModulePermission.public],
      memberRoute: '/member/forms',
      adminRoute: '/admin/forms',
    ),

    // Module Tâches
    ModuleConfig(
      id: 'tasks',
      name: 'Tâches',
      description: 'Gestion des tâches et projets',
      icon: 'task',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/tasks',
      adminRoute: '/admin/tasks',
    ),



    // Module Automatisation
    ModuleConfig(
      id: 'automation',
      name: 'Automatisation',
      description: 'Automatisations et workflows intelligents pour optimiser la gestion de l\'église',
      icon: 'auto_awesome',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/automation',
      adminRoute: '/admin/automation',
      customConfig: {
        'features': [
          'Déclencheurs automatiques',
          'Actions programmées',
          'Conditions avancées',
          'Templates prédéfinis',
          'Suivi d\'exécution',
          'Statistiques détaillées',
          'Planification récurrente',
          'Notifications automatiques',
        ],
        'triggers': [
          'Nouvelle personne',
          'Inscription groupe',
          'Inscription événement',
          'Assignation service',
          'Date planifiée',
          'Demande de prière',
          'Tâche terminée',
          'Article publié',
        ],
        'actions': [
          'Envoyer email',
          'Envoyer notification',
          'Assigner tâche',
          'Ajouter à groupe',
          'Mettre à jour champ',
          'Créer événement',
          'Planifier suivi',
          'Enregistrer activité',
        ],
      },
    ),

    // Module Rendez-vous
    ModuleConfig(
      id: 'appointments',
      name: 'Rendez-vous',
      description: 'Système de prise de rendez-vous',
      icon: 'schedule',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/appointments',
      adminRoute: '/admin/appointments',
    ),

    // Module Prières
    ModuleConfig(
      id: 'prayers',
      name: 'Mur de Prière',
      description: 'Partage de demandes de prière',
      icon: 'prayer',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/prayers',
      adminRoute: '/admin/prayers',
    ),

    // Module Pages Personnalisées
    ModuleConfig(
      id: 'pages',
      name: 'Pages',
      description: 'Création de pages personnalisées',
      icon: 'web',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/pages',
      adminRoute: '/admin/pages',
    ),

    // Module Blog
    ModuleConfig(
      id: 'blog',
      name: 'Blog',
      description: 'Articles et actualités',
      icon: 'article',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member, ModulePermission.public],
      memberRoute: '/member/blog',
      adminRoute: '/admin/blog',
    ),

    // Module Rapports
    ModuleConfig(
      id: 'reports',
      name: 'Rapports',
      description: 'Génération et analyse de rapports statistiques détaillés pour l\'église',
      icon: 'assessment',
      isEnabled: true,
      permissions: [ModulePermission.admin, ModulePermission.member],
      memberRoute: '/member/reports',
      adminRoute: '/admin/reports',
      customConfig: {
        'features': [
          'Rapports de présence',
          'Analyses financières',
          'Statistiques des membres',
          'Rapports d\'événements',
          'Graphiques personnalisés',
          'Export de données',
          'Planification automatique',
          'Templates prédéfinis',
        ],
        'report_types': [
          'attendance',
          'financial',
          'membership',
          'event',
          'custom',
        ],
        'templates': [
          'Présence hebdomadaire',
          'Dons mensuels',
          'Croissance des membres',
          'Participation aux événements',
          'Analyse des donateurs',
          'Démographie par âge',
          'Heures de bénévolat',
          'Satisfaction des événements',
        ],
        'permissions': {
          'member': ['view_public', 'view_shared', 'generate'],
          'admin': ['create', 'edit', 'delete', 'share', 'manage_all'],
        },
      },
    ),
  ];

  /// Obtenir un module par son ID
  static ModuleConfig? getModule(String id) {
    try {
      return modules.firstWhere((module) => module.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir tous les modules activés
  static List<ModuleConfig> getEnabledModules() {
    return modules.where((module) => module.isEnabled).toList();
  }

  /// Obtenir les modules avec une permission spécifique
  static List<ModuleConfig> getModulesWithPermission(ModulePermission permission) {
    return getEnabledModules()
        .where((module) => module.hasPermission(permission))
        .toList();
  }

  /// Obtenir les modules pour l'interface membre
  static List<ModuleConfig> getMemberModules() {
    return getModulesWithPermission(ModulePermission.member);
  }

  /// Obtenir les modules pour l'interface admin
  static List<ModuleConfig> getAdminModules() {
    return getModulesWithPermission(ModulePermission.admin);
  }

  /// Vérifier si un module est activé
  static bool isModuleEnabled(String moduleId) {
    final module = getModule(moduleId);
    return module?.isEnabled ?? false;
  }

  /// Obtenir la route membre d'un module
  static String? getMemberRoute(String moduleId) {
    final module = getModule(moduleId);
    return module?.memberRoute;
  }

  /// Obtenir la route admin d'un module
  static String? getAdminRoute(String moduleId) {
    final module = getModule(moduleId);
    return module?.adminRoute;
  }
}