import 'package:cloud_firestore/cloud_firestore.dart';
import 'branham_sermon_model.dart';

/// Modèle pour une prédication de William Marrion Branham avec liens audio personnalisés
class AdminBranhamSermon {
  final String id;
  final String title;
  final String date;
  final String location;
  final String audioUrl;
  final String? audioDownloadUrl;
  final String? pdfUrl;
  final String? imageUrl;
  final String? description;
  final Duration? duration;
  final String language;
  final String? series;
  final List<String> keywords;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final bool isActive;
  final int displayOrder;

  const AdminBranhamSermon({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.audioUrl,
    this.audioDownloadUrl,
    this.pdfUrl,
    this.imageUrl,
    this.description,
    this.duration,
    this.language = 'fr',
    this.series,
    this.keywords = const [],
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.isActive = true,
    this.displayOrder = 0,
  });

  /// Créer depuis Firestore
  factory AdminBranhamSermon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminBranhamSermon(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      location: data['location'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      audioDownloadUrl: data['audioDownloadUrl'],
      pdfUrl: data['pdfUrl'],
      imageUrl: data['imageUrl'],
      description: data['description'],
      duration: data['durationSeconds'] != null 
          ? Duration(seconds: data['durationSeconds']) 
          : null,
      language: data['language'] ?? 'fr',
      series: data['series'],
      keywords: List<String>.from(data['keywords'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      createdBy: data['createdBy'],
      isActive: data['isActive'] ?? true,
      displayOrder: data['displayOrder'] ?? 0);
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': date,
      'location': location,
      'audioUrl': audioUrl,
      'audioDownloadUrl': audioDownloadUrl,
      'pdfUrl': pdfUrl,
      'imageUrl': imageUrl,
      'description': description,
      'durationSeconds': duration?.inSeconds,
      'language': language,
      'series': series,
      'keywords': keywords,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }

  /// Copier avec modifications
  AdminBranhamSermon copyWith({
    String? title,
    String? date,
    String? location,
    String? audioUrl,
    String? audioDownloadUrl,
    String? pdfUrl,
    String? imageUrl,
    String? description,
    Duration? duration,
    String? language,
    String? series,
    List<String>? keywords,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
    int? displayOrder,
  }) {
    return AdminBranhamSermon(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDownloadUrl: audioDownloadUrl ?? this.audioDownloadUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      language: language ?? this.language,
      series: series ?? this.series,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder);
  }

  /// Convertir vers BranhamSermon pour l'affichage
  BranhamSermon toBranhamSermon() {
    return BranhamSermon(
      id: id,
      title: title,
      date: date,
      location: location,
      duration: duration,
      audioStreamUrl: audioUrl,
      audioDownloadUrl: audioDownloadUrl,
      pdfUrl: pdfUrl,
      language: language,
      series: series,
      imageUrl: imageUrl,
      publishedDate: createdAt,
      createdAt: createdAt,
      isFavorite: false,
      year: _extractYear(date),
      keywords: keywords);
  }

  /// Extraire l'année de la date de prédication
  static int? _extractYear(String date) {
    // Format attendu: 47-0412, 65-1207, etc.
    if (date.length >= 2) {
      final yearPart = date.substring(0, 2);
      final year = int.tryParse(yearPart);
      if (year != null) {
        // Convertir 47 -> 1947, 65 -> 1965
        return year <= 65 ? 1900 + year : 1900 + year;
      }
    }
    return null;
  }
}
