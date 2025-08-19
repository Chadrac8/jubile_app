import 'package:flutter/material.dart';
import '../models/blog_model.dart';

class BlogPostCard extends StatelessWidget {
  final BlogPost post;
  final bool isAdminView;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFeatured;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;

  const BlogPostCard({
    super.key,
    required this.post,
    this.isAdminView = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFeatured,
    this.onPublish,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image en vedette
            if (post.featuredImageUrl != null) _buildFeaturedImage(context),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec statut et actions
                  _buildHeader(context),
                  
                  const SizedBox(height: 8),
                  
                  // Titre
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Excerpt
                  if (post.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.excerpt,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Métadonnées
                  _buildMetadata(context),
                  
                  // Catégories et tags
                  if (post.categories.isNotEmpty || post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildCategoriesAndTags(context),
                  ],
                  
                  // Actions admin
                  if (isAdminView) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    _buildAdminActions(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedImage(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              post.featuredImageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        
        // Badge featured
        if (post.isFeatured)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'EN VEDETTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Badge de statut
        _buildStatusBadge(context),
        
        const Spacer(),
        
        // Menu actions
        if (isAdminView && (onEdit != null || onDelete != null))
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Modifier'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onToggleFeatured != null)
                PopupMenuItem(
                  value: 'toggle_featured',
                  child: ListTile(
                    leading: Icon(post.isFeatured ? Icons.star : Icons.star_border),
                    title: Text(post.isFeatured ? 'Retirer vedette' : 'Mettre en vedette'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onPublish != null && post.status == BlogPostStatus.draft)
                const PopupMenuItem(
                  value: 'publish',
                  child: ListTile(
                    leading: Icon(Icons.publish, color: Colors.green),
                    title: Text('Publier', style: TextStyle(color: Colors.green)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onArchive != null && post.status == BlogPostStatus.published)
                const PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    leading: Icon(Icons.archive, color: Colors.orange),
                    title: Text('Archiver', style: TextStyle(color: Colors.orange)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onDelete != null) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (post.status) {
      case BlogPostStatus.published:
        color = Colors.green;
        icon = Icons.public;
        label = 'PUBLIÉ';
        break;
      case BlogPostStatus.draft:
        color = Colors.orange;
        icon = Icons.drafts;
        label = 'BROUILLON';
        break;
      case BlogPostStatus.scheduled:
        color = Colors.blue;
        icon = Icons.schedule;
        label = 'PROGRAMMÉ';
        break;
      case BlogPostStatus.archived:
        color = Colors.grey;
        icon = Icons.archive;
        label = 'ARCHIVÉ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        // Photo auteur
        if (post.authorPhotoUrl != null)
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(post.authorPhotoUrl!),
            onBackgroundImageError: (error, stackTrace) {},
            child: post.authorPhotoUrl == null 
                ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                : null,
          )
        else
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
          ),
        
        const SizedBox(width: 8),
        
        // Informations auteur et date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDate(post.status == BlogPostStatus.published && post.publishedAt != null
                    ? post.publishedAt!
                    : post.updatedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Statistiques
        if (isAdminView || post.status == BlogPostStatus.published) ...[
          const SizedBox(width: 8),
          _buildStats(context),
        ],
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        // Temps de lecture
        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '${post.readingTimeMinutes} min',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Vues
        Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          post.views.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Likes
        Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          post.likes.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        
        if (post.allowComments && post.commentsCount > 0) ...[
          const SizedBox(width: 12),
          
          // Commentaires
          Icon(Icons.comment, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            post.commentsCount.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoriesAndTags(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Catégories
        if (post.categories.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: post.categories.map((category) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
        
        // Tags
        if (post.tags.isNotEmpty) ...[
          if (post.categories.isNotEmpty) const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: post.tags.take(5).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Row(
      children: [
        // Informations de programmation
        if (post.status == BlogPostStatus.scheduled && post.scheduledAt != null) ...[
          Icon(Icons.schedule, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 4),
          Text(
            'Programmé pour le ${_formatDate(post.scheduledAt!)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        
        const Spacer(),
        
        // Actions rapides
        if (onPublish != null && post.status == BlogPostStatus.draft)
          TextButton.icon(
            onPressed: onPublish,
            icon: const Icon(Icons.publish, size: 16),
            label: const Text('Publier'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
      case 'toggle_featured':
        onToggleFeatured?.call();
        break;
      case 'publish':
        onPublish?.call();
        break;
      case 'archive':
        onArchive?.call();
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}