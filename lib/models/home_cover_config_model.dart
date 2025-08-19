import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de configuration pour l'image de couverture de la page d'accueil membre
class HomeCoverConfigModel {
  final String id;
  final String coverImageUrl;
  final List<String> coverImageUrls; // Liste d'images pour le carrousel
  final String? coverVideoUrl; // URL de la vidéo de couverture
  final bool useVideo; // Utiliser la vidéo au lieu des images
  final String? coverTitle;
  final String? coverSubtitle;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  
  // Nouveaux champs pour la gestion du live
  final DateTime? liveDateTime;
  final String? liveUrl;
  final bool isLiveActive;

  HomeCoverConfigModel({
    required this.id,
    required this.coverImageUrl,
    this.coverImageUrls = const [], // Liste par défaut vide
    this.coverVideoUrl,
    this.useVideo = false,
    this.coverTitle,
    this.coverSubtitle,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.liveDateTime,
    this.liveUrl,
    this.isLiveActive = false,
  });

  /// Constructeur pour créer une nouvelle configuration
  factory HomeCoverConfigModel.create({
    required String coverImageUrl,
    List<String> coverImageUrls = const [],
    String? coverVideoUrl,
    bool useVideo = false,
    String? coverTitle,
    String? coverSubtitle,
    String? createdBy,
    DateTime? liveDateTime,
    String? liveUrl,
    bool isLiveActive = false,
  }) {
    final now = DateTime.now();
    return HomeCoverConfigModel(
      id: '', // Will be set by Firestore
      coverImageUrl: coverImageUrl,
      coverImageUrls: coverImageUrls,
      coverVideoUrl: coverVideoUrl,
      useVideo: useVideo,
      coverTitle: coverTitle,
      coverSubtitle: coverSubtitle,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      lastModifiedBy: createdBy,
      liveDateTime: liveDateTime,
      liveUrl: liveUrl,
      isLiveActive: isLiveActive);
  }

  /// Créer à partir des données Firestore
  factory HomeCoverConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeCoverConfigModel(
      id: doc.id,
      coverImageUrl: data['coverImageUrl'] ?? '',
      coverImageUrls: List<String>.from(data['coverImageUrls'] ?? []),
      coverVideoUrl: data['coverVideoUrl'],
      useVideo: data['useVideo'] ?? false,
      coverTitle: data['coverTitle'],
      coverSubtitle: data['coverSubtitle'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      liveDateTime: (data['liveDateTime'] as Timestamp?)?.toDate(),
      liveUrl: data['liveUrl'],
      isLiveActive: data['isLiveActive'] ?? false);
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'coverImageUrl': coverImageUrl,
      'coverImageUrls': coverImageUrls,
      'coverVideoUrl': coverVideoUrl,
      'useVideo': useVideo,
      'coverTitle': coverTitle,
      'coverSubtitle': coverSubtitle,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'liveDateTime': liveDateTime != null ? Timestamp.fromDate(liveDateTime!) : null,
      'liveUrl': liveUrl,
      'isLiveActive': isLiveActive,
    };
  }

  /// Créer une copie avec des modifications
  HomeCoverConfigModel copyWith({
    String? id,
    String? coverImageUrl,
    List<String>? coverImageUrls,
    String? coverVideoUrl,
    bool? useVideo,
    String? coverTitle,
    String? coverSubtitle,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    DateTime? liveDateTime,
    String? liveUrl,
    bool? isLiveActive,
  }) {
    return HomeCoverConfigModel(
      id: id ?? this.id,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageUrls: coverImageUrls ?? this.coverImageUrls,
      coverVideoUrl: coverVideoUrl ?? this.coverVideoUrl,
      useVideo: useVideo ?? this.useVideo,
      coverTitle: coverTitle ?? this.coverTitle,
      coverSubtitle: coverSubtitle ?? this.coverSubtitle,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      liveDateTime: liveDateTime ?? this.liveDateTime,
      liveUrl: liveUrl ?? this.liveUrl,
      isLiveActive: isLiveActive ?? this.isLiveActive);
  }

  /// Configuration par défaut
  static HomeCoverConfigModel get defaultConfig {
    return HomeCoverConfigModel(
      id: 'default',
      coverImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=400&fit=crop',
      coverTitle: 'Bienvenue dans notre communauté',
      coverSubtitle: 'Ensemble, nous grandissons dans la foi',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
      lastModifiedBy: 'system',
      liveDateTime: null,
      liveUrl: null,
      isLiveActive: false);
  }

  /// Vérifier si le live est en cours
  bool get isLiveNow {
    if (!isLiveActive || liveDateTime == null) return false;
    final now = DateTime.now();
    final liveDT = liveDateTime!;
    // Le live est considéré en cours s'il a commencé et qu'il ne s'est pas écoulé plus de 3 heures
    return now.isAfter(liveDT) && now.difference(liveDT).inHours < 3;
  }

  /// Vérifier si le live est programmé pour bientôt
  bool get isLiveUpcoming {
    if (!isLiveActive || liveDateTime == null) return false;
    final now = DateTime.now();
    return now.isBefore(liveDateTime!);
  }

  /// Obtenir le temps restant avant le live en minutes
  int? get minutesUntilLive {
    if (!isLiveUpcoming) return null;
    return liveDateTime!.difference(DateTime.now()).inMinutes;
  }

  /// Obtenir le temps restant formaté (ex: "1h 30min", "45min", "Dans quelques minutes")
  String? get timeUntilLiveFormatted {
    if (!isLiveUpcoming) return null;
    
    final minutes = minutesUntilLive!;
    if (minutes <= 0) return 'Maintenant';
    if (minutes < 5) return 'Dans quelques minutes';
    if (minutes < 60) return '${minutes}min';
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${remainingMinutes}min';
    }
  }

  @override
  String toString() {
    return 'HomeCoverConfigModel(id: $id, coverImageUrl: $coverImageUrl, coverTitle: $coverTitle, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeCoverConfigModel &&
        other.id == id &&
        other.coverImageUrl == coverImageUrl &&
        other.coverTitle == coverTitle &&
        other.coverSubtitle == coverSubtitle &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        coverImageUrl.hashCode ^
        coverTitle.hashCode ^
        coverSubtitle.hashCode ^
        isActive.hashCode;
  }
}
