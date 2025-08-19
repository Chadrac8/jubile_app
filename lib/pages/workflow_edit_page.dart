import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class WorkflowEditPage extends StatefulWidget {
  final PersonWorkflowModel personWorkflow;
  final WorkflowModel workflow;
  final PersonModel person;

  const WorkflowEditPage({
    super.key,
    required this.personWorkflow,
    required this.workflow,
    required this.person,
  });

  @override
  State<WorkflowEditPage> createState() => _WorkflowEditPageState();
}

class _WorkflowEditPageState extends State<WorkflowEditPage> {
  late TextEditingController _notesController;
  String _selectedStatus = 'pending';
  bool _isLoading = false;
  bool _hasChanges = false;
  WorkflowModel? _currentWorkflow;
  List<PersonModel> _availablePersons = [];

  final List<String> _statusOptions = [
    'pending',
    'in_progress',
    'completed',
    'paused',
  ];

  final Map<String, String> _statusLabels = {
    'pending': 'En attente',
    'in_progress': 'En cours',
    'completed': 'Terminé',
    'paused': 'En pause',
  };

  final Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'in_progress': Colors.blue,
    'completed': Colors.green,
    'paused': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.personWorkflow.notes);
    _selectedStatus = widget.personWorkflow.status;
    _currentWorkflow = widget.workflow;
    _loadAvailablePersons();
    
    _notesController.addListener(() {
      if (!_hasChanges) {
        setState(() {
          _hasChanges = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePersons() async {
    try {
      final persons = await FirebaseService.getAvailablePersonsForAssignment();
      setState(() {
        _availablePersons = persons;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des personnes : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseService.updateWorkflowInfo(
        widget.person.id,
        widget.personWorkflow.id,
        notes: _notesController.text,
        status: _selectedStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modifications sauvegardées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Indiquer que des changements ont été faits
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde : $e'),
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

  Future<void> _assignStepResponsible(String stepId) async {
    if (_availablePersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune personne disponible pour l\'assignation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedPerson = await showDialog<PersonModel>(
      context: context,
      builder: (context) => _PersonSelectionDialog(
        availablePersons: _availablePersons,
        title: 'Assigner un responsable',
      ),
    );

    if (selectedPerson != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseService.assignStepResponsible(
          widget.person.id,
          widget.personWorkflow.id,
          stepId,
          selectedPerson.id,
          selectedPerson.fullName,
        );

        // Recharger le workflow pour obtenir les dernières données
        final updatedWorkflow = await FirebaseService.getWorkflow(widget.workflow.id);
        if (updatedWorkflow != null) {
          setState(() {
            _currentWorkflow = updatedWorkflow;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Responsable assigné : \${selectedPerson.fullName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'assignation : $e'),
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
  }

  Future<void> _unassignStepResponsible(String stepId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir retirer l\'assignation de cette étape ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseService.unassignStepResponsible(
          widget.person.id,
          widget.personWorkflow.id,
          stepId,
        );

        // Recharger le workflow pour obtenir les dernières données
        final updatedWorkflow = await FirebaseService.getWorkflow(widget.workflow.id);
        if (updatedWorkflow != null) {
          setState(() {
            _currentWorkflow = updatedWorkflow;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignation supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression : $e'),
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
  }

  Future<void> _editStep(WorkflowStep step) async {
    final result = await showDialog<WorkflowStep>(
      context: context,
      builder: (context) => _StepEditDialog(step: step),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseService.updateWorkflowStep(
          widget.person.id,
          widget.personWorkflow.id,
          step.id,
          name: result.name,
          description: result.description,
          estimatedDuration: result.estimatedDuration,
          isRequired: result.isRequired,
        );

        // Recharger le workflow
        final updatedWorkflow = await FirebaseService.getWorkflow(widget.workflow.id);
        if (updatedWorkflow != null) {
          setState(() {
            _currentWorkflow = updatedWorkflow;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Étape mise à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la mise à jour : $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le suivi'),
        backgroundColor: Color(int.parse(_currentWorkflow?.color.replaceFirst('#', '0xFF') ?? '0xFF2196F3')),
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _isLoading ? null : _saveChanges,
              icon: const Icon(Icons.save),
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkflowInfoCard(),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                  const SizedBox(height: 16),
                  _buildStepsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildWorkflowInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes,
                  color: Color(int.parse(_currentWorkflow?.color.replaceFirst('#', '0xFF') ?? '0xFF2196F3')),
                ),
                const SizedBox(width: 8),
                Text(
                  'Informations du suivi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person),
              title: Text('Personne'),
              subtitle: Text(widget.person.fullName),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.track_changes),
              title: Text('Workflow'),
              subtitle: Text(_currentWorkflow?.name ?? 'Non défini'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description),
              title: Text('Description'),
              subtitle: Text(_currentWorkflow?.description ?? 'Aucune description'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statut du suivi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _statusColors[status],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_statusLabels[status] ?? status),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes personnalisées',
                hintText: 'Ajoutez des notes sur ce suivi...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Étapes du workflow',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\${_currentWorkflow?.steps.length ?? 0} étape(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentWorkflow?.steps.isEmpty ?? true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aucune étape définie'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentWorkflow!.steps.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final step = _currentWorkflow!.steps[index];
                  final isCompleted = widget.personWorkflow.completedSteps.contains(step.id);
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '\${index + 1}',
                          style: TextStyle(
                            color: isCompleted ? Colors.white : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      step.name,
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (step.description.isNotEmpty)
                          Text(step.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\${step.estimatedDuration} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (step.isRequired) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Requis',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (step.assignedToName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Assigné à : \${step.assignedToName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editStep(step);
                            break;
                          case 'assign':
                            _assignStepResponsible(step.id);
                            break;
                          case 'unassign':
                            _unassignStepResponsible(step.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Modifier l\'étape'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (step.assignedTo == null)
                          const PopupMenuItem(
                            value: 'assign',
                            child: ListTile(
                              leading: Icon(Icons.person_add),
                              title: Text('Assigner un responsable'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'unassign',
                            child: ListTile(
                              leading: Icon(Icons.person_remove),
                              title: Text('Retirer l\'assignation'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonSelectionDialog extends StatelessWidget {
  final List<PersonModel> availablePersons;
  final String title;

  const _PersonSelectionDialog({
    required this.availablePersons,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: availablePersons.length,
          itemBuilder: (context, index) {
            final person = availablePersons[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: person.profileImageUrl != null
                    ? NetworkImage(person.profileImageUrl!)
                    : null,
                child: person.profileImageUrl == null
                    ? Text('${person.firstName[0]}${person.lastName[0]}')
                    : null,
              ),
              title: Text(person.fullName),
              subtitle: Text(person.email),
              onTap: () => Navigator.pop(context, person),
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

class _StepEditDialog extends StatefulWidget {
  final WorkflowStep step;

  const _StepEditDialog({required this.step});

  @override
  State<_StepEditDialog> createState() => _StepEditDialogState();
}

class _StepEditDialogState extends State<_StepEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  bool _isRequired = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.step.name);
    _descriptionController = TextEditingController(text: widget.step.description);
    _durationController = TextEditingController(text: widget.step.estimatedDuration.toString());
    _isRequired = widget.step.isRequired;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier l\'étape'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'étape',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durée estimée (minutes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Étape requise'),
              value: _isRequired,
              onChanged: (value) {
                setState(() {
                  _isRequired = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
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
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Le nom de l\'étape est requis'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final duration = int.tryParse(_durationController.text) ?? 30;
            
            final updatedStep = widget.step.copyWith(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              estimatedDuration: duration,
              isRequired: _isRequired,
            );

            Navigator.pop(context, updatedStep);
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}