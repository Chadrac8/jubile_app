import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/prayer_model.dart';
import '../theme.dart';
import '../auth/auth_service.dart';
import '../services/prayers_firebase_service.dart';

class PrayerCard extends StatefulWidget {
  final PrayerModel prayer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isAdminView;

  const PrayerCard({
    Key? key,
    required this.prayer,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isAdminView = false,
  }) : super(key: key);

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> with TickerProviderStateMixin {
  late AnimationController _prayerAnimationController;
  late Animation<double> _prayerAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _prayerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _prayerAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _prayerAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _prayerAnimationController.dispose();
    super.dispose();
  }

  Color _getTypeColor() {
    switch (widget.prayer.type) {
      case PrayerType.request:
        return Colors.orange;
      case PrayerType.testimony:
        return Colors.green;
      case PrayerType.intercession:
        return Colors.blue;
      case PrayerType.thanksgiving:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.prayer.type) {
      case PrayerType.request:
        return Icons.pan_tool;
      case PrayerType.testimony:
        return Icons.star;
      case PrayerType.intercession:
        return Icons.favorite;
      case PrayerType.thanksgiving:
        return Icons.celebration;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  Future<void> _handlePrayerAction() async {
    if (_isProcessing) return;

    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final hasPrayed = widget.prayer.prayedByUsers.contains(user.uid);
      
      if (hasPrayed) {
        await PrayersFirebaseService.removePrayerCount(widget.prayer.id, user.uid);
      } else {
        await PrayersFirebaseService.addPrayerCount(widget.prayer.id, user.uid);
        _prayerAnimationController.forward().then((_) {
          _prayerAnimationController.reverse();
        });
      }

      // Feedback haptique
      // HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showCommentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commentaires (${widget.prayer.comments.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: widget.prayer.comments.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun commentaire pour le moment.\nSoyez le premier à encourager !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.prayer.comments.length,
                  itemBuilder: (context, index) {
                    final comment = widget.prayer.comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.authorPhoto != null
                            ? CachedNetworkImageProvider(comment.authorPhoto!)
                            : null,
                        child: comment.authorPhoto == null
                             ? Text(comment.authorName.trim().isNotEmpty 
                                 ? comment.authorName.trim()[0].toUpperCase() 
                                 : '?')
                             : null,
                      ),
                      title: Text(comment.authorName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.content),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(comment.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddCommentDialog();
            },
            child: const Text('Ajouter un commentaire'),
          ),
        ],
      ),
    );
  }

  void _showAddCommentDialog() {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un commentaire d\'encouragement'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Votre message d\'encouragement...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (commentController.text.trim().isNotEmpty) {
                final user = AuthService.currentUser;
                if (user != null) {
                  final comment = PrayerComment(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    authorId: user.uid,
                    authorName: user.displayName ?? 'Anonyme',
                    authorPhoto: user.photoURL,
                    content: commentController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  
                  try {
                    await PrayersFirebaseService.addComment(widget.prayer.id, comment);
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Commentaire ajouté avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final hasPrayed = user != null && widget.prayer.prayedByUsers.contains(user.uid);
    final isAuthor = user != null && widget.prayer.authorId == user.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec type et status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getTypeColor(), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getTypeIcon(), size: 16, color: _getTypeColor()),
                        const SizedBox(width: 4),
                        Text(
                          widget.prayer.type.label,
                          style: TextStyle(
                            color: _getTypeColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.prayer.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.prayer.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!widget.prayer.isApproved && widget.isAdminView)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'En attente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    _formatDate(widget.prayer.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Titre
              Text(
                widget.prayer.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Contenu
              Text(
                widget.prayer.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Auteur et actions
              Row(
                children: [
                  // Auteur
                  if (!widget.prayer.isAnonymous) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: widget.prayer.authorPhoto != null
                          ? CachedNetworkImageProvider(widget.prayer.authorPhoto!)
                          : null,
                      child: widget.prayer.authorPhoto == null
                          ? Text(
                              widget.prayer.authorName.trim().isNotEmpty 
                                  ? widget.prayer.authorName.trim()[0].toUpperCase() 
                                  : '?',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.prayer.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text(
                      'Anonyme',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const Spacer(),

                  // Actions
                  if (widget.showActions) ...[
                    // Commentaires
                    IconButton(
                      onPressed: _showCommentsDialog,
                      icon: const Icon(Icons.comment_outlined, size: 20),
                      tooltip: 'Commentaires',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    if (widget.prayer.comments.isNotEmpty)
                      Text(
                        '${widget.prayer.comments.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    const SizedBox(width: 8),

                    // Prière
                    AnimatedBuilder(
                      animation: _prayerAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _prayerAnimation.value,
                          child: IconButton(
                            onPressed: _isProcessing ? null : _handlePrayerAction,
                            icon: Icon(
                              hasPrayed ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: hasPrayed ? AppTheme.primaryColor : Colors.grey,
                            ),
                            tooltip: hasPrayed ? 'Je ne prie plus' : 'Je prie pour toi',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        );
                      },
                    ),
                    if (widget.prayer.prayerCount > 0)
                      Text(
                        '${widget.prayer.prayerCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasPrayed ? AppTheme.primaryColor : Colors.grey,
                          fontWeight: hasPrayed ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                  ],

                  // Actions admin/auteur
                  if (widget.isAdminView || isAuthor) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            widget.onEdit?.call();
                            break;
                          case 'delete':
                            widget.onDelete?.call();
                            break;
                          case 'approve':
                            PrayersFirebaseService.approvePrayer(widget.prayer.id);
                            break;
                          case 'reject':
                            PrayersFirebaseService.rejectPrayer(widget.prayer.id);
                            break;
                          case 'archive':
                            PrayersFirebaseService.archivePrayer(widget.prayer.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (isAuthor) ...[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer'),
                              ],
                            ),
                          ),
                        ],
                        if (widget.isAdminView) ...[
                          if (!widget.prayer.isApproved)
                            const PopupMenuItem(
                              value: 'approve',
                              child: Row(
                                children: [
                                  Icon(Icons.check, size: 16, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Approuver'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'reject',
                            child: Row(
                              children: [
                                Icon(Icons.close, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Rejeter'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(Icons.archive, size: 16),
                                SizedBox(width: 8),
                                Text('Archiver'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}