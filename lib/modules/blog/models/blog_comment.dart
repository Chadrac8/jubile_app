import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut des commentaires
enum CommentStatus {
  pending,
  approved,
  rejected,
  spam,
}

/// Modèle pour les commentaires de blog
class BlogComment {
  final String? id;
  final String postId;
  final String? parentId; // Pour les réponses
  final String authorId;
  final String authorName;
  final String? authorEmail;
  final String? authorPhotoUrl;
  final String content;
  final CommentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final bool isModerated;
  final Map<String, dynamic> customFields;

  BlogComment({
    this.id,
    required this.postId,
    this.parentId,
    required this.authorId,
    required this.authorName,
    this.authorEmail,
    this.authorPhotoUrl,
    required this.content,
    this.status = CommentStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.isModerated = false,
    this.customFields = const {},
  });

  /// Factory depuis Firestore
  factory BlogComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BlogComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      parentId: data['parentId'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorEmail: data['authorEmail'],
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      status: CommentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CommentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      isModerated: data['isModerated'] ?? false,
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }

  /// Factory depuis Map
  factory BlogComment.fromMap(Map<String, dynamic> data, String id) {
    return BlogComment(
      id: id,
      postId: data['postId'] ?? '',
      parentId: data['parentId'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorEmail: data['authorEmail'],
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      status: CommentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CommentStatus.pending,
      ),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      likes: data['likes'] ?? 0,
      isModerated: data['isModerated'] ?? false,
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }

  /// Convertir vers Map
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'parentId': parentId,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likes': likes,
      'isModerated': isModerated,
      'customFields': customFields,
    };
  }

  /// Copie avec modifications
  BlogComment copyWith({
    String? id,
    String? postId,
    String? parentId,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? authorPhotoUrl,
    String? content,
    CommentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    bool? isModerated,
    Map<String, dynamic>? customFields,
  }) {
    return BlogComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      isModerated: isModerated ?? this.isModerated,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Vérifier si c'est une réponse
  bool get isReply => parentId != null;

  /// Label du statut
  String get statusLabel {
    switch (status) {
      case CommentStatus.pending:
        return 'En attente';
      case CommentStatus.approved:
        return 'Approuvé';
      case CommentStatus.rejected:
        return 'Rejeté';
      case CommentStatus.spam:
        return 'Spam';
    }
  }

  @override
  String toString() {
    return 'BlogComment(id: $id, postId: $postId, author: $authorName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlogComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}