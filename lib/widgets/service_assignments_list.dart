import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/person_model.dart';
import '../services/services_firebase_service.dart';
import '../services/firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class ServiceAssignmentsList extends StatefulWidget {
  final ServiceModel service;

  const ServiceAssignmentsList({super.key, required this.service});

  @override
  State<ServiceAssignmentsList> createState() => _ServiceAssignmentsListState();
}

class _ServiceAssignmentsListState extends State<ServiceAssignmentsList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _assignTeamToService() async {
    try {
      final teams = await ServicesFirebaseService.getTeamsStream().first;
      
      if (teams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Aucune équipe disponible. Créez d\'abord des équipes.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Filter teams that are not already assigned
      final availableTeams = teams.where((team) => 
        !widget.service.teamIds.contains(team.id)
      ).toList();

      if (availableTeams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Toutes les équipes sont déjà assignées à ce service.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _TeamSelectionDialog(
            teams: availableTeams,
            onTeamSelected: (teamId) async {
              Navigator.of(context).pop(); // Close dialog first
              
              try {
                await ServicesFirebaseService.assignTeamToService(widget.service.id, teamId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Équipe assignée avec succès'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
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
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des équipes: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _assignPerson(String positionId) async {
    try {
      final persons = await ServicesFirebaseService.getAvailablePersonsForAssignment();
      
      if (persons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aucune personne disponible.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => _PersonSelectionDialog(
          persons: persons,
          onPersonSelected: (personId) async {
            try {
              final assignment = ServiceAssignmentModel(
                id: '',
                serviceId: widget.service.id,
                positionId: positionId,
                personId: personId,
                status: 'invited',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await ServicesFirebaseService.createAssignment(assignment);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Personne assignée avec succès'),
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
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des personnes: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _changeAssignmentStatus(ServiceAssignmentModel assignment, String newStatus) async {
    try {
      final updatedAssignment = ServiceAssignmentModel(
        id: assignment.id,
        serviceId: assignment.serviceId,
        positionId: assignment.positionId,
        personId: assignment.personId,
        status: newStatus,
        notes: assignment.notes,
        respondedAt: DateTime.now(),
        lastReminderSent: assignment.lastReminderSent,
        createdAt: assignment.createdAt,
        updatedAt: DateTime.now(),
        assignedBy: assignment.assignedBy,
      );
      
      await ServicesFirebaseService.updateAssignment(updatedAssignment);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour: ${updatedAssignment.statusLabel}'),
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

  Future<void> _removeAssignment(ServiceAssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette affectation ?'),
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
        await ServicesFirebaseService.removeAssignment(assignment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Affectation supprimée'),
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
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'tentative':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Header with add team button
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
                    Expanded(
                      child: Text(
                        'Équipes et affectations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _assignTeamToService,
                      icon: const Icon(Icons.add),
                      label: const Text('Assigner équipe'),
                    ),
                  ],
                ),
              ),

              // Assignments list
              Expanded(
                child: StreamBuilder<List<ServiceAssignmentModel>>(
                  stream: ServicesFirebaseService.getServiceAssignmentsStream(widget.service.id),
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

                    final assignments = snapshot.data!;

                    if (assignments.isEmpty) {
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
                                Icons.groups,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aucune affectation',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Commencez par assigner des équipes à ce service',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _assignTeamToService,
                              icon: const Icon(Icons.add),
                              label: const Text('Assigner une équipe'),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildAssignmentsList(assignments);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsList(List<ServiceAssignmentModel> assignments) {
    // Group assignments by position
    final Map<String, List<ServiceAssignmentModel>> groupedAssignments = {};
    for (final assignment in assignments) {
      if (!groupedAssignments.containsKey(assignment.positionId)) {
        groupedAssignments[assignment.positionId] = [];
      }
      groupedAssignments[assignment.positionId]!.add(assignment);
    }

    return StreamBuilder<List<PositionModel>>(
      stream: ServicesFirebaseService.getAllPositionsStream(),
      builder: (context, positionsSnapshot) {
        if (!positionsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final positions = positionsSnapshot.data!;

        return StreamBuilder<List<PersonModel>>(
          stream: FirebaseService.getPersonsStream(),
          builder: (context, personsSnapshot) {
            if (!personsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final persons = personsSnapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedAssignments.keys.length,
              itemBuilder: (context, index) {
                final positionId = groupedAssignments.keys.elementAt(index);
                final positionAssignments = groupedAssignments[positionId]!;
                final position = positions.firstWhere(
                  (p) => p.id == positionId,
                  orElse: () => PositionModel(
                    id: positionId,
                    teamId: '',
                    name: 'Position inconnue',
                    description: '',
                    createdAt: DateTime.now(),
                  ),
                );

                return _buildPositionCard(position, positionAssignments, persons);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPositionCard(
    PositionModel position,
    List<ServiceAssignmentModel> assignments,
    List<PersonModel> persons,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: position.isLeaderPosition 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    position.isLeaderPosition ? Icons.star : Icons.person,
                    size: 20,
                    color: position.isLeaderPosition 
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (position.description.isNotEmpty)
                        Text(
                          position.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _assignPerson(position.id),
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Assigner une personne',
                ),
              ],
            ),

            if (assignments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Assignments list
              ...assignments.map((assignment) {
                final person = persons.firstWhere(
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
                
                return _buildAssignmentTile(assignment, person);
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentTile(ServiceAssignmentModel assignment, PersonModel person) {
    final statusColor = _getStatusColor(assignment.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Person avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: person.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      person.profileImageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          person.displayInitials,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    person.displayInitials,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Person info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        assignment.statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (assignment.respondedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(assignment.respondedAt!),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'accept':
                  _changeAssignmentStatus(assignment, 'accepted');
                  break;
                case 'decline':
                  _changeAssignmentStatus(assignment, 'declined');
                  break;
                case 'tentative':
                  _changeAssignmentStatus(assignment, 'tentative');
                  break;
                case 'confirm':
                  _changeAssignmentStatus(assignment, 'confirmed');
                  break;
                case 'remind':
                  ServicesFirebaseService.sendReminder(assignment.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rappel envoyé')),
                  );
                  break;
                case 'remove':
                  _removeAssignment(assignment);
                  break;
              }
            },
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
                const PopupMenuItem(
                  value: 'tentative',
                  child: Row(
                    children: [
                      Icon(Icons.help, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Peut-être'),
                    ],
                  ),
                ),
              ],
              if (assignment.isAccepted && !assignment.isConfirmed)
                const PopupMenuItem(
                  value: 'confirm',
                  child: Row(
                    children: [
                      Icon(Icons.verified),
                      SizedBox(width: 8),
                      Text('Confirmer'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'remind',
                child: Row(
                  children: [
                    Icon(Icons.notifications),
                    SizedBox(width: 8),
                    Text('Envoyer rappel'),
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TeamSelectionDialog extends StatelessWidget {
  final List<TeamModel> teams;
  final Function(String) onTeamSelected;

  const _TeamSelectionDialog({
    required this.teams,
    required this.onTeamSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner une équipe'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            final color = Color(int.parse(team.color.replaceFirst('#', '0xFF')));
            
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.groups,
                  color: color,
                ),
              ),
              title: Text(team.name),
              subtitle: Text(team.description),
              onTap: () {
                Navigator.pop(context);
                onTeamSelected(team.id);
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
    );
  }
}

class _PersonSelectionDialog extends StatefulWidget {
  final List<PersonModel> persons;
  final Function(String) onPersonSelected;

  const _PersonSelectionDialog({
    required this.persons,
    required this.onPersonSelected,
  });

  @override
  State<_PersonSelectionDialog> createState() => _PersonSelectionDialogState();
}

class _PersonSelectionDialogState extends State<_PersonSelectionDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPersons = widget.persons.where((person) {
      return person.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             person.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Sélectionner une personne'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: person.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                person.profileImageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    person.displayInitials,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              person.displayInitials,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    title: Text(person.fullName),
                    subtitle: Text(person.email),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onPersonSelected(person.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}