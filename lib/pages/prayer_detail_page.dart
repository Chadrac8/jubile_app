import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
// Share functionality removed (package not available)
import '../models/prayer_model.dart';
import '../services/prayers_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'prayer_form_page.dart';

class PrayerDetailPage extends StatefulWidget {
  final PrayerModel prayer;

  const PrayerDetailPage({super.key, required this.prayer});

  @override
  State<PrayerDetailPage> createState() => _PrayerDetailPageState();
}

class _PrayerDetailPageState extends State<PrayerDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _prayerAnimationController;
  late Animation<double> _prayerAnimation;
  bool _isProcessing = false;
  final TextEditingController _commentController = TextEditingController();

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
    _commentController.dispose();
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
    return DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date);
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      }
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return _formatDate(date);
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasPrayed 
                ? 'Prière retirée' 
                : 'Merci pour votre prière 🙏'),
            backgroundColor: hasPrayed ? Colors.grey : Colors.green,
            duration: const Duration(seconds: 2),
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
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      final comment = PrayerComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: user.uid,
        authorName: user.displayName ?? 'Utilisateur',
        authorPhoto: user.photoURL,
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await PrayersFirebaseService.addComment(widget.prayer.id, comment);
      _commentController.clear();

      if (mounted) {
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

  void _sharePrayer() {
    // Share functionality not available in this environment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage non disponible'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _editPrayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrayerFormPage(prayer: widget.prayer),
      ),
    );
  }

  Future<void> _deletePrayer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette prière ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PrayersFirebaseService.deletePrayer(widget.prayer.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prière supprimée avec succès'),
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final hasPrayed = user != null && widget.prayer.prayedByUsers.contains(user.uid);
    final isAuthor = user != null && widget.prayer.authorId == user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la prière'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePrayer,
            tooltip: 'Partager',
          ),
          if (isAuthor)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editPrayer();
                    break;
                  case 'delete':
                    _deletePrayer();
                    break;
                }
              },
              itemBuilder: (context) => [
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
            ),
        ],
      ),
      body: StreamBuilder<PrayerModel?>(
        stream: Stream.periodic(const Duration(seconds: 5))
            .asyncMap((_) => PrayersFirebaseService.getPrayerById(widget.prayer.id)),
        initialData: widget.prayer,
        builder: (context, snapshot) {
          final prayer = snapshot.data ?? widget.prayer;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header avec type et statut
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor().withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getTypeColor(),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getTypeIcon(),
                                        size: 20,
                                        color: _getTypeColor(),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        prayer.type.label,
                                        style: TextStyle(
                                          color: _getTypeColor(),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (prayer.category.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      prayer.category,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              prayer.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatRelativeDate(prayer.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contenu
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer.content,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            if (prayer.tags.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Mots-clés:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: prayer.tags.map((tag) {
                                  return Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Auteur et statistiques
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Auteur
                                if (!prayer.isAnonymous) ...[
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: prayer.authorPhoto != null
                                        ? CachedNetworkImageProvider(prayer.authorPhoto!)
                                        : null,
                                    child: prayer.authorPhoto == null
                                        ? Text(
                                            prayer.authorName.trim().isNotEmpty 
                                                ? prayer.authorName.trim()[0].toUpperCase() 
                                                : '?',
                                            style: const TextStyle(fontSize: 16),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prayer.authorName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Auteur de cette prière',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(Icons.person_outline, size: 40, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Anonyme',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          'Prière anonyme',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _prayerAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _prayerAnimation.value,
                                          child: Icon(
                                            Icons.favorite,
                                            size: 24,
                                            color: prayer.prayerCount > 0 
                                                ? Theme.of(context).colorScheme.primaryColor 
                                                : Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${prayer.prayerCount}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: prayer.prayerCount > 0 
                                            ? Theme.of(context).colorScheme.primaryColor 
                                            : Colors.grey,
                                      ),
                                    ),
                                    const Text(
                                      'Prières',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Icon(
                                      Icons.comment,
                                      size: 24,
                                      color: prayer.comments.isNotEmpty 
                                          ? Colors.blue 
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${prayer.comments.length}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: prayer.comments.isNotEmpty 
                                            ? Colors.blue 
                                            : Colors.grey,
                                      ),
                                    ),
                                    const Text(
                                      'Commentaires',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Commentaires
                    if (prayer.comments.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commentaires d\'encouragement (${prayer.comments.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...prayer.comments.map((comment) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage: comment.authorPhoto != null
                                            ? CachedNetworkImageProvider(comment.authorPhoto!)
                                            : null,
                                         child: comment.authorPhoto == null
                                             ? Text(
                                                 comment.authorName.trim().isNotEmpty 
                                                     ? comment.authorName.trim()[0].toUpperCase() 
                                                     : '?',
                                                 style: const TextStyle(fontSize: 12),
                                               )
                                             : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  comment.authorName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatRelativeDate(comment.createdAt),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment.content,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 80), // Espace pour les boutons flottants
                  ],
                ),
              ),

              // Barre d'actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Bouton de prière
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _prayerAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _prayerAnimation.value,
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _handlePrayerAction,
                                icon: Icon(
                                  hasPrayed ? Icons.favorite : Icons.favorite_border,
                                  color: hasPrayed ? Colors.white : null,
                                ),
                                label: Text(
                                  hasPrayed ? 'Je ne prie plus' : 'Je prie pour toi',
                                  style: TextStyle(
                                    color: hasPrayed ? Colors.white : null,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasPrayed 
                                      ? Theme.of(context).colorScheme.primaryColor 
                                      : null,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Bouton de commentaire
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ajouter un commentaire d\'encouragement',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: _commentController,
                                        decoration: const InputDecoration(
                                          hintText: 'Votre message d\'encouragement...',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 3,
                                        maxLength: 200,
                                        autofocus: true,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _commentController.clear();
                                            },
                                            child: const Text('Annuler'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _addComment();
                                            },
                                            child: const Text('Publier'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.comment_outlined),
                          label: const Text('Commenter'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}