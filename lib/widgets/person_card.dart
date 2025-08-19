import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/firebase_service.dart';
import '../services/roles_firebase_service.dart';
import '../theme.dart';


class PersonCard extends StatefulWidget {
  final PersonModel person;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final bool isGridView;

  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
    this.isGridView = false,
  });

  @override
  State<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<PersonCard>
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

  String _getStatusBadgeText() {
    if (!widget.person.isActive) return 'Inactif';
    if (widget.person.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
      return 'Nouveau';
    }
    return '';
  }

  Color _getStatusBadgeColor() {
    if (!widget.person.isActive) return Theme.of(context).colorScheme.error;
    if (widget.person.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Colors.transparent;
  }

  Widget _buildRoleBadges() {
    if (widget.person.roles.isEmpty) return const SizedBox.shrink();
    
    return StreamBuilder<List<RoleModel>>(
      stream: RolesFirebaseService.getRolesStream(activeOnly: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final allRoles = snapshot.data!;
        final personRoles = allRoles.where((role) => role != null && widget.person.roles.contains(role!.id)).take(2).toList();
        
        if (personRoles.isEmpty) return const SizedBox.shrink();
        
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: personRoles.map((role) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                  width: 1,
                ),
              ),
              child: Text(
                role.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    final imageUrl = "https://images.unsplash.com/photo-1615506236937-446d39d6cbce?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDgzNTY1MTF8&ixlib=rb-4.1.0&q=80&w=1080";

    return Container(
      width: widget.isGridView ? 60 : 50,
      height: widget.isGridView ? 60 : 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: widget.isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: widget.person.profileImageUrl != null
            ? (widget.person.profileImageUrl!.startsWith('data:image')
                ? Image.memory(
                    Uri.parse(widget.person.profileImageUrl!).data!.contentAsBytes(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
                  )
                : CachedNetworkImage(
                    imageUrl: widget.person.profileImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildLoadingAvatar(),
                    errorWidget: (context, url, error) => _buildFallbackAvatar(),
                  ))
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingAvatar(),
                errorWidget: (context, url, error) => _buildFallbackAvatar(),
              ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          widget.person.displayInitials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
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
    if (widget.isGridView) {
      return _buildGridCard();
    } else {
      return _buildListCard();
    }
  }

  Widget _buildListCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection Checkbox
                if (widget.isSelectionMode) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) => widget.onSelectionChanged(value ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Profile Image
                _buildProfileImage(),
                const SizedBox(width: 16),
                
                // Person Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.person.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status Badge
                          if (_getStatusBadgeText().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusBadgeColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusBadgeText(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Email and Phone
                      if (widget.person.email.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.person.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                      
                      if (widget.person.phone != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.person.phone!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                      
                      // Age and Gender
                      if (widget.person.age != null || widget.person.gender != null) ...[
                        Row(
                          children: [
                            if (widget.person.age != null) ...[
                              Icon(
                                Icons.cake,
                                size: 14,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.person.age} ans',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                            if (widget.person.age != null && widget.person.gender != null)
                              const Text(' • '),
                            if (widget.person.gender != null)
                              Text(
                                widget.person.gender!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Role Badges
                      _buildRoleBadges(),
                    ],
                  ),
                ),
                
                // Arrow Icon
                if (!widget.isSelectionMode)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard() {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Selection Checkbox
              if (widget.isSelectionMode) ...[
                Align(
                  alignment: Alignment.topRight,
                  child: Checkbox(
                    value: widget.isSelected,
                    onChanged: (value) => widget.onSelectionChanged(value ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
              ],
              
              // Profile Image
              _buildProfileImage(),
              const SizedBox(height: 12),
              
              // Name
              Text(
                widget.person.fullName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              
              // Email
              if (widget.person.email.isNotEmpty) ...[
                Text(
                  widget.person.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              
              // Age
              if (widget.person.age != null) ...[
                Text(
                  '${widget.person.age} ans',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Status Badge
              if (_getStatusBadgeText().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusBadgeText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Role Badges
              _buildRoleBadges(),
            ],
          ),
        ),
      ),
    );
  }
}