import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_field_model.dart';
import '../services/custom_fields_firebase_service.dart';

class CustomFieldFormPage extends StatefulWidget {
  final CustomFieldModel? field;

  const CustomFieldFormPage({super.key, this.field});

  @override
  State<CustomFieldFormPage> createState() => _CustomFieldFormPageState();
}

class _CustomFieldFormPageState extends State<CustomFieldFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _labelController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _helpTextController = TextEditingController();
  final _defaultValueController = TextEditingController();
  final _optionsController = TextEditingController();

  CustomFieldType _selectedType = CustomFieldType.text;
  bool _isRequired = false;
  bool _isVisible = true;
  bool _isLoading = false;

  final CustomFieldsFirebaseService _service = CustomFieldsFirebaseService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    _placeholderController.dispose();
    _helpTextController.dispose();
    _defaultValueController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.field != null) {
      final field = widget.field!;
      _nameController.text = field.name;
      _labelController.text = field.label;
      _placeholderController.text = field.placeholder ?? '';
      _helpTextController.text = field.helpText ?? '';
      _defaultValueController.text = field.defaultValue ?? '';
      _optionsController.text = field.options.join('\n');
      _selectedType = field.type;
      _isRequired = field.isRequired;
      _isVisible = field.isVisible;
    }
  }

  Future<void> _saveField() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      // Parse options for select/multiselect fields
      List<String> options = [];
      if (_selectedType == CustomFieldType.select || _selectedType == CustomFieldType.multiselect) {
        options = _optionsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      final field = CustomFieldModel(
        id: widget.field?.id ?? '',
        name: _nameController.text.toLowerCase().replaceAll(' ', '_'),
        label: _labelController.text,
        type: _selectedType,
        isRequired: _isRequired,
        isVisible: _isVisible,
        order: widget.field?.order ?? 0,
        options: options,
        defaultValue: _defaultValueController.text.isEmpty ? null : _defaultValueController.text,
        placeholder: _placeholderController.text.isEmpty ? null : _placeholderController.text,
        helpText: _helpTextController.text.isEmpty ? null : _helpTextController.text,
        createdAt: widget.field?.createdAt ?? now,
        updatedAt: now,
        createdBy: widget.field?.createdBy ?? userId,
      );

      if (widget.field == null) {
        await _service.createCustomField(field);
      } else {
        await _service.updateCustomField(field);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.field == null ? 'Champ créé avec succès' : 'Champ modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.field == null ? 'Nouveau champ' : 'Modifier le champ'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveField,
              child: const Text('Sauvegarder'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Name and Label
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Libellé *',
                  hintText: 'Nom affiché du champ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le libellé est requis';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Auto-generate name from label
                  if (widget.field == null) {
                    _nameController.text = value.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom technique *',
                  hintText: 'Nom utilisé dans la base de données',
                  border: OutlineInputBorder(),
                ),
                enabled: widget.field == null, // Can't change name of existing field
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom technique est requis';
                  }
                  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                    return 'Le nom ne peut contenir que des lettres minuscules, chiffres et _';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Type
              DropdownButtonFormField<CustomFieldType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type de champ *',
                  border: OutlineInputBorder(),
                ),
                items: CustomFieldType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Placeholder
              TextFormField(
                controller: _placeholderController,
                decoration: const InputDecoration(
                  labelText: 'Texte d\'aide',
                  hintText: 'Texte affiché en gris dans le champ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Options (only for select/multiselect)
              if (_selectedType == CustomFieldType.select || _selectedType == CustomFieldType.multiselect) ...[
                TextFormField(
                  controller: _optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Options (une par ligne) *',
                    hintText: 'Option 1\nOption 2\nOption 3',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Au moins une option est requise';
                    }
                    final options = value.split('\n').where((e) => e.trim().isNotEmpty).toList();
                    if (options.length < 2) {
                      return 'Au moins deux options sont requises';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Default Value
              TextFormField(
                controller: _defaultValueController,
                decoration: const InputDecoration(
                  labelText: 'Valeur par défaut',
                  hintText: 'Valeur pré-remplie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Help Text
              TextFormField(
                controller: _helpTextController,
                decoration: const InputDecoration(
                  labelText: 'Texte d\'aide',
                  hintText: 'Explication affichée sous le champ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Switches
              SwitchListTile(
                title: const Text('Champ requis'),
                subtitle: const Text('L\'utilisateur doit remplir ce champ'),
                value: _isRequired,
                onChanged: (value) => setState(() => _isRequired = value),
              ),
              SwitchListTile(
                title: const Text('Champ visible'),
                subtitle: const Text('Le champ apparaît dans les formulaires'),
                value: _isVisible,
                onChanged: (value) => setState(() => _isVisible = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.text:
        return 'Texte';
      case CustomFieldType.number:
        return 'Nombre';
      case CustomFieldType.date:
        return 'Date';
      case CustomFieldType.boolean:
        return 'Oui/Non';
      case CustomFieldType.select:
        return 'Sélection unique';
      case CustomFieldType.multiselect:
        return 'Sélection multiple';
      case CustomFieldType.phone:
        return 'Téléphone';
      case CustomFieldType.email:
        return 'Email';
      case CustomFieldType.url:
        return 'URL';
    }
  }
}