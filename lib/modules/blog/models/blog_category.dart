import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les catégories de blog
class BlogCategory {
  final String? id;
  final String name;
  final String slug;
  final String description;
  final String? colorCode;
  final String? iconName;
  final String? imageUrl;
  final int postCount;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic> customFields;

  BlogCategory({
    this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.colorCode,
    this.iconName,
    this.imageUrl,
    this.postCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.customFields = const {},
  });

  /// Factory depuis Firestore
  factory BlogCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BlogCategory(
      id: doc.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      description: data['description'] ?? '',
      colorCode: data['colorCode'],
      iconName: data['iconName'],
      imageUrl: data['imageUrl'],
      postCount: data['postCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }

  /// Factory depuis Map
  factory BlogCategory.fromMap(Map<String, dynamic> data, String id) {
    return BlogCategory(
      id: id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      description: data['description'] ?? '',
      colorCode: data['colorCode'],
      iconName: data['iconName'],
      imageUrl: data['imageUrl'],
      postCount: data['postCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: data['createdBy'] ?? '',
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
    );
  }

  /// Convertir vers Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'colorCode': colorCode,
      'iconName': iconName,
      'imageUrl': imageUrl,
      'postCount': postCount,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'customFields': customFields,
    };
  }

  /// Copie avec modifications
  BlogCategory copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? colorCode,
    String? iconName,
    String? imageUrl,
    int? postCount,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? customFields,
  }) {
    return BlogCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      colorCode: colorCode ?? this.colorCode,
      iconName: iconName ?? this.iconName,
      imageUrl: imageUrl ?? this.imageUrl,
      postCount: postCount ?? this.postCount,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Générer un slug depuis le nom
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  String toString() {
    return 'BlogCategory(id: $id, name: $name, slug: $slug, postCount: $postCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlogCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}