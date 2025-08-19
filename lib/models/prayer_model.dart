import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final PrayerType type;
  final String category;
  final bool isAnonymous;
  final bool isApproved;
  final int prayerCount;
  final List<String> prayedByUsers;
  final List<PrayerComment> comments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  final List<String> tags;

  PrayerModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.type,
    required this.category,
    required this.isAnonymous,
    this.isApproved = true,
    this.prayerCount = 0,
    this.prayedByUsers = const [],
    this.comments = const [],
    required this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'type': type.name,
      'category': category,
      'isAnonymous': isAnonymous,
      'isApproved': isApproved,
      'prayerCount': prayerCount,
      'prayedByUsers': prayedByUsers,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isArchived': isArchived,
      'tags': tags,
    };
  }

  factory PrayerModel.fromMap(Map<String, dynamic> map) {
    return PrayerModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhoto: map['authorPhoto'],
      type: PrayerType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PrayerType.request,
      ),
      category: map['category'] ?? 'Général',
      isAnonymous: map['isAnonymous'] ?? false,
      isApproved: map['isApproved'] ?? true,
      prayerCount: map['prayerCount'] ?? 0,
      prayedByUsers: List<String>.from(map['prayedByUsers'] ?? []),
      comments: (map['comments'] as List<dynamic>?)
          ?.map((comment) => PrayerComment.fromMap(comment))
          .toList() ?? [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      isArchived: map['isArchived'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  PrayerModel copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorPhoto,
    PrayerType? type,
    String? category,
    bool? isAnonymous,
    bool? isApproved,
    int? prayerCount,
    List<String>? prayedByUsers,
    List<PrayerComment>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    List<String>? tags,
  }) {
    return PrayerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      type: type ?? this.type,
      category: category ?? this.category,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isApproved: isApproved ?? this.isApproved,
      prayerCount: prayerCount ?? this.prayerCount,
      prayedByUsers: prayedByUsers ?? this.prayedByUsers,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
    );
  }
}

class PrayerComment {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String content;
  final DateTime createdAt;
  final bool isApproved;

  PrayerComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.content,
    required this.createdAt,
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isApproved': isApproved,
    };
  }

  factory PrayerComment.fromMap(Map<String, dynamic> map) {
    return PrayerComment(
      id: map['id'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhoto: map['authorPhoto'],
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isApproved: map['isApproved'] ?? true,
    );
  }
}

enum PrayerType {
  request('Demande de prière', 'pan_tool'),
  testimony('Témoignage', 'star'),
  intercession('Intercession', 'favorite'),
  thanksgiving('Action de grâce', 'celebration');

  const PrayerType(this.label, this.icon);
  final String label;
  final String icon;
}

enum PrayerStatus {
  pending('En attente'),
  approved('Approuvé'),
  rejected('Rejeté'),
  archived('Archivé');

  const PrayerStatus(this.label);
  final String label;
}

class PrayerStats {
  final int totalPrayers;
  final int todayPrayers;
  final int weekPrayers;
  final int monthPrayers;
  final int totalPrayerCount;
  final Map<String, int> prayersByType;
  final Map<String, int> prayersByCategory;
  final int pendingApproval;

  PrayerStats({
    this.totalPrayers = 0,
    this.todayPrayers = 0,
    this.weekPrayers = 0,
    this.monthPrayers = 0,
    this.totalPrayerCount = 0,
    this.prayersByType = const {},
    this.prayersByCategory = const {},
    this.pendingApproval = 0,
  });
}