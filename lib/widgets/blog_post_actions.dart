import 'package:flutter/material.dart';
import '../models/blog_model.dart';

class BlogPostActions extends StatelessWidget {
  final BlogPost post;
  final bool hasLiked;
  final VoidCallback onLike;
  final VoidCallback onShare;

  const BlogPostActions({
    super.key,
    required this.post,
    required this.hasLiked,
    required this.onLike,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Like
          _buildActionButton(
            icon: hasLiked ? Icons.favorite : Icons.favorite_border,
            label: '${post.likes}',
            color: hasLiked ? Colors.red : null,
            onTap: onLike,
          ),
          
          const SizedBox(width: 24),
          
          // Commentaires
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: '${post.commentsCount}',
            onTap: null, // Navigation handled by parent
          ),
          
          const SizedBox(width: 24),
          
          // Vues
          _buildActionButton(
            icon: Icons.visibility_outlined,
            label: '${post.views}',
            onTap: null,
          ),
          
          const Spacer(),
          
          // Partager
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Partager',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}