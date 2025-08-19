import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/service_assignment.dart';
import '../services/services_service.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../extensions/datetime_extensions.dart';

/// Vue de détail d'un service
class ServiceDetailView extends StatefulWidget {
  final Service? service;

  const ServiceDetailView({Key? key, this.service}) : super(key: key);

  @override
  State<ServiceDetailView> createState() => _ServiceDetailViewState();
}

class _ServiceDetailViewState extends State<ServiceDetailView>
    with SingleTickerProviderStateMixin {
  final ServicesService _servicesService = ServicesService();
  late TabController _tabController;
  
  Service? _service;
  List<ServiceAssignment> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service = widget.service;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_service?.id == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final assignments = await _servicesService.getServiceAssignments(_service!.id!);
      
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return const BasePage(
        title: 'Service',
        body: Center(
          child: Text('Service introuvable'),
        ),
      );
    }

    return BasePage(
      title: _service!.name,
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Dupliquer'),
              ),
            ),
            if (_service!.status == ServiceStatus.scheduled)
              const PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Annuler'),
                ),
              ),
            if (_service!.status == ServiceStatus.inProgress)
              const PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(Icons.check, color: Colors.green),
                  title: Text('Terminer'),
                ),
              ),
          ],
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildAssignmentsTab(),
                _buildLogisticsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Détails', icon: Icon(Icons.info)),
          Tab(text: 'Équipe', icon: Icon(Icons.people)),
          Tab(text: 'Logistique', icon: Icon(Icons.build)),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image d'en-tête
          if (_service!.imageUrl != null)
            CustomCard(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _service!.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Informations principales
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _service!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_service!.status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _service!.statusDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Chip(
                    label: Text(_service!.type.displayName),
                    backgroundColor: _service!.colorCode != null
                        ? Color(int.parse(_service!.colorCode!.replaceFirst('#', '0xff')))
                        : Theme.of(context).primaryColor,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_service!.description.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_service!.description),
                    const SizedBox(height: 16),
                  ],
                  
                  // Détails temporels
                  _buildDetailRow(
                    'Date et heure',
                    '${_formatDateTime(_service!.startDate)} - ${_formatTime(_service!.endDate)}',
                    Icons.access_time,
                  ),
                  
                  _buildDetailRow(
                    'Durée',
                    _formatDuration(_service!.duration),
                    Icons.timer,
                  ),
                  
                  _buildDetailRow(
                    'Lieu',
                    _service!.location,
                    Icons.location_on,
                  ),
                  
                  if (_service!.isStreamingEnabled) ...[
                    _buildDetailRow(
                      'Diffusion en ligne',
                      _service!.streamingUrl ?? 'Activée',
                      Icons.live_tv,
                    ),
                  ],
                  
                  if (_service!.isRecurring) ...[
                    _buildDetailRow(
                      'Récurrence',
                      'Service récurrent',
                      Icons.repeat,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notes
          if (_service!.notes != null && _service!.notes!.isNotEmpty)
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_service!.notes!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Équipe assignée (${_assignments.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAssignMemberDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assigner'),
                ),
              ],
            ),
          ),
          
          // Liste des assignations
          Expanded(
            child: _assignments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune assignation',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Commencez par assigner des membres à ce service.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = _assignments[index];
                      return _buildAssignmentCard(assignment);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Équipements nécessaires
          if (_service!.equipmentNeeded.isNotEmpty)
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Équipements nécessaires',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _service!.equipmentNeeded.map((equipment) {
                        return Chip(
                          label: Text(equipment),
                          backgroundColor: Colors.blue[100],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Paramètres techniques
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration technique',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_service!.isStreamingEnabled) ...[
                    ListTile(
                      leading: const Icon(Icons.live_tv, color: Colors.red),
                      title: const Text('Diffusion en ligne'),
                      subtitle: Text(_service!.streamingUrl ?? 'URL non spécifiée'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  
                  ListTile(
                    leading: Icon(
                      _service!.isRecurring ? Icons.repeat : Icons.event,
                      color: Colors.blue,
                    ),
                    title: Text(_service!.isRecurring ? 'Service récurrent' : 'Service unique'),
                    subtitle: _service!.isRecurring && _service!.recurrencePattern != null
                        ? Text('Récurrence: ${_service!.recurrencePattern!.type.name}')
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques de participation (placeholder)
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Participation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.green),
                    title: const Text('Membres assignés'),
                    trailing: Text(
                      _assignments.length.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.blue),
                    title: const Text('Confirmations'),
                    trailing: Text(
                      _assignments.where((a) => a.status == AssignmentStatus.confirmed).length.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.pending, color: Colors.orange),
                    title: const Text('En attente'),
                    trailing: Text(
                      _assignments.where((a) => a.status == AssignmentStatus.pending).length.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(ServiceAssignment assignment) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(assignment.statusColor.replaceFirst('#', '0xff'))),
          child: Icon(
            _getAssignmentStatusIcon(assignment.status),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              assignment.memberName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (assignment.isTeamLead) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 16, color: Colors.amber),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.role),
            if (assignment.responsibilities.isNotEmpty)
              Text(
                assignment.responsibilities.join(', '),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (assignment.notes != null && assignment.notes!.isNotEmpty)
              Text(
                assignment.notes!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAssignmentAction(value, assignment),
          itemBuilder: (context) => [
            if (assignment.status == AssignmentStatus.pending)
              const PopupMenuItem(
                value: 'confirm',
                child: ListTile(
                  leading: Icon(Icons.check, color: Colors.green),
                  title: Text('Confirmer'),
                ),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text('Retirer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.of(context).pushNamed('/service/form', arguments: _service)
            .then((_) => _loadData());
        break;
      case 'duplicate':
        _duplicateService();
        break;
      case 'cancel':
        _cancelService();
        break;
      case 'complete':
        _completeService();
        break;
    }
  }

  void _handleAssignmentAction(String action, ServiceAssignment assignment) {
    switch (action) {
      case 'confirm':
        _confirmAssignment(assignment);
        break;
      case 'edit':
        _editAssignment(assignment);
        break;
      case 'remove':
        _removeAssignment(assignment);
        break;
    }
  }

  Future<void> _duplicateService() async {
    try {
      await _servicesService.duplicateService(_service!.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service dupliqué avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _cancelService() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le service'),
        content: Text('Êtes-vous sûr de vouloir annuler "${_service!.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _servicesService.cancelService(_service!.id!);
        setState(() {
          _service = _service!.copyWith(status: ServiceStatus.cancelled);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service annulé')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _completeService() async {
    try {
      await _servicesService.completeService(_service!.id!);
      setState(() {
        _service = _service!.copyWith(status: ServiceStatus.completed);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service marqué comme terminé')),
      );
      _loadData(); // Recharger pour voir les assignations mises à jour
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _confirmAssignment(ServiceAssignment assignment) async {
    try {
      await _servicesService.updateAssignmentStatus(
        assignment.id!,
        AssignmentStatus.confirmed,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignation confirmée')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _editAssignment(ServiceAssignment assignment) {
    // TODO: Implémenter l'édition d'assignation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  Future<void> _removeAssignment(ServiceAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'assignation'),
        content: Text('Êtes-vous sûr de vouloir retirer ${assignment.memberName} de ce service ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _servicesService.removeAssignment(assignment.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignation supprimée')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showAssignMemberDialog() {
    // TODO: Implémenter le dialogue d'assignation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.relativeDateTime;
  }

  String _formatTime(DateTime dateTime) {
    return dateTime.timeOnly;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return Colors.blue;
      case ServiceStatus.inProgress:
        return Colors.green;
      case ServiceStatus.completed:
        return Colors.grey;
      case ServiceStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getAssignmentStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return Icons.hourglass_empty;
      case AssignmentStatus.confirmed:
        return Icons.check_circle;
      case AssignmentStatus.declined:
        return Icons.cancel;
      case AssignmentStatus.completed:
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }
}