import 'package:flutter/material.dart';
import '../models/blog_model.dart';
import '../widgets/blog_post_metadata.dart';

class BlogPostPreviewDialog extends StatelessWidget {
  final BlogPost post;

  const BlogPostPreviewDialog({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.preview,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aperçu de l\'article',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Contenu de l'aperçu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image en vedette
                    if (post.featuredImageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Titre
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Métadonnées
                    BlogPostMetadata(post: post),
                    
                    const SizedBox(height: 16),
                    
                    // Excerpt
                    if (post.excerpt.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          post.excerpt,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Contenu
                    Text(
                      post.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Images additionnelles
                    if (post.imageUrls.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Images additionnelles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: post.imageUrls.length,
                        itemBuilder: (context, index) {
                          final imageUrl = post.imageUrls[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Catégories et tags
                    if (post.categories.isNotEmpty || post.tags.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Catégories
                      if (post.categories.isNotEmpty) ...[
                        Text(
                          'Catégories',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: post.categories.map((category) => Chip(
                            label: Text(category),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Tags
                      if (post.tags.isNotEmpty) ...[
                        Text(
                          'Tags',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: post.tags.map((tag) => Chip(
                            label: Text('#$tag'),
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(color: Colors.grey[700]),
                          )).toList(),
                        ),
                      ],
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Informations de statut
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(),
                                color: _getStatusColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Statut: ${post.status.displayName}',
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          if (post.status == BlogPostStatus.scheduled && post.scheduledAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Programmé pour le ${_formatDate(post.scheduledAt!)}',
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              if (post.allowComments)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Commentaires autorisés',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              
                              if (post.isFeatured) ...[
                                if (post.allowComments) const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, size: 12, color: Colors.amber),
                                      SizedBox(width: 4),
                                      Text(
                                        'En vedette',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Color _getStatusColor() {
    switch (post.status) {
      case BlogPostStatus.published:
        return Colors.green;
      case BlogPostStatus.draft:
        return Colors.orange;
      case BlogPostStatus.scheduled:
        return Colors.blue;
      case BlogPostStatus.archived:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (post.status) {
      case BlogPostStatus.published:
        return Icons.public;
      case BlogPostStatus.draft:
        return Icons.drafts;
      case BlogPostStatus.scheduled:
        return Icons.schedule;
      case BlogPostStatus.archived:
        return Icons.archive;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}