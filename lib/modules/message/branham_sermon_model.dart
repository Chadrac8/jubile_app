import 'sermon_model.dart';

/// Modèle pour une prédication de William Marrion Branham depuis branham.org
class BranhamSermon {
  final String id;
  final String title;
  final String date;
  final String location;
  final Duration? duration;
  final String? audioStreamUrl;
  final String? audioDownloadUrl;
  final String? pdfUrl;
  final String language;
  final String? series;
  final String? imageUrl;
  final DateTime? publishedDate;
  final DateTime createdAt;
  final bool isFavorite;
  final int? year;
  final List<String> keywords;

  const BranhamSermon({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    this.duration,
    this.audioStreamUrl,
    this.audioDownloadUrl,
    this.pdfUrl,
    this.language = 'FRN',
    this.series,
    this.imageUrl,
    this.publishedDate,
    required this.createdAt,
    this.isFavorite = false,
    this.year,
    this.keywords = const [],
  });

  /// Création depuis les données scrapées de branham.org
  factory BranhamSermon.fromBranhamData(Map<String, dynamic> data) {
    return BranhamSermon(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      location: data['location'] ?? '',
      duration: data['duration'] != null 
          ? Duration(minutes: int.tryParse(data['duration'].toString()) ?? 0)
          : null,
      audioStreamUrl: data['streamUrl'],
      audioDownloadUrl: data['downloadUrl'],
      pdfUrl: data['pdfUrl'],
      language: data['language'] ?? 'FRN',
      series: data['series'],
      imageUrl: data['imageUrl'],
      publishedDate: data['publishedDate'] != null 
          ? DateTime.tryParse(data['publishedDate'])
          : null,
      year: data['year'],
      keywords: List<String>.from(data['keywords'] ?? []),
      createdAt: DateTime.now());
  }

  /// Conversion en JSON pour stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'duration': duration?.inMinutes,
      'audioStreamUrl': audioStreamUrl,
      'audioDownloadUrl': audioDownloadUrl,
      'pdfUrl': pdfUrl,
      'language': language,
      'series': series,
      'imageUrl': imageUrl,
      'publishedDate': publishedDate?.toIso8601String(),
      'year': year,
      'keywords': keywords,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Création depuis JSON
  factory BranhamSermon.fromJson(Map<String, dynamic> json) {
    return BranhamSermon(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      location: json['location'] ?? '',
      duration: json['duration'] != null 
          ? Duration(minutes: json['duration'] as int)
          : null,
      audioStreamUrl: json['audioStreamUrl'],
      audioDownloadUrl: json['audioDownloadUrl'],
      pdfUrl: json['pdfUrl'],
      language: json['language'] ?? 'FRN',
      series: json['series'],
      imageUrl: json['imageUrl'],
      publishedDate: json['publishedDate'] != null 
          ? DateTime.parse(json['publishedDate'])
          : null,
      year: json['year'],
      keywords: List<String>.from(json['keywords'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']));
  }

  /// Conversion vers le modèle Sermon existant
  Sermon toSermon() {
    return Sermon(
      id: id,
      title: title,
      date: date,
      location: location,
      duration: duration,
      audioUrl: audioStreamUrl ?? audioDownloadUrl,
      transcriptPath: pdfUrl,
      keywords: keywords,
      isFavorite: isFavorite,
      description: 'Prédication de frère Branham du $date à $location',
      year: year,
      series: series,
      createdAt: createdAt);
  }

  /// Copie avec modifications
  BranhamSermon copyWith({
    String? id,
    String? title,
    String? date,
    String? location,
    Duration? duration,
    String? audioStreamUrl,
    String? audioDownloadUrl,
    String? pdfUrl,
    String? language,
    String? series,
    String? imageUrl,
    DateTime? publishedDate,
    DateTime? createdAt,
    bool? isFavorite,
    int? year,
    List<String>? keywords,
  }) {
    return BranhamSermon(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      audioStreamUrl: audioStreamUrl ?? this.audioStreamUrl,
      audioDownloadUrl: audioDownloadUrl ?? this.audioDownloadUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      language: language ?? this.language,
      series: series ?? this.series,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      year: year ?? this.year,
      keywords: keywords ?? this.keywords);
  }

  /// Formatage de la durée
  String get durationFormatted {
    if (duration == null) return '';
    final minutes = duration!.inMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Titre de la série ou "Prédication individuelle"
  String get seriesTitle => series ?? 'Prédication individuelle';

  /// URL de l'image par défaut
  String get defaultImageUrl => 'https://branham.org/azure/branham/6a775f7a-f93c-432d-b613-b19324ee651e.jpg';

  /// Vérifie si la prédication a un audio
  bool get hasAudio => audioStreamUrl != null || audioDownloadUrl != null;

  /// Vérifie si la prédication a un PDF
  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
}
