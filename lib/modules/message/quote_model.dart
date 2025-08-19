/// Modèle pour une citation de William Marrion Branham
class Quote {
  final String id;
  final String text;
  final String theme;
  final String reference;
  final String? date;
  final String? sermonTitle;
  final String? location;
  final List<String> keywords;
  final bool isFavorite;
  final DateTime createdAt;

  const Quote({
    required this.id,
    required this.text,
    required this.theme,
    required this.reference,
    this.date,
    this.sermonTitle,
    this.location,
    this.keywords = const [],
    this.isFavorite = false,
    required this.createdAt,
  });

  /// Création depuis JSON
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      text: json['text'] as String,
      theme: json['theme'] as String,
      reference: json['reference'] as String,
      date: json['date'] as String?,
      sermonTitle: json['sermonTitle'] as String?,
      location: json['location'] as String?,
      keywords: List<String>.from(json['keywords'] ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String));
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'theme': theme,
      'reference': reference,
      'date': date,
      'sermonTitle': sermonTitle,
      'location': location,
      'keywords': keywords,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copie avec modifications
  Quote copyWith({
    String? id,
    String? text,
    String? theme,
    String? reference,
    String? date,
    String? sermonTitle,
    String? location,
    List<String>? keywords,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      theme: theme ?? this.theme,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      sermonTitle: sermonTitle ?? this.sermonTitle,
      location: location ?? this.location,
      keywords: keywords ?? this.keywords,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quote &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Quote{id: $id, theme: $theme, text: ${text.substring(0, 50)}...}';
  }
}
