import 'package:flutter/material.dart';
import '../models/form_model.dart';
import '../../compatibility/app_theme_bridge.dart';

class FormFieldEditor extends StatefulWidget {
  final CustomFormField field;
  final Function(CustomFormField) onSave;

  const FormFieldEditor({
    super.key,
    required this.field,
    required this.onSave,
  });

  @override
  State<FormFieldEditor> createState() => _FormFieldEditorState();
}

class _FormFieldEditorState extends State<FormFieldEditor> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _helpTextController = TextEditingController();
  
  late String _selectedType;
  late bool _isRequired;
  late List<String> _options;
  late Map<String, dynamic> _validation;
  late Map<String, dynamic> _conditional;
  late Map<String, dynamic> _personField;

  final List<Map<String, dynamic>> _fieldTypes = [
    {'type': 'text', 'label': 'Texte court', 'icon': Icons.text_fields},
    {'type': 'textarea', 'label': 'Texte long', 'icon': Icons.subject},
    {'type': 'email', 'label': 'Email', 'icon': Icons.email},
    {'type': 'phone', 'label': 'Téléphone', 'icon': Icons.phone},
    {'type': 'checkbox', 'label': 'Cases à cocher', 'icon': Icons.check_box},
    {'type': 'radio', 'label': 'Boutons radio', 'icon': Icons.radio_button_checked},
    {'type': 'select', 'label': 'Liste déroulante', 'icon': Icons.arrow_drop_down},
    {'type': 'date', 'label': 'Date', 'icon': Icons.calendar_today},
    {'type': 'time', 'label': 'Heure', 'icon': Icons.access_time},
    {'type': 'file', 'label': 'Fichier', 'icon': Icons.attach_file},
    {'type': 'signature', 'label': 'Signature', 'icon': Icons.edit},
    {'type': 'section', 'label': 'Section', 'icon': Icons.view_headline},
    {'type': 'title', 'label': 'Titre', 'icon': Icons.title},
    {'type': 'instructions', 'label': 'Instructions', 'icon': Icons.info},
    {'type': 'person_field', 'label': 'Champ personne', 'icon': Icons.person},
  ];

  final List<Map<String, String>> _personFieldOptions = [
    {'value': 'firstName', 'label': 'Prénom'},
    {'value': 'lastName', 'label': 'Nom'},
    {'value': 'email', 'label': 'Email'},
    {'value': 'phone', 'label': 'Téléphone'},
    {'value': 'address', 'label': 'Adresse'},
    {'value': 'birthDate', 'label': 'Date de naissance'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromField();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _helpTextController.dispose();
    super.dispose();
  }

  void _initializeFromField() {
    _labelController.text = widget.field.label;
    _placeholderController.text = widget.field.placeholder ?? '';
    _helpTextController.text = widget.field.helpText ?? '';
    _selectedType = widget.field.type;
    _isRequired = widget.field.isRequired;
    _options = List.from(widget.field.options);
    _validation = Map.from(widget.field.validation);
    _conditional = Map.from(widget.field.conditional);
    _personField = Map.from(widget.field.personField);
  }

  void _saveField() {
    if (!_formKey.currentState!.validate()) return;

    final updatedField = widget.field.copyWith(
      type: _selectedType,
      label: _labelController.text,
      placeholder: _placeholderController.text.isEmpty ? null : _placeholderController.text,
      helpText: _helpTextController.text.isEmpty ? null : _helpTextController.text,
      isRequired: _isRequired,
      options: _options,
      validation: _validation,
      conditional: _conditional,
      personField: _personField,
    );

    widget.onSave(updatedField);
    Navigator.of(context).pop();
  }

  void _addOption() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une option'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Texte de l\'option',
            border: OutlineInputBorder(),
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
              if (controller.text.isNotEmpty) {
                setState(() {
                  _options.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _editOption(int index) {
    final controller = TextEditingController(text: _options[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'option'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Texte de l\'option',
            border: OutlineInputBorder(),
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
              if (controller.text.isNotEmpty) {
                setState(() {
                  _options[index] = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Theme.of(context).colorScheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Modifier le champ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicSettings(),
                      const SizedBox(height: 24),
                      if (_hasOptions) _buildOptionsSection(),
                      if (_selectedType == 'person_field') _buildPersonFieldSection(),
                      const SizedBox(height: 24),
                      _buildAdvancedSettings(),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Theme.of(context).colorScheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveField,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sauvegarder'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres de base',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Type de champ
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Type de champ',
            border: OutlineInputBorder(),
          ),
          items: _fieldTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type['type'] as String,
              child: Row(
                children: [
                  Icon(type['icon'] as IconData, size: 20),
                  const SizedBox(width: 8),
                  Text(type['label'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              // Reset options when changing type
              if (!_hasOptions) {
                _options.clear();
              }
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Label
        TextFormField(
          controller: _labelController,
          decoration: const InputDecoration(
            labelText: 'Label du champ *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le label est obligatoire';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Placeholder (si applicable)
        if (_canHavePlaceholder)
          Column(
            children: [
              TextFormField(
                controller: _placeholderController,
                decoration: const InputDecoration(
                  labelText: 'Texte d\'aide (placeholder)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        
        // Help text
        TextFormField(
          controller: _helpTextController,
          decoration: const InputDecoration(
            labelText: 'Texte d\'aide',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        // Required checkbox
        if (_canBeRequired)
          CheckboxListTile(
            title: const Text('Champ obligatoire'),
            value: _isRequired,
            onChanged: (value) {
              setState(() {
                _isRequired = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_options.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 48,
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune option ajoutée',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_options.length, (index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.drag_handle),
                title: Text(_options[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editOption(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Theme.of(context).colorScheme.errorColor),
                      onPressed: () => _removeOption(index),
                    ),
                  ],
                ),
                onTap: () => _editOption(index),
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPersonFieldSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Champ personne',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: _personField['field'],
          decoration: const InputDecoration(
            labelText: 'Champ à pré-remplir',
            border: OutlineInputBorder(),
          ),
          items: _personFieldOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _personField = {'field': value};
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Ce champ sera automatiquement pré-rempli avec les données de la personne connectée',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return ExpansionTile(
      title: const Text('Paramètres avancés'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Validation rules
              if (_canHaveValidation) ...[
                Text(
                  'Validation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (_selectedType == 'text' || _selectedType == 'textarea') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _validation['minLength']?.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Longueur minimum',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            setState(() {
                              if (intValue != null) {
                                _validation['minLength'] = intValue;
                              } else {
                                _validation.remove('minLength');
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _validation['maxLength']?.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Longueur maximum',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            setState(() {
                              if (intValue != null) {
                                _validation['maxLength'] = intValue;
                              } else {
                                _validation.remove('maxLength');
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
              ],
              
              // TODO: Add conditional logic settings
              Text(
                'Logique conditionnelle',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Fonctionnalité disponible prochainement',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hasOptions => ['checkbox', 'radio', 'select'].contains(_selectedType);
  bool get _canHavePlaceholder => ['text', 'textarea', 'email', 'phone', 'number'].contains(_selectedType);
  bool get _canBeRequired => !['section', 'title', 'instructions'].contains(_selectedType);
  bool get _canHaveValidation => ['text', 'textarea', 'email', 'phone', 'number'].contains(_selectedType);
}