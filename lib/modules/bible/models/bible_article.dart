import 'package:uuid/uuid.dart';

/// Modèle pour un article biblique
class BibleArticle {
  final String id;
  final String title;
  final String content;
  final String summary;
  final String category;
  final String author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final List<BibleReference> bibleReferences;
  final String? imageUrl;
  final int readingTimeMinutes;
  final bool isPublished;
  final int viewCount;

  BibleArticle({
    String? id,
    required this.title,
    required this.content,
    required this.summary,
    required this.category,
    required this.author,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    List<BibleReference>? bibleReferences,
    this.imageUrl,
    this.readingTimeMinutes = 5,
    this.isPublished = true,
    this.viewCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [],
        bibleReferences = bibleReferences ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'category': category,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'bibleReferences': bibleReferences.map((ref) => ref.toJson()).toList(),
      'imageUrl': imageUrl,
      'readingTimeMinutes': readingTimeMinutes,
      'isPublished': isPublished,
      'viewCount': viewCount,
    };
  }

  static BibleArticle fromJson(Map<String, dynamic> json) {
    return BibleArticle(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      summary: json['summary'],
      category: json['category'],
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      bibleReferences: (json['bibleReferences'] as List<dynamic>? ?? [])
          .map((ref) => BibleReference.fromJson(ref))
          .toList(),
      imageUrl: json['imageUrl'],
      readingTimeMinutes: json['readingTimeMinutes'] ?? 5,
      isPublished: json['isPublished'] ?? true,
      viewCount: json['viewCount'] ?? 0);
  }

  BibleArticle copyWith({
    String? title,
    String? content,
    String? summary,
    String? category,
    String? author,
    DateTime? updatedAt,
    List<String>? tags,
    List<BibleReference>? bibleReferences,
    String? imageUrl,
    int? readingTimeMinutes,
    bool? isPublished,
    int? viewCount,
  }) {
    return BibleArticle(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      author: author ?? this.author,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      bibleReferences: bibleReferences ?? this.bibleReferences,
      imageUrl: imageUrl ?? this.imageUrl,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      isPublished: isPublished ?? this.isPublished,
      viewCount: viewCount ?? this.viewCount);
  }
}

/// Référence biblique pour les articles
class BibleReference {
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  BibleReference({
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
    };
  }

  static BibleReference fromJson(Map<String, dynamic> json) {
    return BibleReference(
      book: json['book'],
      chapter: json['chapter'],
      startVerse: json['startVerse'],
      endVerse: json['endVerse']);
  }

  String get displayText {
    if (startVerse != null && endVerse != null) {
      if (startVerse == endVerse) {
        return '$book $chapter:$startVerse';
      } else {
        return '$book $chapter:$startVerse-$endVerse';
      }
    } else if (startVerse != null) {
      return '$book $chapter:$startVerse';
    } else {
      return '$book $chapter';
    }
  }
}

/// Catégories d'articles disponibles
enum BibleArticleCategory {
  theology('Théologie'),
  history('Histoire'),
  prophecy('Prophétie'),
  biography('Biographies'),
  teachings('Enseignements'),
  devotional('Dévotion'),
  apologetics('Apologétique'),
  culture('Culture biblique'),
  archaeology('Archéologie'),
  other('Autre');

  const BibleArticleCategory(this.displayName);
  final String displayName;

  static BibleArticleCategory fromString(String value) {
    return BibleArticleCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => BibleArticleCategory.other);
  }
}

/// Statistiques de lecture d'articles
class ArticleReadingStats {
  final String userId;
  final String articleId;
  final DateTime firstReadAt;
  final DateTime lastReadAt;
  final int readCount;
  final bool isBookmarked;
  final double readingProgress; // 0.0 à 1.0

  ArticleReadingStats({
    required this.userId,
    required this.articleId,
    DateTime? firstReadAt,
    DateTime? lastReadAt,
    this.readCount = 1,
    this.isBookmarked = false,
    this.readingProgress = 0.0,
  })  : firstReadAt = firstReadAt ?? DateTime.now(),
        lastReadAt = lastReadAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'articleId': articleId,
      'firstReadAt': firstReadAt.toIso8601String(),
      'lastReadAt': lastReadAt.toIso8601String(),
      'readCount': readCount,
      'isBookmarked': isBookmarked,
      'readingProgress': readingProgress,
    };
  }

  static ArticleReadingStats fromJson(Map<String, dynamic> json) {
    return ArticleReadingStats(
      userId: json['userId'],
      articleId: json['articleId'],
      firstReadAt: DateTime.parse(json['firstReadAt']),
      lastReadAt: DateTime.parse(json['lastReadAt']),
      readCount: json['readCount'] ?? 1,
      isBookmarked: json['isBookmarked'] ?? false,
      readingProgress: (json['readingProgress'] ?? 0.0).toDouble());
  }

  ArticleReadingStats copyWith({
    DateTime? lastReadAt,
    int? readCount,
    bool? isBookmarked,
    double? readingProgress,
  }) {
    return ArticleReadingStats(
      userId: userId,
      articleId: articleId,
      firstReadAt: firstReadAt,
      lastReadAt: lastReadAt ?? DateTime.now(),
      readCount: readCount ?? this.readCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      readingProgress: readingProgress ?? this.readingProgress);
  }
}
