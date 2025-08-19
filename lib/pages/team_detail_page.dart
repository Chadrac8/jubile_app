// Removed invalid duplicated color lines from previous patch
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_model.dart';
import '../services/services_firebase_service.dart';
import 'team_form_page.dart';
import 'position_form_page.dart';
import 'team_assignments_page.dart';
import '../widgets/position_card.dart';


class TeamDetailPage extends StatefulWidget {
  final String teamId;

  const TeamDetailPage({super.key, required this.teamId});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TeamModel? _team;
  List<PositionModel> _positions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final team = await ServicesFirebaseService.getTeam(widget.teamId);
      final positions = await ServicesFirebaseService.getPositionsForTeamAsList(widget.teamId);

      setState(() {
        _team = team;
        _positions = positions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6F61EF);
    }
  }

  Future<void> _editTeam() async {
    if (_team == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamFormPage(team: _team),
      ),
    );

    if (result == true) {
      _loadTeamData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Équipe modifiée avec succès')),
      );
    }
  }

  Future<void> _addPosition() async {
    if (_team == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PositionFormPage(teamId: _team!.id),
      ),
    );

    if (result == true) {
      _loadTeamData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Position ajoutée avec succès')),
      );
    }
  }

  Future<void> _toggleTeamStatus() async {
    if (_team == null) return;

    try {
      final updatedTeam = TeamModel(
        id: _team!.id,
        name: _team!.name,
        description: _team!.description,
        color: _team!.color,
        positionIds: _team!.positionIds,
        isActive: !_team!.isActive,
        createdAt: _team!.createdAt,
        updatedAt: DateTime.now(),
      );

      await ServicesFirebaseService.updateTeam(updatedTeam);
      _loadTeamData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedTeam.isActive 
                ? 'Équipe activée' 
                : 'Équipe désactivée',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    if (_team == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'équipe'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'équipe "${_team!.name}" ? '
          'Cette action est irréversible et supprimera également toutes les positions associées.',
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
        await ServicesFirebaseService.deleteTeam(_team!.id);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Équipe supprimée avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _team == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
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
                  _error ?? 'Équipe introuvable',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final teamColor = _parseColor(_team!.color);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with team info
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000), // 0.1 opacity
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    child: CachedNetworkImage(
                      imageUrl: "https://images.unsplash.com/photo-1486092403097-cdb66be65823?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDk3NDE2NzZ8&ixlib=rb-4.1.0&q=80&w=1080",
                      width: double.infinity,
                      height: 200,
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x4D000000), // 0.3 opacity
                          Colors.transparent,
                          Color(0xB3000000), // 0.7 opacity
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Color(0x4D000000), // 0.3 opacity
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          iconColor: Colors.white,
                          color: Theme.of(context).colorScheme.surface,
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editTeam();
                                break;
                              case 'toggle_status':
                                _toggleTeamStatus();
                                break;
                              case 'delete':
                                _showDeleteConfirmation();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Modifier'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle_status',
                              child: ListTile(
                                leading: Icon(_team!.isActive ? Icons.pause : Icons.play_arrow),
                                title: Text(_team!.isActive ? 'Désactiver' : 'Activer'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: teamColor.withAlpha(230), // 0.9 opacity
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.groups,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _team!.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (!_team!.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xE6FFA726), // 0.9 opacity for orange
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Inactif',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _team!.description.isNotEmpty 
                                    ? _team!.description 
                                    : 'Aucune description',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_positions.length} position(s) • Créée le ${_formatDate(_team!.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withAlpha(51), // 0.2 opacity
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.assignment_ind),
                    text: 'Positions (${_positions.length})',
                  ),
                  const Tab(
                    icon: Icon(Icons.info_outline),
                    text: 'Informations',
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPositionsTab(),
                  _buildInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating action button for adding positions
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _addPosition,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle Position'),
              backgroundColor: teamColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildPositionsTab() {
    if (_positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_ind_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune position',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des positions pour définir les rôles dans cette équipe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179), // 0.7 opacity
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _addPosition,
              icon: const Icon(Icons.add),
              label: const Text('Créer une position'),
              style: FilledButton.styleFrom(
                backgroundColor: _parseColor(_team!.color),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _positions.length,
      itemBuilder: (context, index) {
        final position = _positions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PositionCard(
            position: position,
            teamColor: _parseColor(_team!.color),
            onTap: () {
              // Navigate to position detail or edit
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _parseColor(_team!.color),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Détails de l\'équipe',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nom', _team!.name),
                  _buildInfoRow('Description', 
                    _team!.description.isNotEmpty ? _team!.description : 'Aucune description'
                  ),
                  _buildInfoRow('Statut', _team!.isActive ? 'Actif' : 'Inactif'),
                  _buildInfoRow('Couleur', '', showColor: true),
                  _buildInfoRow('Positions', '${_positions.length} position(s)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Statistics card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: _parseColor(_team!.color),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Statistiques',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Date de création', _formatDate(_team!.createdAt)),
                  _buildInfoRow('Dernière modification', _formatDate(_team!.updatedAt)),
                  _buildInfoRow('Positions actives', 
                    '${_positions.where((p) => p.isActive).length}/${_positions.length}'
                  ),
                  _buildInfoRow('Positions de leadership', 
                    '${_positions.where((p) => p.isLeaderPosition).length}'
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Actions card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: _parseColor(_team!.color),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamAssignmentsPage(team: _team!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment),
                      label: const Text('Voir les assignations'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _parseColor(_team!.color),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voir toutes les assignations de service liées à cette équipe',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 opacity
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool showColor = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179), // 0.7 opacity
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: showColor 
                ? Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _parseColor(_team!.color),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withAlpha(77), // 0.3 opacity
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _team!.color,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}