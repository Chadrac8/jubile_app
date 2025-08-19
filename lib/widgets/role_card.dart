import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/roles_firebase_service.dart';
import '../theme.dart';

class RoleCard extends StatefulWidget {
  final RoleModel role;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final bool canEdit;

  const RoleCard({
    super.key,
    required this.role,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
    this.canEdit = false,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  Color get _roleColor => Color(int.parse(widget.role.color.replaceFirst('#', '0xFF')));

  IconData get _roleIcon {
    const iconMap = {
      'admin_panel_settings': Icons.admin_panel_settings,
      'church': Icons.church,
      'supervisor_account': Icons.supervisor_account,
      'description': Icons.description,
      'person': Icons.person,
      'security': Icons.security,
    };
    
    return iconMap[widget.role.icon] ?? Icons.security;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: widget.isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildContent(),
            if (widget.role.permissions.isNotEmpty) _buildPermissions(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _roleColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _roleColor,
            radius: 24,
            child: Icon(
              _roleIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.role.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _roleColor,
                        ),
                      ),
                    ),
                    if (widget.isSelectionMode)
                      Checkbox(
                        value: widget.isSelected,
                        onChanged: (value) => widget.onSelectionChanged(value ?? false),
                        activeColor: AppTheme.primaryColor,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.role.isActive ? AppTheme.successColor : AppTheme.warningColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.role.isActive ? 'Actif' : 'Inactif',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.role.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<PersonModel>>(
            stream: RolesFirebaseService.getPersonsWithRole(widget.role.id),
            builder: (context, snapshot) {
              final personCount = snapshot.data?.length ?? 0;
              
              return Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$personCount personne${personCount > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.security,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.role.permissions.length} permission${widget.role.permissions.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissions() {
    // Afficher seulement les 3 premières permissions
    final displayPermissions = widget.role.permissions.take(3).toList();
    final remainingCount = widget.role.permissions.length - displayPermissions.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions principales',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...displayPermissions.map((permission) => _buildPermissionChip(permission)),
              if (remainingCount > 0)
                Chip(
                  label: Text('+$remainingCount'),
                  backgroundColor: Colors.grey[200],
                  labelStyle: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip(String permission) {
    return Chip(
      label: Text(
        RolesFirebaseService.getPermissionLabel(permission),
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: _roleColor.withOpacity(0.1),
      side: BorderSide(color: _roleColor.withOpacity(0.3)),
      labelStyle: TextStyle(color: _roleColor),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 4),
          Text(
            'Créé le ${_formatDate(widget.role.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[400],
            ),
          ),
          const Spacer(),
          if (widget.canEdit && !widget.isSelectionMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: widget.onTap,
                  color: Colors.grey[600],
                  iconSize: 20,
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showActionMenu(context),
                  color: Colors.grey[600],
                  iconSize: 20,
                  tooltip: 'Plus d\'actions',
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                widget.onTap();
              },
            ),
            ListTile(
              leading: Icon(
                widget.role.isActive ? Icons.cancel : Icons.check_circle,
              ),
              title: Text(widget.role.isActive ? 'Désactiver' : 'Activer'),
              onTap: () {
                Navigator.pop(context);
                _toggleStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Voir les assignations'),
              onTap: () {
                Navigator.pop(context);
                _viewAssignments();
              },
            ),
            if (widget.role.permissions.contains('system_admin')) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text('Rôle système'),
                subtitle: const Text('Ce rôle ne peut pas être supprimé'),
                enabled: false,
              ),
            ] else ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteRole(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus() async {
    try {
      final updatedRole = RoleModel(
        id: widget.role.id,
        name: widget.role.name,
        description: widget.role.description,
        color: widget.role.color,
        permissions: widget.role.permissions,
        icon: widget.role.icon,
        isActive: !widget.role.isActive,
        createdAt: widget.role.createdAt,
      );
      
      await RolesFirebaseService.updateRole(updatedRole);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle ${widget.role.isActive ? 'désactivé' : 'activé'} avec succès'),
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

  void _viewAssignments() {
    // TODO: Naviguer vers la page des assignations du rôle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité à venir'),
      ),
    );
  }

  Future<void> _deleteRole(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rôle'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le rôle "${widget.role.name}" ?\n\n'
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
      try {
        await RolesFirebaseService.deleteRole(widget.role.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rôle supprimé avec succès'),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}