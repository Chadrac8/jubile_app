import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../models/group_model.dart';
import '../models/person_model.dart';
import '../services/groups_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';


class GroupCard extends StatefulWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final bool isGridView;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
    this.isGridView = false,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard>
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

  Color get _groupColor => Color(int.parse(widget.group.color.replaceFirst('#', '0xFF')));

  String _getFrequencyText() {
    switch (widget.group.frequency.toLowerCase()) {
      case 'weekly':
        return 'Hebdomadaire';
      case 'biweekly':
        return 'Bi-mensuel';
      case 'monthly':
        return 'Mensuel';
      case 'quarterly':
        return 'Trimestriel';
      default:
        return widget.group.frequency;
    }
  }

  Widget _buildGroupImage() {
    // Si le groupe a une image personnalisée, l'utiliser
    if (widget.group.groupImageUrl != null && widget.group.groupImageUrl!.isNotEmpty) {
      return Container(
        width: widget.isGridView ? double.infinity : 80,
        height: widget.isGridView ? 120 : 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.isGridView ? 12 : 8),
          color: _groupColor.withOpacity(0.1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.isGridView ? 12 : 8),
          child: widget.group.groupImageUrl!.startsWith('data:image')
              ? Image.memory(
                  base64Decode(widget.group.groupImageUrl!.split(',').last),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                )
              : CachedNetworkImage(
                  imageUrl: widget.group.groupImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildLoadingImage(),
                  errorWidget: (context, url, error) => _buildFallbackImage(),
                ),
        ),
      );
    }

    // Sinon, générer une image basée sur le type de groupe
    final imageUrl = "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDgzNTgwNTl8&ixlib=rb-4.1.0&q=80&w=1080";

    return Container(
      width: widget.isGridView ? double.infinity : 80,
      height: widget.isGridView ? 120 : 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.isGridView ? 12 : 8),
        color: _groupColor.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.isGridView ? 12 : 8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingImage(),
          errorWidget: (context, url, error) => _buildFallbackImage(),
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      color: _groupColor.withOpacity(0.1),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_groupColor),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    IconData groupIcon;
    switch (widget.group.type.toLowerCase()) {
      case 'prayer':
      case 'prière':
        groupIcon = Icons.favorite;
        break;
      case 'youth':
      case 'jeunesse':
        groupIcon = Icons.sports_soccer;
        break;
      case 'bible study':
      case 'étude biblique':
        groupIcon = Icons.menu_book;
        break;
      case 'worship':
      case 'louange':
        groupIcon = Icons.music_note;
        break;
      case 'leadership':
        groupIcon = Icons.account_tree;
        break;
      default:
        groupIcon = Icons.groups;
    }

    return Container(
      color: _groupColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          groupIcon,
          size: widget.isGridView ? 40 : 32,
          color: _groupColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
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
      ),
    );
  }

  Widget _buildCard() {
    return widget.isGridView ? _buildGridCard() : _buildListCard();
  }

  Widget _buildListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: widget.isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Group Image
            _buildGroupImage(),
            
            const SizedBox(width: 16),
            
            // Group Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.group.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isSelectionMode)
                        Checkbox(
                          value: widget.isSelected,
                          onChanged: (value) => widget.onSelectionChanged(value ?? false),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Type and Frequency
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _groupColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.group.type,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _groupColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getFrequencyText(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Schedule and Location
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.group.scheduleText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.group.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Member count and next meeting
                  FutureBuilder<List<dynamic>>(
                    future: Future.wait([
                      GroupsFirebaseService.getGroupMembersWithPersonData(widget.group.id),
                      GroupsFirebaseService.getNextMeeting(widget.group.id).catchError((e) {
                        print('Erreur next meeting dans group_card: $e');
                        return null;
                      }),
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        // En cas d'erreur, afficher au moins le nombre de membres
                        return FutureBuilder<List<PersonModel>>(
                          future: GroupsFirebaseService.getGroupMembersWithPersonData(widget.group.id),
                          builder: (context, membersSnapshot) {
                            if (!membersSnapshot.hasData) {
                              return Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chargement...',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              );
                            }
                            final members = membersSnapshot.data!;
                            return Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${members.length} membre${members.length > 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      
                      if (!snapshot.hasData) {
                        return Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Chargement...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      final members = snapshot.data![0] as List;
                      final nextMeeting = snapshot.data![1] as GroupMeetingModel?;
                      
                      return Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${members.length} membre${members.length > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (nextMeeting != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.event,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Prochaine: ${_formatDate(nextMeeting.date)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: widget.isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Image and Selection
          Stack(
            children: [
              _buildGroupImage(),
              if (widget.isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          
          // Group Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Name
                  Text(
                    widget.group.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _groupColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.group.type,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _groupColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Schedule
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.group.scheduleText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.group.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Member count
                  FutureBuilder<List<dynamic>>(
                    future: GroupsFirebaseService.getGroupMembersWithPersonData(widget.group.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 16);
                      }
                      
                      final members = snapshot.data! as List;
                      return Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${members.length} membre${members.length > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference <= 7) {
      return 'Dans $difference jours';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}