import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../widgets/event_card.dart';
import '../widgets/event_search_filter_bar.dart';
import '../widgets/event_calendar_view.dart';
import 'event_detail_page.dart';
import 'event_form_page.dart';
import '../theme.dart';


class EventsHomePage extends StatefulWidget {
  const EventsHomePage({super.key});

  @override
  State<EventsHomePage> createState() => _EventsHomePageState();
}

class _EventsHomePageState extends State<EventsHomePage>
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
  
  List<EventModel> _selectedEvents = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _tabController.dispose();
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
        _selectedEvents.clear();
      }
    });
  }

  void _onEventSelected(EventModel event, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedEvents.add(event);
      } else {
        _selectedEvents.removeWhere((e) => e.id == event.id);
      }
    });
  }

  Future<void> _addNewEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventFormPage(),
      ),
    );
    
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Événement créé avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _performBulkAction(String action) async {
    switch (action) {
      case 'publish':
        await _publishSelectedEvents();
        break;
      case 'archive':
        await _archiveSelectedEvents();
        break;
      case 'duplicate':
        await _duplicateSelectedEvents();
        break;
      case 'export':
        await _exportSelectedEvents();
        break;
      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _publishSelectedEvents() async {
    try {
      for (final event in _selectedEvents) {
        if (event.isDraft) {
          final updatedEvent = event.copyWith(
            status: 'publie',
            updatedAt: DateTime.now(),
          );
          await EventsFirebaseService.updateEvent(updatedEvent);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedEvents.length} événement(s) publié(s)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _toggleSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _archiveSelectedEvents() async {
    try {
      for (final event in _selectedEvents) {
        await EventsFirebaseService.archiveEvent(event.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedEvents.length} événement(s) archivé(s)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _toggleSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _duplicateSelectedEvents() async {
    try {
      int duplicatedCount = 0;
      for (final event in _selectedEvents) {
        final newStartDate = DateTime.now().add(const Duration(days: 7));
        await EventsFirebaseService.duplicateEvent(
          event.id,
          '${event.title} (Copie)',
          newStartDate,
        );
        duplicatedCount++;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$duplicatedCount événement(s) dupliqué(s)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _toggleSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedEvents() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des événements en cours...'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
    // TODO: Implement export functionality
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les événements'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedEvents.length} événement(s) ? '
          'Cette action est irréversible et supprimera également toutes les inscriptions associées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        for (final event in _selectedEvents) {
          await EventsFirebaseService.deleteEvent(event.id);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedEvents.length} événement(s) supprimé(s)'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _toggleSelectionMode();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header avec recherche et filtres
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar personnalisé
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        if (_isSelectionMode) ...[
                          IconButton(
                            onPressed: _toggleSelectionMode,
                            icon: const Icon(Icons.close),
                          ),
                          Expanded(
                            child: Text(
                              '${_selectedEvents.length} sélectionné(s)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_selectedEvents.isNotEmpty) ...[
                            IconButton(
                              onPressed: () => _showBulkActionsMenu(),
                              icon: const Icon(Icons.more_vert),
                            ),
                          ],
                        ] else ...[
                          Expanded(
                            child: Text(
                              'Événements',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleViewMode,
                            icon: Icon(_isCalendarView ? Icons.view_list : Icons.calendar_month),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Barre de recherche et filtres
                  EventSearchFilterBar(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onFiltersChanged: _onFiltersChanged,
                    selectedTypeFilters: _selectedTypeFilters,
                    selectedStatusFilters: _selectedStatusFilters,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  
                  // Onglets pour la navigation
                  if (!_isSelectionMode && !_isCalendarView)
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textSecondaryColor,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(text: 'À venir'),
                        Tab(text: 'Passés'),
                        Tab(text: 'Tous'),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: _isCalendarView 
                ? _buildCalendarView()
                : _buildListView(),
          ),
        ],
      ),
      
      // FAB
      floatingActionButton: _isSelectionMode 
          ? null
          : ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: _addNewEvent,
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Nouvel événement'),
              ),
            ),
    );
  }

  Widget _buildCalendarView() {
    return StreamBuilder<List<EventModel>>(
      stream: EventsFirebaseService.getEventsStream(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        typeFilters: _selectedTypeFilters.isNotEmpty ? _selectedTypeFilters : null,
        statusFilters: _selectedStatusFilters.isNotEmpty ? _selectedStatusFilters : null,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
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
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return EventCalendarView(
          events: snapshot.data!,
          onEventTap: _onEventTap,
          onEventLongPress: _onEventLongPress,
          isSelectionMode: _isSelectionMode,
          selectedEvents: _selectedEvents,
          onSelectionChanged: _onEventSelected,
        );
      },
    );
  }

  Widget _buildListView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEventsList(['publie'], isUpcoming: true),
        _buildEventsList(['publie', 'archive'], isPast: true),
        _buildEventsList(_selectedStatusFilters),
      ],
    );
  }

  Widget _buildEventsList(List<String> statusFilters, {bool isUpcoming = false, bool isPast = false}) {
    final now = DateTime.now();
    
    return StreamBuilder<List<EventModel>>(
      stream: EventsFirebaseService.getEventsStream(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        typeFilters: _selectedTypeFilters.isNotEmpty ? _selectedTypeFilters : null,
        statusFilters: statusFilters,
        startDate: isUpcoming ? now : _startDate,
        endDate: isPast ? now : _endDate,
        limit: 100,
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
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var events = snapshot.data!;
        
        // Filter by time for upcoming/past
        if (isUpcoming) {
          events = events.where((event) => event.startDate.isAfter(now)).toList();
        } else if (isPast) {
          events = events.where((event) => event.startDate.isBefore(now)).toList();
        }

        if (events.isEmpty) {
          String emptyMessage = 'Aucun événement';
          if (isUpcoming) {
            emptyMessage = 'Aucun événement à venir';
          } else if (isPast) {
            emptyMessage = 'Aucun événement passé';
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.event_outlined,
                    size: 64,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier événement pour commencer',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _addNewEvent,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un événement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: EventCard(
                event: event,
                onTap: () => _onEventTap(event),
                onLongPress: () => _onEventLongPress(event),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedEvents.any((e) => e.id == event.id),
                onSelectionChanged: (isSelected) => _onEventSelected(event, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  void _onEventTap(EventModel event) {
    if (_isSelectionMode) {
      final isSelected = _selectedEvents.any((e) => e.id == event.id);
      _onEventSelected(event, !isSelected);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailPage(event: event),
        ),
      );
    }
  }

  void _onEventLongPress(EventModel event) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onEventSelected(event, true);
    }
  }

  void _showBulkActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.publish, color: AppTheme.successColor),
              title: const Text('Publier'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('publish');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: AppTheme.warningColor),
              title: const Text('Archiver'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('archive');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.primaryColor),
              title: const Text('Dupliquer'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('duplicate');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: AppTheme.secondaryColor),
              title: const Text('Exporter'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('export');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('delete');
              },
            ),
          ],
        ),
      ),
    );
  }
}