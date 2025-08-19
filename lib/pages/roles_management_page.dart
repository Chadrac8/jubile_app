import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/roles_firebase_service.dart';
import '../widgets/role_card.dart';
import 'role_form_page.dart';
import 'role_assignments_page.dart';
import '../theme.dart';

class RolesManagementPage extends StatefulWidget {
  const RolesManagementPage({super.key});

  @override
  State<RolesManagementPage> createState() => _RolesManagementPageState();
}

class _RolesManagementPageState extends State<RolesManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  bool _showActiveOnly = true;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late TabController _tabController;
  
  List<RoleModel> _selectedRoles = [];
  bool _isSelectionMode = false;
  bool _hasManageRolesPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );

    _tabController = TabController(length: 3, vsync: this);
    
    _fabAnimationController.forward();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await RolesFirebaseService.currentUserHasPermission('manage_roles');
    if (mounted) {
      setState(() {
        _hasManageRolesPermission = hasPermission;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onActiveFilterChanged(bool activeOnly) {
    setState(() {
      _showActiveOnly = activeOnly;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedRoles.clear();
      }
    });
  }

  void _onRoleSelected(RoleModel role, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedRoles.add(role);
      } else {
        _selectedRoles.removeWhere((r) => r.id == role.id);
      }
    });
  }

  Future<void> _addNewRole() async {
    if (!_hasManageRolesPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous n\'avez pas les permissions pour créer des rôles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleFormPage(),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rôle créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les rôles'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedRoles.length} rôle(s) sélectionné(s) ?\n\n'
          'Cette action est irréversible.',
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteSelectedRoles();
    }
  }

  Future<void> _deleteSelectedRoles() async {
    try {
      for (final role in _selectedRoles) {
        await RolesFirebaseService.deleteRole(role.id);
      }

      if (mounted) {
        setState(() {
          _selectedRoles.clear();
          _isSelectionMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rôles supprimés avec succès'),
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

  Future<void> _activateSelectedRoles() async {
    try {
      for (final role in _selectedRoles) {
        final updatedRole = RoleModel(
          id: role.id,
          name: role.name,
          description: role.description,
          color: role.color,
          permissions: role.permissions,
          icon: role.icon,
          isActive: true,
          createdAt: role.createdAt,
        );
        await RolesFirebaseService.updateRole(updatedRole);
      }

      if (mounted) {
        setState(() {
          _selectedRoles.clear();
          _isSelectionMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rôles activés avec succès'),
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

  Future<void> _deactivateSelectedRoles() async {
    try {
      for (final role in _selectedRoles) {
        final updatedRole = RoleModel(
          id: role.id,
          name: role.name,
          description: role.description,
          color: role.color,
          permissions: role.permissions,
          icon: role.icon,
          isActive: false,
          createdAt: role.createdAt,
        );
        await RolesFirebaseService.updateRole(updatedRole);
      }

      if (mounted) {
        setState(() {
          _selectedRoles.clear();
          _isSelectionMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rôles désactivés avec succès'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedRoles.length} rôle(s) sélectionné(s)')
            : const Text('Gestion des Rôles'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode && _hasManageRolesPermission) ...[
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _selectedRoles.isNotEmpty ? _activateSelectedRoles : null,
              tooltip: 'Activer',
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _selectedRoles.isNotEmpty ? _deactivateSelectedRoles : null,
              tooltip: 'Désactiver',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedRoles.isNotEmpty ? _showDeleteConfirmation : null,
              tooltip: 'Supprimer',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Sélection multiple',
            ),
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoleAssignmentsPage(),
                ),
              ),
              tooltip: 'Assignations',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Rôles', icon: Icon(Icons.security)),
            Tab(text: 'Permissions', icon: Icon(Icons.key)),
            Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRolesList(),
                _buildPermissionsTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _hasManageRolesPermission && !_isSelectionMode
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: _addNewRole,
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau rôle'),
              ),
            )
          : null,
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher des rôles...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Rôles actifs uniquement'),
                  value: _showActiveOnly,
                  onChanged: _onActiveFilterChanged,
                  activeColor: AppTheme.primaryColor,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    return StreamBuilder<List<RoleModel>>(
      stream: RolesFirebaseService.getRolesStream(
        searchQuery: _searchQuery,
        activeOnly: _showActiveOnly,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final roles = snapshot.data!;

        if (roles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'Aucun rôle trouvé' : 'Aucun rôle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty 
                      ? 'Aucun rôle ne correspond à votre recherche'
                      : 'Commencez par créer votre premier rôle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isEmpty && _hasManageRolesPermission) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addNewRole,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un rôle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            return RoleCard(
              role: role,
              onTap: () => _onRoleTap(role),
              onLongPress: () => _onRoleLongPress(role),
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedRoles.any((r) => r.id == role.id),
              onSelectionChanged: (isSelected) => _onRoleSelected(role, isSelected),
              canEdit: _hasManageRolesPermission,
            );
          },
        );
      },
    );
  }

  Widget _buildPermissionsTab() {
    final permissionCategories = RolesFirebaseService.getPermissionCategories();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permissionCategories.length,
      itemBuilder: (context, index) {
        final category = permissionCategories.keys.elementAt(index);
        final permissions = permissionCategories[category]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: Icon(
              _getCategoryIcon(category),
              color: AppTheme.primaryColor,
            ),
            children: permissions.map((permission) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.key, size: 16),
                title: Text(RolesFirebaseService.getPermissionLabel(permission)),
                subtitle: Text(permission),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: RolesFirebaseService.getRoleStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard(
                'Total des rôles',
                stats['totalRoles'].toString(),
                Icons.security,
                AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Rôles actifs',
                      stats['activeRoles'].toString(),
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Rôles inactifs',
                      stats['inactiveRoles'].toString(),
                      Icons.cancel,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Utilisation des rôles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<RoleModel>>(
                stream: RolesFirebaseService.getRolesStream(),
                builder: (context, roleSnapshot) {
                  if (!roleSnapshot.hasData) return const SizedBox.shrink();
                  
                  final roles = roleSnapshot.data!;
                  final roleUsage = stats['roleUsage'] as Map<String, dynamic>;
                  
                  return Column(
                    children: roles.map((role) {
                      final usage = roleUsage[role.id] ?? 0;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                            child: Icon(
                              _getIconFromString(role.icon),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(role.name),
                          trailing: Chip(
                            label: Text('$usage personne${usage > 1 ? 's' : ''}'),
                            backgroundColor: usage > 0 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[200],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    const categoryIcons = {
      'Personnes': Icons.people,
      'Groupes': Icons.groups,
      'Événements': Icons.event,
      'Services': Icons.church,
      'Formulaires': Icons.assignment,
      'Tâches': Icons.task_alt,
      'Chants': Icons.library_music,
      'Pages': Icons.web,
      'Rendez-vous': Icons.event_available,
      'Administration': Icons.admin_panel_settings,
    };
    
    return categoryIcons[category] ?? Icons.folder;
  }

  IconData _getIconFromString(String iconName) {
    const iconMap = {
      'admin_panel_settings': Icons.admin_panel_settings,
      'church': Icons.church,
      'supervisor_account': Icons.supervisor_account,
      'description': Icons.description,
      'person': Icons.person,
      'security': Icons.security,
    };
    
    return iconMap[iconName] ?? Icons.security;
  }

  void _onRoleTap(RoleModel role) {
    if (_isSelectionMode) {
      final isSelected = _selectedRoles.any((r) => r.id == role.id);
      _onRoleSelected(role, !isSelected);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoleFormPage(role: role),
        ),
      );
    }
  }

  void _onRoleLongPress(RoleModel role) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onRoleSelected(role, true);
    }
  }
}