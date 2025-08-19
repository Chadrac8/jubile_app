import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/roles_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class RoleFormPage extends StatefulWidget {
  final RoleModel? role;

  const RoleFormPage({super.key, this.role});

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form values
  String _selectedColor = '#6F61EF';
  String _selectedIcon = 'security';
  List<String> _selectedPermissions = [];
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _predefinedColors = [
    '#6F61EF', // Primary
    '#39D2C0', // Secondary
    '#EE8B60', // Tertiary
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DDA0DD', // Plum
    '#98D8C8', // Mint
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#3F51B5', // Indigo
    '#607D8B', // Blue Grey
    '#795548', // Brown
  ];

  final List<Map<String, String>> _iconOptions = [
    {'value': 'security', 'label': 'Sécurité'},
    {'value': 'admin_panel_settings', 'label': 'Administration'},
    {'value': 'church', 'label': 'Église'},
    {'value': 'supervisor_account', 'label': 'Supervision'},
    {'value': 'person', 'label': 'Personne'},
    {'value': 'people', 'label': 'Personnes'},
    {'value': 'group', 'label': 'Groupe'},
    {'value': 'groups', 'label': 'Groupes'},
    {'value': 'event', 'label': 'Événement'},
    {'value': 'assignment', 'label': 'Assignation'},
    {'value': 'description', 'label': 'Description'},
    {'value': 'work', 'label': 'Travail'},
    {'value': 'school', 'label': 'Formation'},
    {'value': 'volunteer_activism', 'label': 'Bénévolat'},
    {'value': 'manage_accounts', 'label': 'Gestion des comptes'},
    {'value': 'psychology', 'label': 'Conseil'},
    {'value': 'music_note', 'label': 'Musique'},
    {'value': 'mic', 'label': 'Microphone'},
    {'value': 'campaign', 'label': 'Communication'},
    {'value': 'handshake', 'label': 'Accueil'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  void _initializeForm() {
    if (widget.role != null) {
      _nameController.text = widget.role!.name;
      _descriptionController.text = widget.role!.description;
      _selectedColor = widget.role!.color;
      _selectedIcon = widget.role!.icon;
      _selectedPermissions = List.from(widget.role!.permissions);
      _isActive = widget.role!.isActive;
    }
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final role = RoleModel(
        id: widget.role?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
        permissions: _selectedPermissions,
        icon: _selectedIcon,
        isActive: _isActive,
        createdAt: widget.role?.createdAt ?? DateTime.now(),
      );

      if (widget.role == null) {
        await RolesFirebaseService.createRole(role);
      } else {
        await RolesFirebaseService.updateRole(role);
      }

      if (mounted) {
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == null ? 'Nouveau rôle' : 'Modifier le rôle'),
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveRole,
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildAppearanceSection(),
                const SizedBox(height: 24),
                _buildPermissionsSection(),
                const SizedBox(height: 24),
                _buildStatusSection(),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveRole,
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        foregroundColor: Colors.white,
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer'),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Informations générales',
      icon: Icons.info,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du rôle',
            hintText: 'Ex: Administrateur, Pasteur, Membre...',
            prefixIcon: Icon(Icons.badge),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom du rôle est obligatoire';
            }
            if (value.trim().length < 2) {
              return 'Le nom doit contenir au moins 2 caractères';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Décrivez les responsabilités de ce rôle...',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est obligatoire';
            }
            if (value.trim().length < 10) {
              return 'La description doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSection(
      title: 'Apparence',
      icon: Icons.palette,
      children: [
        const Text(
          'Couleur',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _predefinedColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Theme.of(context).colorScheme.primaryColor, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Icône',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedIcon,
          decoration: const InputDecoration(
            labelText: 'Choisir une icône',
            prefixIcon: Icon(Icons.image),
          ),
          items: _iconOptions.map((option) {
            return DropdownMenuItem(
              value: option['value'],
              child: Row(
                children: [
                  Icon(_getIconFromString(option['value']!)),
                  const SizedBox(width: 12),
                  Text(option['label']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedIcon = value);
            }
          },
        ),
        const SizedBox(height: 16),
        // Prévisualisation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                child: Icon(
                  _getIconFromString(_selectedIcon),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Aperçu du rôle',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Aperçu de l\'apparence du rôle',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    final permissionCategories = RolesFirebaseService.getPermissionCategories();
    
    return _buildSection(
      title: 'Permissions',
      icon: Icons.key,
      children: [
        Text(
          '${_selectedPermissions.length} permission${_selectedPermissions.length > 1 ? 's' : ''} sélectionnée${_selectedPermissions.length > 1 ? 's' : ''}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        ...permissionCategories.entries.map((entry) {
          final category = entry.key;
          final permissions = entry.value;
          final selectedInCategory = permissions.where((p) => _selectedPermissions.contains(p)).length;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(category),
                subtitle: Text('$selectedInCategory/${permissions.length} sélectionnée${selectedInCategory > 1 ? 's' : ''}'),
                leading: Icon(
                  _getCategoryIcon(category),
                  color: selectedInCategory > 0 ? Theme.of(context).colorScheme.primaryColor : Colors.grey,
                ),
                children: permissions.map((permission) {
                  final isSelected = _selectedPermissions.contains(permission);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(RolesFirebaseService.getPermissionLabel(permission)),
                    subtitle: Text(
                      permission,
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedPermissions.add(permission);
                        } else {
                          _selectedPermissions.remove(permission);
                        }
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primaryColor,
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatusSection() {
    return _buildSection(
      title: 'Statut',
      icon: Icons.toggle_on,
      children: [
        SwitchListTile(
          title: const Text('Rôle actif'),
          subtitle: Text(_isActive 
              ? 'Ce rôle peut être assigné aux utilisateurs'
              : 'Ce rôle est désactivé et ne peut pas être assigné'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
          activeColor: Theme.of(context).colorScheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
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
      'security': Icons.security,
      'admin_panel_settings': Icons.admin_panel_settings,
      'church': Icons.church,
      'supervisor_account': Icons.supervisor_account,
      'person': Icons.person,
      'people': Icons.people,
      'group': Icons.group,
      'groups': Icons.groups,
      'event': Icons.event,
      'assignment': Icons.assignment,
      'description': Icons.description,
      'work': Icons.work,
      'school': Icons.school,
      'volunteer_activism': Icons.volunteer_activism,
      'manage_accounts': Icons.manage_accounts,
      'psychology': Icons.psychology,
      'music_note': Icons.music_note,
      'mic': Icons.mic,
      'campaign': Icons.campaign,
      'handshake': Icons.handshake,
    };
    
    return iconMap[iconName] ?? Icons.security;
  }
}