/// Modèle pour une prédication de William Marrion Branham
class Sermon {
  final String id;
  final String title;
  final String date;
  final String? location;
  final Duration? duration;
  final String? audioUrl;
  final String? transcriptPath;
  final List<String> keywords;
  final bool isFavorite;
  final String? description;
  final int? year;
  final String? series;
  final DateTime createdAt;

  const Sermon({
    required this.id,
    required this.title,
    required this.date,
    this.location,
    this.duration,
    this.audioUrl,
    this.transcriptPath,
    this.keywords = const [],
    this.isFavorite = false,
    this.description,
    this.year,
    this.series,
    required this.createdAt,
  });

  /// Création depuis JSON
  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      location: json['location'] as String?,
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      audioUrl: json['audioUrl'] as String?,
      transcriptPath: json['transcriptPath'] as String?,
      keywords: List<String>.from(json['keywords'] ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
      description: json['description'] as String?,
      year: json['year'] as int?,
      series: json['series'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String));
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'duration': duration?.inMilliseconds,
      'audioUrl': audioUrl,
      'transcriptPath': transcriptPath,
      'keywords': keywords,
      'isFavorite': isFavorite,
      'description': description,
      'year': year,
      'series': series,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copie avec modifications
  Sermon copyWith({
    String? id,
    String? title,
    String? date,
    String? location,
    Duration? duration,
    String? audioUrl,
    String? transcriptPath,
    List<String>? keywords,
    bool? isFavorite,
    String? description,
    int? year,
    String? series,
    DateTime? createdAt,
  }) {
    return Sermon(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      transcriptPath: transcriptPath ?? this.transcriptPath,
      keywords: keywords ?? this.keywords,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      year: year ?? this.year,
      series: series ?? this.series,
      createdAt: createdAt ?? this.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sermon &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Sermon{id: $id, title: $title, date: $date}';
  }
}
