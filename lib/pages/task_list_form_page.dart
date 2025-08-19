import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/person_model.dart';
import '../services/tasks_firebase_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';

class TaskListFormPage extends StatefulWidget {
  final TaskListModel? taskList;

  const TaskListFormPage({super.key, this.taskList});

  @override
  State<TaskListFormPage> createState() => _TaskListFormPageState();
}

class _TaskListFormPageState extends State<TaskListFormPage>
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
  String _visibility = 'private';
  List<String> _visibilityTargets = [];
  String _status = 'active';
  String? _color;
  String? _iconName;
  List<String> _memberIds = [];
  bool _isLoading = false;

  final List<Map<String, String>> _visibilityOptions = [
    {'value': 'public', 'label': 'Publique', 'description': 'Visible par tous'},
    {'value': 'private', 'label': 'Privée', 'description': 'Visible uniquement par le propriétaire'},
    {'value': 'group', 'label': 'Réservée aux groupes', 'description': 'Visible par les membres de groupes spécifiques'},
    {'value': 'role', 'label': 'Réservée aux rôles', 'description': 'Visible par les membres avec des rôles spécifiques'},
  ];

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
  ];

  final List<Map<String, String>> _iconOptions = [
    {'value': 'list_alt', 'label': 'Liste'},
    {'value': 'task_alt', 'label': 'Tâche'},
    {'value': 'checklist', 'label': 'Checklist'},
    {'value': 'assignment', 'label': 'Assignation'},
    {'value': 'folder', 'label': 'Dossier'},
    {'value': 'work', 'label': 'Travail'},
    {'value': 'home', 'label': 'Maison'},
    {'value': 'school', 'label': 'École'},
    {'value': 'shopping_cart', 'label': 'Courses'},
    {'value': 'event', 'label': 'Événement'},
    {'value': 'people', 'label': 'Personnes'},
    {'value': 'church', 'label': 'Église'},
    {'value': 'volunteer_activism', 'label': 'Bénévolat'},
    {'value': 'groups', 'label': 'Groupes'},
    {'value': 'campaign', 'label': 'Campagne'},
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  void _initializeForm() {
    if (widget.taskList != null) {
      final taskList = widget.taskList!;
      _nameController.text = taskList.name;
      _descriptionController.text = taskList.description;
      _visibility = taskList.visibility;
      _visibilityTargets = List.from(taskList.visibilityTargets);
      _status = taskList.status;
      _color = taskList.color;
      _iconName = taskList.iconName;
      _memberIds = List.from(taskList.memberIds);
    } else {
      _color = _predefinedColors.first;
      _iconName = _iconOptions.first['value'];
    }
  }

  Future<void> _selectMembers() async {
    try {
      final persons = await FirebaseService.getAllPersons();
      
      if (!mounted) return;
      
      final selectedIds = await showDialog<List<String>>(
        context: context,
        builder: (context) => _MemberSelectionDialog(
          persons: persons,
          selectedIds: _memberIds,
        ),
      );
      
      if (selectedIds != null) {
        setState(() => _memberIds = selectedIds);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des personnes: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveTaskList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final currentUserId = AuthService.currentUser?.uid ?? '';

      if (widget.taskList == null) {
        // Create new task list
        final taskList = TaskListModel(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          ownerId: currentUserId,
          visibility: _visibility,
          visibilityTargets: _visibilityTargets,
          status: _status,
          color: _color,
          iconName: _iconName,
          memberIds: _memberIds,
          createdAt: now,
          updatedAt: now,
        );

        await TasksFirebaseService.createTaskList(taskList);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liste créée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing task list
        final updatedTaskList = widget.taskList!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          visibility: _visibility,
          visibilityTargets: _visibilityTargets,
          status: _status,
          color: _color,
          iconName: _iconName,
          memberIds: _memberIds,
          updatedAt: now,
          lastModifiedBy: currentUserId,
        );

        await TasksFirebaseService.updateTaskList(updatedTaskList);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liste mise à jour avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskList == null ? 'Nouvelle liste' : 'Modifier la liste'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTaskList,
              child: const Text('Sauvegarder'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 50 * _slideAnimation.value),
              child: _buildForm(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Informations générales',
            icon: Icons.info_outline,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nom de la liste',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Apparence',
            icon: Icons.palette,
            children: [
              _buildColorSelector(),
              const SizedBox(height: 16),
              _buildIconSelector(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Visibilité',
            icon: Icons.visibility,
            children: [
              _buildVisibilitySelector(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Membres',
            icon: Icons.people_outline,
            children: [
              _buildMemberSelector(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Statut',
            icon: Icons.flag_outlined,
            children: [
              _buildStatusSelector(),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Couleur de la liste'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _predefinedColors.map((color) {
            final isSelected = _color == color;
            final colorValue = Color(int.parse(color.replaceFirst('#', '0xFF')));
            
            return GestureDetector(
              onTap: () => setState(() => _color = color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorValue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: colorValue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Icône de la liste'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _iconName,
          decoration: const InputDecoration(
            labelText: 'Icône',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: _iconOptions.map((icon) {
            return DropdownMenuItem(
              value: icon['value'],
              child: Row(
                children: [
                  Icon(_getIconFromString(icon['value']!)),
                  const SizedBox(width: 8),
                  Text(icon['label']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _iconName = value);
          },
        ),
      ],
    );
  }

  Widget _buildVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Qui peut voir cette liste ?'),
        const SizedBox(height: 12),
        ..._visibilityOptions.map((option) {
          return RadioListTile<String>(
            title: Text(option['label']!),
            subtitle: Text(option['description']!),
            value: option['value']!,
            groupValue: _visibility,
            onChanged: (value) {
              setState(() {
                _visibility = value!;
                _visibilityTargets.clear();
              });
            },
          );
        }).toList(),
        if (_visibility == 'group' || _visibility == 'role') ...[
          const SizedBox(height: 16),
          const Text('Configuration de la visibilité à implémenter'),
        ],
      ],
    );
  }

  Widget _buildMemberSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Membres avec accès')),
            TextButton.icon(
              onPressed: _selectMembers,
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        if (_memberIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _memberIds.map((id) {
              return Chip(
                label: Text('Membre $id'), // TODO: Load actual person name
                onDeleted: () {
                  setState(() => _memberIds.remove(id));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSelector() {
    return SwitchListTile(
      title: const Text('Liste active'),
      subtitle: const Text('Les listes inactives sont archivées'),
      value: _status == 'active',
      onChanged: (value) {
        setState(() => _status = value ? 'active' : 'archived');
      },
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'list_alt':
        return Icons.list_alt;
      case 'task_alt':
        return Icons.task_alt;
      case 'checklist':
        return Icons.checklist;
      case 'assignment':
        return Icons.assignment;
      case 'folder':
        return Icons.folder;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'event':
        return Icons.event;
      case 'people':
        return Icons.people;
      case 'church':
        return Icons.church;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'groups':
        return Icons.groups;
      case 'campaign':
        return Icons.campaign;
      default:
        return Icons.list_alt;
    }
  }
}

class _MemberSelectionDialog extends StatefulWidget {
  final List<PersonModel> persons;
  final List<String> selectedIds;

  const _MemberSelectionDialog({
    required this.persons,
    required this.selectedIds,
  });

  @override
  State<_MemberSelectionDialog> createState() => _MemberSelectionDialogState();
}

class _MemberSelectionDialogState extends State<_MemberSelectionDialog> {
  late List<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredPersons = widget.persons.where((person) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return person.fullName.toLowerCase().contains(query) ||
             person.email.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: const Text('Sélectionner les membres'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  final isSelected = _selectedIds.contains(person.id);
                  
                  return CheckboxListTile(
                    title: Text(person.fullName),
                    subtitle: Text(person.email),
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedIds.add(person.id);
                        } else {
                          _selectedIds.remove(person.id);
                        }
                      });
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
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}