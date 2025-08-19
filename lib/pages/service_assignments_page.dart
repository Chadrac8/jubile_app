import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../models/person_model.dart';
import '../services/services_firebase_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';


class ServiceAssignmentsPage extends StatefulWidget {
  final ServiceModel service;

  const ServiceAssignmentsPage({super.key, required this.service});

  @override
  State<ServiceAssignmentsPage> createState() => _ServiceAssignmentsPageState();
}

class _ServiceAssignmentsPageState extends State<ServiceAssignmentsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _statusFilter = 'all';
  bool _isLoading = false;
  
  List<TeamModel> _teams = [];
  List<PositionModel> _positions = [];
  List<PersonModel> _persons = [];
  List<ServiceAssignmentModel> _assignments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load teams for this service
      print('ServiceAssignmentsPage: Chargement pour le service ${widget.service.name}');
      print('ServiceAssignmentsPage: TeamIds du service: ${widget.service.teamIds}');
      
      if (widget.service.teamIds.isEmpty) {
        print('ServiceAssignmentsPage: Aucune équipe associée au service, chargement de toutes les équipes');
        // Si le service n'a pas d'équipes spécifiques, charger toutes les équipes
        final allTeams = await ServicesFirebaseService.getTeamsStream().first;
        _teams = allTeams;
      } else {
        final teamsFutures = widget.service.teamIds
            .map((teamId) => ServicesFirebaseService.getTeam(teamId));
        final teamsResults = await Future.wait(teamsFutures);
        _teams = teamsResults.where((team) => team != null).cast<TeamModel>().toList();
      }
      
      print('ServiceAssignmentsPage: Équipes chargées: ${_teams.length}');

      // Load all positions for these teams
      final allPositionIds = _teams.expand((team) => team.positionIds).toList();
      print('ServiceAssignmentsPage: IDs positions à charger: ${allPositionIds.length}');
      
      if (allPositionIds.isEmpty) {
        // Si aucune position spécifique, charger toutes les positions
        print('ServiceAssignmentsPage: Aucune position spécifique, chargement de toutes les positions');
        final allPositions = await ServicesFirebaseService.getAllPositionsStream().first;
        _positions = allPositions;
      } else {
        final positionsFutures = allPositionIds
            .map((positionId) => ServicesFirebaseService.getPosition(positionId));
        final positionsResults = await Future.wait(positionsFutures);
        _positions = positionsResults.where((pos) => pos != null).cast<PositionModel>().toList();
      }
      
      print('ServiceAssignmentsPage: Positions chargées: ${_positions.length}');

      // Load all active persons
      final personsSnapshot = await FirebaseService.getPersonsStream().first;
      _persons = personsSnapshot.where((person) => person.isActive).toList();
      print('ServiceAssignmentsPage: Personnes actives chargées: ${_persons.length}');

      // Load existing assignments for this service
      final assignmentsSnapshot = await ServicesFirebaseService
          .getServiceAssignmentsStream(widget.service.id).first;
      _assignments = assignmentsSnapshot;
      print('ServiceAssignmentsPage: Assignations existantes: ${_assignments.length}');
      
      print('ServiceAssignmentsPage: Chargement terminé avec succès');

    } catch (e) {
      print('ServiceAssignmentsPage: Erreur lors du chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createAssignment(String positionId, String personId) async {
    try {
      final assignment = ServiceAssignmentModel(
        id: '',
        serviceId: widget.service.id,
        positionId: positionId,
        personId: personId,
        status: 'invited',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignedBy: AuthService.currentUser?.uid,
      );

      await ServicesFirebaseService.createAssignment(assignment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assignation créée avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _updateAssignmentStatus(ServiceAssignmentModel assignment, String newStatus) async {
    try {
      final updatedAssignment = assignment.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        respondedAt: DateTime.now(),
      );

      await ServicesFirebaseService.updateAssignment(updatedAssignment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${updatedAssignment.statusLabel}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeAssignment(ServiceAssignmentModel assignment) async {
    try {
      await ServicesFirebaseService.removeAssignment(assignment.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assignation supprimée'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<ServiceAssignmentModel> _getFilteredAssignments() {
    var filtered = _assignments.where((assignment) {
      if (_statusFilter != 'all' && assignment.status != _statusFilter) {
        return false;
      }
      
      if (_searchQuery.isNotEmpty) {
        final person = _persons.firstWhere(
          (p) => p.id == assignment.personId, 
          orElse: () => PersonModel(
            id: '', 
            firstName: '', 
            lastName: '', 
            email: '', 
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final position = _positions.firstWhere(
          (p) => p.id == assignment.positionId,
          orElse: () => PositionModel(
            id: '', 
            teamId: '', 
            name: '', 
            description: '', 
            createdAt: DateTime.now(),
          ),
        );
        
        final searchLower = _searchQuery.toLowerCase();
        if (!person.fullName.toLowerCase().contains(searchLower) &&
            !position.name.toLowerCase().contains(searchLower)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Sort by status priority and then by creation date
    filtered.sort((a, b) {
      final statusPriority = {
        'invited': 0,
        'tentative': 1,
        'accepted': 2,
        'confirmed': 3,
        'declined': 4,
      };
      final aPriority = statusPriority[a.status] ?? 5;
      final bPriority = statusPriority[b.status] ?? 5;
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assignations'),
            Text(
              widget.service.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assignations', icon: Icon(Icons.assignment)),
            Tab(text: 'Nouvelle assignation', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAssignmentsTab(),
                _buildNewAssignmentTab(),
              ],
            ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Column(
      children: [
        // Header with image
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage("https://pixabay.com/get/g31db9d0b6344e03e499dd44026c9db760a8fd4ad67f11cda6324156f30e571a7bfcb50596e56d030db368dc3cb9f8cc10917d4d296b29725359dd3004269ab52_1280.jpg"),
              fit: BoxFit.cover,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xB3000000), // 70% opacity black
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des assignations',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR')
                        .format(widget.service.dateTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Filters and search
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher une personne ou un poste...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _statusFilter == 'all',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Invités'),
                      selected: _statusFilter == 'invited',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'invited');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Acceptés'),
                      selected: _statusFilter == 'accepted',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'accepted');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Refusés'),
                      selected: _statusFilter == 'declined',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'declined');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Confirmés'),
                      selected: _statusFilter == 'confirmed',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'confirmed');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Assignments list
        Expanded(
          child: _buildAssignmentsList(),
        ),
      ],
    );
  }

  Widget _buildAssignmentsList() {
    final filteredAssignments = _getFilteredAssignments();
    
    if (filteredAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _assignments.isEmpty 
                  ? 'Aucune assignation pour ce service'
                  : 'Aucune assignation ne correspond aux filtres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez l\'onglet "Nouvelle assignation" pour ajouter des personnes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredAssignments.length,
      itemBuilder: (context, index) {
        final assignment = filteredAssignments[index];
        final person = _persons.firstWhere(
          (p) => p.id == assignment.personId,
          orElse: () => PersonModel(
            id: assignment.personId,
            firstName: 'Personne',
            lastName: 'inconnue',
            email: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final position = _positions.firstWhere(
          (p) => p.id == assignment.positionId,
          orElse: () => PositionModel(
            id: assignment.positionId,
            teamId: '',
            name: 'Position inconnue',
            description: '',
            createdAt: DateTime.now(),
          ),
        );
        final team = _teams.firstWhere(
          (t) => t.id == position.teamId,
          orElse: () => TeamModel(
            id: position.teamId,
            name: 'Équipe inconnue',
            description: '',
            color: '#6F61EF',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(team.color.replaceAll('#', '0xFF'))),
              child: Text(
                person.fullName.isNotEmpty 
                    ? person.fullName.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(person.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${team.name} • ${position.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(assignment.status).withAlpha(25), // 10% opacity
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    assignment.statusLabel,
                    style: TextStyle(
                      color: _getStatusColor(assignment.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleAssignmentAction(assignment, action),
              itemBuilder: (context) => [
                if (assignment.isPending) ...[
                  const PopupMenuItem(
                    value: 'accept',
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Accepter'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'decline',
                    child: Row(
                      children: [
                        Icon(Icons.close, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Refuser'),
                      ],
                    ),
                  ),
                ],
                if (assignment.isAccepted) ...[
                  const PopupMenuItem(
                    value: 'confirm',
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Confirmer'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'notes',
                  child: Row(
                    children: [
                      Icon(Icons.note),
                      SizedBox(width: 8),
                      Text('Notes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewAssignmentTab() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle assignation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez un poste puis assignez des personnes pour le service "${widget.service.name}".',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Teams and positions
        Expanded(
          child: _buildTeamsAndPositions(),
        ),
      ],
    );
  }

  Widget _buildTeamsAndPositions() {
    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune équipe assignée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des équipes à ce service pour pouvoir faire des assignations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final teamPositions = _positions.where((p) => p.teamId == team.id).toList();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(team.color.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Text('${teamPositions.length} poste(s)'),
            children: teamPositions.map((position) {
              final existingAssignments = _assignments
                  .where((a) => a.positionId == position.id)
                  .length;
              final remainingSlots = position.maxAssignments - existingAssignments;
              
              return ListTile(
                title: Text(position.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (position.description.isNotEmpty)
                      Text(position.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          position.isLeaderPosition 
                              ? Icons.star 
                              : Icons.person,
                          size: 16,
                          color: position.isLeaderPosition 
                              ? Colors.amber 
                              : Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$existingAssignments/${position.maxAssignments} assigné(s)',
                          style: TextStyle(
                            color: remainingSlots > 0 
                                ? Colors.green 
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: remainingSlots > 0
                    ? IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () => _showPersonSelectionDialog(position),
                      )
                    : const Icon(
                        Icons.people,
                        color: Colors.grey,
                      ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showPersonSelectionDialog(PositionModel position) {
    final alreadyAssigned = _assignments
        .where((a) => a.positionId == position.id)
        .map((a) => a.personId)
        .toSet();
    
    final availablePersons = _persons
        .where((person) => !alreadyAssigned.contains(person.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assigner au poste "${position.name}"'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: availablePersons.isEmpty
              ? const Center(
                  child: Text('Aucune personne disponible pour ce poste.'),
                )
              : ListView.builder(
                  itemCount: availablePersons.length,
                  itemBuilder: (context, index) {
                    final person = availablePersons[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          person.fullName.isNotEmpty 
                              ? person.fullName.substring(0, 1).toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(person.fullName),
                      subtitle: Text(person.email),
                      onTap: () {
                        Navigator.pop(context);
                        _createAssignment(position.id, person.id);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _handleAssignmentAction(ServiceAssignmentModel assignment, String action) {
    switch (action) {
      case 'accept':
        _updateAssignmentStatus(assignment, 'accepted');
        break;
      case 'decline':
        _updateAssignmentStatus(assignment, 'declined');
        break;
      case 'confirm':
        _updateAssignmentStatus(assignment, 'confirmed');
        break;
      case 'notes':
        _showNotesDialog(assignment);
        break;
      case 'remove':
        _showRemoveConfirmation(assignment);
        break;
    }
  }

  void _showNotesDialog(ServiceAssignmentModel assignment) {
    final notesController = TextEditingController(text: assignment.notes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes pour l\'assignation'),
        content: TextField(
          controller: notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ajoutez des notes ou instructions...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final updatedAssignment = assignment.copyWith(
                  notes: notesController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                await ServicesFirebaseService.updateAssignment(updatedAssignment);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(ServiceAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'assignation'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette assignation ? Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeAssignment(assignment);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'invited':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'tentative':
        return Colors.orange;
      case 'confirmed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// Extension to add copyWith method to ServiceAssignmentModel
extension ServiceAssignmentModelExtension on ServiceAssignmentModel {
  ServiceAssignmentModel copyWith({
    String? id,
    String? serviceId,
    String? positionId,
    String? personId,
    String? status,
    String? notes,
    DateTime? respondedAt,
    DateTime? lastReminderSent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedBy,
  }) {
    return ServiceAssignmentModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      positionId: positionId ?? this.positionId,
      personId: personId ?? this.personId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      respondedAt: respondedAt ?? this.respondedAt,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedBy: assignedBy ?? this.assignedBy,
    );
  }
}