import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/person_model.dart';
import '../services/appointments_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _motifController = TextEditingController();
  final _notesController = TextEditingController();
  final _adresseController = TextEditingController();
  final _numeroTelController = TextEditingController();
  
  // Form state
  PersonModel? _currentUser;
  List<PersonModel> _responsables = [];
  List<DateTime> _availableSlots = [];
  PersonModel? _selectedResponsable;
  DateTime? _selectedDateTime;
  String _selectedLieu = 'en_personne';
  String _selectedMotif = '';
  bool _isLoading = true;
  bool _isLoadingSlots = false;
  bool _isSaving = false;
  
  final List<String> _motifOptions = [
    'Entretien pastoral',
    'Conseil spirituel',
    'Prière personnelle',
    'Orientation de vie',
    'Problème familial',
    'Question de foi',
    'Baptême',
    'Mariage',
    'Préparation au service',
    'Formation',
    'Autre',
  ];

  final Map<String, String> _lieuOptions = {
    'en_personne': 'En personne',
    'appel_video': 'Appel vidéo',
    'telephone': 'Téléphone',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _motifController.dispose();
    _notesController.dispose();
    _adresseController.dispose();
    _numeroTelController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = await AuthService.getCurrentUserProfile();
      final responsables = await AppointmentsFirebaseService.getResponsables();
      
      setState(() {
        _currentUser = currentUser;
        _responsables = responsables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedResponsable == null) return;

    setState(() => _isLoadingSlots = true);

    try {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));
      
      final slots = await AppointmentsFirebaseService.getAvailableSlots(
        _selectedResponsable!.id,
        now,
        endDate,
      );

      setState(() {
        _availableSlots = slots;
        _selectedDateTime = null;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      _showErrorSnackBar('Erreur lors du chargement des créneaux: $e');
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || 
        _selectedResponsable == null || 
        _selectedDateTime == null ||
        _currentUser == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Check if user already has an appointment on the same day
      final existingAppointment = await AppointmentsFirebaseService
          .getAppointmentByMemberAndDate(_currentUser!.id, _selectedDateTime!);
      
      if (existingAppointment != null) {
        _showErrorSnackBar('Vous avez déjà un rendez-vous ce jour-là');
        setState(() => _isSaving = false);
        return;
      }

      final appointment = AppointmentModel(
        id: '',
        membreId: _currentUser!.id,
        responsableId: _selectedResponsable!.id,
        dateTime: _selectedDateTime!,
        motif: _selectedMotif.isNotEmpty ? _selectedMotif : _motifController.text,
        lieu: _selectedLieu,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        adresse: _selectedLieu == 'en_personne' && _adresseController.text.isNotEmpty 
            ? _adresseController.text : null,
        numeroTelephone: _selectedLieu == 'telephone' && _numeroTelController.text.isNotEmpty 
            ? _numeroTelController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastModifiedBy: _currentUser!.id,
      );

      await AppointmentsFirebaseService.createAppointment(appointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de rendez-vous envoyée avec succès !'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la réservation: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouveau Rendez-vous'),
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildResponsableSelector(),
            const SizedBox(height: 24),
            if (_selectedResponsable != null) ...[
              _buildDateTimeSelector(),
              const SizedBox(height: 24),
            ],
            if (_selectedDateTime != null) ...[
              _buildMotifSelector(),
              const SizedBox(height: 24),
              _buildLieuSelector(),
              const SizedBox(height: 24),
              _buildNotesField(),
              const SizedBox(height: 24),
              if (_selectedLieu == 'en_personne')
                _buildAdresseField(),
              if (_selectedLieu == 'telephone')
                _buildTelephoneField(),
              const SizedBox(height: 32),
              _buildConfirmationSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryColor,
              Theme.of(context).colorScheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Prendre rendez-vous',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Planifiez facilement un moment d\'échange avec un responsable de l\'église.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsableSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Choisir un responsable',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_responsables.isEmpty)
              const Text('Aucun responsable disponible')
            else
              ...(_responsables.map((responsable) => _buildResponsableCard(responsable))),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsableCard(PersonModel responsable) {
    final isSelected = _selectedResponsable?.id == responsable.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedResponsable = responsable;
            _selectedDateTime = null;
            _availableSlots = [];
          });
          _loadAvailableSlots();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primaryColor,
                child: Text(
                  responsable.displayInitials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      responsable.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).colorScheme.primaryColor : null,
                      ),
                    ),
                    if (responsable.roles.isNotEmpty)
                      Text(
                        responsable.roles.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.textTertiaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Choisir un créneau',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_availableSlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucun créneau disponible pour ${_selectedResponsable!.fullName} dans les 30 prochains jours.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildSlotGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    final groupedSlots = <String, List<DateTime>>{};
    
    for (final slot in _availableSlots) {
      final dateKey = DateFormat('yyyy-MM-dd').format(slot);
      groupedSlots.putIfAbsent(dateKey, () => []).add(slot);
    }

    return Column(
      children: groupedSlots.entries.map((entry) {
        final date = DateTime.parse(entry.key);
        final slots = entry.value..sort();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDateHeader(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((slot) => _buildSlotChip(slot)).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlotChip(DateTime slot) {
    final isSelected = _selectedDateTime == slot;
    
    return InkWell(
      onTap: () => setState(() => _selectedDateTime = slot),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryColor : null,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primaryColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          DateFormat('HH:mm').format(slot),
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.textPrimaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMotifSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Motif du rendez-vous',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _motifOptions.map((motif) {
                final isSelected = _selectedMotif == motif;
                return FilterChip(
                  label: Text(motif),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMotif = selected ? motif : '';
                      if (selected && motif == 'Autre') {
                        _motifController.clear();
                      }
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primaryColor,
                );
              }).toList(),
            ),
            if (_selectedMotif == 'Autre') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _motifController,
                decoration: InputDecoration(
                  labelText: 'Précisez le motif',
                  hintText: 'Décrivez brièvement le motif de votre rendez-vous',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (_selectedMotif == 'Autre' && (value == null || value.trim().isEmpty)) {
                    return 'Veuillez préciser le motif';
                  }
                  return null;
                },
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLieuSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Modalité du rendez-vous',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._lieuOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                subtitle: Text(_getLieuDescription(entry.key)),
                value: entry.key,
                groupValue: _selectedLieu,
                onChanged: (value) => setState(() => _selectedLieu = value!),
                activeColor: Theme.of(context).colorScheme.primaryColor,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Notes personnelles (facultatif)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Ajoutez des informations complémentaires...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdresseField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Lieu de rencontre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: InputDecoration(
                labelText: 'Adresse ou lieu spécifique',
                hintText: 'Ex: Bureau pastoral, Église, Café...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelephoneField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Numéro de téléphone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroTelController,
              decoration: InputDecoration(
                labelText: 'Votre numéro de téléphone',
                hintText: 'Ex: +33 6 12 34 56 78',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Responsable', _selectedResponsable!.fullName),
            _buildSummaryRow('Date et heure', _formatDateTimeFull(_selectedDateTime!)),
            _buildSummaryRow('Motif', _selectedMotif.isNotEmpty ? _selectedMotif : _motifController.text),
            _buildSummaryRow('Modalité', _lieuOptions[_selectedLieu]!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirmer le rendez-vous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Theme.of(context).colorScheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLieuDescription(String lieu) {
    switch (lieu) {
      case 'en_personne':
        return 'Rencontre physique';
      case 'appel_video':
        return 'Visioconférence (Zoom, Meet...)';
      case 'telephone':
        return 'Appel téléphonique';
      default:
        return '';
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    if (_isSameDay(date, now)) {
      return 'Aujourd\'hui - ${DateFormat('EEEE d MMMM', 'fr_FR').format(date)}';
    } else if (_isSameDay(date, tomorrow)) {
      return 'Demain - ${DateFormat('EEEE d MMMM', 'fr_FR').format(date)}';
    } else {
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    }
  }

  String _formatDateTimeFull(DateTime dateTime) {
    return '${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(dateTime)} à ${DateFormat('HH:mm').format(dateTime)}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}