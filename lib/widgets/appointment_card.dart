import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class AppointmentCard extends StatefulWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final bool showActions;
  final bool isCompact;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
    this.onCancel,
    this.showActions = false,
    this.isCompact = false,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  PersonModel? _responsable;
  bool _isLoadingResponsable = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadResponsable();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadResponsable() async {
    try {
      final responsable = await FirebaseService.getPerson(widget.appointment.responsableId);
      if (mounted) {
        setState(() {
          _responsable = responsable;
          _isLoadingResponsable = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingResponsable = false);
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  Color get _statusColor {
    switch (widget.appointment.statut) {
      case 'en_attente':
        return AppTheme.warningColor;
      case 'confirme':
        return AppTheme.successColor;
      case 'refuse':
        return AppTheme.errorColor;
      case 'termine':
        return Colors.grey;
      case 'annule':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData get _statusIcon {
    switch (widget.appointment.statut) {
      case 'en_attente':
        return Icons.schedule;
      case 'confirme':
        return Icons.check_circle;
      case 'refuse':
        return Icons.cancel;
      case 'termine':
        return Icons.done_all;
      case 'annule':
        return Icons.block;
      default:
        return Icons.event;
    }
  }

  IconData get _locationIcon {
    switch (widget.appointment.lieu) {
      case 'en_personne':
        return Icons.place;
      case 'appel_video':
        return Icons.videocam;
      case 'telephone':
        return Icons.phone;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildCard(),
          );
        },
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: EdgeInsets.only(bottom: widget.isCompact ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // 5% opacity black
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _statusColor.withAlpha(51), // 20% opacity
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (!widget.isCompact) ...[
              const SizedBox(height: 12),
              _buildDetails(),
              if (widget.appointment.notes != null) ...[
                const SizedBox(height: 8),
                _buildNotes(),
              ],
              if (widget.showActions) ...[
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _statusColor.withAlpha(25), // 10% opacity
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _statusIcon,
            color: _statusColor,
            size: widget.isCompact ? 16 : 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingResponsable)
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                Text(
                  _responsable?.fullName ?? 'Responsable inconnu',
                  style: TextStyle(
                    fontSize: widget.isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: widget.isCompact ? 12 : 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(widget.appointment.dateTime),
                    style: TextStyle(
                      fontSize: widget.isCompact ? 12 : 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.appointment.statutLabel,
            style: TextStyle(
              fontSize: widget.isCompact ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        _buildDetailRow(
          icon: _locationIcon,
          label: 'Lieu',
          value: widget.appointment.lieuLabel,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.subject,
          label: 'Motif',
          value: widget.appointment.motif,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.appointment.notes!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (widget.appointment.statut == 'en_attente' && widget.onCancel != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Annuler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onTap,
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Détails'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    String dateStr;
    if (difference == 0) {
      dateStr = 'Aujourd\'hui';
    } else if (difference == 1) {
      dateStr = 'Demain';
    } else if (difference == -1) {
      dateStr = 'Hier';
    } else if (difference > 1 && difference <= 7) {
      dateStr = DateFormat('EEEE', 'fr_FR').format(dateTime);
    } else {
      dateStr = DateFormat('dd MMM', 'fr_FR').format(dateTime);
    }
    
    final timeStr = DateFormat('HH:mm').format(dateTime);
    return '$dateStr à $timeStr';
  }
}