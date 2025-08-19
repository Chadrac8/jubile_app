import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour gérer les playlists YouTube de William Marrion Branham
class YouTubePlaylist {
  final String id;
  final String title;
  final String description;
  final String playlistId; // ID de la playlist YouTube
  final String playlistUrl; // URL complète de la playlist
  final String thumbnailUrl;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const YouTubePlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.playlistId,
    required this.playlistUrl,
    this.thumbnailUrl = '',
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  /// Création depuis Firestore
  factory YouTubePlaylist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return YouTubePlaylist(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      playlistId: data['playlistId'] ?? '',
      playlistUrl: data['playlistUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy']);
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'playlistId': playlistId,
      'playlistUrl': playlistUrl,
      'thumbnailUrl': thumbnailUrl,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Validation des données
  List<String> validate() {
    final errors = <String>[];
    
    if (title.trim().isEmpty) {
      errors.add('Le titre est requis');
    }
    
    if (playlistUrl.trim().isEmpty) {
      errors.add('L\'URL de la playlist est requise');
    } else if (!isValidYouTubePlaylistUrl(playlistUrl)) {
      errors.add('L\'URL doit être une playlist YouTube valide');
    }
    
    return errors;
  }

  /// Extrait l'ID de playlist depuis l'URL YouTube
  static String extractPlaylistId(String url) {
    final regExp = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  /// Valide si l'URL est une playlist YouTube valide
  static bool isValidYouTubePlaylistUrl(String url) {
    if (url.trim().isEmpty) return false;
    
    // Patterns pour les URLs de playlist YouTube
    final patterns = [
      r'https?://(?:www\.)?youtube\.com/playlist\?list=[a-zA-Z0-9_-]+',
      r'https?://(?:www\.)?youtube\.com/watch\?.*list=[a-zA-Z0-9_-]+',
      r'https?://youtu\.be/.*\?.*list=[a-zA-Z0-9_-]+',
    ];
    
    return patterns.any((pattern) => RegExp(pattern).hasMatch(url));
  }

  /// Génère l'URL d'embed pour la playlist
  String get embedUrl {
    if (playlistId.isEmpty) return '';
    return 'https://www.youtube.com/embed/videoseries?list=$playlistId&autoplay=0&loop=1';
  }

  /// Génère l'URL de thumbnail pour la playlist
  String get defaultThumbnailUrl {
    if (playlistId.isEmpty) return '';
    return 'https://img.youtube.com/vi/playlist/$playlistId/maxresdefault.jpg';
  }

  /// Copie avec modifications
  YouTubePlaylist copyWith({
    String? id,
    String? title,
    String? description,
    String? playlistId,
    String? playlistUrl,
    String? thumbnailUrl,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return YouTubePlaylist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      playlistId: playlistId ?? this.playlistId,
      playlistUrl: playlistUrl ?? this.playlistUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy);
  }

  @override
  String toString() {
    return 'YouTubePlaylist(id: $id, title: $title, playlistId: $playlistId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YouTubePlaylist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
