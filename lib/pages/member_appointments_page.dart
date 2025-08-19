import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/person_model.dart';
import '../services/appointments_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import '../widgets/appointment_card.dart';
import 'appointment_booking_page.dart';
import 'appointment_detail_page.dart';

class MemberAppointmentsPage extends StatefulWidget {
  const MemberAppointmentsPage({super.key});

  @override
  State<MemberAppointmentsPage> createState() => _MemberAppointmentsPageState();
}

class _MemberAppointmentsPageState extends State<MemberAppointmentsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  PersonModel? _currentUser;
  String _selectedFilter = 'upcoming';
  bool _isLoading = true;

  final Map<String, String> _filterLabels = {
    'upcoming': 'À venir',
    'pending': 'En attente',
    'confirmed': 'Confirmés',
    'past': 'Passés',
    'all': 'Tous',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await AuthService.getCurrentUserProfile();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bookNewAppointment() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppointmentBookingPage(),
      ),
    );

    if (result == true) {
      // Refresh the list
      setState(() {});
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ce rendez-vous ?\n\n'
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AppointmentsFirebaseService.cancelAppointment(
          appointment.id,
          'Annulé par le membre',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendez-vous annulé avec succès'),
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
  }

  List<String> _getStatusFilters() {
    switch (_selectedFilter) {
      case 'pending':
        return ['en_attente'];
      case 'confirmed':
        return ['confirme'];
      case 'past':
        return ['termine', 'annule', 'refuse'];
      case 'all':
        return ['en_attente', 'confirme', 'termine', 'annule', 'refuse'];
      default: // upcoming
        return ['en_attente', 'confirme'];
    }
  }

  DateTime? _getStartDate() {
    if (_selectedFilter == 'upcoming') {
      return DateTime.now();
    } else if (_selectedFilter == 'past') {
      return DateTime(2020);
    }
    return null;
  }

  DateTime? _getEndDate() {
    if (_selectedFilter == 'past') {
      return DateTime.now();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes Rendez-vous'),
        ),
        body: const Center(
          child: Text('Erreur lors du chargement du profil utilisateur'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _bookNewAppointment,
            tooltip: 'Nouveau rendez-vous',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterSelector(),
            Expanded(child: _buildAppointmentsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bookNewAppointment,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour ${_currentUser!.firstName} !',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gérez vos rendez-vous facilement',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
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
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: AppointmentsFirebaseService.getAppointmentsStream(
        membreId: _currentUser!.id,
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
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: AppTheme.textTertiaryColor),
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
    String title, subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'pending':
        title = 'Aucun rendez-vous en attente';
        subtitle = 'Vos demandes de rendez-vous apparaîtront ici';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        title = 'Aucun rendez-vous confirmé';
        subtitle = 'Vos rendez-vous confirmés apparaîtront ici';
        icon = Icons.check_circle;
        break;
      case 'past':
        title = 'Aucun rendez-vous passé';
        subtitle = 'L\'historique de vos rendez-vous apparaîtra ici';
        icon = Icons.history;
        break;
      default:
        title = 'Aucun rendez-vous à venir';
        subtitle = 'Prenez votre premier rendez-vous !';
        icon = Icons.event_available;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textTertiaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedFilter == 'upcoming') ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _bookNewAppointment,
              icon: const Icon(Icons.add),
              label: const Text('Prendre rendez-vous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return AppointmentCard(
      appointment: appointment,
      onTap: () => _viewAppointmentDetail(appointment),
      onCancel: appointment.statut == 'en_attente' 
          ? () => _cancelAppointment(appointment)
          : null,
      showActions: true,
    );
  }

  Widget _buildStatusBadge(AppointmentModel appointment) {
    Color color;
    IconData icon;

    switch (appointment.statut) {
      case 'en_attente':
        color = AppTheme.warningColor;
        icon = Icons.schedule;
        break;
      case 'confirme':
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case 'refuse':
        color = AppTheme.errorColor;
        icon = Icons.cancel;
        break;
      case 'termine':
        color = AppTheme.primaryColor;
        icon = Icons.check;
        break;
      case 'annule':
        color = AppTheme.textTertiaryColor;
        icon = Icons.event_busy;
        break;
      default:
        color = AppTheme.textTertiaryColor;
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