import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/blog_model.dart';
import '../auth/auth_service.dart';

class BlogFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _postsCollection = 'blog_posts';
  static const String _commentsCollection = 'blog_comments';
  static const String _categoriesCollection = 'blog_categories';
  static const String _likesCollection = 'blog_post_likes';
  static const String _viewsCollection = 'blog_post_views';

  // ==================== ARTICLES ====================

  /// Créer un nouvel article de blog
  static Future<String> createPost(BlogPost post) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final docRef = _firestore.collection(_postsCollection).doc();
      
      final postData = post.copyWith(
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Utilisateur',
        authorPhotoUrl: currentUser.photoURL,
        updatedAt: DateTime.now(),
      );

      await docRef.set(postData.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'article: $e');
    }
  }

  /// Mettre à jour un article de blog
  static Future<void> updatePost(String postId, BlogPost post) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Vérifier les permissions
      final existingPost = await getPost(postId);
      if (existingPost == null) throw Exception('Article non trouvé');
      
      if (existingPost.authorId != currentUser.uid && !await _canManageAllPosts()) {
        throw Exception('Permissions insuffisantes');
      }

      final updatedPost = post.copyWith(
        updatedAt: DateTime.now(),
        publishedAt: post.status == BlogPostStatus.published && existingPost.status != BlogPostStatus.published
            ? DateTime.now()
            : post.publishedAt,
      );

      await _firestore.collection(_postsCollection).doc(postId).update(updatedPost.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'article: $e');
    }
  }

  /// Supprimer un article de blog
  static Future<void> deletePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final post = await getPost(postId);
      if (post == null) throw Exception('Article non trouvé');

      if (post.authorId != currentUser.uid && !await _canManageAllPosts()) {
        throw Exception('Permissions insuffisantes');
      }

      // Supprimer l'article et ses données associées
      final batch = _firestore.batch();
      
      // Supprimer l'article
      batch.delete(_firestore.collection(_postsCollection).doc(postId));
      
      // Supprimer les commentaires
      final comments = await _firestore
          .collection(_commentsCollection)
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var comment in comments.docs) {
        batch.delete(comment.reference);
      }
      
      // Supprimer les likes
      final likes = await _firestore
          .collection(_likesCollection)
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var like in likes.docs) {
        batch.delete(like.reference);
      }
      
      // Supprimer les vues
      final views = await _firestore
          .collection(_viewsCollection)
          .where('postId', isEqualTo: postId)
          .get();
      
      for (var view in views.docs) {
        batch.delete(view.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'article: $e');
    }
  }

  /// Obtenir un article par ID
  static Future<BlogPost?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection(_postsCollection).doc(postId).get();
      if (!doc.exists) return null;
      return BlogPost.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'article: $e');
    }
  }

  /// Stream des articles avec filtres
  static Stream<List<BlogPost>> getPostsStream({
    List<BlogPostStatus>? statuses,
    List<String>? categories,
    List<String>? tags,
    String? authorId,
    String? searchQuery,
    int limit = 20,
    String? orderBy = 'publishedAt',
    bool descending = true,
    bool featuredOnly = false,
  }) {
    try {
      Query query = _firestore.collection(_postsCollection);

      // Filtres
      if (statuses != null && statuses.isNotEmpty) {
        query = query.where('status', whereIn: statuses.map((s) => s.name).toList());
      }

      if (authorId != null && authorId.isNotEmpty) {
        query = query.where('authorId', isEqualTo: authorId);
      }

      if (featuredOnly) {
        query = query.where('isFeatured', isEqualTo: true);
      }

      if (categories != null && categories.isNotEmpty) {
        query = query.where('categories', arrayContainsAny: categories);
      }

      // Tri
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        var posts = snapshot.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();

        // Filtrage par tags (côté client)
        if (tags != null && tags.isNotEmpty) {
          posts = posts.where((post) {
            return post.tags.any((tag) => tags.contains(tag));
          }).toList();
        }

        // Recherche textuelle (côté client)
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          posts = posts.where((post) {
            return post.title.toLowerCase().contains(query) ||
                   post.content.toLowerCase().contains(query) ||
                   post.excerpt.toLowerCase().contains(query) ||
                   post.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();
        }

        return posts;
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des articles: $e');
    }
  }

  /// Obtenir les articles publiés pour le public
  static Stream<List<BlogPost>> getPublishedPostsStream({
    List<String>? categories,
    List<String>? tags,
    String? searchQuery,
    int limit = 20,
    bool featuredOnly = false,
  }) {
    return getPostsStream(
      statuses: [BlogPostStatus.published],
      categories: categories,
      tags: tags,
      searchQuery: searchQuery,
      limit: limit,
      orderBy: 'publishedAt',
      descending: true,
      featuredOnly: featuredOnly,
    );
  }

  /// Publier un article
  static Future<void> publishPost(String postId) async {
    final post = await getPost(postId);
    if (post == null) throw Exception('Article non trouvé');

    await updatePost(postId, post.copyWith(
      status: BlogPostStatus.published,
      publishedAt: DateTime.now(),
    ));
  }

  /// Programmer un article
  static Future<void> schedulePost(String postId, DateTime scheduledDate) async {
    final post = await getPost(postId);
    if (post == null) throw Exception('Article non trouvé');

    await updatePost(postId, post.copyWith(
      status: BlogPostStatus.scheduled,
      scheduledAt: scheduledDate,
    ));
  }

  /// Archiver un article
  static Future<void> archivePost(String postId) async {
    final post = await getPost(postId);
    if (post == null) throw Exception('Article non trouvé');

    await updatePost(postId, post.copyWith(
      status: BlogPostStatus.archived,
    ));
  }

  /// Marquer un article comme featured
  static Future<void> toggleFeaturedPost(String postId) async {
    final post = await getPost(postId);
    if (post == null) throw Exception('Article non trouvé');

    await updatePost(postId, post.copyWith(
      isFeatured: !post.isFeatured,
    ));
  }

  // ==================== COMMENTAIRES ====================

  /// Ajouter un commentaire
  static Future<String> addComment(BlogComment comment) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final docRef = _firestore.collection(_commentsCollection).doc();
      
      final commentData = comment.copyWith(
        // Les commentaires sont automatiquement approuvés pour les utilisateurs authentifiés
        isApproved: true,
      );

      await docRef.set(commentData.toFirestore());

      // Incrémenter le compteur de commentaires de l'article
      await _firestore.collection(_postsCollection).doc(comment.postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du commentaire: $e');
    }
  }

  /// Mettre à jour un commentaire
  static Future<void> updateComment(String commentId, BlogComment comment) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final existingComment = await getComment(commentId);
      if (existingComment == null) throw Exception('Commentaire non trouvé');

      if (existingComment.authorId != currentUser.uid && !await _canManageAllPosts()) {
        throw Exception('Permissions insuffisantes');
      }

      await _firestore.collection(_commentsCollection).doc(commentId)
          .update(comment.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du commentaire: $e');
    }
  }

  /// Supprimer un commentaire
  static Future<void> deleteComment(String commentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final comment = await getComment(commentId);
      if (comment == null) throw Exception('Commentaire non trouvé');

      if (comment.authorId != currentUser.uid && !await _canManageAllPosts()) {
        throw Exception('Permissions insuffisantes');
      }

      await _firestore.collection(_commentsCollection).doc(commentId).delete();

      // Décrémenter le compteur de commentaires de l'article
      await _firestore.collection(_postsCollection).doc(comment.postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression du commentaire: $e');
    }
  }

  /// Obtenir un commentaire par ID
  static Future<BlogComment?> getComment(String commentId) async {
    try {
      final doc = await _firestore.collection(_commentsCollection).doc(commentId).get();
      if (!doc.exists) return null;
      return BlogComment.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du commentaire: $e');
    }
  }

  /// Stream des commentaires d'un article
  static Stream<List<BlogComment>> getCommentsStream(String postId, {bool approvedOnly = true}) {
    try {
      Query query = _firestore.collection(_commentsCollection)
          .where('postId', isEqualTo: postId);

      if (approvedOnly) {
        query = query.where('isApproved', isEqualTo: true);
      }

      return query.orderBy('createdAt', descending: false).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => BlogComment.fromFirestore(doc)).toList();
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commentaires: $e');
    }
  }

  /// Approuver un commentaire
  static Future<void> approveComment(String commentId) async {
    try {
      if (!await _canManageAllPosts()) {
        throw Exception('Permissions insuffisantes');
      }

      await _firestore.collection(_commentsCollection).doc(commentId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'approbation du commentaire: $e');
    }
  }

  /// Rejeter un commentaire
  static Future<void> rejectComment(String commentId) async {
    try {
      if (!await _canManageAllPosts()) {
        throw Exception('Permissions insuffisantes');
      }

      await _firestore.collection(_commentsCollection).doc(commentId).update({
        'isApproved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors du rejet du commentaire: $e');
    }
  }

  // ==================== CATÉGORIES ====================

  /// Créer une catégorie
  static Future<String> createCategory(BlogCategory category) async {
    try {
      final docRef = _firestore.collection(_categoriesCollection).doc();
      await docRef.set(category.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la catégorie: $e');
    }
  }

  /// Mettre à jour une catégorie
  static Future<void> updateCategory(String categoryId, BlogCategory category) async {
    try {
      await _firestore.collection(_categoriesCollection).doc(categoryId)
          .update(category.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la catégorie: $e');
    }
  }

  /// Supprimer une catégorie
  static Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_categoriesCollection).doc(categoryId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la catégorie: $e');
    }
  }

  /// Stream des catégories
  static Stream<List<BlogCategory>> getCategoriesStream() {
    try {
      return _firestore.collection(_categoriesCollection)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => BlogCategory.fromFirestore(doc)).toList();
          });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  /// Mettre à jour le nombre d'articles dans les catégories
  static Future<void> updateCategoryPostCounts() async {
    try {
      final categories = await _firestore.collection(_categoriesCollection).get();
      
      for (var categoryDoc in categories.docs) {
        final category = BlogCategory.fromFirestore(categoryDoc);
        
        final postsCount = await _firestore.collection(_postsCollection)
            .where('categories', arrayContains: category.name)
            .where('status', isEqualTo: BlogPostStatus.published.name)
            .count()
            .get();

        await categoryDoc.reference.update({
          'postCount': postsCount.count,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des compteurs de catégories: $e');
    }
  }

  // ==================== LIKES ====================

  /// Liker un article
  static Future<void> likePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Vérifier si l'utilisateur a déjà liké cet article
      final existingLike = await _firestore.collection(_likesCollection)
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (existingLike.docs.isNotEmpty) {
        // Supprimer le like (contrairement au like)
        await _firestore.collection(_likesCollection).doc(existingLike.docs.first.id).delete();
        
        // Décrémenter le compteur
        await _firestore.collection(_postsCollection).doc(postId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Ajouter le like
        final likeData = BlogPostLike(
          id: '',
          postId: postId,
          userId: currentUser.uid,
          createdAt: DateTime.now(),
        );

        await _firestore.collection(_likesCollection).add(likeData.toFirestore());
        
        // Incrémenter le compteur
        await _firestore.collection(_postsCollection).doc(postId).update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('Erreur lors du like de l\'article: $e');
    }
  }

  /// Vérifier si l'utilisateur a liké un article
  static Future<bool> hasUserLikedPost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final like = await _firestore.collection(_likesCollection)
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      return like.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== VUES ====================

  /// Enregistrer une vue d'article
  static Future<void> recordPostView(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      
      // Vérifier si l'utilisateur a déjà vu cet article récemment (dans les dernières 24h)
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      
      Query query = _firestore.collection(_viewsCollection)
          .where('postId', isEqualTo: postId)
          .where('viewedAt', isGreaterThan: Timestamp.fromDate(cutoffTime));

      if (currentUser != null) {
        query = query.where('userId', isEqualTo: currentUser.uid);
      }

      final recentViews = await query.get();
      
      if (recentViews.docs.isEmpty) {
        // Enregistrer la nouvelle vue
        final viewData = BlogPostView(
          id: '',
          postId: postId,
          userId: currentUser?.uid,
          viewedAt: DateTime.now(),
        );

        await _firestore.collection(_viewsCollection).add(viewData.toFirestore());
        
        // Incrémenter le compteur de vues
        await _firestore.collection(_postsCollection).doc(postId).update({
          'views': FieldValue.increment(1),
        });
      }
    } catch (e) {
      // Silently fail for views - not critical
      print('Erreur lors de l\'enregistrement de la vue: $e');
    }
  }

  // ==================== TAGS ====================

  /// Obtenir tous les tags utilisés
  static Future<List<String>> getAllTags() async {
    try {
      final posts = await _firestore.collection(_postsCollection)
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .get();

      final Set<String> allTags = {};
      
      for (var doc in posts.docs) {
        final post = BlogPost.fromFirestore(doc);
        allTags.addAll(post.tags);
      }

      final sortedTags = allTags.toList()..sort();
      return sortedTags;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des tags: $e');
    }
  }

  /// Obtenir les tags populaires
  static Future<Map<String, int>> getPopularTags({int limit = 20}) async {
    try {
      final posts = await _firestore.collection(_postsCollection)
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .get();

      final Map<String, int> tagCounts = {};
      
      for (var doc in posts.docs) {
        final post = BlogPost.fromFirestore(doc);
        for (var tag in post.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Trier par popularité et limiter
      final sortedEntries = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries.take(limit));
    } catch (e) {
      throw Exception('Erreur lors de la récupération des tags populaires: $e');
    }
  }

  // ==================== RECHERCHE ET STATISTIQUES ====================

  /// Rechercher des articles
  static Future<List<BlogPost>> searchPosts(String query, {int limit = 20}) async {
    try {
      // Pour une recherche complète, on récupère tous les articles publiés
      // et on fait la recherche côté client
      final posts = await _firestore.collection(_postsCollection)
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .orderBy('publishedAt', descending: true)
          .limit(100) // Limiter pour éviter de charger trop de données
          .get();

      final searchQuery = query.toLowerCase();
      final results = <BlogPost>[];

      for (var doc in posts.docs) {
        final post = BlogPost.fromFirestore(doc);
        
        if (post.title.toLowerCase().contains(searchQuery) ||
            post.content.toLowerCase().contains(searchQuery) ||
            post.excerpt.toLowerCase().contains(searchQuery) ||
            post.tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
            post.categories.any((cat) => cat.toLowerCase().contains(searchQuery))) {
          results.add(post);
        }

        if (results.length >= limit) break;
      }

      return results;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir les statistiques du blog
  static Future<Map<String, dynamic>> getBlogStatistics() async {
    try {
      final stats = <String, dynamic>{};

      // Compter les articles par statut
      for (var status in BlogPostStatus.values) {
        final count = await _firestore.collection(_postsCollection)
            .where('status', isEqualTo: status.name)
            .count()
            .get();
        stats['posts_${status.name}'] = count.count;
      }

      // Compter les commentaires
      final commentsCount = await _firestore.collection(_commentsCollection)
          .count()
          .get();
      stats['total_comments'] = commentsCount.count;

      // Compter les catégories
      final categoriesCount = await _firestore.collection(_categoriesCollection)
          .count()
          .get();
      stats['total_categories'] = categoriesCount.count;

      // Articles les plus populaires (par vues)
      final popularPosts = await _firestore.collection(_postsCollection)
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .orderBy('views', descending: true)
          .limit(5)
          .get();
      
      stats['popular_posts'] = popularPosts.docs
          .map((doc) => BlogPost.fromFirestore(doc))
          .toList();

      // Articles récents
      final recentPosts = await _firestore.collection(_postsCollection)
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .orderBy('publishedAt', descending: true)
          .limit(5)
          .get();
      
      stats['recent_posts'] = recentPosts.docs
          .map((doc) => BlogPost.fromFirestore(doc))
          .toList();

      return stats;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // ==================== MÉTHODES PRIVÉES ====================

  /// Vérifier si l'utilisateur peut gérer tous les articles
  static Future<bool> _canManageAllPosts() async {
    try {
      // Ici, on peut vérifier les rôles/permissions
      // Pour l'instant, on considère que tous les utilisateurs authentifiés peuvent gérer
      // Dans une vraie application, on vérifierait les rôles spécifiques
      return _auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Nettoyer les articles programmés qui doivent être publiés
  static Future<void> processScheduledPosts() async {
    try {
      final now = DateTime.now();
      
      final scheduledPosts = await _firestore.collection(_postsCollection)
          .where('status', isEqualTo: BlogPostStatus.scheduled.name)
          .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      
      for (var doc in scheduledPosts.docs) {
        batch.update(doc.reference, {
          'status': BlogPostStatus.published.name,
          'publishedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors du traitement des articles programmés: $e');
    }
  }
}