import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_model.dart';
import '../services/services_firebase_service.dart';
import '../widgets/service_card.dart';
import '../widgets/service_search_filter_bar.dart';
import '../widgets/service_calendar_view.dart';
import 'service_detail_page.dart';
import 'service_form_page.dart';
import 'teams_management_page.dart';
import 'assignments_overview_page.dart';
import '../theme.dart';


class ServicesHomePage extends StatefulWidget {
  const ServicesHomePage({super.key});

  @override
  State<ServicesHomePage> createState() => _ServicesHomePageState();
}

class _ServicesHomePageState extends State<ServicesHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  List<String> _selectedTypeFilters = [];
  List<String> _selectedStatusFilters = ['publie', 'brouillon'];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCalendarView = false;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late TabController _tabController;
  
  List<ServiceModel> _selectedServices = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController.forward();
    
    // Set default date range (next 3 months)
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onFiltersChanged(List<String> typeFilters, List<String> statusFilters, DateTime? startDate, DateTime? endDate) {
    setState(() {
      _selectedTypeFilters = typeFilters;
      _selectedStatusFilters = statusFilters;
      _startDate = startDate;
      _endDate = endDate;
    });
  }

  void _toggleViewMode() {
    setState(() => _isCalendarView = !_isCalendarView);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedServices.clear();
      }
    });
  }

  void _onServiceSelected(ServiceModel service, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedServices.add(service);
      } else {
        _selectedServices.remove(service);
      }
    });
  }

  Future<void> _addNewService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServiceFormPage(),
      ),
    );
    
    if (result == true) {
      // Refresh will happen automatically through stream
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Service créé avec succès'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _navigateToTeamsManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeamsManagementPage(),
      ),
    );
  }

  Future<void> _navigateToAssignments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssignmentsOverviewPage(),
      ),
    );
  }

  Future<void> _navigateToStatistics() async {
    // TODO: Implement statistics page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité des statistiques en cours de développement')),
    );
  }

  Future<void> _performBulkAction(String action) async {
    switch (action) {
      case 'publish':
        await _publishSelectedServices();
        break;
      case 'archive':
        await _archiveSelectedServices();
        break;
      case 'duplicate':
        await _duplicateSelectedServices();
        break;
      case 'export':
        await _exportSelectedServices();
        break;
      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _publishSelectedServices() async {
    try {
      for (final service in _selectedServices) {
        if (service.isDraft) {
          await ServicesFirebaseService.updateService(
            service.copyWith(
              status: 'publie',
              updatedAt: DateTime.now(),
            )
          );
        }
      }
      setState(() {
        _selectedServices.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedServices.length} service(s) publié(s)'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _archiveSelectedServices() async {
    try {
      for (final service in _selectedServices) {
        await ServicesFirebaseService.archiveService(service.id);
      }
      setState(() {
        _selectedServices.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedServices.length} service(s) archivé(s)'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _duplicateSelectedServices() async {
    try {
      for (final service in _selectedServices) {
        final newDate = service.dateTime.add(const Duration(days: 7));
        await ServicesFirebaseService.duplicateService(
          service.id,
          '${service.name} (Copie)',
          newDate,
        );
      }
      setState(() {
        _selectedServices.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedServices.length} service(s) dupliqué(s)'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _exportSelectedServices() async {
    try {
      // Export functionality would be implemented here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export de ${_selectedServices.length} service(s) en cours...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedServices.length} service(s) ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final service in _selectedServices) {
          await ServicesFirebaseService.deleteService(service.id);
        }
        setState(() {
          _selectedServices.clear();
          _isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedServices.length} service(s) supprimé(s)'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and view toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_isSelectionMode) ...[
                    IconButton(
                      onPressed: _toggleSelectionMode,
                      icon: const Icon(Icons.close),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedServices.length} sélectionné(s)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedServices.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _performBulkAction('publish'),
                        icon: const Icon(Icons.publish),
                        tooltip: 'Publier',
                      ),
                      IconButton(
                        onPressed: () => _performBulkAction('duplicate'),
                        icon: const Icon(Icons.copy),
                        tooltip: 'Dupliquer',
                      ),
                      IconButton(
                        onPressed: () => _performBulkAction('archive'),
                        icon: const Icon(Icons.archive),
                        tooltip: 'Archiver',
                      ),
                      IconButton(
                        onPressed: () => _performBulkAction('delete'),
                        icon: const Icon(Icons.delete),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_note,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Services',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Planification et gestion des services',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleViewMode,
                      icon: Icon(_isCalendarView ? Icons.view_list : Icons.calendar_month),
                      tooltip: _isCalendarView ? 'Vue liste' : 'Vue calendrier',
                    ),
                    IconButton(
                      onPressed: _toggleSelectionMode,
                      icon: const Icon(Icons.checklist),
                      tooltip: 'Mode sélection',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Options',
                      onSelected: (value) {
                        switch (value) {
                          case 'teams':
                            _navigateToTeamsManagement();
                            break;
                          case 'assignments':
                            _navigateToAssignments();
                            break;
                          case 'statistics':
                            _navigateToStatistics();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'teams',
                          child: ListTile(
                            leading: Icon(Icons.groups),
                            title: Text('Gérer les équipes'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'assignments',
                          child: ListTile(
                            leading: Icon(Icons.assignment_ind),
                            title: Text('Assignations'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'statistics',
                          child: ListTile(
                            leading: Icon(Icons.analytics),
                            title: Text('Statistiques'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Search and filter bar
            ServiceSearchFilterBar(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onFiltersChanged: _onFiltersChanged,
              selectedTypeFilters: _selectedTypeFilters,
              selectedStatusFilters: _selectedStatusFilters,
              startDate: _startDate,
              endDate: _endDate,
            ),

            // Content
            Expanded(
              child: StreamBuilder<List<ServiceModel>>(
                stream: ServicesFirebaseService.getServicesStream(
                  searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                  typeFilters: _selectedTypeFilters.isEmpty ? null : _selectedTypeFilters,
                  statusFilters: _selectedStatusFilters.isEmpty ? null : _selectedStatusFilters,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur lors du chargement',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final services = snapshot.data!;

                  if (services.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_note,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucun service trouvé',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez par créer votre premier service',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _addNewService,
                            icon: const Icon(Icons.add),
                            label: const Text('Créer un service'),
                          ),
                        ],
                      ),
                    );
                  }

                  return _isCalendarView 
                      ? ServiceCalendarView(
                          services: services,
                          onServiceTap: _onServiceTap,
                          onServiceLongPress: _onServiceLongPress,
                          isSelectionMode: _isSelectionMode,
                          selectedServices: _selectedServices,
                          onSelectionChanged: _onServiceSelected,
                        )
                      : _buildListView(services);
                },
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: _isSelectionMode 
          ? null 
          : ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: _addNewService,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau Service'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
    );
  }

  Widget _buildListView(List<ServiceModel> services) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ServiceCard(
            service: service,
            onTap: () => _onServiceTap(service),
            onLongPress: () => _onServiceLongPress(service),
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedServices.contains(service),
            onSelectionChanged: (isSelected) => _onServiceSelected(service, isSelected),
          ),
        );
      },
    );
  }

  void _onServiceTap(ServiceModel service) {
    if (_isSelectionMode) {
      _onServiceSelected(service, !_selectedServices.contains(service));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceDetailPage(service: service),
        ),
      );
    }
  }

  void _onServiceLongPress(ServiceModel service) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onServiceSelected(service, true);
    }
  }
}