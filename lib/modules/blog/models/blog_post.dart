import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut des articles de blog
enum BlogPostStatus {
  draft,
  published,
  scheduled,
  archived,
}

/// Modèle principal pour les articles de blog
class BlogPost {
  final String? id;
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
    this.id,
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

  /// Factory depuis Map
  factory BlogPost.fromMap(Map<String, dynamic> data, String id) {
    return BlogPost(
      id: id,
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
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      publishedAt: data['publishedAt'] != null 
          ? (data['publishedAt'] is Timestamp 
              ? (data['publishedAt'] as Timestamp).toDate()
              : DateTime.parse(data['publishedAt'])) 
          : null,
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] is Timestamp 
              ? (data['scheduledAt'] as Timestamp).toDate()
              : DateTime.parse(data['scheduledAt'])) 
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
  Map<String, dynamic> toMap() {
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

  /// Copie avec modifications
  BlogPost copyWith({
    String? id,
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
    DateTime? createdAt,
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
      id: id ?? this.id,
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
      createdAt: createdAt ?? this.createdAt,
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

  /// Getter pour le statut coloré
  String get statusLabel {
    switch (status) {
      case BlogPostStatus.draft:
        return 'Brouillon';
      case BlogPostStatus.published:
        return 'Publié';
      case BlogPostStatus.scheduled:
        return 'Programmé';
      case BlogPostStatus.archived:
        return 'Archivé';
    }
  }

  /// Getter pour vérifier si l'article est public
  bool get isPublic => status == BlogPostStatus.published;

  /// Getter pour vérifier si l'article est récent (moins de 7 jours)
  bool get isRecent {
    if (publishedAt == null) return false;
    return DateTime.now().difference(publishedAt!).inDays < 7;
  }

  /// Getter pour le temps de lecture estimé (mots par minute)
  int get estimatedReadingTime {
    final wordCount = content.split(' ').length;
    return (wordCount / 200).ceil(); // 200 mots par minute
  }

  @override
  String toString() {
    return 'BlogPost(id: $id, title: $title, status: $status, author: $authorName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlogPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}