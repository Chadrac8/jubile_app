import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour représenter un article de blog
class BlogPost {
  final String id;
  final String title;
  final String content;
  final String excerpt;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final List<String> categories;
  final List<String> tags;
  final String? featuredImageUrl;
  final List<String> imageUrls;
  final BlogPostStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? scheduledAt;
  final int views;
  final int likes;
  final int commentsCount;
  final bool allowComments;
  final bool isFeatured;
  final Map<String, dynamic> seoData;
  final Map<String, dynamic> customFields;

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.categories = const [],
    this.tags = const [],
    this.featuredImageUrl,
    this.imageUrls = const [],
    this.status = BlogPostStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.scheduledAt,
    this.views = 0,
    this.likes = 0,
    this.commentsCount = 0,
    this.allowComments = true,
    this.isFeatured = false,
    this.seoData = const {},
    this.customFields = const {},
  });

  /// Factory pour créer depuis Firestore
  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BlogPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      excerpt: data['excerpt'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      categories: List<String>.from(data['categories'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      featuredImageUrl: data['featuredImageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: BlogPostStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BlogPostStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      publishedAt: data['publishedAt'] != null 
          ? (data['publishedAt'] as Timestamp).toDate() 
          : null,
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] as Timestamp).toDate() 
          : null,
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      allowComments: data['allowComments'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      seoData: Map<String, dynamic>.from(data['seoData'] ?? {}),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'categories': categories,
      'tags': tags,
      'featuredImageUrl': featuredImageUrl,
      'imageUrls': imageUrls,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'views': views,
      'likes': likes,
      'commentsCount': commentsCount,
      'allowComments': allowComments,
      'isFeatured': isFeatured,
      'seoData': seoData,
      'customFields': customFields,
    };
  }

  /// Créer une copie avec des modifications
  BlogPost copyWith({
    String? title,
    String? content,
    String? excerpt,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    List<String>? categories,
    List<String>? tags,
    String? featuredImageUrl,
    List<String>? imageUrls,
    BlogPostStatus? status,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? scheduledAt,
    int? views,
    int? likes,
    int? commentsCount,
    bool? allowComments,
    bool? isFeatured,
    Map<String, dynamic>? seoData,
    Map<String, dynamic>? customFields,
  }) {
    return BlogPost(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      allowComments: allowComments ?? this.allowComments,
      isFeatured: isFeatured ?? this.isFeatured,
      seoData: seoData ?? this.seoData,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Vérifier si l'article est publié
  bool get isPublished => status == BlogPostStatus.published && publishedAt != null;

  /// Vérifier si l'article est programmé
  bool get isScheduled => status == BlogPostStatus.scheduled && scheduledAt != null;

  /// Obtenir l'URL de l'article
  String get slug => title.toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();

  /// Obtenir le temps de lecture estimé
  int get readingTimeMinutes {
    const int wordsPerMinute = 200;
    final int wordCount = content.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }
}

/// Statut d'un article de blog
enum BlogPostStatus {
  draft('Brouillon'),
  published('Publié'),
  scheduled('Programmé'),
  archived('Archivé');

  const BlogPostStatus(this.displayName);
  final String displayName;
}

/// Modèle pour représenter un commentaire de blog
class BlogComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isApproved;
  final String? parentCommentId; // Pour les réponses aux commentaires
  final int likes;
  final bool isAuthorReply; // Si c'est une réponse de l'auteur de l'article

  BlogComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isApproved = false,
    this.parentCommentId,
    this.likes = 0,
    this.isAuthorReply = false,
  });

  factory BlogComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BlogComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isApproved: data['isApproved'] ?? false,
      parentCommentId: data['parentCommentId'],
      likes: data['likes'] ?? 0,
      isAuthorReply: data['isAuthorReply'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isApproved': isApproved,
      'parentCommentId': parentCommentId,
      'likes': likes,
      'isAuthorReply': isAuthorReply,
    };
  }

  BlogComment copyWith({
    String? content,
    DateTime? updatedAt,
    bool? isApproved,
    int? likes,
  }) {
    return BlogComment(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      parentCommentId: parentCommentId,
      likes: likes ?? this.likes,
      isAuthorReply: isAuthorReply,
    );
  }
}

/// Modèle pour représenter une catégorie de blog
class BlogCategory {
  final String id;
  final String name;
  final String description;
  final String? color;
  final String? iconName;
  final int postCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogCategory({
    required this.id,
    required this.name,
    required this.description,
    this.color,
    this.iconName,
    this.postCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BlogCategory(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      color: data['color'],
      iconName: data['iconName'],
      postCount: data['postCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'iconName': iconName,
      'postCount': postCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BlogCategory copyWith({
    String? name,
    String? description,
    String? color,
    String? iconName,
    int? postCount,
    DateTime? updatedAt,
  }) {
    return BlogCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      postCount: postCount ?? this.postCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Modèle pour les likes d'articles
class BlogPostLike {
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;

  BlogPostLike({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  factory BlogPostLike.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BlogPostLike(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Modèle pour les vues d'articles
class BlogPostView {
  final String id;
  final String postId;
  final String? userId;
  final String? ipAddress;
  final DateTime viewedAt;

  BlogPostView({
    required this.id,
    required this.postId,
    this.userId,
    this.ipAddress,
    required this.viewedAt,
  });

  factory BlogPostView.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BlogPostView(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'],
      ipAddress: data['ipAddress'],
      viewedAt: (data['viewedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'ipAddress': ipAddress,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }
}