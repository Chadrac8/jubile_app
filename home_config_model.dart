class HomeConfigModel {
  final String id;
  final String? coverImageUrl;
  final String? videoUrl;
  final String versetDuJour;
  final String versetReference;
  final String? sermonYouTubeUrl;
  final String sermonTitle;
  final DateTime lastUpdated;
  final String? lastUpdatedBy;

  HomeConfigModel({
    required this.id,
    this.coverImageUrl,
    this.videoUrl,
    required this.versetDuJour,
    required this.versetReference,
    this.sermonYouTubeUrl,
    required this.sermonTitle,
    required this.lastUpdated,
    this.lastUpdatedBy,
  });

  factory HomeConfigModel.fromMap(Map<String, dynamic> map, String id) {
    return HomeConfigModel(
      id: id,
      coverImageUrl: map['coverImageUrl'],
      videoUrl: map['videoUrl'],
      versetDuJour: map['versetDuJour'] ?? '',
      versetReference: map['versetReference'] ?? '',
      sermonYouTubeUrl: map['sermonYouTubeUrl'],
      sermonTitle: map['sermonTitle'] ?? 'Dernier sermon',
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
      lastUpdatedBy: map['lastUpdatedBy']);
  }

  Map<String, dynamic> toMap() {
    return {
      'coverImageUrl': coverImageUrl,
      'videoUrl': videoUrl,
      'versetDuJour': versetDuJour,
      'versetReference': versetReference,
      'sermonYouTubeUrl': sermonYouTubeUrl,
      'sermonTitle': sermonTitle,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastUpdatedBy': lastUpdatedBy,
    };
  }

  HomeConfigModel copyWith({
    String? coverImageUrl,
    String? videoUrl,
    String? versetDuJour,
    String? versetReference,
    String? sermonYouTubeUrl,
    String? sermonTitle,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
    bool? clearCoverImage, // Flag pour supprimer l'image
  }) {
    return HomeConfigModel(
      id: id,
      coverImageUrl: clearCoverImage == true ? null : (coverImageUrl ?? this.coverImageUrl),
      videoUrl: videoUrl ?? this.videoUrl,
      versetDuJour: versetDuJour ?? this.versetDuJour,
      versetReference: versetReference ?? this.versetReference,
      sermonYouTubeUrl: sermonYouTubeUrl ?? this.sermonYouTubeUrl,
      sermonTitle: sermonTitle ?? this.sermonTitle,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy);
  }
}

class ChurchInfoModel {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String description;
  final String? logoUrl;
  final List<String> serviceHours;
  final Map<String, String>? socialMedia;

  ChurchInfoModel({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.description,
    this.logoUrl,
    required this.serviceHours,
    this.socialMedia,
  });

  factory ChurchInfoModel.fromMap(Map<String, dynamic> map) {
    return ChurchInfoModel(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'],
      serviceHours: List<String>.from(map['serviceHours'] ?? []),
      socialMedia: Map<String, String>.from(map['socialMedia'] ?? {}));
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'description': description,
      'logoUrl': logoUrl,
      'serviceHours': serviceHours,
      'socialMedia': socialMedia,
    };
  }
}

class BlogArticleModel {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final DateTime publishedAt;
  final List<String> categories;
  final bool isPublished;

  BlogArticleModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.publishedAt,
    required this.categories,
    required this.isPublished,
  });

  factory BlogArticleModel.fromMap(Map<String, dynamic> map, String id) {
    return BlogArticleModel(
      id: id,
      title: map['title'] ?? '',
      excerpt: map['excerpt'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      publishedAt: DateTime.parse(map['publishedAt'] ?? DateTime.now().toIso8601String()),
      categories: List<String>.from(map['categories'] ?? []),
      isPublished: map['isPublished'] ?? false);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'publishedAt': publishedAt.toIso8601String(),
      'categories': categories,
      'isPublished': isPublished,
    };
  }
}
