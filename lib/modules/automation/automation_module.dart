import 'package:flutter/material.dart';
import '../../core/module_manager.dart';
import '../../config/app_modules.dart';
import 'views/automation_member_view.dart';
import 'views/automation_admin_view.dart';
import 'views/automation_detail_view.dart';
import 'views/automation_form_view.dart';
import 'views/automation_execution_detail_view.dart';
import 'services/automation_service.dart';

/// Module d'automatisation inspiré de Planning Center Online
class AutomationModule extends BaseModule {
  static const String moduleId = 'automation';
  
  late final AutomationService _automationService;

  AutomationModule() : super(_getModuleConfig());

  static ModuleConfig _getModuleConfig() {
    return AppModulesConfig.getModule(moduleId) ?? 
        const ModuleConfig(
          id: moduleId,
          name: 'Automatisation',
          description: 'Automatisations et workflows intelligents pour optimiser la gestion de l\'église',
          icon: 'auto_awesome',
          isEnabled: true,
          permissions: [ModulePermission.admin, ModulePermission.member],
        );
  }

  @override
  Map<String, WidgetBuilder> get routes => {
    '/member/automation': (context) => const AutomationMemberView(),
    '/admin/automation': (context) => const AutomationAdminView(),
    '/automation/detail': (context) {
      final automation = ModalRoute.of(context)?.settings.arguments;
      return AutomationDetailView(automation: automation as dynamic);
    },
    '/automation/form': (context) => const AutomationFormView(),
    '/automation/edit': (context) {
      final automation = ModalRoute.of(context)?.settings.arguments;
      return AutomationFormView(
        automation: automation as dynamic,
        isEdit: true,
      );
    },
    '/automation/execution': (context) {
      final execution = ModalRoute.of(context)?.settings.arguments;
      return AutomationExecutionDetailView(execution: execution as dynamic);
    },
  };

  @override
  Future<void> initialize() async {
    await super.initialize();
    _automationService = AutomationService();
    await _automationService.initialize();
    print('✅ Module Automatisation initialisé avec succès');
  }

  @override
  Future<void> dispose() async {
    await _automationService.dispose();
    await super.dispose();
    print('🔧 Module Automatisation fermé');
  }

  /// Obtient le service d'automatisation
  AutomationService get automationService => _automationService;

  @override
  Widget buildDashboardWidget(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _automationService.getAutomationStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Automatisations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stats['active'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'Actives',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stats['totalExecutions'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'Exécutions',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(stats['averageSuccessRate'] ?? 0.0).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Text(
                          'Succès',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/admin/automation');
                    },
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Gérer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Vue de détail d'une exécution d'automatisation
class AutomationExecutionDetailView extends StatelessWidget {
  final dynamic execution;

  const AutomationExecutionDetailView({
    Key? key,
    required this.execution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'Exécution'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatisation: ${execution?.automationName ?? "Inconnu"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Statut', '${execution?.status?.label ?? "Inconnu"}'),
                    _buildInfoRow('Déclenchée le', _formatDateTime(execution?.triggeredAt)),
                    if (execution?.startedAt != null)
                      _buildInfoRow('Démarrée le', _formatDateTime(execution.startedAt)),
                    if (execution?.completedAt != null)
                      _buildInfoRow('Terminée le', _formatDateTime(execution.completedAt)),
                    if (execution?.totalExecutionDuration != null)
                      _buildInfoRow('Durée', '${execution.totalExecutionDuration.inSeconds}s'),
                    _buildInfoRow('Type', execution?.isManual == true ? 'Manuel' : 'Automatique'),
                    if (execution?.error != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Erreur:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        execution.error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (execution?.actionExecutions?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              const Text(
                'Actions Exécutées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...execution.actionExecutions.map((actionExecution) => 
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: actionExecution.isSuccessful ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(actionExecution.actionType),
                    subtitle: Text(
                      actionExecution.isSuccessful 
                          ? 'Succès' 
                          : actionExecution.error ?? 'Échec',
                    ),
                    trailing: actionExecution.executionDuration != null
                        ? Text('${actionExecution.executionDuration!.inMilliseconds}ms')
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Non défini';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}