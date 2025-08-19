import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/group_model.dart';
import '../services/groups_firebase_service.dart';
import '../widgets/group_card.dart';
import '../widgets/group_search_filter_bar.dart';
import 'group_detail_page.dart';
import 'group_form_page.dart';
import '../../compatibility/app_theme_bridge.dart';


class GroupsHomePage extends StatefulWidget {
  const GroupsHomePage({super.key});

  @override
  State<GroupsHomePage> createState() => _GroupsHomePageState();
}

class _GroupsHomePageState extends State<GroupsHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  List<String> _selectedTypeFilters = [];
  List<String> _selectedDayFilters = [];
  bool _showActiveOnly = true;
  bool _isGridView = false;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  List<GroupModel> _selectedGroups = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFiltersChanged(List<String> typeFilters, List<String> dayFilters, bool activeOnly) {
    setState(() {
      _selectedTypeFilters = typeFilters;
      _selectedDayFilters = dayFilters;
      _showActiveOnly = activeOnly;
    });
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedGroups.clear();
      }
    });
  }

  void _onGroupSelected(GroupModel group, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedGroups.add(group);
      } else {
        _selectedGroups.removeWhere((g) => g.id == group.id);
      }
    });
  }

  Future<void> _addNewGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupFormPage(),
      ),
    );
    
    if (result == true) {
      // Group was created successfully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Groupe créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _performBulkAction(String action) async {
    switch (action) {
      case 'archive':
        await _archiveSelectedGroups();
        break;
      case 'export':
        await _exportSelectedGroups();
        break;
      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _archiveSelectedGroups() async {
    try {
      for (final group in _selectedGroups) {
        await GroupsFirebaseService.archiveGroup(group.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedGroups.length} groupe(s) archivé(s)'),
            backgroundColor: Colors.orange,
          ),
        );
        _toggleSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'archivage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedGroups() async {
    try {
      // Export logic would go here
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export de ${_selectedGroups.length} groupe(s) en cours...'),
            backgroundColor: Colors.blue,
          ),
        );
        _toggleSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedGroups.length} groupe(s) ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        for (final group in _selectedGroups) {
          await GroupsFirebaseService.deleteGroup(group.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedGroups.length} groupe(s) supprimé(s)'),
              backgroundColor: Colors.red,
            ),
          );
          _toggleSelectionMode();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.groups,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Groupes',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Gestion des petits groupes et communautés',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isSelectionMode) ...[
                          IconButton(
                            onPressed: _toggleSelectionMode,
                            icon: const Icon(Icons.close),
                            tooltip: 'Annuler la sélection',
                          ),
                          PopupMenuButton<String>(
                            onSelected: _performBulkAction,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive, size: 20),
                                    SizedBox(width: 12),
                                    Text('Archiver'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    Icon(Icons.download, size: 20),
                                    SizedBox(width: 12),
                                    Text('Exporter'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.more_vert,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ] else ...[
                          IconButton(
                            onPressed: _toggleViewMode,
                            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                            tooltip: _isGridView ? 'Vue liste' : 'Vue grille',
                          ),
                          IconButton(
                            onPressed: _toggleSelectionMode,
                            icon: const Icon(Icons.checklist),
                            tooltip: 'Mode sélection',
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Search and Filter Bar
                    GroupSearchFilterBar(
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onFiltersChanged: _onFiltersChanged,
                      selectedTypeFilters: _selectedTypeFilters,
                      selectedDayFilters: _selectedDayFilters,
                      showActiveOnly: _showActiveOnly,
                    ),
                    
                    if (_isSelectionMode) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedGroups.length} groupe(s) sélectionné(s)',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Groups List
              Expanded(
                child: StreamBuilder<List<GroupModel>>(
                  stream: GroupsFirebaseService.getGroupsStream(
                    searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                    typeFilters: _selectedTypeFilters.isEmpty ? null : _selectedTypeFilters,
                    dayFilters: _selectedDayFilters.isEmpty ? null : _selectedDayFilters,
                    activeOnly: _showActiveOnly,
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
                                color: Theme.of(context).colorScheme.error,
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

                    final groups = snapshot.data!;

                    if (groups.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Icon(
                                Icons.groups_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aucun groupe trouvé',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedTypeFilters.isNotEmpty || _selectedDayFilters.isNotEmpty
                                  ? 'Essayez de modifier vos critères de recherche'
                                  : 'Commencez par créer votre premier groupe',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_searchQuery.isEmpty && _selectedTypeFilters.isEmpty && _selectedDayFilters.isEmpty)
                              ElevatedButton.icon(
                                onPressed: _addNewGroup,
                                icon: const Icon(Icons.add),
                                label: const Text('Créer un groupe'),
                              ),
                          ],
                        ),
                      );
                    }

                    return _isGridView 
                        ? _buildGridView(groups)
                        : _buildListView(groups);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_isSelectionMode ? ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _addNewGroup,
          icon: const Icon(Icons.add),
          label: const Text('Nouveau groupe'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ) : null,
    );
  }

  Widget _buildListView(List<GroupModel> groups) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final group = groups[index];
        return GroupCard(
          group: group,
          onTap: () => _onGroupTap(group),
          onLongPress: () => _onGroupLongPress(group),
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedGroups.any((g) => g.id == group.id),
          onSelectionChanged: (isSelected) => _onGroupSelected(group, isSelected),
          isGridView: false,
        );
      },
    );
  }

  Widget _buildGridView(List<GroupModel> groups) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return GroupCard(
          group: group,
          onTap: () => _onGroupTap(group),
          onLongPress: () => _onGroupLongPress(group),
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedGroups.any((g) => g.id == group.id),
          onSelectionChanged: (isSelected) => _onGroupSelected(group, isSelected),
          isGridView: true,
        );
      },
    );
  }

  void _onGroupTap(GroupModel group) {
    if (_isSelectionMode) {
      _onGroupLongPress(group);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupDetailPage(group: group),
        ),
      );
    }
  }

  void _onGroupLongPress(GroupModel group) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
    }
    _onGroupSelected(group, !_selectedGroups.any((g) => g.id == group.id));
  }
}