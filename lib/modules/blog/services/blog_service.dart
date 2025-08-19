import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/services/base_firebase_service.dart';
import '../models/blog_post.dart';
import '../models/blog_comment.dart';
import '../models/blog_category.dart';

/// Service principal pour la gestion du blog
class BlogService extends BaseFirebaseService<BlogPost> {
  @override
  String get collectionName => 'blog_posts';

  @override
  BlogPost fromFirestore(DocumentSnapshot doc) {
    return BlogPost.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Map<String, dynamic> toFirestore(BlogPost model) {
    return model.toMap();
  }

  // Collections pour les sous-modèles
  CollectionReference get _commentsCollection => FirebaseFirestore.instance.collection('blog_comments');
  CollectionReference get _categoriesCollection => FirebaseFirestore.instance.collection('blog_categories');

  /// ========== MÉTHODES POUR LES ARTICLES ==========

  /// Obtenir tous les articles publiés (vue publique)
  Future<List<BlogPost>> getPublishedPosts({
    int? limit,
    String? category,
    List<String>? tags,
  }) async {
    try {
      Query query = collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .orderBy('publishedAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('categories', arrayContains: category);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des articles publiés: \$e');
      return [];
    }
  }

  /// Obtenir les articles en vedette
  Future<List<BlogPost>> getFeaturedPosts({int limit = 5}) async {
    try {
      final snapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .where('isFeatured', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des articles en vedette: \$e');
      return [];
    }
  }

  /// Obtenir les articles récents
  Future<List<BlogPost>> getRecentPosts({int limit = 10}) async {
    try {
      final snapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des articles récents: \$e');
      return [];
    }
  }

  /// Obtenir les articles par auteur
  Future<List<BlogPost>> getPostsByAuthor(String authorId) async {
    try {
      final snapshot = await collection
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des articles par auteur: \$e');
      return [];
    }
  }

  /// Rechercher des articles
  Future<List<BlogPost>> searchPosts(String searchQuery) async {
    try {
      // Recherche par titre et contenu (limité avec Firestore)
      final titleResults = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .orderBy('title')
          .startAt([searchQuery])
          .endAt([searchQuery + '\uf8ff'])
          .get();

      final posts = titleResults.docs.map((doc) => fromFirestore(doc)).toList();

      // Recherche également dans les tags
      final tagResults = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .where('tags', arrayContains: searchQuery.toLowerCase())
          .get();

      final tagPosts = tagResults.docs.map((doc) => fromFirestore(doc)).toList();

      // Combiner et dédupliquer les résultats
      final allPosts = <String, BlogPost>{};
      for (final post in posts) {
        if (post.id != null) allPosts[post.id!] = post;
      }
      for (final post in tagPosts) {
        if (post.id != null) allPosts[post.id!] = post;
      }

      return allPosts.values.toList();
    } catch (e) {
      print('Erreur lors de la recherche d\'articles: \$e');
      return [];
    }
  }

  /// Publier un article (changer le statut vers publié)
  Future<bool> publishPost(String postId) async {
    try {
      await collection.doc(postId).update({
        'status': BlogPostStatus.published.name,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la publication de l\'article: \$e');
      return false;
    }
  }

  /// Archiver un article
  Future<bool> archivePost(String postId) async {
    try {
      await collection.doc(postId).update({
        'status': BlogPostStatus.archived.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de l\'archivage de l\'article: \$e');
      return false;
    }
  }

  /// Programmer la publication d'un article
  Future<bool> schedulePost(String postId, DateTime scheduledDate) async {
    try {
      await collection.doc(postId).update({
        'status': BlogPostStatus.scheduled.name,
        'scheduledAt': Timestamp.fromDate(scheduledDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la programmation de l\'article: \$e');
      return false;
    }
  }

  /// Incrémenter le nombre de vues
  Future<void> incrementViews(String postId) async {
    try {
      await collection.doc(postId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erreur lors de l\'incrémentation des vues: \$e');
    }
  }

  /// Liker/Unliker un article
  Future<bool> toggleLike(String postId) async {
    try {
      // Dans un vrai système, on gérerait les likes individuels par utilisateur
      await collection.doc(postId).update({
        'likes': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('Erreur lors du like de l\'article: \$e');
      return false;
    }
  }

  /// ========== MÉTHODES POUR LES COMMENTAIRES ==========

  /// Obtenir les commentaires d'un article
  Future<List<BlogComment>> getComments(String postId) async {
    try {
      final snapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .where('status', isEqualTo: CommentStatus.approved.name)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => BlogComment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des commentaires: \$e');
      return [];
    }
  }

  /// Ajouter un commentaire
  Future<String?> addComment(BlogComment comment) async {
    try {
      final docRef = await _commentsCollection.add(comment.toMap());
      
      // Incrémenter le compteur de commentaires de l'article
      await collection.doc(comment.postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      print('Erreur lors de l\'ajout du commentaire: \$e');
      return null;
    }
  }

  /// Approuver un commentaire
  Future<bool> approveComment(String commentId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'status': CommentStatus.approved.name,
        'isModerated': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de l\'approbation du commentaire: \$e');
      return false;
    }
  }

  /// Rejeter un commentaire
  Future<bool> rejectComment(String commentId) async {
    try {
      await _commentsCollection.doc(commentId).update({
        'status': CommentStatus.rejected.name,
        'isModerated': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors du rejet du commentaire: \$e');
      return false;
    }
  }

  /// Obtenir les commentaires en attente de modération
  Future<List<BlogComment>> getPendingComments() async {
    try {
      final snapshot = await _commentsCollection
          .where('status', isEqualTo: CommentStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BlogComment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des commentaires en attente: \$e');
      return [];
    }
  }

  /// ========== MÉTHODES POUR LES CATÉGORIES ==========

  /// Obtenir toutes les catégories actives
  Future<List<BlogCategory>> getActiveCategories() async {
    try {
      final snapshot = await _categoriesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => BlogCategory.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des catégories: \$e');
      return [];
    }
  }

  /// Ajouter une catégorie
  Future<String?> addCategory(BlogCategory category) async {
    try {
      final docRef = await _categoriesCollection.add(category.toMap());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de l\'ajout de la catégorie: \$e');
      return null;
    }
  }

  /// Mettre à jour le nombre d'articles d'une catégorie
  Future<void> updateCategoryPostCount(String categoryName) async {
    try {
      final count = await getPostCountByCategory(categoryName);
      
      final categoryQuery = await _categoriesCollection
          .where('name', isEqualTo: categoryName)
          .get();

      if (categoryQuery.docs.isNotEmpty) {
        await _categoriesCollection.doc(categoryQuery.docs.first.id).update({
          'postCount': count,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du compteur de catégorie: \$e');
    }
  }

  /// Obtenir le nombre d'articles par catégorie
  Future<int> getPostCountByCategory(String categoryName) async {
    try {
      final snapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .where('categories', arrayContains: categoryName)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des articles par catégorie: \$e');
      return 0;
    }
  }

  /// ========== MÉTHODES STATISTIQUES ==========

  /// Obtenir les statistiques du blog
  Future<Map<String, dynamic>> getBlogStatistics() async {
    try {
      // Total des articles
      final totalSnapshot = await collection.get();
      final total = totalSnapshot.docs.length;

      // Articles publiés
      final publishedSnapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .get();
      final published = publishedSnapshot.docs.length;

      // Brouillons
      final draftSnapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.draft.name)
          .get();
      final drafts = draftSnapshot.docs.length;

      // Articles programmés
      final scheduledSnapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.scheduled.name)
          .get();
      final scheduled = scheduledSnapshot.docs.length;

      // Commentaires total
      final commentsSnapshot = await _commentsCollection.get();
      final totalComments = commentsSnapshot.docs.length;

      // Commentaires en attente
      final pendingCommentsSnapshot = await _commentsCollection
          .where('status', isEqualTo: CommentStatus.pending.name)
          .get();
      final pendingComments = pendingCommentsSnapshot.docs.length;

      // Articles de cette semaine
      final weekStart = DateTime.now().subtract(const Duration(days: 7));
      final thisWeekSnapshot = await collection
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekStart))
          .get();
      final thisWeek = thisWeekSnapshot.docs.length;

      return {
        'total': total,
        'published': published,
        'drafts': drafts,
        'scheduled': scheduled,
        'totalComments': totalComments,
        'pendingComments': pendingComments,
        'thisWeek': thisWeek,
        'categories': (await getActiveCategories()).length,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: \$e');
      return {
        'total': 0,
        'published': 0,
        'drafts': 0,
        'scheduled': 0,
        'totalComments': 0,
        'pendingComments': 0,
        'thisWeek': 0,
        'categories': 0,
      };
    }
  }

  /// Obtenir les articles les plus populaires
  Future<List<BlogPost>> getPopularPosts({int limit = 5}) async {
    try {
      final snapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .orderBy('views', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des articles populaires: \$e');
      return [];
    }
  }

  /// Obtenir les statistiques des vues par mois
  Future<Map<String, int>> getViewsByMonth() async {
    try {
      final snapshot = await collection
          .where('status', isEqualTo: BlogPostStatus.published.name)
          .get();

      final viewsByMonth = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final post = fromFirestore(doc);
        if (post.publishedAt != null) {
          final monthKey = '${post.publishedAt!.year}-${post.publishedAt!.month.toString().padLeft(2, '0')}';
          viewsByMonth[monthKey] = (viewsByMonth[monthKey] ?? 0) + post.views;
        }
      }

      return viewsByMonth;
    } catch (e) {
      print('Erreur lors de la récupération des vues par mois: \$e');
      return {};
    }
  }

  /// ========== MÉTHODES UTILITAIRES ==========

  /// Dupliquer un article
  Future<String?> duplicatePost(String postId) async {
    try {
      final doc = await collection.doc(postId).get();
      if (!doc.exists) return null;

      final originalPost = fromFirestore(doc);
      final duplicatedPost = originalPost.copyWith(
        id: null,
        title: '${originalPost.title} (Copie)',
        status: BlogPostStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: null,
        scheduledAt: null,
        views: 0,
        likes: 0,
        commentsCount: 0,
      );

      return await create(duplicatedPost);
    } catch (e) {
      print('Erreur lors de la duplication de l\'article: \$e');
      return null;
    }
  }
}