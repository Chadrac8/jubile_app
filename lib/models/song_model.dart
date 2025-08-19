import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de données pour un chant
class SongModel {
  final String id;
  final String title;
  final String authors;
  final String lyrics;
  final String originalKey;
  final String? currentKey;
  final String style;
  final List<String> tags;
  final List<String> bibleReferences;
  final int? tempo;
  final String? audioUrl;
  final List<String> attachmentUrls;
  final String status;
  final String visibility;
  final String? privateNotes;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? modifiedBy;
  final Map<String, dynamic> metadata;

  SongModel({
    required this.id,
    required this.title,
    required this.authors,
    required this.lyrics,
    required this.originalKey,
    this.currentKey,
    required this.style,
    required this.tags,
    required this.bibleReferences,
    this.tempo,
    this.audioUrl,
    required this.attachmentUrls,
    required this.status,
    required this.visibility,
    this.privateNotes,
    required this.usageCount,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.modifiedBy,
    required this.metadata,
  });

  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SongModel(
      id: doc.id,
      title: data['title'] ?? '',
      authors: data['authors'] ?? '',
      lyrics: data['lyrics'] ?? '',
      originalKey: data['originalKey'] ?? 'C',
      currentKey: data['currentKey'],
      style: data['style'] ?? 'Adoration',
      tags: List<String>.from(data['tags'] ?? []),
      bibleReferences: List<String>.from(data['bibleReferences'] ?? []),
      tempo: data['tempo'],
      audioUrl: data['audioUrl'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      status: data['status'] ?? 'draft',
      visibility: data['visibility'] ?? 'private',
      privateNotes: data['privateNotes'],
      usageCount: data['usageCount'] ?? 0,
      lastUsedAt: data['lastUsedAt']?.toDate(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      modifiedBy: data['modifiedBy'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'authors': authors,
      'lyrics': lyrics,
      'originalKey': originalKey,
      'currentKey': currentKey,
      'style': style,
      'tags': tags,
      'bibleReferences': bibleReferences,
      'tempo': tempo,
      'audioUrl': audioUrl,
      'attachmentUrls': attachmentUrls,
      'status': status,
      'visibility': visibility,
      'privateNotes': privateNotes,
      'usageCount': usageCount,
      'lastUsedAt': lastUsedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
      'metadata': metadata,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? authors,
    String? lyrics,
    String? originalKey,
    String? currentKey,
    String? style,
    List<String>? tags,
    List<String>? bibleReferences,
    int? tempo,
    String? audioUrl,
    List<String>? attachmentUrls,
    String? status,
    String? visibility,
    String? privateNotes,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? modifiedBy,
    Map<String, dynamic>? metadata,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      lyrics: lyrics ?? this.lyrics,
      originalKey: originalKey ?? this.originalKey,
      currentKey: currentKey ?? this.currentKey,
      style: style ?? this.style,
      tags: tags ?? this.tags,
      bibleReferences: bibleReferences ?? this.bibleReferences,
      tempo: tempo ?? this.tempo,
      audioUrl: audioUrl ?? this.audioUrl,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      privateNotes: privateNotes ?? this.privateNotes,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  static List<String> get availableStyles => [
    'Adoration',
    'Louange',
    'Communion',
    'Prière',
    'Évangélisation',
    'Baptême',
    'Mariage',
    'Funérailles',
    'Enfants',
    'Jeunes',
    'Noël',
    'Pâques',
    'Autre'
  ];

  static List<String> get availableKeys => [
    'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B',
    'Am', 'A#m', 'Bbm', 'Bm', 'Cm', 'C#m', 'Dm', 'D#m', 'Ebm', 'Em', 'Fm', 'F#m', 'Gm', 'G#m'
  ];

  static List<String> get availableStatuses => [
    'draft',
    'published',
    'archived'
  ];

  static List<String> get availableVisibilities => [
    'public',
    'private',
    'members_only'
  ];
}

/// Modèle pour les setlists (listes de chants)
class SetlistModel {
  final String id;
  final String name;
  final String description;
  final List<String> songIds;
  final DateTime serviceDate;
  final String? serviceType;
  final String? teamId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? modifiedBy;

  SetlistModel({
    required this.id,
    required this.name,
    required this.description,
    required this.songIds,
    required this.serviceDate,
    this.serviceType,
    this.teamId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.modifiedBy,
  });

  factory SetlistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SetlistModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      songIds: List<String>.from(data['songIds'] ?? []),
      serviceDate: data['serviceDate']?.toDate() ?? DateTime.now(),
      serviceType: data['serviceType'],
      teamId: data['teamId'],
      notes: data['notes'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      modifiedBy: data['modifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'songIds': songIds,
      'serviceDate': serviceDate,
      'serviceType': serviceType,
      'teamId': teamId,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  SetlistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    DateTime? serviceDate,
    String? serviceType,
    String? teamId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? modifiedBy,
  }) {
    return SetlistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      serviceDate: serviceDate ?? this.serviceDate,
      serviceType: serviceType ?? this.serviceType,
      teamId: teamId ?? this.teamId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }
}