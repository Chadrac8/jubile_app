import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_model.dart';
import '../services/services_firebase_service.dart';
import '../widgets/team_card.dart';
import 'team_form_page.dart';
import 'team_detail_page.dart';


class TeamsManagementPage extends StatefulWidget {
  const TeamsManagementPage({super.key});

  @override
  State<TeamsManagementPage> createState() => _TeamsManagementPageState();
}

class _TeamsManagementPageState extends State<TeamsManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactiveTeams = false;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  List<TeamModel> _selectedTeams = [];
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
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<TeamModel> _filterTeams(List<TeamModel> teams) {
    List<TeamModel> filtered = teams;

    // Filter by active status
    if (!_showInactiveTeams) {
      filtered = filtered.where((team) => team.isActive).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((team) {
        return team.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               team.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleShowInactive() {
    setState(() {
      _showInactiveTeams = !_showInactiveTeams;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTeams.clear();
      }
    });
  }

  void _onTeamSelected(TeamModel team, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTeams.add(team);
      } else {
        _selectedTeams.remove(team);
      }
    });
  }

  void _onTeamTap(TeamModel team) {
    if (_isSelectionMode) {
      _onTeamSelected(team, !_selectedTeams.contains(team));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamDetailPage(teamId: team.id),
        ),
      );
    }
  }

  void _onTeamLongPress(TeamModel team) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onTeamSelected(team, true);
    }
  }

  Future<void> _addNewTeam() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeamFormPage(),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Équipe créée avec succès'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _performBulkAction(String action) async {
    switch (action) {
      case 'activate':
        await _activateSelectedTeams();
        break;
      case 'deactivate':
        await _deactivateSelectedTeams();
        break;
      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _activateSelectedTeams() async {
    try {
      for (final team in _selectedTeams) {
        if (!team.isActive) {
          final updatedTeam = TeamModel(
            id: team.id,
            name: team.name,
            description: team.description,
            color: team.color,
            positionIds: team.positionIds,
            isActive: true,
            createdAt: team.createdAt,
            updatedAt: DateTime.now(),
          );
          await ServicesFirebaseService.updateTeam(updatedTeam);
        }
      }
      
      setState(() {
        _selectedTeams.clear();
        _isSelectionMode = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Équipes activées avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deactivateSelectedTeams() async {
    try {
      for (final team in _selectedTeams) {
        if (team.isActive) {
          final updatedTeam = TeamModel(
            id: team.id,
            name: team.name,
            description: team.description,
            color: team.color,
            positionIds: team.positionIds,
            isActive: false,
            createdAt: team.createdAt,
            updatedAt: DateTime.now(),
          );
          await ServicesFirebaseService.updateTeam(updatedTeam);
        }
      }
      
      setState(() {
        _selectedTeams.clear();
        _isSelectionMode = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Équipes désactivées avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer ${_selectedTeams.length} équipe(s) ? '
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
      await _deleteSelectedTeams();
    }
  }

  Future<void> _deleteSelectedTeams() async {
    try {
      for (final team in _selectedTeams) {
        await ServicesFirebaseService.deleteTeam(team.id);
      }
      
      setState(() {
        _selectedTeams.clear();
        _isSelectionMode = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Équipes supprimées avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_isSelectionMode) ...[
                        IconButton(
                          onPressed: _toggleSelectionMode,
                          icon: const Icon(Icons.close),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedTeams.length} sélectionné(s)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedTeams.isNotEmpty) ...[
                          IconButton(
                            onPressed: () => _performBulkAction('activate'),
                            icon: const Icon(Icons.check_circle),
                            tooltip: 'Activer',
                          ),
                          IconButton(
                            onPressed: () => _performBulkAction('deactivate'),
                            icon: const Icon(Icons.pause_circle),
                            tooltip: 'Désactiver',
                          ),
                          IconButton(
                            onPressed: () => _performBulkAction('delete'),
                            icon: const Icon(Icons.delete),
                            tooltip: 'Supprimer',
                          ),
                        ],
                      ] else ...[
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.groups,
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
                                'Équipes',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Gestion des équipes de service',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleShowInactive,
                          icon: Icon(_showInactiveTeams ? Icons.visibility_off : Icons.visibility),
                          tooltip: _showInactiveTeams ? 'Masquer inactives' : 'Voir inactives',
                        ),
                        IconButton(
                          onPressed: _toggleSelectionMode,
                          icon: const Icon(Icons.checklist),
                          tooltip: 'Mode sélection',
                        ),
                      ],
                    ],
                  ),
                  if (!_isSelectionMode) ...[
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une équipe...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Teams list
            Expanded(
              child: StreamBuilder<List<TeamModel>>(
                stream: ServicesFirebaseService.getTeamsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

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
                            'Erreur de chargement',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final teams = _filterTeams(snapshot.data!);

                  if (teams.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TeamCard(
                          team: team,
                          onTap: () => _onTeamTap(team),
                          onLongPress: () => _onTeamLongPress(team),
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedTeams.contains(team),
                          onSelectionChanged: (isSelected) => _onTeamSelected(team, isSelected),
                        ),
                      );
                    },
                  );
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
                onPressed: _addNewTeam,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle Équipe'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header image
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: "https://images.unsplash.com/photo-1571069424149-c456e0b413d6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDk3NDE0Njd8&ixlib=rb-4.1.0&q=80&w=1080",
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.groups,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune équipe',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer votre première équipe de service',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _addNewTeam,
            icon: const Icon(Icons.add),
            label: const Text('Créer une équipe'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères de recherche',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              setState(() {
                _showInactiveTeams = false;
              });
            },
            child: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }
}