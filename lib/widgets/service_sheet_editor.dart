import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/services_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class ServiceSheetEditor extends StatefulWidget {
  final ServiceModel service;

  const ServiceSheetEditor({super.key, required this.service});

  @override
  State<ServiceSheetEditor> createState() => _ServiceSheetEditorState();
}

class _ServiceSheetEditorState extends State<ServiceSheetEditor> {
  ServiceSheetModel? _serviceSheet;
  bool _isLoading = true;
  bool _isEditMode = false;

  final List<Map<String, dynamic>> _itemTypes = [
    {'value': 'section', 'label': 'Section', 'icon': Icons.view_headline, 'color': Colors.teal},
    {'value': 'louange', 'label': 'Louange', 'icon': Icons.music_note, 'color': Colors.purple},
    {'value': 'predication', 'label': 'Prédication', 'icon': Icons.record_voice_over, 'color': Colors.blue},
    {'value': 'annonce', 'label': 'Annonces', 'icon': Icons.campaign, 'color': Colors.orange},
    {'value': 'priere', 'label': 'Prière', 'icon': Icons.favorite, 'color': Colors.red},
    {'value': 'chant', 'label': 'Chant', 'icon': Icons.library_music, 'color': Colors.green},
    {'value': 'lecture', 'label': 'Lecture', 'icon': Icons.menu_book, 'color': Colors.indigo},
    {'value': 'offrande', 'label': 'Offrande', 'icon': Icons.volunteer_activism, 'color': Colors.amber},
    {'value': 'autre', 'label': 'Autre', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadServiceSheet();
  }

  Future<void> _loadServiceSheet() async {
    try {
      final sheet = await ServicesFirebaseService.getServiceSheet(widget.service.id);
      setState(() {
        _serviceSheet = sheet ?? _createDefaultSheet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  ServiceSheetModel _createDefaultSheet() {
    return ServiceSheetModel(
      id: '',
      serviceId: widget.service.id,
      title: 'Feuille de service - ${widget.service.name}',
      items: _getDefaultItems(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<ServiceSheetItem> _getDefaultItems() {
    return [
      ServiceSheetItem(
        id: 'section_ouverture',
        type: 'section',
        title: 'OUVERTURE DU CULTE',
        order: 1,
        durationMinutes: 0,
      ),
      ServiceSheetItem(
        id: 'accueil',
        type: 'autre',
        title: 'Accueil et salutations',
        order: 2,
        durationMinutes: 5,
      ),
      ServiceSheetItem(
        id: 'section_louange',
        type: 'section',
        title: 'TEMPS DE LOUANGE',
        order: 3,
        durationMinutes: 0,
      ),
      ServiceSheetItem(
        id: 'louange1',
        type: 'louange',
        title: 'Chants de louange',
        order: 4,
        durationMinutes: 20,
      ),
      ServiceSheetItem(
        id: 'priere_ouverture',
        type: 'priere',
        title: 'Prière d\'ouverture',
        order: 5,
        durationMinutes: 5,
      ),
      ServiceSheetItem(
        id: 'section_parole',
        type: 'section',
        title: 'TEMPS DE LA PAROLE',
        order: 6,
        durationMinutes: 0,
      ),
      ServiceSheetItem(
        id: 'annonces',
        type: 'annonce',
        title: 'Annonces',
        order: 7,
        durationMinutes: 5,
      ),
      ServiceSheetItem(
        id: 'lecture',
        type: 'lecture',
        title: 'Lecture biblique',
        order: 8,
        durationMinutes: 5,
      ),
      ServiceSheetItem(
        id: 'predication',
        type: 'predication',
        title: 'Prédication',
        order: 9,
        durationMinutes: 30,
      ),
      ServiceSheetItem(
        id: 'section_reponse',
        type: 'section',
        title: 'TEMPS DE RÉPONSE',
        order: 10,
        durationMinutes: 0,
      ),
      ServiceSheetItem(
        id: 'offrande',
        type: 'offrande',
        title: 'Offrande',
        order: 11,
        durationMinutes: 10,
      ),
      ServiceSheetItem(
        id: 'section_conclusion',
        type: 'section',
        title: 'CONCLUSION',
        order: 12,
        durationMinutes: 0,
      ),
      ServiceSheetItem(
        id: 'conclusion',
        type: 'priere',
        title: 'Prière de conclusion',
        order: 13,
        durationMinutes: 5,
      ),
    ];
  }

  Future<void> _saveServiceSheet() async {
    if (_serviceSheet == null) return;

    try {
      if (_serviceSheet!.id.isEmpty) {
        await ServicesFirebaseService.createServiceSheet(_serviceSheet!);
      } else {
        await ServicesFirebaseService.updateServiceSheet(
          ServiceSheetModel(
            id: _serviceSheet!.id,
            serviceId: _serviceSheet!.serviceId,
            title: _serviceSheet!.title,
            items: _serviceSheet!.items,
            notes: _serviceSheet!.notes,
            createdAt: _serviceSheet!.createdAt,
            updatedAt: DateTime.now(),
            createdBy: _serviceSheet!.createdBy,
          ),
        );
      }
      setState(() => _isEditMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Feuille de service sauvegardée'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        itemTypes: _itemTypes,
        onAdd: (item) {
          setState(() {
            final newItem = ServiceSheetItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: item['type'],
              title: item['title'],
              order: _serviceSheet!.items.length + 1,
              durationMinutes: item['duration'],
            );
            _serviceSheet = ServiceSheetModel(
              id: _serviceSheet!.id,
              serviceId: _serviceSheet!.serviceId,
              title: _serviceSheet!.title,
              items: [..._serviceSheet!.items, newItem],
              notes: _serviceSheet!.notes,
              createdAt: _serviceSheet!.createdAt,
              updatedAt: DateTime.now(),
              createdBy: _serviceSheet!.createdBy,
            );
          });
        },
      ),
    );
  }

  void _editItem(ServiceSheetItem item) {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(
        item: item,
        itemTypes: _itemTypes,
        onUpdate: (updatedItem) {
          setState(() {
            final items = _serviceSheet!.items.map((i) => 
                i.id == item.id ? updatedItem : i).toList();
            _serviceSheet = ServiceSheetModel(
              id: _serviceSheet!.id,
              serviceId: _serviceSheet!.serviceId,
              title: _serviceSheet!.title,
              items: items,
              notes: _serviceSheet!.notes,
              createdAt: _serviceSheet!.createdAt,
              updatedAt: DateTime.now(),
              createdBy: _serviceSheet!.createdBy,
            );
          });
        },
      ),
    );
  }

  void _deleteItem(ServiceSheetItem item) {
    setState(() {
      final items = _serviceSheet!.items.where((i) => i.id != item.id).toList();
      // Reorder items
      for (int i = 0; i < items.length; i++) {
        items[i] = ServiceSheetItem(
          id: items[i].id,
          type: items[i].type,
          title: items[i].title,
          description: items[i].description,
          order: i + 1,
          durationMinutes: items[i].durationMinutes,
          responsiblePersonId: items[i].responsiblePersonId,
          // songId: items[i].songId, // Removed - Songs module deleted
          attachmentUrls: items[i].attachmentUrls,
          customData: items[i].customData,
        );
      }
      _serviceSheet = ServiceSheetModel(
        id: _serviceSheet!.id,
        serviceId: _serviceSheet!.serviceId,
        title: _serviceSheet!.title,
        items: items,
        notes: _serviceSheet!.notes,
        createdAt: _serviceSheet!.createdAt,
        updatedAt: DateTime.now(),
        createdBy: _serviceSheet!.createdBy,
      );
    });
  }

  Color _getItemColor(String type) {
    return _itemTypes.firstWhere(
      (item) => item['value'] == type,
      orElse: () => _itemTypes.last,
    )['color'];
  }

  IconData _getItemIcon(String type) {
    return _itemTypes.firstWhere(
      (item) => item['value'] == type,
      orElse: () => _itemTypes.last,
    )['icon'];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_serviceSheet == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune feuille de service',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Créez une feuille de service pour organiser votre culte',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _serviceSheet = _createDefaultSheet();
                  _isEditMode = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer une feuille'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceSheet!.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Durée totale: ${_serviceSheet!.totalDuration} minutes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEditMode) ...[
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter un élément',
                ),
                IconButton(
                  onPressed: _saveServiceSheet,
                  icon: const Icon(Icons.save),
                  tooltip: 'Sauvegarder',
                ),
                IconButton(
                  onPressed: () => setState(() => _isEditMode = false),
                  icon: const Icon(Icons.close),
                  tooltip: 'Annuler',
                ),
              ] else ...[
                IconButton(
                  onPressed: () => setState(() => _isEditMode = true),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement print/export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité d\'export à venir')),
                    );
                  },
                  icon: const Icon(Icons.print),
                  tooltip: 'Imprimer/Exporter',
                ),
              ],
            ],
          ),
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _serviceSheet!.items.length,
            itemBuilder: (context, index) {
              final item = _serviceSheet!.items[index];
              return _buildItemCard(item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ServiceSheetItem item, int index) {
    final color = _getItemColor(item.type);
    final icon = _getItemIcon(item.type);
    final isSection = item.type == 'section';

    // Style spécial pour les sections
    if (isSection) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12, top: 8),
        child: Card(
          elevation: 2,
          color: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: Colors.white),
                      Text(
                        '${item.order}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (item.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.description!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isEditMode)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: color),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editItem(item);
                          break;
                        case 'delete':
                          _deleteItem(item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Style normal pour les autres éléments
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              Text(
                '${item.order}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.typeLabel),
            if (item.description != null)
              Text(
                item.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.durationMinutes > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.durationMinutes}min',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            if (_isEditMode) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editItem(item);
                      break;
                    case 'delete':
                      _deleteItem(item);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final List<Map<String, dynamic>> itemTypes;
  final Function(Map<String, dynamic>) onAdd;

  const _AddItemDialog({
    required this.itemTypes,
    required this.onAdd,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'autre';
  int _duration = 5;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un élément'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: widget.itemTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Row(
                    children: [
                      Icon(type['icon'], color: type['color'], size: 20),
                      const SizedBox(width: 8),
                      Text(type['label']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Durée: $_duration min'),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (value) => setState(() => _duration = value.round()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              widget.onAdd({
                'type': _selectedType,
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty 
                    ? null 
                    : _descriptionController.text.trim(),
                'duration': _duration,
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

class _EditItemDialog extends StatefulWidget {
  final ServiceSheetItem item;
  final List<Map<String, dynamic>> itemTypes;
  final Function(ServiceSheetItem) onUpdate;

  const _EditItemDialog({
    required this.item,
    required this.itemTypes,
    required this.onUpdate,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedType;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _selectedType = widget.item.type;
    _duration = widget.item.durationMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier l\'élément'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: widget.itemTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Row(
                    children: [
                      Icon(type['icon'], color: type['color'], size: 20),
                      const SizedBox(width: 8),
                      Text(type['label']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Durée: $_duration min'),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (value) => setState(() => _duration = value.round()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              final updatedItem = ServiceSheetItem(
                id: widget.item.id,
                type: _selectedType,
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim().isEmpty 
                    ? null 
                    : _descriptionController.text.trim(),
                order: widget.item.order,
                durationMinutes: _duration,
                responsiblePersonId: widget.item.responsiblePersonId,
                // songId: widget.item.songId, // Removed - Songs module deleted
                attachmentUrls: widget.item.attachmentUrls,
                customData: widget.item.customData,
              );
              widget.onUpdate(updatedItem);
              Navigator.pop(context);
            }
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}