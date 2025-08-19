import 'package:flutter/material.dart';
import '../models/custom_field_model.dart';
import '../services/custom_fields_firebase_service.dart';
import '../theme.dart';
import 'custom_field_form_page.dart';

class CustomFieldsManagementPage extends StatefulWidget {
  const CustomFieldsManagementPage({super.key});

  @override
  State<CustomFieldsManagementPage> createState() => _CustomFieldsManagementPageState();
}

class _CustomFieldsManagementPageState extends State<CustomFieldsManagementPage> {
  final CustomFieldsFirebaseService _service = CustomFieldsFirebaseService();
  List<CustomFieldModel> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _service.getCustomFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteField(CustomFieldModel field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le champ "${field.label}" ?\n\n'
          'Cette action supprimera également toutes les données associées à ce champ.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteCustomField(field.id);
        await _loadFields();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Champ "${field.label}" supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editField(CustomFieldModel? field) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomFieldFormPage(field: field),
      ),
    );

    if (result == true) {
      _loadFields();
    }
  }

  Future<void> _reorderFields(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final List<CustomFieldModel> newFields = List.from(_fields);
    final CustomFieldModel item = newFields.removeAt(oldIndex);
    newFields.insert(newIndex, item);

    setState(() {
      _fields = newFields;
    });

    try {
      await _service.reorderCustomFields(_fields);
    } catch (e) {
      // Revert on error
      await _loadFields();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réorganisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Champs personnalisés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFields,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fields.isEmpty
              ? _buildEmptyState()
              : _buildFieldsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editField(null),
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un champ',
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card d'information d'accès
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comment accéder à cette page ?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vous pouvez accéder à la gestion des champs personnalisés de 2 façons :',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Depuis le module Personnes → Menu (⋮) → Champs personnalisés',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Depuis la navigation Admin → Plus → Champs personnalisés',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // État vide principal
          Icon(
            Icons.dynamic_form,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun champ personnalisé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez des champs personnalisés pour enrichir\nles informations de vos membres',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _editField(null),
            icon: const Icon(Icons.add),
            label: const Text('Créer un champ'),
          ),
          const SizedBox(height: 32),
          
          // Card d'aide sur les types de champs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Types de champs disponibles',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFieldTypeInfo(Icons.text_fields, 'Texte', 'Champ texte libre'),
                  _buildFieldTypeInfo(Icons.numbers, 'Nombre', 'Nombre entier ou décimal'),
                  _buildFieldTypeInfo(Icons.calendar_today, 'Date', 'Sélecteur de date'),
                  _buildFieldTypeInfo(Icons.toggle_on, 'Booléen', 'Interrupteur Oui/Non'),
                  _buildFieldTypeInfo(Icons.arrow_drop_down_circle, 'Sélection', 'Liste déroulante'),
                  _buildFieldTypeInfo(Icons.checklist, 'Multi-sélection', 'Choix multiples'),
                  _buildFieldTypeInfo(Icons.phone, 'Téléphone', 'Numéro de téléphone'),
                  _buildFieldTypeInfo(Icons.email, 'Email', 'Adresse email'),
                  _buildFieldTypeInfo(Icons.link, 'URL', 'Lien web'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTypeInfo(IconData icon, String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '- $description',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList() {
    return Column(
      children: [
        // Card d'information d'accès (version condensée)
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Accessible depuis : Personnes → Menu (⋮) → Champs personnalisés',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Liste des champs
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _fields.length,
            onReorder: _reorderFields,
            itemBuilder: (context, index) {
              final field = _fields[index];
              return Card(
          key: ValueKey(field.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: field.isRequired ? Colors.red.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getFieldTypeIcon(field.type),
                color: field.isRequired ? Colors.red : Colors.blue,
              ),
            ),
            title: Text(field.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.type.displayName),
                if (field.helpText != null && field.helpText!.isNotEmpty)
                  Text(
                    field.helpText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (field.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Requis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editField(field);
                        break;
                      case 'delete':
                        _deleteField(field);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
            },
          ),
        ),
      ],
    );
  }

  IconData _getFieldTypeIcon(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.text:
        return Icons.text_fields;
      case CustomFieldType.number:
        return Icons.numbers;
      case CustomFieldType.date:
        return Icons.calendar_today;
      case CustomFieldType.boolean:
        return Icons.check_box;
      case CustomFieldType.select:
        return Icons.radio_button_checked;
      case CustomFieldType.multiselect:
        return Icons.checklist;
      case CustomFieldType.phone:
        return Icons.phone;
      case CustomFieldType.email:
        return Icons.email;
      case CustomFieldType.url:
        return Icons.link;
    }
  }
}