/// Modèle pour un verset biblique
class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });
}

/// Modèle pour un livre biblique
class BibleBook {
  final String name;
  final List<List<String>> chapters; // [chapter][verse]

  BibleBook({required this.name, required this.chapters});
}

/// Modèle pour un surlignage avec couleur et style
class BibleHighlight {
  final String verseKey; // format: "book_chapter_verse"
  final String color; // nom de la couleur
  final String style; // style du surlignage
  final DateTime createdAt;

  BibleHighlight({
    required this.verseKey,
    required this.color,
    required this.style,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'verseKey': verseKey,
      'color': color,
      'style': style,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BibleHighlight.fromJson(Map<String, dynamic> json) {
    return BibleHighlight(
      verseKey: json['verseKey'],
      color: json['color'],
      style: json['style'],
      createdAt: DateTime.parse(json['createdAt']));
  }
}

/// Configuration des couleurs et styles de surlignage
class HighlightConfig {
  static const Map<String, Map<String, dynamic>> colors = {
    'yellow': {
      'name': 'Jaune',
      'color': 0xFFFFEB3B,
      'textColor': 0xFF000000,
      'icon': '💛',
    },
    'green': {
      'name': 'Vert',
      'color': 0xFF4CAF50,
      'textColor': 0xFFFFFFFF,
      'icon': '💚',
    },
    'blue': {
      'name': 'Bleu',
      'color': 0xFF2196F3,
      'textColor': 0xFFFFFFFF,
      'icon': '💙',
    },
    'orange': {
      'name': 'Orange',
      'color': 0xFFFF9800,
      'textColor': 0xFF000000,
      'icon': '🧡',
    },
    'purple': {
      'name': 'Violet',
      'color': 0xFF9C27B0,
      'textColor': 0xFFFFFFFF,
      'icon': '💜',
    },
    'red': {
      'name': 'Rouge',
      'color': 0xFFF44336,
      'textColor': 0xFFFFFFFF,
      'icon': '❤️',
    },
  };

  static const Map<String, Map<String, dynamic>> styles = {
    'highlight': {
      'name': 'Surlignage',
      'description': 'Arrière-plan coloré',
      'icon': '🖍️',
    },
    'underline': {
      'name': 'Soulignement',
      'description': 'Ligne sous le texte',
      'icon': '📝',
    },
    'border': {
      'name': 'Encadrement',
      'description': 'Bordure colorée',
      'icon': '📦',
    },
  };
}
