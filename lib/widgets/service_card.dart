import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_model.dart';
import '../services/services_firebase_service.dart';
// Removed unused import '../../compatibility/app_theme_bridge.dart';


class ServiceCard extends StatefulWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
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
    switch (widget.service.status) {
      case 'publie': return Colors.green;
      case 'brouillon': return Colors.orange;
      case 'archive': return Colors.grey;
      case 'annule': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Removed unused _getServiceTypeKeyword

  Widget _buildServiceImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Container(
        height: 120,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: CachedNetworkImage(
          imageUrl: "https://images.unsplash.com/photo-1618347991384-a4e195e722c5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDgzNTkyNjN8&ixlib=rb-4.1.0&q=80&w=1080",
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingImage(),
          errorWidget: (context, url, error) => _buildFallbackImage(),
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      height: 120,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    IconData iconData;
    switch (widget.service.type) {
      case 'culte': 
        iconData = Icons.church;
        break;
      case 'repetition': 
        iconData = Icons.music_note;
        break;
      case 'evenement_special': 
        iconData = Icons.celebration;
        break;
      case 'reunion': 
        iconData = Icons.groups;
        break;
      default: 
        iconData = Icons.event;
    }
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCC1976D2), // 80% opacity of primary (#1976D2)
            Color(0xCC9C27B0), // 80% opacity of secondary (#9C27B0)
          ],
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildCard(),
          ),
        );
      },
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected 
                ? Theme.of(context).colorScheme.primary
                : Color(0x33000000), // 20% opacity black for outline
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // 10% opacity black
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            Stack(
              children: [
                _buildServiceImage(),
                
                // Selection indicator
                if (widget.isSelectionMode)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Color(0xCCFFFFFF), // 80% opacity white
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        widget.isSelected ? Icons.check : Icons.circle_outlined,
                        size: 20,
                        color: widget.isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),

                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.service.statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Type badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xB3000000), // 70% opacity black
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.service.typeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.service.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (widget.service.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.service.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Color(0xB3000000), // 70% opacity black
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Date and Time
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDateTime(widget.service.dateTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0x99000000), // 60% opacity black
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.service.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Color(0xB3000000), // 70% opacity black
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Duration and Teams
                  Row(
                    children: [
                      // Duration
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.service.durationMinutes}min',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Teams count
                      if (widget.service.teamIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups,
                                size: 12,
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.service.teamIds.length} équipe(s)',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Actions menu
                      if (!widget.isSelectionMode)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                        color: Color(0x99000000), // 60% opacity black
                          ),
                          onSelected: (value) => _handleAction(value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility),
                                  SizedBox(width: 8),
                                  Text('Voir'),
                                ],
                              ),
                            ),
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
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy),
                                  SizedBox(width: 8),
                                  Text('Dupliquer'),
                                ],
                              ),
                            ),
                            if (widget.service.isDraft)
                              const PopupMenuItem(
                                value: 'publish',
                                child: Row(
                                  children: [
                                    Icon(Icons.publish),
                                    SizedBox(width: 8),
                                    Text('Publier'),
                                  ],
                                ),
                              ),
                            if (widget.service.isPublished && !widget.service.isArchived)
                              const PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive),
                                    SizedBox(width: 8),
                                    Text('Archiver'),
                                  ],
                                ),
                              ),
                            if (widget.service.isPublished && !widget.service.isCancelled)
                              const PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel),
                                    SizedBox(width: 8),
                                    Text('Annuler'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action) async {
    try {
      switch (action) {
        case 'view':
          widget.onTap();
          break;
        case 'edit':
          // Navigate to edit page - would be implemented
          break;
        case 'duplicate':
          final newDate = widget.service.dateTime.add(const Duration(days: 7));
          await ServicesFirebaseService.duplicateService(
            widget.service.id,
            '${widget.service.name} (Copie)',
            newDate,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service dupliqué avec succès')),
          );
          break;
        case 'publish':
          await ServicesFirebaseService.updateService(
            widget.service.copyWith(
              status: 'publie',
              updatedAt: DateTime.now(),
            )
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service publié avec succès')),
          );
          break;
        case 'archive':
          await ServicesFirebaseService.archiveService(widget.service.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service archivé avec succès')),
          );
          break;
        case 'cancel':
          await ServicesFirebaseService.updateService(
            widget.service.copyWith(
              status: 'annule',
              updatedAt: DateTime.now(),
            )
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service annulé')),
          );
          break;
        case 'delete':
          await _showDeleteConfirmation();
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Confirmer la suppression'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer ce service ?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible. Toutes les assignations et feuilles de route associées seront également supprimées.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Service à supprimer :',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.service.name} - ${_formatDateTime(widget.service.dateTime)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteService();
    }
  }

  Future<void> _deleteService() async {
    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Suppression du service en cours...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Supprimer le service
      await ServicesFirebaseService.deleteService(widget.service.id);

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Service supprimé avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Erreur lors de la suppression: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    
    final weekdays = [
      'lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'
    ];
    
    final weekday = weekdays[dateTime.weekday - 1];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$weekday $day $month à ${hour}h$minute';
  }
}