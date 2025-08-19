import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/person_model.dart';
import '../services/appointments_firebase_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import '../widgets/appointment_card.dart';
import '../widgets/availability_editor.dart';
import '../widgets/appointment_statistics_widget.dart';
import 'appointment_detail_page.dart';
import 'availability_management_page.dart';

class AppointmentsAdminPage extends StatefulWidget {
  const AppointmentsAdminPage({super.key});

  @override
  State<AppointmentsAdminPage> createState() => _AppointmentsAdminPageState();
}

class _AppointmentsAdminPageState extends State<AppointmentsAdminPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  PersonModel? _currentUser;
  String _selectedFilter = 'pending';
  String _selectedResponsable = 'all';
  List<PersonModel> _responsables = [];
  bool _isLoading = true;

  final Map<String, String> _filterLabels = {
    'pending': 'En attente',
    'confirmed': 'Confirmés',
    'today': 'Aujourd\'hui',
    'upcoming': 'À venir',
    'past': 'Passés',
    'all': 'Tous',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
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

  Future<void> _confirmAppointment(AppointmentModel appointment) async {
    try {
      await AppointmentsFirebaseService.confirmAppointment(appointment.id);
      _showSuccessSnackBar('Rendez-vous confirmé');
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<void> _rejectAppointment(AppointmentModel appointment) async {
    final reason = await _showReasonDialog();
    if (reason != null && reason.isNotEmpty) {
      try {
        await AppointmentsFirebaseService.rejectAppointment(appointment.id, reason);
        _showSuccessSnackBar('Rendez-vous refusé');
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raison du refus'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Expliquez pourquoi vous refusez ce rendez-vous...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorColor),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  List<String> _getStatusFilters() {
    switch (_selectedFilter) {
      case 'pending':
        return ['en_attente'];
      case 'confirmed':
        return ['confirme'];
      case 'today':
      case 'upcoming':
        return ['en_attente', 'confirme'];
      case 'past':
        return ['termine', 'annule', 'refuse'];
      default: // all
        return ['en_attente', 'confirme', 'termine', 'annule', 'refuse'];
    }
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'upcoming':
        return now;
      case 'past':
        return DateTime(2020);
      default:
        return null;
    }
  }

  DateTime? _getEndDate() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case 'past':
        return now;
      default:
        return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des rendez-vous'),
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mes RDV', icon: Icon(Icons.person, size: 20)),
            Tab(text: 'Tous les RDV', icon: Icon(Icons.list, size: 20)),
            Tab(text: 'Disponibilités', icon: Icon(Icons.schedule, size: 20)),
            Tab(text: 'Statistiques', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyAppointmentsTab(),
            _buildAllAppointmentsTab(),
            _buildAvailabilityTab(),
            _buildStatisticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyAppointmentsTab() {
    return Column(
      children: [
        _buildFilterSelector(),
        Expanded(child: _buildAppointmentsList(responsableId: _currentUser?.id)),
      ],
    );
  }

  Widget _buildAllAppointmentsTab() {
    return Column(
      children: [
        _buildFilterSelector(),
        _buildResponsableFilter(),
        Expanded(child: _buildAppointmentsList()),
      ],
    );
  }

  Widget _buildAvailabilityTab() {
    return AvailabilityEditor(
      responsableId: _currentUser?.id,
      onChanged: () {
        // Optionnel: rafraîchir les données si nécessaire
      },
    );
  }

  Widget _buildStatisticsTab() {
    return AppointmentStatisticsWidget(
      responsableId: _currentUser?.id,
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterLabels.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = entry.key);
                },
                backgroundColor: Colors.white,
                selectedColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.primaryColor : Theme.of(context).colorScheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResponsableFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedResponsable,
        decoration: InputDecoration(
          labelText: 'Filtrer par responsable',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('Tous les responsables')),
          ..._responsables.map((responsable) => DropdownMenuItem(
            value: responsable.id,
            child: Text(responsable.fullName),
          )),
        ],
        onChanged: (value) => setState(() => _selectedResponsable = value!),
      ),
    );
  }

  Widget _buildAppointmentsList({String? responsableId}) {
    final finalResponsableId = responsableId ?? 
        (_selectedResponsable != 'all' ? _selectedResponsable : null);

    return StreamBuilder<List<AppointmentModel>>(
      stream: AppointmentsFirebaseService.getAppointmentsStream(
        responsableId: finalResponsableId,
        statusFilters: _getStatusFilters(),
        startDate: _getStartDate(),
        endDate: _getEndDate(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.textTertiaryColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(appointments[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Theme.of(context).colorScheme.textTertiaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun rendez-vous trouvé',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les rendez-vous correspondant à vos filtres apparaîtront ici',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return AppointmentCard(
      appointment: appointment,
      onTap: () => _viewAppointmentDetail(appointment),
      showActions: appointment.statut == 'en_attente',
    );
  }

  Widget _buildStatusBadge(AppointmentModel appointment) {
    Color color;
    IconData icon;

    switch (appointment.statut) {
      case 'en_attente':
        color = Theme.of(context).colorScheme.warningColor;
        icon = Icons.schedule;
        break;
      case 'confirme':
        color = Theme.of(context).colorScheme.successColor;
        icon = Icons.check_circle;
        break;
      case 'refuse':
        color = Theme.of(context).colorScheme.errorColor;
        icon = Icons.cancel;
        break;
      case 'termine':
        color = Theme.of(context).colorScheme.primaryColor;
        icon = Icons.check;
        break;
      case 'annule':
        color = Theme.of(context).colorScheme.textTertiaryColor;
        icon = Icons.event_busy;
        break;
      default:
        color = Theme.of(context).colorScheme.textTertiaryColor;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            appointment.statutLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLocationIcon(String lieu) {
    switch (lieu) {
      case 'en_personne':
        return Icons.location_on;
      case 'appel_video':
        return Icons.video_call;
      case 'telephone':
        return Icons.phone;
      default:
        return Icons.help;
    }
  }

  void _viewAppointmentDetail(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailPage(appointment: appointment),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year à ${hour}h$minute';
  }
}