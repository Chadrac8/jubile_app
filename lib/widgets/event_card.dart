import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../theme.dart';


class EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    switch (widget.event.status) {
      case 'publie': return AppTheme.successColor;
      case 'brouillon': return AppTheme.warningColor;
      case 'archive': return AppTheme.textTertiaryColor;
      case 'annule': return AppTheme.errorColor;
      default: return AppTheme.textSecondaryColor;
    }
  }

  String _getEventTypeKeyword() {
    switch (widget.event.type) {
      case 'celebration': return 'church celebration';
      case 'bapteme': return 'baptism ceremony';
      case 'formation': return 'training workshop';
      case 'sortie': return 'group outing';
      case 'conference': return 'conference seminar';
      case 'reunion': return 'meeting discussion';
      default: return 'community event';
    }
  }

  Widget _buildEventImage() {
    if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.event.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingImage(),
        errorWidget: (context, url, error) => _buildFallbackImage(),
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildLoadingImage() {
    return Container(
      color: AppTheme.backgroundColor,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    final keyword = _getEventTypeKeyword();
    final imageUrl = "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDgzNjE4MTV8&ixlib=rb-4.1.0&q=80&w=1080";
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.backgroundColor,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.secondaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            _getEventIcon(),
            size: 40,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  IconData _getEventIcon() {
    switch (widget.event.type) {
      case 'celebration': return Icons.celebration;
      case 'bapteme': return Icons.water_drop;
      case 'formation': return Icons.school;
      case 'sortie': return Icons.directions_walk;
      case 'conference': return Icons.mic;
      case 'reunion': return Icons.groups;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isSelected ? 0.15 : 0.08),
              blurRadius: widget.isSelected ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: widget.isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et sélection
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildEventImage(),
                  ),
                ),
                
                // Badge de statut
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.event.statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Indicateur de sélection
                if (widget.isSelectionMode)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.isSelected ? AppTheme.primaryColor : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isSelected ? AppTheme.primaryColor : AppTheme.textTertiaryColor,
                          width: 2,
                        ),
                      ),
                      child: widget.isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),

                // Badge d'inscription si activée
                if (widget.event.isRegistrationEnabled)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.how_to_reg,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.event.typeLabel,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Date et heure
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDateTime(widget.event.startDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Lieu
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.event.location,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Informations supplémentaires
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nombre d'inscrits si inscriptions activées
                        if (widget.event.isRegistrationEnabled)
                          FutureBuilder<int>(
                            future: EventsFirebaseService.getConfirmedRegistrationsCount(widget.event.id),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: AppTheme.secondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$count inscrit${count > 1 ? 's' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          const SizedBox.shrink(),
                        
                        // Actions rapides
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _handleAction('edit'),
                              icon: const Icon(Icons.edit, size: 18),
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                              color: AppTheme.textSecondaryColor,
                            ),
                            IconButton(
                              onPressed: () => _handleAction('more'),
                              icon: const Icon(Icons.more_horiz, size: 18),
                              iconSize: 18,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit page
        break;
      case 'more':
        _showActionMenu();
        break;
      case 'publish':
        try {
          final updatedEvent = widget.event.copyWith(
            status: 'publie',
            updatedAt: DateTime.now(),
          );
          await EventsFirebaseService.updateEvent(updatedEvent);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Événement publié'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
        break;
      case 'duplicate':
        try {
          final newStartDate = DateTime.now().add(const Duration(days: 7));
          await EventsFirebaseService.duplicateEvent(
            widget.event.id,
            '${widget.event.title} (Copie)',
            newStartDate,
          );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Événement dupliqué'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
        break;
      case 'archive':
        try {
          await EventsFirebaseService.archiveEvent(widget.event.id);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Événement archivé'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
        break;
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.event.isDraft) ...[
              ListTile(
                leading: const Icon(Icons.publish, color: AppTheme.successColor),
                title: const Text('Publier'),
                onTap: () {
                  Navigator.pop(context);
                  _handleAction('publish');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.primaryColor),
              title: const Text('Dupliquer'),
              onTap: () {
                Navigator.pop(context);
                _handleAction('duplicate');
              },
            ),
            if (!widget.event.isArchived) ...[
              ListTile(
                leading: const Icon(Icons.archive, color: AppTheme.warningColor),
                title: const Text('Archiver'),
                onTap: () {
                  Navigator.pop(context);
                  _handleAction('archive');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete confirmation
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateString;
    if (eventDate == today) {
      dateString = 'Aujourd\'hui';
    } else if (eventDate == tomorrow) {
      dateString = 'Demain';
    } else {
      final months = [
        'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
        'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
      ];
      dateString = '${dateTime.day} ${months[dateTime.month - 1]}';
      if (dateTime.year != now.year) {
        dateString += ' ${dateTime.year}';
      }
    }
    
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$dateString à ${hour}h$minute';
  }
}