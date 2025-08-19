import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';
import '../services/workflow_initialization_service.dart';
import '../../compatibility/app_theme_bridge.dart';


class WorkflowFormPage extends StatefulWidget {
  final String? workflowId; // Pour modification
  final String? personId; // Pour assignment direct
  final String? personName; // Pour affichage
  
  const WorkflowFormPage({
    super.key,
    this.workflowId,
    this.personId,
    this.personName,
  });

  @override
  State<WorkflowFormPage> createState() => _WorkflowFormPageState();
}

class _WorkflowFormPageState extends State<WorkflowFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Général';
  String _selectedColor = '#2196F3';
  String _selectedIcon = 'track_changes';
  bool _isActive = true;
  bool _isLoading = false;
  
  List<WorkflowStep> _steps = [];
  WorkflowModel? _existingWorkflow;

  // Options prédéfinies
  final List<String> _categories = [
    'Général',
    'Intégration',
    'Soins pastoraux',
    'Formation',
    'Leadership',
    'Célébrations',
    'Missions',
    'Bénévolat',
  ];

  final List<Map<String, String>> _colorOptions = [
    {'name': 'Bleu', 'value': '#2196F3'},
    {'name': 'Vert', 'value': '#4CAF50'},
    {'name': 'Orange', 'value': '#FF9800'},
    {'name': 'Rouge', 'value': '#F44336'},
    {'name': 'Violet', 'value': '#9C27B0'},
    {'name': 'Indigo', 'value': '#3F51B5'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Rose', 'value': '#E91E63'},
    {'name': 'Marron', 'value': '#795548'},
    {'name': 'Gris', 'value': '#607D8B'},
  ];

  final List<Map<String, String>> _iconOptions = [
    {'name': 'Suivi général', 'value': 'track_changes'},
    {'name': 'Nouvelle personne', 'value': 'person_add'},
    {'name': 'Soins pastoraux', 'value': 'favorite'},
    {'name': 'Formation', 'value': 'school'},
    {'name': 'Guérison', 'value': 'healing'},
    {'name': 'Église', 'value': 'church'},
    {'name': 'Groupes', 'value': 'groups'},
    {'name': 'Bénévolat', 'value': 'volunteer_activism'},
    {'name': 'Conseil', 'value': 'psychology'},
    {'name': 'Célébration', 'value': 'celebration'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.workflowId != null) {
      _loadExistingWorkflow();
    } else {
      // Ajouter une première étape par défaut
      _addDefaultStep();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingWorkflow() async {
    try {
      final workflow = await FirebaseService.getWorkflow(widget.workflowId!);
      if (workflow != null && mounted) {
        setState(() {
          _existingWorkflow = workflow;
          _nameController.text = workflow.name;
          _descriptionController.text = workflow.description;
          _selectedCategory = workflow.category;
          _selectedColor = workflow.color;
          _selectedIcon = workflow.icon;
          _isActive = workflow.isActive;
          _steps = List.from(workflow.steps);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addDefaultStep() {
    setState(() {
      _steps.add(WorkflowStep(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Première étape',
        description: 'Description de la première étape',
        order: _steps.length + 1,
        isRequired: true,
        estimatedDuration: 30,
      ));
    });
  }

  void _addStep() {
    setState(() {
      _steps.add(WorkflowStep(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        description: '',
        order: _steps.length + 1,
        isRequired: false,
        estimatedDuration: 30,
      ));
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      // Réorganiser les ordres
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = WorkflowStep(
          id: _steps[i].id,
          name: _steps[i].name,
          description: _steps[i].description,
          order: i + 1,
          isRequired: _steps[i].isRequired,
          estimatedDuration: _steps[i].estimatedDuration,
        );
      }
    });
  }

  void _updateStep(int index, WorkflowStep updatedStep) {
    setState(() {
      _steps[index] = updatedStep;
    });
  }

  Future<void> _saveWorkflow() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez ajouter au moins une étape'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Vérifier que toutes les étapes ont un nom
    for (var step in _steps) {
      if (step.name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Toutes les étapes doivent avoir un nom'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workflow = WorkflowModel(
        id: _existingWorkflow?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        steps: _steps,
        category: _selectedCategory,
        color: _selectedColor,
        icon: _selectedIcon,
        isActive: _isActive,
        createdAt: _existingWorkflow?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: _existingWorkflow?.createdBy ?? '', // TODO: Get current user ID
      );

      String workflowId;
      if (_existingWorkflow != null) {
        // Mise à jour d'un workflow existant
        await FirebaseService.updateWorkflow(workflow.id, workflow);
        workflowId = workflow.id;
      } else {
        // Création d'un nouveau workflow
        workflowId = await FirebaseService.createWorkflow(workflow);
      }

      // Si on a un personId, assigner automatiquement le workflow
      if (widget.personId != null && workflowId.isNotEmpty) {
        await FirebaseService.startWorkflowForPerson(widget.personId!, workflowId);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'track_changes':
        return Icons.track_changes;
      case 'person_add':
        return Icons.person_add;
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'healing':
        return Icons.healing;
      case 'church':
        return Icons.church;
      case 'groups':
        return Icons.groups;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'psychology':
        return Icons.psychology;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.track_changes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_existingWorkflow != null ? 'Modifier le workflow' : 'Nouveau workflow'),
            if (widget.personName != null)
              Text(
                'Pour: ${widget.personName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveWorkflow,
              child: const Text('Sauvegarder'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image d'en-tête
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage("https://pixabay.com/get/g333a9455ffb685a7ace2267c54bb92110854647fae340b791a399723a68c3d006c491fd6bd23a4f8da1f26fa9988a7a68aba6d3d4bacff2439ad728db0948592_1280.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconData(_selectedIcon),
                        size: 32,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _existingWorkflow != null ? 'Modifier le workflow' : 'Créer un nouveau workflow',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Informations de base
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations générales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom du workflow
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du workflow *',
                        hintText: 'Ex: Accueil nouveaux membres',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Décrivez le processus et ses objectifs',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Catégorie
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Apparence
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apparence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Couleur
                    Text(
                      'Couleur',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((colorOption) {
                        final isSelected = _selectedColor == colorOption['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = colorOption['value']!;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse(colorOption['value']!.replaceFirst('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Icône
                    Text(
                      'Icône',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconOptions.map((iconOption) {
                        final isSelected = _selectedIcon == iconOption['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = iconOption['value']!;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))).withOpacity(0.1)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              _getIconData(iconOption['value']!),
                              color: isSelected
                                  ? Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Étapes du workflow
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Étapes du workflow',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addStep,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une étape'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_steps.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.playlist_add,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune étape définie',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Ajoutez des étapes pour structurer votre workflow',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          return _buildStepEditor(index);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Workflow actif'),
                      subtitle: Text(_isActive 
                          ? 'Ce workflow peut être utilisé'
                          : 'Ce workflow est désactivé'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStepEditor(int index) {
    final step = _steps[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.name.isEmpty ? 'Étape ${index + 1}' : step.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (step.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Obligatoire',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
              onTap: () => _removeStep(index),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Nom de l'étape
                TextFormField(
                  initialValue: step.name,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'étape *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _updateStep(index, WorkflowStep(
                      id: step.id,
                      name: value,
                      description: step.description,
                      order: step.order,
                      isRequired: step.isRequired,
                      estimatedDuration: step.estimatedDuration,
                    ));
                  },
                ),
                const SizedBox(height: 12),
                
                // Description
                TextFormField(
                  initialValue: step.description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    _updateStep(index, WorkflowStep(
                      id: step.id,
                      name: step.name,
                      description: value,
                      order: step.order,
                      isRequired: step.isRequired,
                      estimatedDuration: step.estimatedDuration,
                    ));
                  },
                ),
                const SizedBox(height: 12),
                
                // Options
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: step.estimatedDuration.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Durée estimée (minutes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final duration = int.tryParse(value) ?? 30;
                          _updateStep(index, WorkflowStep(
                            id: step.id,
                            name: step.name,
                            description: step.description,
                            order: step.order,
                            isRequired: step.isRequired,
                            estimatedDuration: duration,
                          ));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        const Text('Obligatoire'),
                        Switch(
                          value: step.isRequired,
                          onChanged: (value) {
                            _updateStep(index, WorkflowStep(
                              id: step.id,
                              name: step.name,
                              description: step.description,
                              order: step.order,
                              isRequired: value,
                              estimatedDuration: step.estimatedDuration,
                            ));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}