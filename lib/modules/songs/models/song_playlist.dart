import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une playlist de chants
class SongPlaylist {
  final String? id;
  final String title;
  final String? description;
  final String createdBy;
  final List<String> songIds;
  final List<String> collaborators;
  final bool isPublic;
  final bool isOfficial;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const SongPlaylist({
    this.id,
    required this.title,
    this.description,
    required this.createdBy,
    this.songIds = const [],
    this.collaborators = const [],
    this.isPublic = false,
    this.isOfficial = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Créer une SongPlaylist à partir des données Firestore
  factory SongPlaylist.fromMap(Map<String, dynamic> map, String id) {
    return SongPlaylist(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      createdBy: map['createdBy'] ?? '',
      songIds: List<String>.from(map['songIds'] ?? []),
      collaborators: List<String>.from(map['collaborators'] ?? []),
      isPublic: map['isPublic'] ?? false,
      isOfficial: map['isOfficial'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convertir la SongPlaylist en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'songIds': songIds,
      'collaborators': collaborators,
      'isPublic': isPublic,
      'isOfficial': isOfficial,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Créer une copie de la SongPlaylist avec des modifications
  SongPlaylist copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    List<String>? songIds,
    List<String>? collaborators,
    bool? isPublic,
    bool? isOfficial,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SongPlaylist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      songIds: songIds ?? this.songIds,
      collaborators: collaborators ?? this.collaborators,
      isPublic: isPublic ?? this.isPublic,
      isOfficial: isOfficial ?? this.isOfficial,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Vérifier si l'utilisateur peut modifier cette playlist
  bool canEdit(String userId) {
    return createdBy == userId || collaborators.contains(userId);
  }

  /// Ajouter un chant à la playlist
  SongPlaylist addSong(String songId) {
    if (songIds.contains(songId)) return this;
    
    return copyWith(
      songIds: [...songIds, songId],
      updatedAt: DateTime.now(),
    );
  }

  /// Supprimer un chant de la playlist
  SongPlaylist removeSong(String songId) {
    if (!songIds.contains(songId)) return this;
    
    return copyWith(
      songIds: songIds.where((id) => id != songId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Réorganiser les chants dans la playlist
  SongPlaylist reorderSongs(List<String> newOrder) {
    return copyWith(
      songIds: newOrder,
      updatedAt: DateTime.now(),
    );
  }

  /// Ajouter un collaborateur
  SongPlaylist addCollaborator(String userId) {
    if (collaborators.contains(userId)) return this;
    
    return copyWith(
      collaborators: [...collaborators, userId],
      updatedAt: DateTime.now(),
    );
  }

  /// Supprimer un collaborateur
  SongPlaylist removeCollaborator(String userId) {
    if (!collaborators.contains(userId)) return this;
    
    return copyWith(
      collaborators: collaborators.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Obtenir le nombre de chants dans la playlist
  int get songsCount => songIds.length;

  @override
  String toString() {
    return 'SongPlaylist(id: $id, title: $title, songsCount: $songsCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongPlaylist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}