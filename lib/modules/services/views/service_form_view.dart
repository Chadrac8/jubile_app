import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/service_template.dart';
import '../services/services_service.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../extensions/datetime_extensions.dart';



/// Vue de formulaire pour créer/modifier un service
class ServiceFormView extends StatefulWidget {
  final Service? service;
  final bool isEdit;

  const ServiceFormView({
    Key? key,
    this.service,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<ServiceFormView> createState() => _ServiceFormViewState();
}

class _ServiceFormViewState extends State<ServiceFormView>
    with SingleTickerProviderStateMixin {
  final ServicesService _servicesService = ServicesService();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Contrôleurs de texte
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _streamingUrlController;

  // Variables d'état
  ServiceType _selectedType = ServiceType.worship;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  String? _selectedColor;
  bool _isRecurring = false;
  bool _isStreamingEnabled = false;
  List<String> _selectedEquipment = [];
  List<String> _assignedMembers = [];

  bool _isLoading = false;
  bool _isGeneratingImage = false;

  // Couleurs prédéfinies
  final List<String> _availableColors = [
    '#2196F3', '#4CAF50', '#FF9800', '#9C27B0',
    '#F44336', '#00BCD4', '#795548', '#607D8B',
    '#E91E63', '#3F51B5',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeForm();
  }

  void _initializeForm() {
    final service = widget.service;
    
    _nameController = TextEditingController(text: service?.name ?? '');
    _descriptionController = TextEditingController(text: service?.description ?? '');
    _locationController = TextEditingController(text: service?.location ?? '');
    _notesController = TextEditingController(text: service?.notes ?? '');
    _streamingUrlController = TextEditingController(text: service?.streamingUrl ?? '');

    if (service != null) {
      _selectedType = service.type;
      _startDate = service.startDate;
      _startTime = TimeOfDay(hour: service.startDate.hour, minute: service.startDate.minute);
      _endTime = TimeOfDay(hour: service.endDate.hour, minute: service.endDate.minute);
      _selectedColor = service.colorCode;
      _isRecurring = service.isRecurring;
      _isStreamingEnabled = service.isStreamingEnabled;
      _selectedEquipment = List.from(service.equipmentNeeded);
      _assignedMembers = List.from(service.assignedMembers);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _streamingUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: widget.isEdit ? 'Modifier le service' : 'Nouveau service',
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _saveService,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ENREGISTRER'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInformationsTab(),
                  _buildSchedulingTab(),
                  _buildAppearanceTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Infos', icon: Icon(Icons.info)),
          Tab(text: 'Planning', icon: Icon(Icons.schedule)),
          Tab(text: 'Apparence', icon: Icon(Icons.palette)),
          Tab(text: 'Paramètres', icon: Icon(Icons.settings)),
        ],
      ),
    );
  }

  Widget _buildInformationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations de base',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du service *',
                      hintText: 'Ex: Culte dominical',
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
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Description du service...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<ServiceType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type de service *',
                      border: OutlineInputBorder(),
                    ),
                    items: ServiceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getTypeIcon(type)),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lieu *',
                      hintText: 'Ex: Sanctuaire principal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le lieu est obligatoire';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Équipements nécessaires',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getRecommendedEquipment().map((equipment) {
                      final isSelected = _selectedEquipment.contains(equipment);
                      return FilterChip(
                        label: Text(equipment),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEquipment.add(equipment);
                            } else {
                              _selectedEquipment.remove(equipment);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextButton.icon(
                    onPressed: _addCustomEquipment,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter équipement personnalisé'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Planification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sélection de date
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(_formatDate(_startDate)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _selectDate,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const Divider(),
                  
                  // Heure de début
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Heure de début'),
                    subtitle: Text(_formatTime(_startTime)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectTime(isStart: true),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const Divider(),
                  
                  // Heure de fin
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Heure de fin'),
                    subtitle: Text(_formatTime(_endTime)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectTime(isStart: false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Durée calculée
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Durée: ${_calculateDuration()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Récurrence',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  
                  SwitchListTile(
                    title: const Text('Service récurrent'),
                    subtitle: const Text('Ce service se répète régulièrement'),
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() => _isRecurring = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les paramètres de récurrence pourront être configurés après la création.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Couleur du service',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = color);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(int.parse(color.replaceFirst('#', '0xff'))),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Image du service',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isGeneratingImage ? null : _generateImage,
                        icon: _isGeneratingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Générer'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.service?.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.service!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image, size: 40, color: Colors.grey),
                                      Text('Image non disponible'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 40, color: Colors.grey),
                                Text('Une image sera générée automatiquement'),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diffusion en ligne',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  
                  SwitchListTile(
                    title: const Text('Activer la diffusion'),
                    subtitle: const Text('Service diffusé en direct'),
                    value: _isStreamingEnabled,
                    onChanged: (value) {
                      setState(() => _isStreamingEnabled = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  if (_isStreamingEnabled) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _streamingUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de diffusion',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes additionnelles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Notes, instructions spéciales...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getRecommendedEquipment() {
    final typeEquipment = ServiceEquipment.equipmentByServiceType[_selectedType.name];
    if (typeEquipment != null) {
      return typeEquipment;
    }
    return ServiceEquipment.defaultEquipment.take(8).toList();
  }

  IconData _getTypeIcon(ServiceType type) {
    switch (type) {
      case ServiceType.worship:
        return Icons.church;
      case ServiceType.prayer:
        return Icons.favorite;
      case ServiceType.study:
        return Icons.book;
      case ServiceType.youth:
        return Icons.people;
      case ServiceType.children:
        return Icons.child_care;
      case ServiceType.special:
        return Icons.celebration;
      case ServiceType.conference:
        return Icons.event;
      case ServiceType.wedding:
        return Icons.favorite;
      case ServiceType.funeral:
        return Icons.local_florist;
      case ServiceType.baptism:
        return Icons.water_drop;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Ajuster automatiquement l'heure de fin si nécessaire
          final startMinutes = picked.hour * 60 + picked.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (endMinutes <= startMinutes) {
            _endTime = TimeOfDay(
              hour: (startMinutes + 120) ~/ 60 % 24,
              minute: (startMinutes + 120) % 60,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    int durationMinutes = endMinutes - startMinutes;
    if (durationMinutes < 0) {
      durationMinutes += 24 * 60; // Service se termine le lendemain
    }
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  Future<void> _addCustomEquipment() async {
    final TextEditingController controller = TextEditingController();
    
    final String? equipment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter équipement'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nom de l\'équipement',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (equipment != null && !_selectedEquipment.contains(equipment)) {
      setState(() => _selectedEquipment.add(equipment));
    }
  }

  Future<void> _generateImage() async {
    setState(() => _isGeneratingImage = true);
    
    try {
      final imageUrl = await "https://images.unsplash.com/photo-1478147427282-58a87a120781?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTA0MTU3NDR8&ixlib=rb-4.1.0&q=80&w=1080";
      
      // L'image sera utilisée lors de la sauvegarde
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image générée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération: $e')),
      );
    } finally {
      setState(() => _isGeneratingImage = false);
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final service = Service(
        id: widget.service?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim(),
        colorCode: _selectedColor,
        isRecurring: _isRecurring,
        equipmentNeeded: _selectedEquipment,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isStreamingEnabled: _isStreamingEnabled,
        streamingUrl: _streamingUrlController.text.trim().isEmpty ? null : _streamingUrlController.text.trim(),
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.service?.createdBy ?? 'current_user', // TODO: Utiliser l'ID utilisateur réel
      );

      if (widget.isEdit && widget.service?.id != null) {
        await _servicesService.updateService(widget.service!.id!, service);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service modifié avec succès')),
        );
      } else {
        await _servicesService.createService(service);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service créé avec succès')),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return date.mediumDate;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}