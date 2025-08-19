import 'package:flutter/material.dart';
import 'module_manager.dart';
import '../shared/utils/navigation_service.dart';
// import '../pages/diagnostic_page.dart';

/// Page d'accueil temporaire qui affiche les modules disponibles
class _ModularHomePage extends StatelessWidget {
  const _ModularHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final moduleManager = ModuleManager();
    final modules = moduleManager.getActiveModules();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChurchFlow - Architecture Modulaire'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modules disponibles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nouveau : Listes intelligentes dans le module Personnes !',
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: modules.isEmpty
                  ? const Center(
                      child: Text('Aucun module chargé'),
                    )
                  : ListView.builder(
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(_getIconData(module.config.icon)),
                            title: Text(module.config.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(module.config.description),
                                if (module.config.id == 'people') ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.list_alt, size: 14, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Listes intelligentes disponibles',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _navigateToModule(context, module),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            _buildModuleStats(context, moduleManager),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/diagnostic');
              },
              icon: const Icon(Icons.info),
              label: const Text('Diagnostic des Modules'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'people':
        return Icons.people;
      case 'group':
        return Icons.group;
      case 'event':
        return Icons.event;
      case 'church':
        return Icons.church;
      case 'form_select':
        return Icons.description;
      case 'task':
        return Icons.task;
      case 'music_note':
        return Icons.music_note;
      case 'schedule':
        return Icons.schedule;
      case 'prayer':
        return Icons.favorite;
      case 'web':
        return Icons.web;
      case 'article':
        return Icons.article;
      case 'assessment':
        return Icons.assessment;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'library_music':
        return Icons.library_music;
      default:
        return Icons.extension;
    }
  }

  void _navigateToModule(BuildContext context, AppModule module) {
    // Pour l'instant, naviguer vers la route admin du module
    final adminRoute = module.config.adminRoute;
    if (adminRoute != null) {
      Navigator.of(context).pushNamed(adminRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucune route définie pour ${module.config.name}'),
        ),
      );
    }
  }

  Widget _buildModuleStats(BuildContext context, ModuleManager moduleManager) {
    final stats = moduleManager.getModuleStats();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Modules totaux: ${stats['totalModules']}'),
            Text('Modules membre: ${stats['memberModules']}'),
            Text('Modules admin: ${stats['adminModules']}'),
            Text('Routes totales: ${stats['totalRoutes']}'),
          ],
        ),
      ),
    );
  }
}

/// Générateur de routes pour l'application
class AppRouter {
  static final ModuleManager _moduleManager = ModuleManager();

  /// Routes de base de l'application (non modulaires)
  static final Map<String, WidgetBuilder> _baseRoutes = {
    '/': (context) => _buildHomePage(),
    '/login': (context) => _buildLoginPage(),
    '/profile-setup': (context) => _buildProfileSetupPage(),
    // '/diagnostic': (context) => _buildDiagnosticPage(),
  };

  /// Générer les routes de l'application
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final routeName = settings.name;
    
    if (routeName == null) {
      return _buildErrorRoute('Route non définie');
    }

    // Vérifier les routes de base
    if (_baseRoutes.containsKey(routeName)) {
      final builder = _baseRoutes[routeName]!;
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }

    // Vérifier les routes des modules
    final moduleRoutes = _moduleManager.getRoutes();
    if (moduleRoutes.containsKey(routeName)) {
      final builder = moduleRoutes[routeName]!;
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }

    // Route non trouvée
    return _buildErrorRoute('Route "$routeName" non trouvée');
  }

  /// Construire une route d'erreur
  static MaterialPageRoute _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erreur de navigation'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  NavigationService.navigateToAndClearStack('/');
                },
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Page d'accueil avec modules
  static Widget _buildHomePage() {
    // Import de la page d'accueil modulaire
    return const _ModularHomePage();
  }

  /// Page de connexion temporaire
  static Widget _buildLoginPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: const Center(
        child: Text('Page de connexion temporaire'),
      ),
    );
  }

  /// Page de configuration de profil temporaire
  static Widget _buildProfileSetupPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration du profil'),
      ),
      body: const Center(
        child: Text('Page de configuration temporaire'),
      ),
    );
  }

  /// Construire la page de diagnostic
  // static Widget _buildDiagnosticPage() {
  //   return const DiagnosticPage();
  // }

  /// Obtenir toutes les routes disponibles
  static Map<String, WidgetBuilder> getAllRoutes() {
    final allRoutes = <String, WidgetBuilder>{};
    allRoutes.addAll(_baseRoutes);
    allRoutes.addAll(_moduleManager.getRoutes());
    return allRoutes;
  }

  /// Vérifier si une route existe
  static bool routeExists(String routeName) {
    final allRoutes = getAllRoutes();
    return allRoutes.containsKey(routeName);
  }

  /// Obtenir les routes par module
  static Map<String, List<String>> getRoutesByModule() {
    final routesByModule = <String, List<String>>{};
    
    // Routes de base
    routesByModule['base'] = _baseRoutes.keys.toList();
    
    // Routes des modules
    for (final module in _moduleManager.getActiveModules()) {
      routesByModule[module.config.id] = module.routes.keys.toList();
    }
    
    return routesByModule;
  }
}

/// Middleware pour les routes
class RouteMiddleware {
  /// Vérifier l'authentification
  static bool checkAuth(String routeName) {
    // Implémentation de la vérification d'authentification
    // À adapter selon votre système d'authentification
    return true;
  }

  /// Vérifier les permissions
  static bool checkPermissions(String routeName, List<String> userRoles) {
    // Implémentation de la vérification des permissions
    // À adapter selon votre système de permissions
    return true;
  }

  /// Appliquer les middlewares à une route
  static bool applyMiddleware(String routeName, Map<String, dynamic> context) {
    // Vérifier l'authentification
    if (!checkAuth(routeName)) {
      NavigationService.navigateToReplacement('/login');
      return false;
    }

    // Vérifier les permissions
    final userRoles = context['userRoles'] as List<String>? ?? [];
    if (!checkPermissions(routeName, userRoles)) {
      NavigationService.showErrorSnackBar('Accès non autorisé');
      return false;
    }

    return true;
  }
}