import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/person_model.dart';
import '../services/events_firebase_service.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;
import 'firebase_storage_diagnostic_page.dart';

class EventFormPage extends StatefulWidget {
  final EventModel? event;

  const EventFormPage({super.key, this.event});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Form values
  String? _selectedType;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _visibility = 'publique';
  List<String> _selectedResponsibleIds = [];
  List<String> _visibilityTargets = [];
  String _status = 'brouillon';
  bool _isRegistrationEnabled = false;
  int? _maxParticipants;
  bool _hasWaitingList = false;
  bool _isRecurring = false;
  bool _isLoading = false;
  
  // Image handling
  String? _imageUrl;
  bool _hasImageChanged = false;

  final List<Map<String, String>> _eventTypes = [
    {'value': 'celebration', 'label': 'Célébration', 'icon': 'celebration'},
    {'value': 'bapteme', 'label': 'Baptême', 'icon': 'water_drop'},
    {'value': 'formation', 'label': 'Formation', 'icon': 'school'},
    {'value': 'sortie', 'label': 'Sortie', 'icon': 'directions_walk'},
    {'value': 'conference', 'label': 'Conférence', 'icon': 'mic'},
    {'value': 'reunion', 'label': 'Réunion', 'icon': 'groups'},
    {'value': 'autre', 'label': 'Autre', 'icon': 'event'},
  ];

  final List<Map<String, String>> _visibilityOptions = [
    {'value': 'publique', 'label': 'Publique', 'description': 'Visible par tous'},
    {'value': 'privee', 'label': 'Privée', 'description': 'Visible uniquement par les responsables'},
    {'value': 'groupe', 'label': 'Réservée aux groupes', 'description': 'Visible par les membres de groupes spécifiques'},
    {'value': 'role', 'label': 'Réservée aux rôles', 'description': 'Visible par les membres avec des rôles spécifiques'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializeForm();
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.event != null) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _selectedType = event.type;
      _startDate = event.startDate;
      _startTime = TimeOfDay.fromDateTime(event.startDate);
      _endDate = event.endDate;
      _endTime = event.endDate != null ? TimeOfDay.fromDateTime(event.endDate!) : null;
      _visibility = event.visibility;
      _selectedResponsibleIds = List.from(event.responsibleIds);
      _visibilityTargets = List.from(event.visibilityTargets);
      _status = event.status;
      _isRegistrationEnabled = event.isRegistrationEnabled;
      _maxParticipants = event.maxParticipants;
      _hasWaitingList = event.hasWaitingList;
      _isRecurring = event.isRecurring;
      _imageUrl = event.imageUrl;
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(hours: 2)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.fromDateTime(_startDate.add(const Duration(hours: 2))),
    );
    
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _pickEventImage() async {
    try {
      setState(() => _isLoading = true);
      
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      if (imageBytes != null) {
        // Sauvegarder l'ancienne URL pour la supprimer après upload réussi
        final oldImageUrl = _imageUrl;
        
        // Upload to Firebase Storage instead of storing as base64
        final imageUrl = await ImageStorage.ImageStorageService.uploadImage(
          imageBytes,
          customPath: 'events/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        if (imageUrl != null) {
          setState(() {
            _imageUrl = imageUrl;
            _hasImageChanged = true;
          });
          
          // Supprimer l'ancienne image si elle existe et est stockée sur Firebase
          if (oldImageUrl != null && 
              oldImageUrl.isNotEmpty && 
              ImageStorage.ImageStorageService.isFirebaseStorageUrl(oldImageUrl)) {
            ImageStorage.ImageStorageService.deleteImageByUrl(oldImageUrl);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image de l\'événement mise à jour avec succès'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        } else {
          throw Exception('Échec de l\'upload de l\'image vers Firebase Storage');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Diagnostic',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FirebaseStorageDiagnosticPage(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }
      
      final event = EventModel(
        id: widget.event?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim(),
        imageUrl: _imageUrl,
        type: _selectedType!,
        responsibleIds: _selectedResponsibleIds,
        visibility: _visibility,
        visibilityTargets: _visibilityTargets,
        status: _status,
        isRegistrationEnabled: _isRegistrationEnabled,
        maxParticipants: _maxParticipants,
        hasWaitingList: _hasWaitingList,
        isRecurring: _isRecurring,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.event?.createdBy,
        lastModifiedBy: 'current_user_id', // TODO: Get from auth
      );
      
      if (widget.event == null) {
        await EventsFirebaseService.createEvent(event);
      } else {
        await EventsFirebaseService.updateEvent(event);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.event == null ? 'Nouvel événement' : 'Modifier l\'événement'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveEvent,
              child: const Text(
                'Sauvegarder',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, _slideAnimation.value),
            end: Offset.zero,
          ).animate(_animationController),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image de l'événement
            _buildImageSection(),
            const SizedBox(height: 24),
            
            // Informations de base
            _buildSection(
              title: 'Informations de base',
              icon: Icons.info_outline,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Titre de l\'événement',
                  icon: Icons.title,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedType,
                  label: 'Type d\'événement',
                  icon: Icons.category,
                  items: _eventTypes,
                  onChanged: (value) => setState(() => _selectedType = value),
                  validator: (value) {
                    if (value == null) {
                      return 'Le type est obligatoire';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Date et heure
            _buildSection(
              title: 'Date et heure',
              icon: Icons.schedule,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDateField('Date de début', _startDate, _selectStartDate)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimeField('Heure de début', _startTime, _selectStartTime)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        'Date de fin (optionnel)', 
                        _endDate, 
                        _selectEndDate,
                        isOptional: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeField(
                        'Heure de fin (optionnel)', 
                        _endTime, 
                        _selectEndTime,
                        isOptional: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Lieu
            _buildSection(
              title: 'Lieu',
              icon: Icons.location_on,
              children: [
                _buildTextField(
                  controller: _locationController,
                  label: 'Lieu ou adresse',
                  icon: Icons.place,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le lieu est obligatoire';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Visibilité et responsables
            _buildSection(
              title: 'Visibilité et responsables',
              icon: Icons.visibility,
              children: [
                _buildVisibilitySelector(),
                const SizedBox(height: 16),
                _buildResponsibleSelector(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Inscriptions
            _buildSection(
              title: 'Inscriptions',
              icon: Icons.how_to_reg,
              children: [
                _buildRegistrationSettings(),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Options avancées
            _buildSection(
              title: 'Options avancées',
              icon: Icons.settings,
              children: [
                _buildAdvancedOptions(),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: _imageUrl != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => setState(() => _imageUrl = null),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: _pickEventImage,
                    icon: const Icon(Icons.edit),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return InkWell(
      onTap: _pickEventImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textTertiaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajouter une image',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap, {bool isOptional = false}) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppTheme.backgroundColor,
        ),
        child: Text(
          date != null ? _formatDate(date) : (isOptional ? 'Non définie' : 'Sélectionner'),
          style: TextStyle(
            color: date != null ? AppTheme.textPrimaryColor : AppTheme.textTertiaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? time, VoidCallback onTap, {bool isOptional = false}) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppTheme.backgroundColor,
        ),
        child: Text(
          time != null ? time.format(context) : (isOptional ? 'Non définie' : 'Sélectionner'),
          style: TextStyle(
            color: time != null ? AppTheme.textPrimaryColor : AppTheme.textTertiaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibilité',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._visibilityOptions.map((option) {
          return RadioListTile<String>(
            value: option['value']!,
            groupValue: _visibility,
            onChanged: (value) => setState(() => _visibility = value!),
            title: Text(option['label']!),
            subtitle: Text(option['description']!),
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildResponsibleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responsables',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _selectedResponsibleIds.isEmpty 
                ? 'Aucun responsable sélectionné'
                : '${_selectedResponsibleIds.length} responsable(s) sélectionné(s)',
            style: TextStyle(
              color: _selectedResponsibleIds.isEmpty 
                  ? AppTheme.textTertiaryColor 
                  : AppTheme.textPrimaryColor,
            ),
          ),
        ),
        // TODO: Implement person selector
      ],
    );
  }

  Widget _buildRegistrationSettings() {
    return Column(
      children: [
        SwitchListTile(
          value: _isRegistrationEnabled,
          onChanged: (value) => setState(() => _isRegistrationEnabled = value),
          title: const Text('Autoriser les inscriptions'),
          subtitle: const Text('Permettre aux membres de s\'inscrire'),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isRegistrationEnabled) ...[
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Nombre maximum de participants',
              prefixIcon: const Icon(Icons.people),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              helperText: 'Laissez vide pour un nombre illimité',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _maxParticipants = value.isNotEmpty ? int.tryParse(value) : null;
              });
            },
            initialValue: _maxParticipants?.toString(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _hasWaitingList,
            onChanged: _maxParticipants != null 
                ? (value) => setState(() => _hasWaitingList = value)
                : null,
            title: const Text('Liste d\'attente'),
            subtitle: const Text('Activer une liste d\'attente si l\'événement est complet'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      children: [
        SwitchListTile(
          value: _isRecurring,
          onChanged: (value) => setState(() => _isRecurring = value),
          title: const Text('Événement récurrent'),
          subtitle: const Text('Répéter cet événement'),
          contentPadding: EdgeInsets.zero,
        ),
        if (widget.event == null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: 'Statut initial',
              prefixIcon: const Icon(Icons.flag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
            ),
            items: const [
              DropdownMenuItem(value: 'brouillon', child: Text('Brouillon')),
              DropdownMenuItem(value: 'publie', child: Text('Publié')),
            ],
            onChanged: (value) => setState(() => _status = value!),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}