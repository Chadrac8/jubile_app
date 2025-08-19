import 'package:flutter/material.dart';
import '../models/automation.dart';
import '../models/automation_execution.dart';
import '../services/automation_service.dart';
import '../../../theme.dart';
import '../../../widgets/custom_card.dart';

/// Vue membre pour les automatisations
class AutomationMemberView extends StatefulWidget {
  const AutomationMemberView({Key? key}) : super(key: key);

  @override
  State<AutomationMemberView> createState() => _AutomationMemberViewState();
}

class _AutomationMemberViewState extends State<AutomationMemberView> {
  final AutomationService _automationService = AutomationService();
  List<Automation> _automations = [];
  List<AutomationExecution> _recentExecutions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final automations = await _automationService.getActiveAutomations();
      final executions = await _automationService.executionService.getRecentExecutions(limit: 20);
      
      setState(() {
        _automations = automations;
        _recentExecutions = executions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Automation> get _filteredAutomations {
    if (_searchQuery.isEmpty) return _automations;
    
    return _automations.where((automation) =>
      automation.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      automation.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      automation.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildStatsCards(),
                const SizedBox(height: 20),
                _buildActiveAutomations(),
                const SizedBox(height: 20),
                _buildRecentActivity(),
              ],
            ),
          );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher une automatisation...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalExecutions = _recentExecutions.length;
    final successfulExecutions = _recentExecutions
        .where((e) => e.status == ExecutionStatus.completed)
        .length;
    final failedExecutions = _recentExecutions
        .where((e) => e.status == ExecutionStatus.failed)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Automatisations\nActives',
              '${_automations.length}',
              Icons.auto_awesome,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Exécutions\nRéussies',
              '$successfulExecutions',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Échecs\nRécents',
              '$failedExecutions',
              Icons.error,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAutomations() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Automatisations Actives',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_filteredAutomations.length} automatisation(s)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredAutomations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Aucune automatisation active'
                              : 'Aucun résultat pour "$_searchQuery"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredAutomations.length,
                    itemBuilder: (context, index) {
                      final automation = _filteredAutomations[index];
                      return _buildAutomationCard(automation);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationCard(Automation automation) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAutomationDetails(automation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTriggerColor(automation.trigger).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTriggerIcon(automation.trigger),
                      color: _getTriggerColor(automation.trigger),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          automation.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          automation.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: automation.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      automation.status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (automation.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: automation.tags.take(3).map((tag) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${automation.executionCount} exécutions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${automation.successRate.toStringAsFixed(1)}% succès',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (automation.lastExecutedAt != null)
                    Text(
                      _formatLastExecution(automation.lastExecutedAt!),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Activité Récente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: _recentExecutions.isEmpty
              ? Center(
                  child: Text(
                    'Aucune activité récente',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentExecutions.take(10).length,
                  itemBuilder: (context, index) {
                    final execution = _recentExecutions[index];
                    return _buildExecutionCard(execution);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExecutionCard(AutomationExecution execution) {
    final statusColor = _getExecutionStatusColor(execution.status);
    
    return CustomCard(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _showExecutionDetails(execution),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      execution.automationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                execution.statusMessage,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                _formatDateTime(execution.triggeredAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutomationDetails(Automation automation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(automation.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(automation.description),
              const SizedBox(height: 16),
              _buildDetailRow('Déclencheur', automation.trigger.label),
              _buildDetailRow('Statut', automation.status.label),
              _buildDetailRow('Actions', '${automation.actions.length} action(s)'),
              _buildDetailRow('Exécutions', '${automation.executionCount}'),
              _buildDetailRow('Taux de succès', '${automation.successRate.toStringAsFixed(1)}%'),
              if (automation.lastExecutedAt != null)
                _buildDetailRow('Dernière exécution', _formatDateTime(automation.lastExecutedAt!)),
              if (automation.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: automation.tags.map((tag) =>
                    Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showExecutionDetails(AutomationExecution execution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exécution: ${execution.automationName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Statut', execution.statusMessage),
              _buildDetailRow('Déclenchée le', _formatDateTime(execution.triggeredAt)),
              if (execution.startedAt != null)
                _buildDetailRow('Démarrée le', _formatDateTime(execution.startedAt!)),
              if (execution.completedAt != null)
                _buildDetailRow('Terminée le', _formatDateTime(execution.completedAt!)),
              if (execution.totalExecutionDuration != null)
                _buildDetailRow('Durée', '${execution.totalExecutionDuration!.inSeconds}s'),
              _buildDetailRow('Actions', '${execution.actionExecutions.length}'),
              _buildDetailRow('Actions réussies', '${execution.successfulActionsCount}'),
              if (execution.failedActionsCount > 0)
                _buildDetailRow('Actions échouées', '${execution.failedActionsCount}'),
              if (execution.error != null) ...[
                const SizedBox(height: 8),
                const Text('Erreur:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                const SizedBox(height: 4),
                Text(execution.error!, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Color _getTriggerColor(AutomationTrigger trigger) {
    switch (trigger) {
      case AutomationTrigger.personAdded:
        return Colors.blue;
      case AutomationTrigger.groupJoined:
        return Colors.green;
      case AutomationTrigger.eventRegistered:
        return Colors.orange;
      case AutomationTrigger.serviceAssigned:
        return Colors.purple;
      case AutomationTrigger.dateScheduled:
        return Colors.teal;
      case AutomationTrigger.prayerRequest:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getTriggerIcon(AutomationTrigger trigger) {
    switch (trigger) {
      case AutomationTrigger.personAdded:
        return Icons.person_add;
      case AutomationTrigger.groupJoined:
        return Icons.group_add;
      case AutomationTrigger.eventRegistered:
        return Icons.event;
      case AutomationTrigger.serviceAssigned:
        return Icons.church;
      case AutomationTrigger.dateScheduled:
        return Icons.schedule;
      case AutomationTrigger.prayerRequest:
        return Icons.volunteer_activism;
      default:
        return Icons.auto_awesome;
    }
  }

  Color _getExecutionStatusColor(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.completed:
        return Colors.green;
      case ExecutionStatus.failed:
        return Colors.red;
      case ExecutionStatus.running:
        return Colors.blue;
      case ExecutionStatus.pending:
        return Colors.orange;
      case ExecutionStatus.cancelled:
        return Colors.grey;
      case ExecutionStatus.skipped:
        return Colors.yellow[700]!;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  String _formatLastExecution(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}