import 'package:flutter/material.dart';
import '../models/page_model.dart';
import '../../compatibility/app_theme_bridge.dart';

class PageCard extends StatefulWidget {
  final CustomPageModel page;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onCopyUrl;

  const PageCard({
    super.key,
    required this.page,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
    required this.onCopyUrl,
  });

  @override
  State<PageCard> createState() => _PageCardState();
}

class _PageCardState extends State<PageCard>
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
    switch (widget.page.status) {
      case 'published':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (widget.page.status) {
      case 'published':
        return Icons.public;
      case 'draft':
        return Icons.edit;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }

  IconData get _visibilityIcon {
    switch (widget.page.visibility) {
      case 'public':
        return Icons.public;
      case 'members':
        return Icons.people;
      case 'groups':
        return Icons.groups;
      case 'roles':
        return Icons.admin_panel_settings;
      default:
        return Icons.visibility;
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: widget.isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête avec image de couverture
            if (widget.page.coverImageUrl != null)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(widget.page.coverImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: _buildHeader(),
                ),
              )
            else
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                      Theme.of(context).colorScheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: _buildHeader(),
              ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.page.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.textPrimaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.page.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.page.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.textSecondaryColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.isSelectionMode)
                        Checkbox(
                          value: widget.isSelected,
                          onChanged: (value) => widget.onSelectionChanged(value ?? false),
                          activeColor: Theme.of(context).colorScheme.primaryColor,
                        )
                      else
                        PopupMenuButton<String>(
                          onSelected: _handleAction,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Modifier'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'preview',
                              child: ListTile(
                                leading: Icon(Icons.visibility),
                                title: Text('Aperçu'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: ListTile(
                                leading: Icon(Icons.copy),
                                title: Text('Dupliquer'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy_url',
                              child: ListTile(
                                leading: Icon(Icons.link),
                                title: Text('Copier l\'URL'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (widget.page.status == 'draft')
                              const PopupMenuItem(
                                value: 'publish',
                                child: ListTile(
                                  leading: Icon(Icons.publish, color: Colors.green),
                                  title: Text('Publier'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            if (widget.page.status == 'published')
                              const PopupMenuItem(
                                value: 'archive',
                                child: ListTile(
                                  leading: Icon(Icons.archive, color: Colors.orange),
                                  title: Text('Archiver'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Supprimer'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // URL et statistiques
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '/${widget.page.slug}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.page.components.length} composant${widget.page.components.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Badges et informations
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: _statusIcon,
                        label: widget.page.statusLabel,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: _visibilityIcon,
                        label: widget.page.visibilityLabel,
                        color: Theme.of(context).colorScheme.primaryColor,
                      ),
                      const Spacer(),
                      if (widget.page.publishDate != null)
                        _buildDateChip(
                          icon: Icons.schedule,
                          label: _formatDate(widget.page.publishDate!),
                          color: Colors.blue,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.page.iconName != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.web, // Vous pouvez mapper iconName vers une vraie icône
                color: Theme.of(context).colorScheme.primaryColor,
                size: 20,
              ),
            ),
          const Spacer(),
          if (widget.page.displayOrder > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${widget.page.displayOrder}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.textPrimaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'copy_url':
        widget.onCopyUrl();
        break;
      // Les autres actions seraient gérées par le parent
      default:
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Demain';
    } else if (difference.inDays == -1) {
      return 'Hier';
    } else if (difference.inDays > 1 && difference.inDays <= 7) {
      return 'Dans ${difference.inDays} jours';
    } else if (difference.inDays < -1 && difference.inDays >= -7) {
      return 'Il y a ${-difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}