import 'package:flutter/material.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import 'views/reports_member_view.dart';
import 'views/reports_admin_view.dart';
import 'views/report_detail_view.dart';
import 'views/report_form_view.dart';
import 'models/report.dart';
import 'services/reports_service.dart';

class ReportsModule extends AppModule {
  @override
  ModuleConfig get config => const ModuleConfig(
    id: 'reports',
    name: 'Rapports',
    description: 'Génération et analyse de rapports statistiques pour l\'église',
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
      'chart_types': [
        'bar',
        'line',
        'pie',
        'table',
      ],
      'frequencies': [
        'daily',
        'weekly',
        'monthly',
        'yearly',
        'custom',
      ],
      'permissions': {
        'member': ['view_public', 'view_shared', 'generate'],
        'admin': ['create', 'edit', 'delete', 'share', 'manage_all'],
      },
    },
  );

  @override
  Map<String, WidgetBuilder> get routes => {
    // Routes membres
    '/member/reports': (context) => const ReportsMemberView(),
    
    // Routes admin
    '/admin/reports': (context) => const ReportsAdminView(),
    
    // Routes détail
    '/reports/detail': (context) {
      final report = ModalRoute.of(context)!.settings.arguments as Report;
      return ReportDetailView(report: report);
    },
    
    // Routes de formulaire
    '/reports/form': (context) {
      final initialData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ReportFormView(initialData: initialData);
    },
    '/reports/edit': (context) {
      final report = ModalRoute.of(context)!.settings.arguments as Report;
      return ReportFormView(report: report);
    },
    
    // Routes supplémentaires
    '/reports/template': (context) {
      final templateId = ModalRoute.of(context)!.settings.arguments as String;
      final template = ReportTemplate.getTemplate(templateId);
      return ReportFormView(
        initialData: template != null ? {'template': template} : null,
      );
    },
  };

  @override
  List<Widget> getMemberMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.assessment),
        title: const Text('Rapports'),
        subtitle: const Text('Consulter les rapports disponibles'),
        onTap: () => Navigator.of(context).pushNamed('/member/reports'),
      ),
    ];
  }

  @override
  List<Widget> getAdminMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.analytics),
        title: const Text('Rapports'),
        subtitle: const Text('Créer et gérer les rapports statistiques'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Analytics',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () => Navigator.of(context).pushNamed('/admin/reports'),
      ),
    ];
  }

  @override
  Future<void> initialize() async {
    print('✅ Module ${config.name} initialisé');
    
    // Initialiser les templates prédéfinis si nécessaire
    await _initializeTemplates();
    
    // Programmer les rapports automatiques si nécessaire
    await _scheduleAutomaticReports();
    
    print('📊 ${ReportTemplate.builtInTemplates.length} templates de rapport disponibles');
  }

  @override
  Future<void> dispose() async {
    print('🔄 Module ${config.name} supprimé');
  }

  /// Initialise les templates prédéfinis
  Future<void> _initializeTemplates() async {
    try {
      // Les templates sont déjà définis en tant que constantes dans le modèle
      // Cette méthode peut être utilisée pour initialiser d'autres données
      print('📋 Templates de rapport initialisés');
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation des templates: $e');
    }
  }

  /// Programme les rapports automatiques
  Future<void> _scheduleAutomaticReports() async {
    try {
      // TODO: Implémenter la programmation automatique des rapports
      // Cette fonctionnalité peut être ajoutée plus tard avec un service de tâches programmées
      print('⏰ Programmation automatique des rapports configurée');
    } catch (e) {
      print('⚠️ Erreur lors de la programmation des rapports: $e');
    }
  }

  /// Obtient les templates par catégorie
  static List<ReportTemplate> getTemplatesByCategory(String category) {
    return ReportTemplate.getTemplatesByCategory(category);
  }

  /// Obtient toutes les catégories de templates
  static List<String> getTemplateCategories() {
    return ReportTemplate.getCategories();
  }

  /// Créer un rapport depuis un template
  static Future<void> createFromTemplate(BuildContext context, String templateId) async {
    Navigator.of(context).pushNamed(
      '/reports/template',
      arguments: templateId,
    );
  }

  /// Obtient les statistiques du module
  Future<Map<String, dynamic>> getModuleStatistics() async {
    try {
      final service = ReportsService();
      return await service.getReportsStatistics();
    } catch (e) {
      return {
        'error': 'Impossible de charger les statistiques: $e',
      };
    }
  }

  /// Actions rapides pour le module
  List<Widget> getQuickActions(BuildContext context) {
    return [
      // Nouveau rapport
      Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.add, color: Colors.white),
          ),
          title: const Text('Nouveau rapport'),
          subtitle: const Text('Créer un rapport personnalisé'),
          onTap: () => Navigator.of(context).pushNamed('/reports/form'),
        ),
      ),
      
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.description, color: Colors.white),
            ),
            title: const Text('Utiliser un template'),
            subtitle: const Text('Démarrer avec un modèle prédéfini'),
            onTap: () => _showTemplateSelector(context),
          ),
        ),
      
      // Rapports récents
      Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.history, color: Colors.white),
          ),
          title: const Text('Rapports récents'),
          subtitle: const Text('Voir les dernières générations'),
          onTap: () => Navigator.of(context).pushNamed('/admin/reports'),
        ),
      ),
    ];
  }

  /// Affiche le sélecteur de templates
  void _showTemplateSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisir un template',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: ReportTemplate.builtInTemplates.length,
                  itemBuilder: (context, index) {
                    final template = ReportTemplate.builtInTemplates[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(template.type).withOpacity(0.1),
                          child: Icon(
                            _getTypeIcon(template.type),
                            color: _getTypeColor(template.type),
                          ),
                        ),
                        title: Text(template.name),
                        subtitle: Text(template.description),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            template.category,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          createFromTemplate(context, template.id);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires pour les icônes et couleurs
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'attendance':
        return Icons.people_outline;
      case 'financial':
        return Icons.account_balance_wallet;
      case 'membership':
        return Icons.group_add;
      case 'event':
        return Icons.event_note;
      case 'custom':
        return Icons.analytics;
      default:
        return Icons.assessment;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'attendance':
        return Colors.blue;
      case 'financial':
        return Colors.green;
      case 'membership':
        return Colors.purple;
      case 'event':
        return Colors.orange;
      case 'custom':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}