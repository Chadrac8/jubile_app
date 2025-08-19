import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/person_model.dart';
import '../services/tasks_firebase_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import '../image_upload.dart';

class TaskFormPage extends StatefulWidget {
  final TaskModel? task;

  const TaskFormPage({super.key, this.task});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form values
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String _priority = 'medium';
  String _status = 'todo';
  List<String> _assigneeIds = [];
  List<String> _tags = [];
  List<String> _attachmentUrls = [];
  String? _linkedToType;
  String? _linkedToId;
  String? _taskListId;
  bool _isRecurring = false;
  Map<String, dynamic>? _recurrencePattern;
  bool _isLoading = false;

  final List<Map<String, String>> _priorityOptions = [
    {'value': 'low', 'label': 'Basse', 'color': '4CAF50'},
    {'value': 'medium', 'label': 'Moyenne', 'color': 'FF9800'},
    {'value': 'high', 'label': 'Haute', 'color': 'F44336'},
  ];

  final List<Map<String, String>> _statusOptions = [
    {'value': 'todo', 'label': 'À faire'},
    {'value': 'in_progress', 'label': 'En cours'},
    {'value': 'completed', 'label': 'Terminé'},
    {'value': 'cancelled', 'label': 'Annulé'},
  ];

  final List<Map<String, String>> _linkTypes = [
    {'value': 'group', 'label': 'Groupe'},
    {'value': 'event', 'label': 'Événement'},
    {'value': 'person', 'label': 'Personne'},
    {'value': 'service', 'label': 'Service'},
    {'value': 'form', 'label': 'Formulaire'},
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
    _titleController.dispose();
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
    if (widget.task != null) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _dueDate = task.dueDate;
      if (task.dueDate != null) {
        _dueTime = TimeOfDay.fromDateTime(task.dueDate!);
      }
      _priority = task.priority;
      _status = task.status;
      _assigneeIds = List.from(task.assigneeIds);
      _tags = List.from(task.tags);
      _attachmentUrls = List.from(task.attachmentUrls);
      _linkedToType = task.linkedToType;
      _linkedToId = task.linkedToId;
      _taskListId = task.taskListId;
      _isRecurring = task.isRecurring;
      _recurrencePattern = task.recurrencePattern;
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() => _dueDate = date);
      if (_dueTime == null) {
        setState(() => _dueTime = TimeOfDay.now());
      }
    }
  }

  Future<void> _selectDueTime() async {
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord sélectionner une date')),
      );
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() => _dueTime = time);
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter un tag'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nom du tag',
              hintText: 'ex: urgent, personnel',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() => _tags.add(tag));
                }
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final bytes = await ImageUploadHelper.pickImageFromGallery();
      if (bytes != null) {
        setState(() => _isLoading = true);
        
        final fileName = 'attachment_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final taskId = widget.task?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final url = await TasksFirebaseService.uploadTaskAttachment(bytes, fileName, taskId);
        
        setState(() {
          _attachmentUrls.add(url);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _selectAssignees() async {
    try {
      final persons = await FirebaseService.getAllPersons();
      
      if (!mounted) return;
      
      final selectedIds = await showDialog<List<String>>(
        context: context,
        builder: (context) => _AssigneeSelectionDialog(
          persons: persons,
          selectedIds: _assigneeIds,
        ),
      );
      
      if (selectedIds != null) {
        setState(() => _assigneeIds = selectedIds);
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

  Future<void> _selectTaskList() async {
    try {
      final taskLists = await TasksFirebaseService.getTaskListsStream().first;
      
      if (!mounted) return;
      
      final selectedListId = await showDialog<String>(
        context: context,
        builder: (context) => _TaskListSelectionDialog(
          taskLists: taskLists,
          selectedId: _taskListId,
        ),
      );
      
      setState(() => _taskListId = selectedListId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des listes: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      DateTime? combinedDueDate;
      if (_dueDate != null && _dueTime != null) {
        combinedDueDate = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
      } else if (_dueDate != null) {
        combinedDueDate = _dueDate;
      }

      final now = DateTime.now();
      final currentUserId = AuthService.currentUser?.uid ?? '';

      if (widget.task == null) {
        // Create new task
        final task = TaskModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: combinedDueDate,
          priority: _priority,
          status: _status,
          assigneeIds: _assigneeIds,
          createdBy: currentUserId,
          tags: _tags,
          attachmentUrls: _attachmentUrls,
          linkedToType: _linkedToType,
          linkedToId: _linkedToId,
          taskListId: _taskListId,
          isRecurring: _isRecurring,
          recurrencePattern: _recurrencePattern,
          createdAt: now,
          updatedAt: now,
        );

        await TasksFirebaseService.createTask(task);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche créée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: combinedDueDate,
          priority: _priority,
          status: _status,
          assigneeIds: _assigneeIds,
          tags: _tags,
          attachmentUrls: _attachmentUrls,
          linkedToType: _linkedToType,
          linkedToId: _linkedToId,
          taskListId: _taskListId,
          isRecurring: _isRecurring,
          recurrencePattern: _recurrencePattern,
          updatedAt: now,
          lastModifiedBy: currentUserId,
        );

        await TasksFirebaseService.updateTask(updatedTask);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche mise à jour avec succès'),
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

  DateTime? get _combinedDueDateTime {
    if (_dueDate == null) return null;
    if (_dueTime == null) return _dueDate;
    
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nouvelle tâche' : 'Modifier la tâche'),
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
              onPressed: _saveTask,
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
                controller: _titleController,
                label: 'Titre de la tâche',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis';
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
            title: 'Priorité et statut',
            icon: Icons.flag_outlined,
            children: [
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              _buildStatusSelector(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Échéance',
            icon: Icons.schedule,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDateField('Date d\'échéance', _dueDate, _selectDueDate),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField('Heure', _dueTime, _selectDueTime),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Assignation',
            icon: Icons.people_outline,
            children: [
              _buildAssigneeSelector(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Organisation',
            icon: Icons.folder_outlined,
            children: [
              _buildTaskListSelector(),
              const SizedBox(height: 16),
              _buildTagsSection(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Pièces jointes',
            icon: Icons.attach_file,
            children: [
              _buildAttachmentsSection(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Liaison',
            icon: Icons.link,
            children: [
              _buildLinkSection(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Récurrence',
            icon: Icons.repeat,
            children: [
              _buildRecurrenceSection(),
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

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priorité'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _priorityOptions.map((priority) {
            final isSelected = _priority == priority['value'];
            final color = Color(int.parse('0xFF${priority['color']}'));
            
            return FilterChip(
              label: Text(priority['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _priority = priority['value']!);
              },
              backgroundColor: color.withOpacity(0.1),
              selectedColor: color.withOpacity(0.3),
              checkmarkColor: color,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Statut',
        prefixIcon: Icon(Icons.flag),
        border: OutlineInputBorder(),
      ),
      items: _statusOptions.map((status) {
        return DropdownMenuItem(
          value: status['value'],
          child: Text(status['label']!),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _status = value);
        }
      },
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Sélectionner',
          style: TextStyle(
            color: date != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          time != null ? time.format(context) : 'Sélectionner',
          style: TextStyle(
            color: time != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Responsables')),
            TextButton.icon(
              onPressed: _selectAssignees,
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Assigner'),
            ),
          ],
        ),
        if (_assigneeIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _assigneeIds.map((id) {
              return Chip(
                label: Text('Personne $id'), // TODO: Load actual person name
                onDeleted: () {
                  setState(() => _assigneeIds.remove(id));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskListSelector() {
    return InkWell(
      onTap: _selectTaskList,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Liste de tâches',
          prefixIcon: Icon(Icons.list_alt),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _taskListId != null ? 'Liste sélectionnée' : 'Aucune liste',
          style: TextStyle(
            color: _taskListId != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Tags')),
            TextButton.icon(
              onPressed: _addTag,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() => _tags.remove(tag));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Fichiers joints')),
            TextButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file, size: 20),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        if (_attachmentUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...(_attachmentUrls.map((url) {
            return ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text('Fichier joint'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() => _attachmentUrls.remove(url));
                },
              ),
            );
          }).toList()),
        ],
      ],
    );
  }

  Widget _buildLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _linkedToType,
          decoration: const InputDecoration(
            labelText: 'Lier à',
            prefixIcon: Icon(Icons.link),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Aucune liaison')),
            ..._linkTypes.map((type) {
              return DropdownMenuItem(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _linkedToType = value;
              _linkedToId = null;
            });
          },
        ),
        if (_linkedToType != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'ID de l\'élément',
              hintText: 'Saisir l\'ID de ${_linkedToType}',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => _linkedToId = value.isEmpty ? null : value,
          ),
        ],
      ],
    );
  }

  Widget _buildRecurrenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Tâche récurrente'),
          subtitle: const Text('Créer automatiquement une nouvelle tâche'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() => _isRecurring = value);
            if (!value) {
              _recurrencePattern = null;
            }
          },
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
          // TODO: Add recurrence pattern configuration
          const Text('Configuration de la récurrence à implémenter'),
        ],
      ],
    );
  }
}

class _AssigneeSelectionDialog extends StatefulWidget {
  final List<PersonModel> persons;
  final List<String> selectedIds;

  const _AssigneeSelectionDialog({
    required this.persons,
    required this.selectedIds,
  });

  @override
  State<_AssigneeSelectionDialog> createState() => _AssigneeSelectionDialogState();
}

class _AssigneeSelectionDialogState extends State<_AssigneeSelectionDialog> {
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
      title: const Text('Sélectionner les responsables'),
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

class _TaskListSelectionDialog extends StatelessWidget {
  final List<TaskListModel> taskLists;
  final String? selectedId;

  const _TaskListSelectionDialog({
    required this.taskLists,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner une liste'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: taskLists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return RadioListTile<String?>(
                title: const Text('Aucune liste'),
                value: null,
                groupValue: selectedId,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }
            
            final taskList = taskLists[index - 1];
            return RadioListTile<String?>(
              title: Text(taskList.name),
              subtitle: Text(taskList.description),
              value: taskList.id,
              groupValue: selectedId,
              onChanged: (value) => Navigator.pop(context, value),
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