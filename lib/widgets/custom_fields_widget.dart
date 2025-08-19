import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/custom_field_model.dart';
import '../services/custom_fields_firebase_service.dart';

class CustomFieldsWidget extends StatefulWidget {
  final Map<String, dynamic> initialValues;
  final Function(Map<String, dynamic>) onChanged;
  final bool isReadOnly;

  const CustomFieldsWidget({
    super.key,
    required this.initialValues,
    required this.onChanged,
    this.isReadOnly = false,
  });

  @override
  State<CustomFieldsWidget> createState() => _CustomFieldsWidgetState();
}

class _CustomFieldsWidgetState extends State<CustomFieldsWidget> {
  final CustomFieldsFirebaseService _service = CustomFieldsFirebaseService();
  List<CustomFieldModel> _fields = [];
  Map<String, dynamic> _values = {};
  Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _values = Map.from(widget.initialValues);
    _loadFields();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _service.getCustomFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
      
      // Initialiser les contrôleurs
      for (final field in fields) {
        if (field.type == CustomFieldType.text ||
            field.type == CustomFieldType.number ||
            field.type == CustomFieldType.phone ||
            field.type == CustomFieldType.email ||
            field.type == CustomFieldType.url) {
          _controllers[field.name] = TextEditingController(
            text: _values[field.name]?.toString() ?? field.defaultValue ?? '',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateValue(String fieldName, dynamic value) {
    setState(() {
      if (value == null || (value is String && value.isEmpty)) {
        _values.remove(fieldName);
      } else {
        _values[fieldName] = value;
      }
    });
    widget.onChanged(_values);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSection(
        context: context,
        title: 'Champs personnalisés',
        icon: Icons.tune,
        children: [
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_fields.isEmpty) {
      return _buildSection(
        context: context,
        title: 'Champs personnalisés',
        icon: Icons.tune,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withAlpha(77),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucun champ personnalisé configuré',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous pouvez créer des champs personnalisés depuis le menu Personnes → Champs personnalisés pour collecter des informations supplémentaires.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _buildSection(
      context: context,
      title: 'Champs personnalisés',
      icon: Icons.tune,
      children: _fields.map((field) => _buildFieldWidget(field)).toList(),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(CustomFieldModel field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldInput(field),
          if (field.helpText != null && field.helpText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                field.helpText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldInput(CustomFieldModel field) {
    switch (field.type) {
      case CustomFieldType.text:
      case CustomFieldType.phone:
      case CustomFieldType.email:
      case CustomFieldType.url:
        return TextFormField(
          controller: _controllers[field.name],
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
            hintText: field.placeholder,
            prefixIcon: Icon(_getIconForFieldType(field.type), color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          keyboardType: _getKeyboardType(field.type),
          inputFormatters: _getInputFormatters(field.type),
          readOnly: widget.isReadOnly,
          validator: (value) => field.validateValue(value),
          onChanged: (value) => _updateValue(field.name, value),
        );

      case CustomFieldType.number:
        return TextFormField(
          controller: _controllers[field.name],
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
            hintText: field.placeholder,
            prefixIcon: Icon(Icons.numbers, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          readOnly: widget.isReadOnly,
          validator: (value) => field.validateValue(value),
          onChanged: (value) {
            final numValue = double.tryParse(value);
            _updateValue(field.name, numValue);
          },
        );

      case CustomFieldType.date:
        return InkWell(
          onTap: widget.isReadOnly ? null : () => _selectDate(field),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label + (field.isRequired ? ' *' : ''),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      Text(
                        _formatDate(_values[field.name] as DateTime?),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _values[field.name] != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        );

      case CustomFieldType.boolean:
        return SwitchListTile(
          title: Text(field.label + (field.isRequired ? ' *' : '')),
          value: _values[field.name] as bool? ?? false,
          onChanged: widget.isReadOnly ? null : (value) => _updateValue(field.name, value),
          contentPadding: EdgeInsets.zero,
        );

      case CustomFieldType.select:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: field.label + (field.isRequired ? ' *' : ''),
            prefixIcon: Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withAlpha(77),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          value: _values[field.name] as String?,
          items: [
            if (!field.isRequired) const DropdownMenuItem(value: null, child: Text('-- Aucun --')),
            ...field.options.map((option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            )),
          ],
          onChanged: widget.isReadOnly ? null : (value) => _updateValue(field.name, value),
          validator: (value) => field.validateValue(value),
        );

      case CustomFieldType.multiselect:
        return _buildMultiSelectField(field);

      // No default needed, all cases are covered
    }
  }

  Widget _buildMultiSelectField(CustomFieldModel field) {
    final selectedOptions = (_values[field.name] as List<String>?) ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label + (field.isRequired ? ' *' : ''),
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: field.options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return CheckboxListTile(
                title: Text(option),
                value: isSelected,
                onChanged: widget.isReadOnly ? null : (checked) {
                  final newSelection = List<String>.from(selectedOptions);
                  if (checked == true && !newSelection.contains(option)) {
                    newSelection.add(option);
                  } else if (checked == false) {
                    newSelection.remove(option);
                  }
                  _updateValue(field.name, newSelection);
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  TextInputType _getKeyboardType(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.email:
        return TextInputType.emailAddress;
      case CustomFieldType.phone:
        return TextInputType.phone;
      case CustomFieldType.url:
        return TextInputType.url;
      case CustomFieldType.number:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.phone:
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]'))];
      case CustomFieldType.number:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))];
      default:
        return [];
    }
  }

  IconData _getIconForFieldType(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.text:
        return Icons.text_fields;
      case CustomFieldType.email:
        return Icons.email;
      case CustomFieldType.phone:
        return Icons.phone;
      case CustomFieldType.url:
        return Icons.link;
      case CustomFieldType.number:
        return Icons.numbers;
      case CustomFieldType.date:
        return Icons.calendar_today;
      case CustomFieldType.boolean:
        return Icons.toggle_on;
      case CustomFieldType.select:
        return Icons.list;
      case CustomFieldType.multiselect:
        return Icons.checklist;
      // No default needed, all cases are covered
    }
  }

  Future<void> _selectDate(CustomFieldModel field) async {
    final currentDate = _values[field.name] as DateTime?;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _updateValue(field.name, pickedDate);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Widget pour afficher les champs personnalisés en lecture seule
class CustomFieldsDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> values;
  final List<CustomFieldModel> fields;

  const CustomFieldsDisplayWidget({
    super.key,
    required this.values,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final visibleFields = fields.where((field) => 
      field.isVisible && values.containsKey(field.name) && values[field.name] != null
    ).toList();

    if (visibleFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Informations supplémentaires',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...visibleFields.map((field) => _buildFieldDisplay(field, context)).toList(),
      ],
    );
  }

  Widget _buildFieldDisplay(CustomFieldModel field, BuildContext context) {
    final value = values[field.name];
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              field.label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(_formatValue(field, value)),
          ),
        ],
      ),
    );
  }

  String _formatValue(CustomFieldModel field, dynamic value) {
    switch (field.type) {
      case CustomFieldType.boolean:
        return (value as bool) ? 'Oui' : 'Non';
      case CustomFieldType.date:
        if (value is DateTime) {
          return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
        }
        return value.toString();
      case CustomFieldType.multiselect:
        if (value is List) {
          return value.join(', ');
        }
        return value.toString();
      default:
        return value.toString();
    }
  }
}