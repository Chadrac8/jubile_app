class BranhamQuote {
  final String text;
  final String reference;
  final String category;
  final DateTime date;
  final String? dailyBread;
  final String? dailyBreadReference;
  final bool isFavorite;

  BranhamQuote({
    required this.text,
    required this.reference,
    required this.category,
    required this.date,
    this.dailyBread,
    this.dailyBreadReference,
    this.isFavorite = false,
  });

  factory BranhamQuote.fromJson(Map<String, dynamic> json) {
    return BranhamQuote(
      text: json['text'] ?? '',
      reference: json['reference'] ?? '',
      category: json['category'] ?? 'Général',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      dailyBread: json['dailyBread'],
      dailyBreadReference: json['dailyBreadReference'],
      isFavorite: json['isFavorite'] ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'reference': reference,
      'category': category,
      'date': date.toIso8601String(),
      'dailyBread': dailyBread,
      'dailyBreadReference': dailyBreadReference,
      'isFavorite': isFavorite,
    };
  }

  BranhamQuote copyWith({
    String? text,
    String? reference,
    String? category,
    DateTime? date,
    String? dailyBread,
    String? dailyBreadReference,
    bool? isFavorite,
  }) {
    return BranhamQuote(
      text: text ?? this.text,
      reference: reference ?? this.reference,
      category: category ?? this.category,
      date: date ?? this.date,
      dailyBread: dailyBread ?? this.dailyBread,
      dailyBreadReference: dailyBreadReference ?? this.dailyBreadReference,
      isFavorite: isFavorite ?? this.isFavorite);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BranhamQuote &&
        other.text == text &&
        other.reference == reference;
  }

  @override
  int get hashCode => text.hashCode ^ reference.hashCode;

  @override
  String toString() {
    return 'BranhamQuote(text: $text, reference: $reference, category: $category)';
  }
}
