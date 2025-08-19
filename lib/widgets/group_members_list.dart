import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/person_model.dart';
import '../services/groups_firebase_service.dart';
import '../services/firebase_service.dart';
// Removed unused import '../../compatibility/app_theme_bridge.dart';

class GroupMembersList extends StatefulWidget {
  final GroupModel group;

  const GroupMembersList({super.key, required this.group});

  @override
  State<GroupMembersList> createState() => _GroupMembersListState();
}

class _GroupMembersListState extends State<GroupMembersList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    try {
      // Get all active persons
      final allPersons = await FirebaseService.getActivePersons();
      
      final currentMembers = await GroupsFirebaseService.getGroupMembersWithPersonData(widget.group.id);
      final currentMemberIds = currentMembers.map((p) => p.id).toSet();
      
      final availablePersons = allPersons.where((p) => !currentMemberIds.contains(p.id)).toList();

      if (availablePersons.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune personne disponible à ajouter'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _AddMemberDialog(
          availablePersons: availablePersons,
        ),
      );

      if (result != null) {
        try {
          await GroupsFirebaseService.addMemberToGroup(
            widget.group.id,
            result['personId'],
            result['role'],
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Membre ajouté avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'ajout: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des personnes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le membre'),
        content: Text('Êtes-vous sûr de vouloir retirer $memberName du groupe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupsFirebaseService.removeMemberFromGroup(memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membre retiré avec succès'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeRole(String memberId, String currentRole, String memberName) async {
    final roles = ['member', 'co-leader', 'leader'];
    final roleLabels = {
      'member': 'Membre',
      'co-leader': 'Co-leader',
      'leader': 'Leader',
    };

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le rôle de $memberName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) => RadioListTile<String>(
            title: Text(roleLabels[role]!),
            value: role,
            groupValue: currentRole,
            onChanged: (value) => Navigator.pop(context, value),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != currentRole) {
      try {
        await GroupsFirebaseService.updateMemberRole(memberId, newRole);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rôle mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color get _groupColor => Color(int.parse(widget.group.color.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header with Add Button
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Membres du groupe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addMember,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _groupColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Members List with optimized loading
          Expanded(
            child: FutureBuilder<List<PersonModel>>(
              future: GroupsFirebaseService.getGroupMembersWithPersonData(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Erreur lors du chargement des membres: ${snapshot.error}');
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
                          'Problème de connexion ou de permissions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(179), // 0.7 * 255 ≈ 179
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Refresh
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _groupColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.group_outlined,
                            size: 40,
                            color: _groupColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun membre',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par ajouter des membres au groupe',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addMember,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter un membre'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _groupColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<GroupMemberModel>>(
                  stream: GroupsFirebaseService.getGroupMembersStream(widget.group.id),
                  builder: (context, membersSnapshot) {
                    if (!membersSnapshot.hasData) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: members.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final person = members[index];
                          // Créer un member model temporaire
                          final tempMember = GroupMemberModel(
                            id: '',
                            groupId: widget.group.id,
                            personId: person.id,
                            role: 'member',
                            joinedAt: DateTime.now(),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          return _buildMemberCard(tempMember, person);
                        },
                      );
                    }

                    final groupMembers = membersSnapshot.data!;
                    final memberMap = {for (var m in groupMembers) m.personId: m};
                    
                    // Filtrer les membres qui existent dans les données du groupe
                    final validMembers = members.where((person) => 
                      memberMap.containsKey(person.id)
                    ).toList();

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: validMembers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final person = validMembers[index];
                        final member = memberMap[person.id]!;
                        return _buildMemberCard(member, person);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMemberCard(GroupMemberModel member, PersonModel person) {
    final roleColors = {
      'leader': Colors.red,
      'co-leader': Colors.orange,
      'member': _groupColor,
      'guest': Colors.grey,
    };

    final roleLabels = {
      'leader': 'Leader',
      'co-leader': 'Co-leader',
      'member': 'Membre',
      'guest': 'Invité',
    };

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Image/Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _groupColor.withAlpha(25),
                borderRadius: BorderRadius.circular(25),
              ),
              child: person.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.memory(
                        Uri.parse(person.profileImageUrl!).data!.contentAsBytes(),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        person.displayInitials,
                        style: TextStyle(
                          color: _groupColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColors[member.role]!.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleLabels[member.role]!,
                          style: TextStyle(
                            color: roleColors[member.role],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rejoint le ${_formatDate(member.joinedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions Menu
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'change_role':
                    await _changeRole(member.id, member.role, person.fullName);
                    break;
                  case 'remove':
                    await _removeMember(member.id, person.fullName);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'change_role',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 20),
                      SizedBox(width: 12),
                      Text('Changer le rôle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Retirer du groupe', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddMemberDialog extends StatefulWidget {
  final List<PersonModel> availablePersons;

  const _AddMemberDialog({required this.availablePersons});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  PersonModel? _selectedPerson;
  String _selectedRole = 'member';
  String _searchQuery = '';

  final Map<String, String> _roleLabels = {
    'member': 'Membre',
    'co-leader': 'Co-leader',
    'leader': 'Leader',
  };

  @override
  Widget build(BuildContext context) {
    final filteredPersons = widget.availablePersons.where((person) {
      if (_searchQuery.isEmpty) return true;
      return person.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Ajouter un membre'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher une personne...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Person List
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  return RadioListTile<PersonModel>(
                    title: Text(person.fullName),
                    subtitle: Text(person.email),
                    value: person,
                    groupValue: _selectedPerson,
                    onChanged: (value) => setState(() => _selectedPerson = value),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Role Selection
            DropdownButtonFormField<String>(
              value: _selectedRole,
              onChanged: (value) => setState(() => _selectedRole = value!),
              decoration: const InputDecoration(
                labelText: 'Rôle',
                border: OutlineInputBorder(),
              ),
              items: _roleLabels.entries.map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedPerson != null
              ? () => Navigator.pop(context, {
                    'personId': _selectedPerson!.id,
                    'role': _selectedRole,
                  })
              : null,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}