import 'package:flutter/material.dart';
import '../models/blog_model.dart';
import '../services/blog_firebase_service.dart';

class BlogRelatedPosts extends StatelessWidget {
  final BlogPost currentPost;
  final Function(BlogPost) onPostTap;

  const BlogRelatedPosts({
    super.key,
    required this.currentPost,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BlogPost>>(
      future: _getRelatedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final relatedPosts = snapshot.data!;
        
        if (relatedPosts.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relatedPosts.length,
            itemBuilder: (context, index) {
              final post = relatedPosts[index];
              return _buildRelatedPostCard(context, post);
            },
          ),
        );
      },
    );
  }

  Widget _buildRelatedPostCard(BuildContext context, BlogPost post) {
    return GestureDetector(
      onTap: () => onPostTap(post),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (post.featuredImageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post.featuredImageUrl!,
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
                )
              else
                Container(
                  height: 100,
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.article,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                ),
              
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Métadonnées
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.readingTimeMinutes} min',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.likes.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<BlogPost>> _getRelatedPosts() async {
    try {
      // Stratégie pour trouver des articles similaires :
      // 1. Articles de la même catégorie
      // 2. Articles avec des tags similaires
      // 3. Articles du même auteur

      final List<BlogPost> candidates = [];

      // Articles de la même catégorie
      if (currentPost.categories.isNotEmpty) {
        final categoryPosts = await BlogFirebaseService.getPublishedPostsStream(
          categories: currentPost.categories,
          limit: 10,
        ).first;

        candidates.addAll(categoryPosts.where((post) => post.id != currentPost.id));
      }

      // Articles avec tags similaires
      if (currentPost.tags.isNotEmpty) {
        final tagPosts = await BlogFirebaseService.getPublishedPostsStream(
          tags: currentPost.tags,
          limit: 10,
        ).first;

        for (final post in tagPosts) {
          if (post.id != currentPost.id && 
              !candidates.any((c) => c.id == post.id)) {
            candidates.add(post);
          }
        }
      }

      // Articles du même auteur
      final authorPosts = await BlogFirebaseService.getPostsStream(
        statuses: [BlogPostStatus.published],
        authorId: currentPost.authorId,
        limit: 5,
      ).first;

      for (final post in authorPosts) {
        if (post.id != currentPost.id && 
            !candidates.any((c) => c.id == post.id)) {
          candidates.add(post);
        }
      }

      // Trier par pertinence et prendre les meilleurs
      candidates.sort((a, b) {
        int scoreA = _calculateRelevanceScore(a);
        int scoreB = _calculateRelevanceScore(b);
        return scoreB.compareTo(scoreA);
      });

      return candidates.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  int _calculateRelevanceScore(BlogPost post) {
    int score = 0;

    // Points pour catégories communes
    for (final category in post.categories) {
      if (currentPost.categories.contains(category)) {
        score += 3;
      }
    }

    // Points pour tags communs
    for (final tag in post.tags) {
      if (currentPost.tags.contains(tag)) {
        score += 2;
      }
    }

    // Points pour même auteur
    if (post.authorId == currentPost.authorId) {
      score += 1;
    }

    // Points pour popularité
    score += (post.likes / 10).round();
    score += (post.views / 100).round();

    return score;
  }
}