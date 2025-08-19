import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../theme.dart';

class EventFormBuilder extends StatefulWidget {
  final EventModel event;

  const EventFormBuilder({super.key, required this.event});

  @override
  State<EventFormBuilder> createState() => _EventFormBuilderState();
}

class _EventFormBuilderState extends State<EventFormBuilder> {
  EventFormModel? _eventForm;
  bool _isLoading = true;
  bool _isEditMode = false;

  final List<Map<String, dynamic>> _fieldTypes = [
    {'value': 'text', 'label': 'Texte', 'icon': Icons.text_fields},
    {'value': 'email', 'label': 'Email', 'icon': Icons.email},
    {'value': 'phone', 'label': 'Téléphone', 'icon': Icons.phone},
    {'value': 'number', 'label': 'Nombre', 'icon': Icons.numbers},
    {'value': 'select', 'label': 'Liste déroulante', 'icon': Icons.arrow_drop_down},
    {'value': 'checkbox', 'label': 'Cases à cocher', 'icon': Icons.check_box},
    {'value': 'textarea', 'label': 'Zone de texte', 'icon': Icons.subject},
  ];

  @override
  void initState() {
    super.initState();
    _loadEventForm();
  }

  Future<void> _loadEventForm() async {
    try {
      final form = await EventsFirebaseService.getEventForm(widget.event.id);
      if (mounted) {
        setState(() {
          _eventForm = form ?? _createDefaultForm();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  EventFormModel _createDefaultForm() {
    return EventFormModel(
      id: '',
      eventId: widget.event.id,
      title: 'Inscription - ${widget.event.title}',
      description: 'Formulaire d\'inscription pour ${widget.event.title}',
      fields: _getDefaultFields(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<EventFormField> _getDefaultFields() {
    return [
      EventFormField(
        id: 'firstName',
        label: 'Prénom',
        type: 'text',
        isRequired: true,
        order: 1,
      ),
      EventFormField(
        id: 'lastName',
        label: 'Nom',
        type: 'text',
        isRequired: true,
        order: 2,
      ),
      EventFormField(
        id: 'email',
        label: 'Email',
        type: 'email',
        isRequired: true,
        order: 3,
      ),
      EventFormField(
        id: 'phone',
        label: 'Téléphone',
        type: 'phone',
        isRequired: false,
        order: 4,
      ),
    ];
  }

  Future<void> _saveEventForm() async {
    if (_eventForm == null) return;
    
    try {
      if (_eventForm!.id.isEmpty) {
        await EventsFirebaseService.createEventForm(_eventForm!);
      } else {
        await EventsFirebaseService.updateEventForm(_eventForm!);
      }
      
      setState(() => _isEditMode = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formulaire sauvegardé'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _addField() {
    if (_eventForm == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _AddFieldDialog(
        fieldTypes: _fieldTypes,
        onAdd: (fieldData) {
          final newField = EventFormField(
            id: fieldData['id'],
            label: fieldData['label'],
            type: fieldData['type'],
            isRequired: fieldData['isRequired'],
            options: fieldData['options'] ?? [],
            placeholder: fieldData['placeholder'],
            helpText: fieldData['helpText'],
            order: _eventForm!.fields.length + 1,
          );
          
          setState(() {
            _eventForm = EventFormModel(
              id: _eventForm!.id,
              eventId: _eventForm!.eventId,
              title: _eventForm!.title,
              description: _eventForm!.description,
              fields: [..._eventForm!.fields, newField],
              confirmationMessage: _eventForm!.confirmationMessage,
              confirmationEmailTemplate: _eventForm!.confirmationEmailTemplate,
              isActive: _eventForm!.isActive,
              createdAt: _eventForm!.createdAt,
              updatedAt: DateTime.now(),
            );
          });
        },
      ),
    );
  }

  void _editField(EventFormField field) {
    showDialog(
      context: context,
      builder: (context) => _EditFieldDialog(
        field: field,
        fieldTypes: _fieldTypes,
        onUpdate: (updatedField) {
          setState(() {
            final fields = _eventForm!.fields.map((f) {
              return f.id == field.id ? updatedField : f;
            }).toList();
            
            _eventForm = EventFormModel(
              id: _eventForm!.id,
              eventId: _eventForm!.eventId,
              title: _eventForm!.title,
              description: _eventForm!.description,
              fields: fields,
              confirmationMessage: _eventForm!.confirmationMessage,
              confirmationEmailTemplate: _eventForm!.confirmationEmailTemplate,
              isActive: _eventForm!.isActive,
              createdAt: _eventForm!.createdAt,
              updatedAt: DateTime.now(),
            );
          });
        },
      ),
    );
  }

  void _deleteField(EventFormField field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le champ'),
        content: Text('Êtes-vous sûr de vouloir supprimer le champ "${field.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final fields = _eventForm!.fields.where((f) => f.id != field.id).toList();
                _eventForm = EventFormModel(
                  id: _eventForm!.id,
                  eventId: _eventForm!.eventId,
                  title: _eventForm!.title,
                  description: _eventForm!.description,
                  fields: fields,
                  confirmationMessage: _eventForm!.confirmationMessage,
                  confirmationEmailTemplate: _eventForm!.confirmationEmailTemplate,
                  isActive: _eventForm!.isActive,
                  createdAt: _eventForm!.createdAt,
                  updatedAt: DateTime.now(),
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Color _getFieldColor(String type) {
    switch (type) {
      case 'text': case 'textarea': return AppTheme.primaryColor;
      case 'email': return AppTheme.secondaryColor;
      case 'phone': return AppTheme.tertiaryColor;
      case 'number': return AppTheme.warningColor;
      case 'select': case 'checkbox': return AppTheme.successColor;
      default: return AppTheme.textSecondaryColor;
    }
  }

  IconData _getFieldIcon(String type) {
    final fieldType = _fieldTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => {'icon': Icons.help_outline},
    );
    return fieldType['icon'];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!widget.event.isRegistrationEnabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Inscriptions désactivées',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les inscriptions ne sont pas activées pour cet événement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête du formulaire
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _eventForm?.title ?? 'Formulaire d\'inscription',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isEditMode = !_isEditMode),
                        icon: Icon(_isEditMode ? Icons.save : Icons.edit),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  if (_eventForm?.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      _eventForm!.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                  if (_isEditMode && _eventForm != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addField,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un champ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _saveEventForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sauvegarder'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Champs du formulaire
            if (_eventForm != null && _eventForm!.fields.isNotEmpty)
              ...(_eventForm!.fields..sort((a, b) => a.order.compareTo(b.order)))
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildFieldCard(entry.value, entry.key),
                      ))
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppTheme.textTertiaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun champ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des champs pour créer votre formulaire d\'inscription',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addField,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un champ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(EventFormField field, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFieldColor(field.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFieldIcon(field.type),
                    color: _getFieldColor(field.type),
                    size: 20,
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
                              field.label,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (field.isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Obligatoire',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _fieldTypes.firstWhere((t) => t['value'] == field.type)['label'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditMode) ...[
                  IconButton(
                    onPressed: () => _editField(field),
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppTheme.textSecondaryColor,
                  ),
                  IconButton(
                    onPressed: () => _deleteField(field),
                    icon: const Icon(Icons.delete, size: 18),
                    color: AppTheme.errorColor,
                  ),
                ],
              ],
            ),
            if (field.helpText?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                field.helpText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiaryColor,
                ),
              ),
            ],
            if (field.type == 'select' || field.type == 'checkbox') ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: field.options.map((option) {
                  return Chip(
                    label: Text(option),
                    backgroundColor: _getFieldColor(field.type).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: _getFieldColor(field.type),
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Dialog classes would be implemented here
class _AddFieldDialog extends StatefulWidget {
  final List<Map<String, dynamic>> fieldTypes;
  final Function(Map<String, dynamic>) onAdd;

  const _AddFieldDialog({
    required this.fieldTypes,
    required this.onAdd,
  });

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _labelController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _helpTextController = TextEditingController();
  String _selectedType = 'text';
  bool _isRequired = false;
  List<String> _options = [];

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _helpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un champ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Libellé du champ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de champ',
                border: OutlineInputBorder(),
              ),
              items: widget.fieldTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isRequired,
              onChanged: (value) => setState(() => _isRequired = value!),
              title: const Text('Champ obligatoire'),
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
            if (_labelController.text.isNotEmpty) {
              widget.onAdd({
                'id': _labelController.text.toLowerCase().replaceAll(' ', '_'),
                'label': _labelController.text,
                'type': _selectedType,
                'isRequired': _isRequired,
                'placeholder': _placeholderController.text.isNotEmpty ? _placeholderController.text : null,
                'helpText': _helpTextController.text.isNotEmpty ? _helpTextController.text : null,
                'options': _options,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _EditFieldDialog extends StatefulWidget {
  final EventFormField field;
  final List<Map<String, dynamic>> fieldTypes;
  final Function(EventFormField) onUpdate;

  const _EditFieldDialog({
    required this.field,
    required this.fieldTypes,
    required this.onUpdate,
  });

  @override
  State<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _placeholderController;
  late final TextEditingController _helpTextController;
  late String _selectedType;
  late bool _isRequired;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _placeholderController = TextEditingController(text: widget.field.placeholder ?? '');
    _helpTextController = TextEditingController(text: widget.field.helpText ?? '');
    _selectedType = widget.field.type;
    _isRequired = widget.field.isRequired;
    _options = List.from(widget.field.options);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _helpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le champ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Libellé du champ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de champ',
                border: OutlineInputBorder(),
              ),
              items: widget.fieldTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isRequired,
              onChanged: (value) => setState(() => _isRequired = value!),
              title: const Text('Champ obligatoire'),
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
            if (_labelController.text.isNotEmpty) {
              final updatedField = EventFormField(
                id: widget.field.id,
                label: _labelController.text,
                type: _selectedType,
                isRequired: _isRequired,
                options: _options,
                placeholder: _placeholderController.text.isNotEmpty ? _placeholderController.text : null,
                helpText: _helpTextController.text.isNotEmpty ? _helpTextController.text : null,
                order: widget.field.order,
              );
              widget.onUpdate(updatedField);
              Navigator.pop(context);
            }
          },
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }
}