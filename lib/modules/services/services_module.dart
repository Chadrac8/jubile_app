import 'package:flutter/material.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import '../../shared/widgets/custom_card.dart';
import 'models/service.dart';
import 'views/services_member_view.dart';
import 'views/services_admin_view.dart';
import 'views/service_detail_view.dart';
import 'views/service_form_view.dart';
import 'services/services_service.dart';

/// Module de gestion des services religieux
class ServicesModule extends BaseModule {
  static const String moduleId = 'services';
  
  late final ServicesService _servicesService;

  ServicesModule() : super(_getModuleConfig());

  static ModuleConfig _getModuleConfig() {
    return AppModulesConfig.getModule(moduleId) ?? 
        const ModuleConfig(
          id: moduleId,
          name: 'Services',
          description: 'Gestion des services et cultes religieux',
          icon: 'church',
          isEnabled: true,
          permissions: [ModulePermission.admin, ModulePermission.member],
        );
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/member/services': (context) => const ServicesMemberView(),
    '/admin/services': (context) => const ServicesAdminView(),
    '/service/detail': (context) => ServiceDetailView(
      service: ModalRoute.of(context)?.settings.arguments as Service?,
    ),
    '/service/form': (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Service) {
        return ServiceFormView(service: args, isEdit: true);
      }
      return const ServiceFormView();
    },
    '/service/edit': (context) => ServiceFormView(
      service: ModalRoute.of(context)?.settings.arguments as Service?,
      isEdit: true,
    ),
  };

  @override
  Future<void> initialize() async {
    try {
      _servicesService = ServicesService();
      
      // Initialisation des données de base si nécessaire
      await _initializeDefaultData();
      
      print('✅ Module Services initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du module Services: $e');
      rethrow;
    }
  }

  @override
  Widget buildModuleCard(BuildContext context) {
    return CustomCard(
      child: InkWell(
        onTap: () => _navigateToModule(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.church,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          config.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Statistics
              FutureBuilder<Map<String, dynamic>>(
                future: _getQuickStats(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildStatChips(context, snapshot.data!);
                  }
                  return const SizedBox(height: 20);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChips(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        _buildStatChip(
          context,
          'Total',
          stats['total']?.toString() ?? '0',
          Icons.event,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          'À venir',
          stats['upcoming']?.toString() ?? '0',
          Icons.schedule,
          Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          'Aujourd\'hui',
          stats['today']?.toString() ?? '0',
          Icons.today,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context) {
    // TODO: Déterminer le rôle de l'utilisateur et naviguer vers la vue appropriée
    // Pour l'instant, on navigue vers la vue membre
    Navigator.of(context).pushNamed('/member/services');
  }

  Future<Map<String, dynamic>> _getQuickStats() async {
    try {
      return await _servicesService.getServiceStatistics();
    } catch (e) {
      print('Erreur lors du chargement des statistiques Services: $e');
      return {
        'total': 0,
        'upcoming': 0,
        'today': 0,
      };
    }
  }

  Future<void> _initializeDefaultData() async {
    try {
      // Vérifier s'il y a déjà des services
      final existingServices = await _servicesService.getAll();
      
      if (existingServices.isEmpty) {
        // Créer quelques services d'exemple
        await _createDefaultServices();
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des données par défaut: $e');
    }
  }

  Future<void> _createDefaultServices() async {
    try {
      final now = DateTime.now();
      final sunday = now.add(Duration(days: (7 - now.weekday) % 7));
      
      // Service de culte dominical
      final worshipService = Service(
        name: 'Culte dominical',
        description: 'Service de louange et prédication hebdomadaire',
        type: ServiceType.worship,
        startDate: DateTime(sunday.year, sunday.month, sunday.day, 10, 0),
        endDate: DateTime(sunday.year, sunday.month, sunday.day, 12, 0),
        location: 'Sanctuaire principal',
        isRecurring: true,
        equipmentNeeded: ['Micro-casque', 'Piano', 'Projecteur', 'Enceintes'],
        colorCode: '#2196F3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );

      // Réunion de prière
      final prayerService = Service(
        name: 'Réunion de prière',
        description: 'Temps de prière et d\'intercession',
        type: ServiceType.prayer,
        startDate: DateTime(sunday.year, sunday.month, sunday.day + 3, 19, 0),
        endDate: DateTime(sunday.year, sunday.month, sunday.day + 3, 20, 30),
        location: 'Salle de prière',
        isRecurring: true,
        equipmentNeeded: ['Micro main', 'Chaises'],
        colorCode: '#4CAF50',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );

      // École du dimanche
      final childrenService = Service(
        name: 'École du dimanche',
        description: 'Enseignement biblique pour les enfants',
        type: ServiceType.children,
        startDate: DateTime(sunday.year, sunday.month, sunday.day, 9, 0),
        endDate: DateTime(sunday.year, sunday.month, sunday.day, 10, 0),
        location: 'Salle des enfants',
        isRecurring: true,
        equipmentNeeded: ['Projecteur', 'Chaises', 'Tables', 'Tableau'],
        colorCode: '#FF9800',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'system',
      );

      await _servicesService.createService(worshipService);
      await _servicesService.createService(prayerService);
      await _servicesService.createService(childrenService);

      print('✅ Services d\'exemple créés avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création des services d\'exemple: $e');
    }
  }

  @override
  bool get isEnabled => config.isEnabled;

  @override
  bool hasPermission(ModulePermission permission) {
    return config.hasPermission(permission);
  }

  @override
  List<String> get requiredPermissions => ['firebase_auth', 'firestore'];

  @override
  String get version => '1.0.0';

  @override
  Map<String, dynamic> get metadata => {
    'author': 'ChurchFlow Team',
    'description': 'Module complet de gestion des services religieux',
    'features': [
      'Création et gestion de services',
      'Système d\'assignations',
      'Modèles de services',
      'Récurrence automatique',
      'Diffusion en ligne',
      'Statistiques détaillées',
      'Gestion d\'équipements',
    ],
    'models': ['Service', 'ServiceAssignment', 'ServiceTemplate'],
    'views': ['ServicesMemberView', 'ServicesAdminView', 'ServiceDetailView', 'ServiceFormView'],
    'routes': [
      '/member/services',
      '/admin/services',
      '/service/detail',
      '/service/form',
      '/service/edit',
    ],
  };

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final stats = await _servicesService.getServiceStatistics();
      final assignmentStats = await _servicesService.getAssignmentStatistics();
      
      return {
        'status': 'healthy',
        'services': {
          'total': stats['total'],
          'upcoming': stats['upcoming'],
          'past': stats['past'],
        },
        'assignments': {
          'total': assignmentStats['total'],
          'confirmed': assignmentStats['byStatus']?['Confirmé'] ?? 0,
          'pending': assignmentStats['byStatus']?['En attente'] ?? 0,
        },
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<void> cleanup() async {
    try {
      // Nettoyage des ressources si nécessaire
      print('🧹 Nettoyage du module Services terminé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage du module Services: $e');
    }
  }
}

/// Extensions pour faciliter l'utilisation du module
extension ServicesModuleExtension on ServicesModule {
  /// Obtient le service ServicesService
  ServicesService get servicesService => _servicesService;

  /// Navigue vers la liste des services
  void navigateToServices(BuildContext context, {bool isAdmin = false}) {
    Navigator.of(context).pushNamed(
      isAdmin ? '/admin/services' : '/member/services',
    );
  }

  /// Navigue vers le détail d'un service
  void navigateToServiceDetail(BuildContext context, Service service) {
    Navigator.of(context).pushNamed('/service/detail', arguments: service);
  }

  /// Navigue vers le formulaire de création de service
  void navigateToCreateService(BuildContext context) {
    Navigator.of(context).pushNamed('/service/form');
  }

  /// Navigue vers le formulaire d'édition de service
  void navigateToEditService(BuildContext context, Service service) {
    Navigator.of(context).pushNamed('/service/edit', arguments: service);
  }
}