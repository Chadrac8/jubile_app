import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dynamic_list_model.dart';
import '../services/dynamic_lists_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import '../widgets/custom_card.dart';

/// Page de construction/édition d'une liste dynamique
class DynamicListBuilderPage extends StatefulWidget {
  final DynamicListModel? existingList;
  final DynamicListTemplate? template;

  const DynamicListBuilderPage({
    Key? key,
    this.existingList,
    this.template,
  }) : super(key: key);

  @override
  State<DynamicListBuilderPage> createState() => _DynamicListBuilderPageState();
}

class _DynamicListBuilderPageState extends State<DynamicListBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedSourceModule = 'people';
  String _selectedCategory = 'general';
  bool _isPublic = false;
  List<DynamicListField> _fields = [];
  List<DynamicListFilter> _filters = [];
  List<DynamicListSort> _sorting = [];
  
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _sourceModules = [
    'people',
    'groups',
    'events',
    'tasks',
    'services',
  ];

  final List<String> _categories = [
    'general',
    'ministry',
    'admin',
    'personal',
  ];

  final Map<String, String> _moduleLabels = {
    'people': 'Personnes',
    'groups': 'Groupes',
    'events': 'Événements',
    'tasks': 'Tâches',
    'services': 'Services',
  };

  final Map<String, String> _categoryLabels = {
    'general': 'Général',
    'ministry': 'Ministère',
    'admin': 'Administration',
    'personal': 'Personnel',
  };

  final Map<String, List<DynamicListField>> _availableFields = {
    'people': [
      DynamicListField(fieldKey: 'firstName', displayName: 'Prénom', fieldType: 'text'),
      DynamicListField(fieldKey: 'lastName', displayName: 'Nom', fieldType: 'text'),
      DynamicListField(fieldKey: 'fullName', displayName: 'Nom complet', fieldType: 'text'),
      DynamicListField(fieldKey: 'email', displayName: 'Email', fieldType: 'email'),
      DynamicListField(fieldKey: 'phone', displayName: 'Téléphone', fieldType: 'phone'),
      DynamicListField(fieldKey: 'birthDate', displayName: 'Date de naissance', fieldType: 'date'),
      DynamicListField(fieldKey: 'address', displayName: 'Adresse', fieldType: 'text'),
      DynamicListField(fieldKey: 'city', displayName: 'Ville', fieldType: 'text'),
      DynamicListField(fieldKey: 'roles', displayName: 'Rôles', fieldType: 'list'),
      DynamicListField(fieldKey: 'isActive', displayName: 'Actif', fieldType: 'boolean'),
      DynamicListField(fieldKey: 'joinDate', displayName: 'Date d\'adhésion', fieldType: 'date'),
    ],
    'groups': [
      DynamicListField(fieldKey: 'name', displayName: 'Nom du groupe', fieldType: 'text'),
      DynamicListField(fieldKey: 'description', displayName: 'Description', fieldType: 'text'),
      DynamicListField(fieldKey: 'category', displayName: 'Catégorie', fieldType: 'text'),
      DynamicListField(fieldKey: 'leader', displayName: 'Responsable', fieldType: 'text'),
      DynamicListField(fieldKey: 'memberCount', displayName: 'Nombre de membres', fieldType: 'number'),
      DynamicListField(fieldKey: 'meetingDay', displayName: 'Jour de réunion', fieldType: 'text'),
      DynamicListField(fieldKey: 'meetingTime', displayName: 'Heure de réunion', fieldType: 'time'),
      DynamicListField(fieldKey: 'location', displayName: 'Lieu', fieldType: 'text'),
      DynamicListField(fieldKey: 'isActive', displayName: 'Actif', fieldType: 'boolean'),
    ],
    'events': [
      DynamicListField(fieldKey: 'title', displayName: 'Titre', fieldType: 'text'),
      DynamicListField(fieldKey: 'description', displayName: 'Description', fieldType: 'text'),
      DynamicListField(fieldKey: 'startDate', displayName: 'Date de début', fieldType: 'datetime'),
      DynamicListField(fieldKey: 'endDate', displayName: 'Date de fin', fieldType: 'datetime'),
      DynamicListField(fieldKey: 'location', displayName: 'Lieu', fieldType: 'text'),
      DynamicListField(fieldKey: 'category', displayName: 'Catégorie', fieldType: 'text'),
      DynamicListField(fieldKey: 'registrationCount', displayName: 'Inscrits', fieldType: 'number'),
      DynamicListField(fieldKey: 'maxParticipants', displayName: 'Participants max', fieldType: 'number'),
      DynamicListField(fieldKey: 'status', displayName: 'Statut', fieldType: 'text'),
    ],
    'tasks': [
      DynamicListField(fieldKey: 'title', displayName: 'Titre', fieldType: 'text'),
      DynamicListField(fieldKey: 'description', displayName: 'Description', fieldType: 'text'),
      DynamicListField(fieldKey: 'priority', displayName: 'Priorité', fieldType: 'text'),
      DynamicListField(fieldKey: 'status', displayName: 'Statut', fieldType: 'text'),
      DynamicListField(fieldKey: 'dueDate', displayName: 'Échéance', fieldType: 'date'),
      DynamicListField(fieldKey: 'assignedTo', displayName: 'Assigné à', fieldType: 'text'),
      DynamicListField(fieldKey: 'assignedBy', displayName: 'Assigné par', fieldType: 'text'),
      DynamicListField(fieldKey: 'category', displayName: 'Catégorie', fieldType: 'text'),
    ],
    'services': [
      DynamicListField(fieldKey: 'title', displayName: 'Titre', fieldType: 'text'),
      DynamicListField(fieldKey: 'date', displayName: 'Date', fieldType: 'datetime'),
      DynamicListField(fieldKey: 'type', displayName: 'Type', fieldType: 'text'),
      DynamicListField(fieldKey: 'leader', displayName: 'Responsable', fieldType: 'text'),
      DynamicListField(fieldKey: 'attendees', displayName: 'Participants', fieldType: 'number'),
      DynamicListField(fieldKey: 'location', displayName: 'Lieu', fieldType: 'text'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingList != null) {
      final list = widget.existingList!;
      _nameController.text = list.name;
      _descriptionController.text = list.description;
      _selectedSourceModule = list.sourceModule;
      _selectedCategory = list.category;
      _isPublic = list.isPublic;
      _fields = List.from(list.fields);
      _filters = List.from(list.filters);
      _sorting = List.from(list.sorting);
    } else if (widget.template != null) {
      final template = widget.template!;
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _selectedSourceModule = template.sourceModule;
      _selectedCategory = template.category;
      _fields = List.from(template.fields);
      _filters = List.from(template.filters);
      _sorting = List.from(template.sorting);
    } else {
      // Champs par défaut pour les personnes
      _fields = [
        DynamicListField(fieldKey: 'firstName', displayName: 'Prénom', fieldType: 'text', order: 0),
        DynamicListField(fieldKey: 'lastName', displayName: 'Nom', fieldType: 'text', order: 1),
        DynamicListField(fieldKey: 'email', displayName: 'Email', fieldType: 'email', order: 2),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text(
          widget.existingList != null ? 'Modifier la liste' : 'Nouvelle liste',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Précédent', style: TextStyle(color: Colors.white)),
            ),
          if (_currentStep < 2)
            TextButton(
              onPressed: _canGoNext() ? () => setState(() => _currentStep++) : null,
              child: const Text('Suivant', style: TextStyle(color: Colors.white)),
            ),
          if (_currentStep == 2)
            TextButton(
              onPressed: _canSave() ? _saveList : null,
              child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Configuration', _currentStep >= 0),
          Expanded(child: Container(height: 2, color: _currentStep >= 1 ? Colors.blue : Colors.grey[300])),
          _buildStepIndicator(1, 'Champs', _currentStep >= 1),
          Expanded(child: Container(height: 2, color: _currentStep >= 2 ? Colors.blue : Colors.grey[300])),
          _buildStepIndicator(2, 'Filtres & Tri', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? Colors.blue : Colors.grey[300],
          child: Text(
            '${step + 1}',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildConfigurationStep();
      case 1:
        return _buildFieldsStep();
      case 2:
        return _buildFiltersStep();
      default:
        return Container();
    }
  }

  Widget _buildConfigurationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration de base',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la liste',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedSourceModule,
                      decoration: const InputDecoration(
                        labelText: 'Source des données',
                        border: OutlineInputBorder(),
                      ),
                      items: _sourceModules.map((module) {
                        return DropdownMenuItem(
                          value: module,
                          child: Text(_moduleLabels[module] ?? module),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSourceModule = value!;
                          _fields = []; // Reset fields when changing module
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(_categoryLabels[category] ?? category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Liste publique'),
                      subtitle: const Text('Visible par tous les utilisateurs'),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() => _isPublic = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsStep() {
    final availableFields = _availableFields[_selectedSourceModule] ?? [];
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sélectionner les champs à afficher',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddFieldDialog,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final field = _fields.removeAt(oldIndex);
                _fields.insert(newIndex, field);
                
                // Update orders
                for (int i = 0; i < _fields.length; i++) {
                  _fields[i] = DynamicListField(
                    fieldKey: _fields[i].fieldKey,
                    displayName: _fields[i].displayName,
                    fieldType: _fields[i].fieldType,
                    isVisible: _fields[i].isVisible,
                    order: i,
                    format: _fields[i].format,
                    isClickable: _fields[i].isClickable,
                  );
                }
              });
            },
            children: _fields.map((field) {
              return _buildFieldCard(field);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCard(DynamicListField field) {
    return CustomCard(
      key: ValueKey(field.fieldKey),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getFieldIcon(field.fieldType),
          color: AppTheme.primaryColor,
        ),
        title: Text(field.displayName),
        subtitle: Text('Type: ${field.fieldType}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: field.isVisible,
              onChanged: (value) {
                setState(() {
                  final index = _fields.indexOf(field);
                  _fields[index] = DynamicListField(
                    fieldKey: field.fieldKey,
                    displayName: field.displayName,
                    fieldType: field.fieldType,
                    isVisible: value,
                    order: field.order,
                    format: field.format,
                    isClickable: field.isClickable,
                  );
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editField(field),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeField(field),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres et tri',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Section Filtres
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      const Text('Filtres'),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addFilter,
                        icon: const Icon(Icons.add),
                        label: const Text('Filtre'),
                      ),
                    ],
                  ),
                  if (_filters.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun filtre défini'),
                    )
                  else
                    ..._filters.map((filter) => _buildFilterCard(filter)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Section Tri
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sort),
                      const SizedBox(width: 8),
                      const Text('Tri'),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addSort,
                        icon: const Icon(Icons.add),
                        label: const Text('Tri'),
                      ),
                    ],
                  ),
                  if (_sorting.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun tri défini'),
                    )
                  else
                    ..._sorting.map((sort) => _buildSortCard(sort)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(DynamicListFilter filter) {
    return Card(
      child: ListTile(
        title: Text('${filter.fieldKey} ${filter.operator} ${filter.value}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeFilter(filter),
        ),
      ),
    );
  }

  Widget _buildSortCard(DynamicListSort sort) {
    return Card(
      child: ListTile(
        title: Text('${sort.fieldKey} - ${sort.direction == 'asc' ? 'Croissant' : 'Décroissant'}'),
        subtitle: Text('Priorité: ${sort.priority}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeSort(sort),
        ),
      ),
    );
  }

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'date':
      case 'datetime':
        return Icons.calendar_today;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'boolean':
        return Icons.check_box;
      case 'list':
        return Icons.list;
      default:
        return Icons.text_fields;
    }
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty && _descriptionController.text.isNotEmpty;
      case 1:
        return _fields.isNotEmpty;
      default:
        return true;
    }
  }

  bool _canSave() {
    return _canGoNext();
  }

  void _showAddFieldDialog() {
    final availableFields = _availableFields[_selectedSourceModule] ?? [];
    final unusedFields = availableFields.where((field) {
      return !_fields.any((f) => f.fieldKey == field.fieldKey);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un champ'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unusedFields.length,
            itemBuilder: (context, index) {
              final field = unusedFields[index];
              return ListTile(
                leading: Icon(_getFieldIcon(field.fieldType)),
                title: Text(field.displayName),
                subtitle: Text(field.fieldType),
                onTap: () {
                  setState(() {
                    _fields.add(DynamicListField(
                      fieldKey: field.fieldKey,
                      displayName: field.displayName,
                      fieldType: field.fieldType,
                      order: _fields.length,
                    ));
                  });
                  Navigator.pop(context);
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

  void _editField(DynamicListField field) {
    final displayNameController = TextEditingController(text: field.displayName);
    bool isClickable = field.isClickable;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le champ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'affichage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return CheckboxListTile(
                  title: const Text('Champ cliquable'),
                  value: isClickable,
                  onChanged: (value) {
                    setDialogState(() => isClickable = value ?? false);
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = _fields.indexOf(field);
                _fields[index] = DynamicListField(
                  fieldKey: field.fieldKey,
                  displayName: displayNameController.text,
                  fieldType: field.fieldType,
                  isVisible: field.isVisible,
                  order: field.order,
                  format: field.format,
                  isClickable: isClickable,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _removeField(DynamicListField field) {
    setState(() {
      _fields.remove(field);
    });
  }

  void _addFilter() {
    // TODO: Implémenter l'ajout de filtres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  void _removeFilter(DynamicListFilter filter) {
    setState(() {
      _filters.remove(filter);
    });
  }

  void _addSort() {
    // TODO: Implémenter l'ajout de tri
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  void _removeSort(DynamicListSort sort) {
    setState(() {
      _sorting.remove(sort);
    });
  }

  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final list = DynamicListModel(
        id: widget.existingList?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        sourceModule: _selectedSourceModule,
        fields: _fields,
        filters: _filters,
        sorting: _sorting,
        createdBy: user.uid,
        createdAt: widget.existingList?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: _isPublic,
        category: _selectedCategory,
      );

      if (widget.existingList != null) {
        await DynamicListsFirebaseService.updateList(widget.existingList!.id, list);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liste mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await DynamicListsFirebaseService.createList(list);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liste créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}