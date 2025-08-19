import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/service_template.dart';
import '../services/services_service.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../extensions/datetime_extensions.dart';

/// Vue administrateur pour les services
class ServicesAdminView extends StatefulWidget {
  const ServicesAdminView({Key? key}) : super(key: key);

  @override
  State<ServicesAdminView> createState() => _ServicesAdminViewState();
}

class _ServicesAdminViewState extends State<ServicesAdminView>
    with SingleTickerProviderStateMixin {
  final ServicesService _servicesService = ServicesService();
  late TabController _tabController;
  
  List<Service> _allServices = [];
  List<ServiceTemplate> _templates = [];
  Map<String, dynamic> _statistics = {};
  
  bool _isLoading = true;
  String _searchQuery = '';
  ServiceType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final services = await _servicesService.getAll();
      final templates = await _servicesService.getServiceTemplates();
      final stats = await _servicesService.getServiceStatistics();
      
      setState(() {
        _allServices = services;
        _templates = templates;
        _statistics = stats;
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

  List<Service> _filterServices() {
    var filtered = _allServices;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((service) {
        return service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               service.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               service.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_selectedType != null) {
      filtered = filtered.where((service) {
        return service.type == _selectedType;
      }).toList();
    }
    
    return filtered..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Gestion des Services',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).pushNamed('/service/form').then((_) => _loadData());
          },
        ),
      ],
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildStatisticsTab(),
                _buildTemplatesTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Services', icon: Icon(Icons.event)),
          Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
          Tab(text: 'Modèles', icon: Icon(Icons.description)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher des services...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() => _selectedType = null);
                  },
                ),
                const SizedBox(width: 8),
                ...ServiceType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.displayName),
                      selected: _selectedType == type,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredServices = _filterServices();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Statistiques rapides
          _buildQuickStats(),
          
          // Liste des services
          Expanded(
            child: filteredServices.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun service trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return _buildServiceCard(service);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_statistics.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              'Total',
              _statistics['total']?.toString() ?? '0',
              Icons.event,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              'À venir',
              _statistics['upcoming']?.toString() ?? '0',
              Icons.schedule,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              'Aujourd\'hui',
              _statistics['today']?.toString() ?? '0',
              Icons.today,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              'Cette semaine',
              _statistics['thisWeek']?.toString() ?? '0',
              Icons.date_range,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: service.colorCode != null
              ? Color(int.parse(service.colorCode!.replaceFirst('#', '0xff')))
              : Theme.of(context).primaryColor,
          child: Text(
            service.type.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.type.displayName),
            Text(
              '${_formatDateTime(service.startDate)} • ${service.location}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(service.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service.statusDisplay,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleServiceAction(value, service),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Voir détails'),
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
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Dupliquer'),
              ),
            ),
            if (service.status == ServiceStatus.scheduled)
              const PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Annuler'),
                ),
              ),
            if (service.status == ServiceStatus.inProgress)
              const PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(Icons.check, color: Colors.green),
                  title: Text('Terminer'),
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer'),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed(
            '/service/detail',
            arguments: service,
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStats(),
            const SizedBox(height: 24),
            _buildServiceTypeStats(),
            const SizedBox(height: 24),
            _buildLocationStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Générales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Services',
                    _statistics['total']?.toString() ?? '0',
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'À venir',
                    _statistics['upcoming']?.toString() ?? '0',
                    Icons.schedule,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Terminés',
                    _statistics['past']?.toString() ?? '0',
                    Icons.done,
                    Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Durée moyenne',
                    '${(_statistics['averageDuration'] ?? 0).toInt()} min',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeStats() {
    final byType = Map<String, int>.from(_statistics['byType'] ?? {});
    
    if (byType.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...byType.entries.map((entry) {
              final total = _statistics['total'] as int? ?? 1;
              final percentage = (entry.value / total * 100).toInt();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value} ($percentage%)'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStats() {
    final byLocation = Map<String, int>.from(_statistics['byLocation'] ?? {});
    
    if (byLocation.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lieux les plus utilisés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...byLocation.entries.take(5).map((entry) {
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(entry.key),
                trailing: Chip(
                  label: Text(entry.value.toString()),
                  backgroundColor: Theme.of(context).primaryColor,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Modèles de Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers création de modèle
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _templates.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun modèle créé',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Créez des modèles pour faciliter la création de services récurrents.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return _buildTemplateCard(template);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ServiceTemplate template) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: template.colorCode != null
              ? Color(int.parse(template.colorCode!.replaceFirst('#', '0xff')))
              : Theme.of(context).primaryColor,
          child: Text(
            template.type.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.type.displayName),
            Text(
              '${template.formattedDuration} • ${template.location}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _createServiceFromTemplate(template),
              tooltip: 'Créer un service',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleTemplateAction(value, template),
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
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleServiceAction(String action, Service service) {
    switch (action) {
      case 'view':
        Navigator.of(context).pushNamed('/service/detail', arguments: service);
        break;
      case 'edit':
        Navigator.of(context).pushNamed('/service/form', arguments: service)
            .then((_) => _loadData());
        break;
      case 'duplicate':
        _duplicateService(service);
        break;
      case 'cancel':
        _cancelService(service);
        break;
      case 'complete':
        _completeService(service);
        break;
      case 'delete':
        _deleteService(service);
        break;
    }
  }

  void _handleTemplateAction(String action, ServiceTemplate template) {
    switch (action) {
      case 'edit':
        // TODO: Naviguer vers édition de modèle
        break;
      case 'duplicate':
        // TODO: Dupliquer le modèle
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  Future<void> _duplicateService(Service service) async {
    try {
      await _servicesService.duplicateService(service.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service dupliqué avec succès')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _cancelService(Service service) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Êtes-vous sûr de vouloir annuler "${service.name}" ?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Raison de l\'annulation (optionnel)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('cancelled'),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result == 'cancelled') {
      try {
        await _servicesService.cancelService(service.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service annulé')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _completeService(Service service) async {
    try {
      await _servicesService.completeService(service.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service marqué comme terminé')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deleteService(Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le service'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${service.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _servicesService.delete(service.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service supprimé')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(ServiceTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le modèle'),
        content: Text('Êtes-vous sûr de vouloir supprimer le modèle "${template.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implémenter suppression de modèle
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modèle supprimé')),
      );
      _loadData();
    }
  }

  Future<void> _createServiceFromTemplate(ServiceTemplate template) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (selectedTime != null) {
        final startDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        try {
          await _servicesService.createServiceFromTemplate(
            templateId: template.id!,
            startDate: startDateTime,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service créé à partir du modèle')),
          );
          _loadData();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.shortDateTime;
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
}