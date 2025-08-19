import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment_model.dart';
import '../models/person_model.dart';
import '../services/appointments_firebase_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';

class AppointmentDetailPage extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  AppointmentModel? _currentAppointment;
  PersonModel? _responsable;
  PersonModel? _membre;
  PersonModel? _currentUser;
  bool _isLoading = true;
  bool _canModify = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
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
      final appointment = await AppointmentsFirebaseService.getAppointment(widget.appointment.id);
      final responsable = await FirebaseService.getPerson(widget.appointment.responsableId);
      final membre = await FirebaseService.getPerson(widget.appointment.membreId);

      setState(() {
        _currentUser = currentUser;
        _currentAppointment = appointment ?? widget.appointment;
        _responsable = responsable;
        _membre = membre;
        _canModify = currentUser?.id == widget.appointment.membreId || 
                     currentUser?.id == widget.appointment.responsableId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await _showConfirmationDialog(
      'Annuler le rendez-vous',
      'Êtes-vous sûr de vouloir annuler ce rendez-vous ?',
      'Annuler',
      AppTheme.errorColor,
    );

    if (confirmed) {
      try {
        await AppointmentsFirebaseService.cancelAppointment(
          _currentAppointment!.id,
          'Annulé par ${_currentUser?.fullName}',
        );
        
        _showSuccessSnackBar('Rendez-vous annulé avec succès');
        _loadData(); // Refresh data
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'annulation: $e');
      }
    }
  }

  Future<void> _confirmAppointment() async {
    if (_currentUser?.id != _currentAppointment?.responsableId) return;

    final confirmed = await _showConfirmationDialog(
      'Confirmer le rendez-vous',
      'Voulez-vous confirmer ce rendez-vous ?',
      'Confirmer',
      AppTheme.successColor,
    );

    if (confirmed) {
      try {
        await AppointmentsFirebaseService.confirmAppointment(_currentAppointment!.id);
        
        _showSuccessSnackBar('Rendez-vous confirmé avec succès');
        _loadData(); // Refresh data
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la confirmation: $e');
      }
    }
  }

  Future<void> _rejectAppointment() async {
    if (_currentUser?.id != _currentAppointment?.responsableId) return;

    final reason = await _showReasonDialog();
    if (reason != null && reason.isNotEmpty) {
      try {
        await AppointmentsFirebaseService.rejectAppointment(_currentAppointment!.id, reason);
        
        _showSuccessSnackBar('Rendez-vous refusé');
        _loadData(); // Refresh data
      } catch (e) {
        _showErrorSnackBar('Erreur lors du refus: $e');
      }
    }
  }

  Future<void> _completeAppointment() async {
    if (_currentUser?.id != _currentAppointment?.responsableId) return;

    final notes = await _showNotesDialog();
    
    try {
      await AppointmentsFirebaseService.completeAppointment(_currentAppointment!.id, notes: notes);
      
      _showSuccessSnackBar('Rendez-vous marqué comme terminé');
      _loadData(); // Refresh data
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<void> _launchVideoCall() async {
    final link = _currentAppointment?.lienVideo;
    if (link != null && link.isNotEmpty) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final phone = _currentAppointment?.numeroTelephone ?? _membre?.phone;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content, String action, Color color) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(action),
          ),
        ],
      ),
    ) ?? false;
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes sur le rendez-vous'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ajoutez des notes sur ce rendez-vous (optionnel)...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Ignorer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
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

    if (_currentAppointment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(
          child: Text('Rendez-vous introuvable'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Détail du rendez-vous'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              const SizedBox(height: 16),
              _buildParticipantsCard(),
              const SizedBox(height: 16),
              if (_currentAppointment!.notes?.isNotEmpty == true)
                _buildNotesCard(),
              if (_currentAppointment!.notesPrivees?.isNotEmpty == true &&
                  _currentUser?.id == _currentAppointment!.responsableId)
                _buildPrivateNotesCard(),
              const SizedBox(height: 16),
              if (_canModify) _buildActionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_currentAppointment!.statut) {
      case 'en_attente':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.schedule;
        statusText = 'En attente de confirmation';
        break;
      case 'confirme':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        statusText = 'Confirmé';
        break;
      case 'refuse':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        statusText = 'Refusé';
        break;
      case 'termine':
        statusColor = AppTheme.primaryColor;
        statusIcon = Icons.check;
        statusText = 'Terminé';
        break;
      case 'annule':
        statusColor = AppTheme.textTertiaryColor;
        statusIcon = Icons.event_busy;
        statusText = 'Annulé';
        break;
      default:
        statusColor = AppTheme.textTertiaryColor;
        statusIcon = Icons.help;
        statusText = 'Statut inconnu';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusColor.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            if (_currentAppointment!.raisonAnnulation?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Raison: ${_currentAppointment!.raisonAnnulation}',
                style: TextStyle(
                  color: statusColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
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
                Icon(Icons.info, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Informations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, 'Date et heure', _formatDateTime(_currentAppointment!.dateTime)),
            _buildDetailRow(Icons.chat, 'Motif', _currentAppointment!.motif),
            _buildDetailRow(_getLocationIcon(_currentAppointment!.lieu), 'Modalité', _currentAppointment!.lieuLabel),
            if (_currentAppointment!.adresse?.isNotEmpty == true)
              _buildDetailRow(Icons.place, 'Lieu', _currentAppointment!.adresse!),
            if (_currentAppointment!.numeroTelephone?.isNotEmpty == true)
              _buildDetailRow(Icons.phone, 'Téléphone', _currentAppointment!.numeroTelephone!),
            if (_currentAppointment!.lienVideo?.isNotEmpty == true)
              _buildDetailRow(Icons.video_call, 'Lien vidéo', 'Disponible', onTap: _launchVideoCall),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsCard() {
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
                Icon(Icons.people, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_responsable != null)
              _buildParticipantRow('Responsable', _responsable!),
            const SizedBox(height: 8),
            if (_membre != null)
              _buildParticipantRow('Membre', _membre!),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
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
                Icon(Icons.note, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Notes du membre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentAppointment!.notes!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateNotesCard() {
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
                Icon(Icons.lock, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Notes privées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentAppointment!.notesPrivees!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    final isResponsable = _currentUser?.id == _currentAppointment!.responsableId;
    final isMembre = _currentUser?.id == _currentAppointment!.membreId;
    final isEnAttente = _currentAppointment!.isEnAttente;
    final isConfirme = _currentAppointment!.isConfirme;
    final isAVenir = _currentAppointment!.isAVenir;

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
                Icon(Icons.settings, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isResponsable) ...[
              if (isEnAttente) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmAppointment,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _rejectAppointment,
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (isConfirme && isAVenir) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _completeAppointment,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Marquer comme terminé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
            if ((isEnAttente || isConfirme) && isAVenir) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cancelAppointment,
                  icon: const Icon(Icons.cancel),
                  label: Text(isResponsable ? 'Annuler le rendez-vous' : 'Annuler ma demande'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (_currentAppointment!.lieu == 'appel_video' && 
                _currentAppointment!.lienVideo?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _launchVideoCall,
                  icon: const Icon(Icons.video_call),
                  label: const Text('Rejoindre l\'appel vidéo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (_currentAppointment!.lieu == 'telephone') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _makePhoneCall,
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppTheme.textTertiaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textTertiaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(String role, PersonModel person) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            person.displayInitials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textTertiaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    final weekdays = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final weekday = weekdays[dateTime.weekday];
    
    return '$weekday $day/$month/$year à ${hour}h$minute';
  }
}