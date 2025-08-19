import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/firebase_service.dart';
import '../services/roles_firebase_service.dart';
import '../widgets/person_card.dart';
import '../widgets/search_filter_bar.dart';
import 'person_detail_page.dart';
import 'person_form_page.dart';

import 'custom_fields_management_page.dart';

import 'workflow_followups_management_page.dart';
import 'families_management_page.dart';


class PeopleHomePage extends StatefulWidget {
  const PeopleHomePage({super.key});

  @override
  State<PeopleHomePage> createState() => _PeopleHomePageState();
}

class _PeopleHomePageState extends State<PeopleHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  List<String> _selectedRoleFilters = [];
  bool _showActiveOnly = true;
  bool _isGridView = false;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  List<PersonModel> _selectedPersons = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
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

  void _onFiltersChanged(List<String> roleFilters, bool activeOnly) {
    setState(() {
      _selectedRoleFilters = roleFilters;
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
        _selectedPersons.clear();
      }
    });
  }

  void _onPersonSelected(PersonModel person, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedPersons.add(person);
      } else {
        _selectedPersons.removeWhere((p) => p.id == person.id);
      }
    });
  }

  Future<void> _addNewPerson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonFormPage(),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Nouvelle personne ajoutée avec succès'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _performBulkAction(String action) async {
    if (_selectedPersons.isEmpty) return;

    switch (action) {
      case 'assign_role':
        await _showRoleAssignmentDialog();
        break;
      case 'add_tag':
        await _showTagDialog();
        break;

      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _showRoleAssignmentDialog() async {
    // Charger les rôles disponibles
    List<RoleModel> availableRoles = [];
    try {
      final rolesSnapshot = await RolesFirebaseService.getRolesStream(activeOnly: true).first;
      availableRoles = rolesSnapshot;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des rôles: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (availableRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun rôle disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Afficher le dialog de sélection de rôle
    final selectedRole = await showDialog<RoleModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attribuer un rôle à ${_selectedPersons.length} personne(s)'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableRoles.length,
            itemBuilder: (context, index) {
              final role = availableRoles[index];
              final roleColor = Color(int.parse(role.color.replaceFirst('#', '0xFF')));
              
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleColor, width: 1),
                  ),
                  child: Icon(
                    _getIconFromString(role.icon),
                    color: roleColor,
                    size: 20,
                  ),
                ),
                title: Text(role.name),
                subtitle: Text(role.description),
                onTap: () => Navigator.pop(context, role),
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

    if (selectedRole != null) {
      try {
        // Attribuer le rôle aux personnes sélectionnées
        final personIds = _selectedPersons.map((p) => p.id).toList();
        await RolesFirebaseService.assignRoleToPersons(personIds, selectedRole.id);

        // Réinitialiser la sélection
        setState(() {
          _selectedPersons.clear();
          _isSelectionMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle "${selectedRole.name}" attribué à ${personIds.length} personne(s)'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'attribution du rôle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'security':
        return Icons.security;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'church':
        return Icons.church;
      case 'supervisor_account':
        return Icons.supervisor_account;
      case 'person':
        return Icons.person;
      case 'people':
        return Icons.people;
      case 'group':
        return Icons.group;
      case 'groups':
        return Icons.groups;
      case 'event':
        return Icons.event;
      case 'assignment':
        return Icons.assignment;
      case 'description':
        return Icons.description;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'manage_accounts':
        return Icons.manage_accounts;
      case 'psychology':
        return Icons.psychology;
      case 'music_note':
        return Icons.music_note;
      case 'mic':
        return Icons.mic;
      case 'campaign':
        return Icons.campaign;
      case 'handshake':
        return Icons.handshake;
      default:
        return Icons.security;
    }
  }

  Future<void> _showTagDialog() async {
    // Implementation for tag dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout de tag en cours...')),
    );
  }



  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${_selectedPersons.length} personne(s) ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final personIds = _selectedPersons.map((p) => p.id).toList();
        await FirebaseService.bulkDeletePersons(personIds);
        
        setState(() {
          _selectedPersons.clear();
          _isSelectionMode = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Personnes supprimées avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: _isSelectionMode
            ? Text('${_selectedPersons.length} sélectionné(s)')
            : Row(
                children: [
                  Icon(
                    Icons.groups,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Personnes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showBulkActionsMenu(),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            ),
          ] else ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
              onPressed: _toggleViewMode,
              tooltip: _isGridView ? 'Vue liste' : 'Vue grille',
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Mode sélection',
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Plus d\'options',
              onSelected: (value) {
                switch (value) {
                  case 'custom_fields':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomFieldsManagementPage(),
                      ),
                    );
                    break;
                  case 'families_management':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamiliesManagementPage(),
                      ),
                    );
                    break;
                  case 'workflow_followups':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkflowFollowupsManagementPage(),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'custom_fields',
                  child: ListTile(
                    leading: Icon(Icons.dynamic_form),
                    title: Text('Champs personnalisés'),
                    subtitle: Text('Gérer les champs personnalisés'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'families_management',
                  child: ListTile(
                    leading: Icon(Icons.family_restroom),
                    title: Text('Gestion des familles'),
                    subtitle: Text('Gérer les relations familiales'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'workflow_followups',
                  child: ListTile(
                    leading: Icon(Icons.track_changes),
                    title: Text('Suivis de workflow'),
                    subtitle: Text('Gérer les suivis de workflow'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          SearchFilterBar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onFiltersChanged: _onFiltersChanged,
            selectedRoleFilters: _selectedRoleFilters,
            showActiveOnly: _showActiveOnly,
          ),
          
          // Statistics Row
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(51),
              ),
            ),
            child: FutureBuilder<Map<String, int>>(
              future: FirebaseService.getPersonStatistics(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatisticItem(
                        'Total',
                        stats['total'].toString(),
                        Icons.groups,
                        Theme.of(context).colorScheme.primary,
                      ),
                      _buildStatisticItem(
                        'Actifs',
                        stats['active'].toString(),
                        Icons.check_circle,
                        Theme.of(context).colorScheme.secondary,
                      ),
                      _buildStatisticItem(
                        'Hommes',
                        stats['male'].toString(),
                        Icons.man,
                        Theme.of(context).colorScheme.tertiary,
                      ),
                      _buildStatisticItem(
                        'Femmes',
                        stats['female'].toString(),
                        Icons.woman,
                        Colors.pink,
                      ),
                    ],
                  );
                }
                return const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          
          // Quick Actions Row
          // Bloc supprimé : Quick Action vers PeopleCustomListsPage (listes personnalisées)
          
          // People List
          Expanded(
            child: StreamBuilder<List<PersonModel>>(
              stream: FirebaseService.getPersonsStream(
                searchQuery: _searchQuery,
                roleFilters: _selectedRoleFilters.isNotEmpty ? _selectedRoleFilters : null,
                activeOnly: _showActiveOnly,
              ),
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
                          style: Theme.of(context).textTheme.titleLarge,
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
                
                final persons = snapshot.data ?? [];
                
                if (persons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucun résultat trouvé'
                              : 'Aucune personne enregistrée',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Essayez de modifier vos critères de recherche'
                              : 'Commencez par ajouter une nouvelle personne',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_searchQuery.isEmpty)
                          ElevatedButton.icon(
                            onPressed: _addNewPerson,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une personne'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                
                return _isGridView
                    ? _buildGridView(persons)
                    : _buildListView(persons);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _addNewPerson,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle personne'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<PersonModel> persons) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        final person = persons[index];
        final isSelected = _selectedPersons.any((p) => p.id == person.id);
        
        return PersonCard(
          person: person,
          onTap: () => _onPersonTap(person),
          onLongPress: () => _onPersonLongPress(person),
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onSelectionChanged: (selected) => _onPersonSelected(person, selected),
        );
      },
    );
  }

  Widget _buildGridView(List<PersonModel> persons) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        final person = persons[index];
        final isSelected = _selectedPersons.any((p) => p.id == person.id);
        
        return PersonCard(
          person: person,
          onTap: () => _onPersonTap(person),
          onLongPress: () => _onPersonLongPress(person),
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onSelectionChanged: (selected) => _onPersonSelected(person, selected),
          isGridView: true,
        );
      },
    );
  }

  void _onPersonTap(PersonModel person) {
    if (_isSelectionMode) {
      final isSelected = _selectedPersons.any((p) => p.id == person.id);
      _onPersonSelected(person, !isSelected);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonDetailPage(person: person),
        ),
      );
    }
  }

  void _onPersonLongPress(PersonModel person) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onPersonSelected(person, true);
    }
  }

  void _showBulkActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Actions pour ${_selectedPersons.length} personne(s)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Attribuer un rôle'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('assign_role');
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_offer),
                title: const Text('Ajouter un tag'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('add_tag');
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Supprimer',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('delete');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}