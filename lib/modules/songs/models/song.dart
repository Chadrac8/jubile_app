import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un chant dans le recueil
class Song {
  final String? id;
  final String title;
  final String? subtitle;
  final String? author;
  final String? composer;
  final String lyrics;
  final String? musicSheet;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> categories;
  final List<String> tags;
  final String? tonality;
  final int? tempo;
  final String? structure;
  final Map<String, String> translations;
  final bool isPublic;
  final bool isApproved;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int views;
  final List<String> favorites;
  final Map<String, dynamic> metadata;

  const Song({
    this.id,
    required this.title,
    this.subtitle,
    this.author,
    this.composer,
    required this.lyrics,
    this.musicSheet,
    this.audioUrl,
    this.videoUrl,
    this.categories = const [],
    this.tags = const [],
    this.tonality,
    this.tempo,
    this.structure,
    this.translations = const {},
    this.isPublic = true,
    this.isApproved = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.views = 0,
    this.favorites = const [],
    this.metadata = const {},
  });

  /// Créer un Song à partir des données Firestore
  factory Song.fromMap(Map<String, dynamic> map, String id) {
    return Song(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      author: map['author'],
      composer: map['composer'],
      lyrics: map['lyrics'] ?? '',
      musicSheet: map['musicSheet'],
      audioUrl: map['audioUrl'],
      videoUrl: map['videoUrl'],
      categories: List<String>.from(map['categories'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      tonality: map['tonality'],
      tempo: map['tempo'],
      structure: map['structure'],
      translations: Map<String, String>.from(map['translations'] ?? {}),
      isPublic: map['isPublic'] ?? true,
      isApproved: map['isApproved'] ?? false,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      views: map['views'] ?? 0,
      favorites: List<String>.from(map['favorites'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convertir le Song en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'author': author,
      'composer': composer,
      'lyrics': lyrics,
      'musicSheet': musicSheet,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'categories': categories,
      'tags': tags,
      'tonality': tonality,
      'tempo': tempo,
      'structure': structure,
      'translations': translations,
      'isPublic': isPublic,
      'isApproved': isApproved,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'views': views,
      'favorites': favorites,
      'metadata': metadata,
    };
  }

  /// Créer une copie du Song avec des modifications
  Song copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? author,
    String? composer,
    String? lyrics,
    String? musicSheet,
    String? audioUrl,
    String? videoUrl,
    List<String>? categories,
    List<String>? tags,
    String? tonality,
    int? tempo,
    String? structure,
    Map<String, String>? translations,
    bool? isPublic,
    bool? isApproved,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? views,
    List<String>? favorites,
    Map<String, dynamic>? metadata,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      author: author ?? this.author,
      composer: composer ?? this.composer,
      lyrics: lyrics ?? this.lyrics,
      musicSheet: musicSheet ?? this.musicSheet,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      tonality: tonality ?? this.tonality,
      tempo: tempo ?? this.tempo,
      structure: structure ?? this.structure,
      translations: translations ?? this.translations,
      isPublic: isPublic ?? this.isPublic,
      isApproved: isApproved ?? this.isApproved,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      views: views ?? this.views,
      favorites: favorites ?? this.favorites,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Vérifier si l'utilisateur a mis ce chant en favori
  bool isFavoriteBy(String userId) {
    return favorites.contains(userId);
  }

  /// Obtenir le texte de recherche pour ce chant
  String get searchText {
    return '''$title ${subtitle ?? ''} ${author ?? ''} ${composer ?? ''} 
             ${categories.join(' ')} ${tags.join(' ')} $lyrics'''
        .toLowerCase();
  }

  /// Obtenir les premières lignes du chant pour l'aperçu
  String get preview {
    final lines = lyrics.split('\n');
    if (lines.isEmpty) return '';
    
    // Prendre les 3 premières lignes non vides
    final previewLines = lines
        .where((line) => line.trim().isNotEmpty)
        .take(3)
        .join('\n');
    
    return previewLines.length > 150 
        ? '${previewLines.substring(0, 150)}...'
        : previewLines;
  }

  /// Obtenir la durée estimée du chant
  String get estimatedDuration {
    if (tempo == null) return 'Non spécifiée';
    
    final lyricsLength = lyrics.replaceAll(RegExp(r'\s+'), ' ').length;
    final wordsCount = lyrics.split(' ').length;
    
    // Estimation basée sur le tempo et le nombre de mots
    final minutes = (wordsCount / (tempo! * 0.5)).round();
    
    if (minutes < 1) return '< 1 min';
    if (minutes == 1) return '1 min';
    return '$minutes min';
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}