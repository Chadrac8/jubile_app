import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../../compatibility/app_theme_bridge.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final bool showActions;
  final ValueChanged<String>? onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
    this.showActions = false,
    this.onStatusChanged,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
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

  Color get _priorityColor {
    switch (widget.task.priority) {
      case 'high':
        return Theme.of(context).colorScheme.errorColor;
      case 'medium':
        return Theme.of(context).colorScheme.warningColor;
      case 'low':
        return Theme.of(context).colorScheme.successColor;
      default:
        return Theme.of(context).colorScheme.warningColor;
    }
  }

  Color get _statusColor {
    switch (widget.task.status) {
      case 'completed':
        return Theme.of(context).colorScheme.successColor;
      case 'in_progress':
        return Theme.of(context).colorScheme.warningColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primaryColor;
    }
  }

  IconData get _statusIcon {
    switch (widget.task.status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
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
          borderRadius: BorderRadius.circular(12),
          side: widget.isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          children: [
            // Priority indicator bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and status
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
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.task.isCompleted
                                ? Colors.grey[600]
                                : null,
                          ),
                        ),
                      ),
                      if (widget.showActions && widget.onStatusChanged != null)
                        _buildStatusButton(),
                      if (!widget.showActions)
                        _buildStatusBadge(),
                    ],
                  ),
                  
                  // Description
                  if (widget.task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.task.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Meta information row
                  Row(
                    children: [
                      // Priority badge
                      _buildPriorityBadge(),
                      
                      const SizedBox(width: 8),
                      
                      // Due date
                      if (widget.task.dueDate != null) ...[
                        _buildDueDateBadge(),
                        const SizedBox(width: 8),
                      ],
                      
                      const Spacer(),
                      
                      // Assignees count
                      if (widget.task.assigneeIds.isNotEmpty)
                        _buildAssigneesBadge(),
                      
                      // Attachments count
                      if (widget.task.attachmentUrls.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildAttachmentsBadge(),
                      ],
                    ],
                  ),
                  
                  // Tags
                  if (widget.task.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTagsSection(),
                  ],
                  
                  // Overdue/Due soon warning
                  if (widget.task.isOverdue || widget.task.isDueSoon) ...[
                    const SizedBox(height: 12),
                    _buildWarningBanner(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton() {
    return PopupMenuButton<String>(
      icon: Icon(_statusIcon, color: _statusColor),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'todo',
          child: Row(
            children: [
              Icon(Icons.radio_button_unchecked, color: Theme.of(context).colorScheme.primaryColor),
              const SizedBox(width: 8),
              const Text('À faire'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'in_progress',
          child: Row(
            children: [
              Icon(Icons.play_circle, color: Theme.of(context).colorScheme.warningColor),
              const SizedBox(width: 8),
              const Text('En cours'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'completed',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.successColor),
              const SizedBox(width: 8),
              const Text('Terminé'),
            ],
          ),
        ),
      ],
      onSelected: (status) {
        widget.onStatusChanged?.call(status);
      },
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon, size: 16, color: _statusColor),
          const SizedBox(width: 4),
          Text(
            widget.task.statusLabel,
            style: TextStyle(
              color: _statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.task.priorityLabel,
        style: TextStyle(
          color: _priorityColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDueDateBadge() {
    final isOverdue = widget.task.isOverdue;
    final isDueSoon = widget.task.isDueSoon;
    
    Color badgeColor = Colors.grey;
    IconData badgeIcon = Icons.schedule;
    
    if (isOverdue) {
      badgeColor = Theme.of(context).colorScheme.errorColor;
      badgeIcon = Icons.warning;
    } else if (isDueSoon) {
      badgeColor = Theme.of(context).colorScheme.warningColor;
      badgeIcon = Icons.schedule;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            _formatDueDate(),
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneesBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.secondaryColor),
          const SizedBox(width: 4),
          Text(
            '${widget.task.assigneeIds.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, size: 14, color: Theme.of(context).colorScheme.tertiaryColor),
          const SizedBox(width: 4),
          Text(
            '${widget.task.attachmentUrls.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.task.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWarningBanner() {
    final isOverdue = widget.task.isOverdue;
    final message = isOverdue ? 'En retard' : 'Échéance proche';
    final color = isOverdue ? Theme.of(context).colorScheme.errorColor : Theme.of(context).colorScheme.warningColor;
    final icon = isOverdue ? Icons.warning : Icons.schedule;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            message,
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

  String _formatDueDate() {
    if (widget.task.dueDate == null) return '';
    
    final now = DateTime.now();
    final dueDate = widget.task.dueDate!;
    final difference = dueDate.difference(now);
    
    if (difference.isNegative) {
      final absDifference = difference.abs();
      if (absDifference.inDays > 0) {
        return '-${absDifference.inDays}j';
      } else if (absDifference.inHours > 0) {
        return '-${absDifference.inHours}h';
      } else {
        return 'En retard';
      }
    } else {
      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else {
        return 'Maintenant';
      }
    }
  }
}