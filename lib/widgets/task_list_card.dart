import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../../compatibility/app_theme_bridge.dart';

class TaskListCard extends StatefulWidget {
  final TaskListModel taskList;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  const TaskListCard({
    super.key,
    required this.taskList,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  State<TaskListCard> createState() => _TaskListCardState();
}

class _TaskListCardState extends State<TaskListCard>
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

  Color get _listColor {
    if (widget.taskList.color != null) {
      return Color(int.parse(widget.taskList.color!.replaceFirst('#', '0xFF')));
    }
    return Theme.of(context).colorScheme.primaryColor;
  }

  IconData get _visibilityIcon {
    switch (widget.taskList.visibility) {
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock;
      case 'group':
        return Icons.groups;
      case 'role':
        return Icons.admin_panel_settings;
      default:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
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
      onTap: widget.isSelectionMode 
          ? () => widget.onSelectionChanged(!widget.isSelected)
          : widget.onTap,
      onLongPress: widget.onLongPress,
      child: Card(
        elevation: widget.isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: widget.isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _listColor.withOpacity(0.05),
                _listColor.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and selection
                Row(
                  children: [
                    if (widget.isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          widget.isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: widget.isSelected
                              ? Theme.of(context).colorScheme.primaryColor
                              : Colors.grey,
                        ),
                      ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _listColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.taskList.iconName != null
                            ? _getIconFromString(widget.taskList.iconName!)
                            : Icons.list_alt,
                        color: _listColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.taskList.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.textPrimaryColor,
                            ),
                          ),
                          if (widget.taskList.description.isNotEmpty)
                            Text(
                              widget.taskList.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.textSecondaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _visibilityIcon,
                      color: Theme.of(context).colorScheme.textTertiaryColor,
                      size: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Progress bar
                _buildProgressSection(),
                
                const SizedBox(height: 16),
                
                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.task_alt,
                      label: '${widget.taskList.taskCount} tâches',
                      color: Theme.of(context).colorScheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.check_circle,
                      label: '${widget.taskList.completedTaskCount} terminées',
                      color: Theme.of(context).colorScheme.successColor,
                    ),
                    const Spacer(),
                    _buildVisibilityBadge(),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Members section
                if (widget.taskList.memberIds.isNotEmpty)
                  _buildMembersSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = widget.taskList.progressPercentage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _listColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(_listColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_visibilityIcon, size: 14, color: Theme.of(context).colorScheme.textTertiaryColor),
          const SizedBox(width: 4),
          Text(
            widget.taskList.visibilityLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.textTertiaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    final memberCount = widget.taskList.memberIds.length;
    
    return Row(
      children: [
        Icon(Icons.people, size: 16, color: Theme.of(context).colorScheme.textTertiaryColor),
        const SizedBox(width: 6),
        Text(
          '$memberCount membre${memberCount > 1 ? 's' : ''}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.textTertiaryColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        // Member avatars (limited to first 3)
        Row(
          children: List.generate(
            memberCount > 3 ? 3 : memberCount,
            (index) => Container(
              margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: _listColor.withOpacity(0.3),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _listColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (memberCount > 3) ...[
          const SizedBox(width: 4),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+${memberCount - 3}',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'list_alt':
        return Icons.list_alt;
      case 'task_alt':
        return Icons.task_alt;
      case 'checklist':
        return Icons.checklist;
      case 'assignment':
        return Icons.assignment;
      case 'folder':
        return Icons.folder;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'event':
        return Icons.event;
      case 'people':
        return Icons.people;
      case 'church':
        return Icons.church;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'groups':
        return Icons.groups;
      case 'campaign':
        return Icons.campaign;
      default:
        return Icons.list_alt;
    }
  }
}