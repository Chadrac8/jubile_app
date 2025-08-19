import 'package:flutter/material.dart';
import '../../models/sermon_model.dart';

/// Service pour gérer la lecture des prédications
class ReadingService {
  static final ReadingService _instance = ReadingService._internal();
  factory ReadingService() => _instance;
  ReadingService._internal();

  List<Sermon>? _cachedSermons;
  
  /// Récupère toutes les prédications pour la lecture
  Future<List<Sermon>> getAllSermons() async {
    if (_cachedSermons != null) {
      return _cachedSermons!;
    }

    try {
      // Pour l'instant, on utilise des données de démonstration
      _cachedSermons = _generateDemoSermons();
      return _cachedSermons!;
    } catch (e) {
      throw Exception('Erreur lors du chargement des prédications: $e');
    }
  }

  /// Recherche dans le contenu des prédications
  Future<List<Sermon>> searchInContent(String query) async {
    final sermons = await getAllSermons();
    final lowercaseQuery = query.toLowerCase();

    return sermons.where((sermon) =>
        sermon.title.toLowerCase().contains(lowercaseQuery) ||
        sermon.date.toLowerCase().contains(lowercaseQuery) ||
        (sermon.location?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        (sermon.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        sermon.keywords.any((k) => k.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Récupère le contenu complet d'une prédication
  Future<String> getSermonContent(String sermonId) async {
    // TODO: Charger le contenu réel depuis un fichier ou une API
    return '''
Mes chers frères et sœurs, permettez-moi de vous dire ce soir que nous vivons dans l'heure la plus glorieuse que l'Église ait jamais connue.

La Bible nous dit que "la foi qui a été transmise aux saints une fois pour toutes". Cette foi n'est pas quelque chose de nouveau, c'est la même foi qui était dans le cœur d'Abel quand il a offert à Dieu un sacrifice plus excellent que celui de Caïn.

[Contenu complet de la prédication...]
''';
  }

  /// Sauvegarde une note personnelle
  Future<void> saveNote(String sermonId, String note, int? position) async {
    // TODO: Implémenter la sauvegarde des notes
  }

  /// Récupère les notes d'une prédication
  Future<List<Map<String, dynamic>>> getNotes(String sermonId) async {
    // TODO: Implémenter la récupération des notes
    return [];
  }

  /// Sauvegarde un surlignage
  Future<void> saveHighlight(String sermonId, int startPosition, int endPosition, Color color) async {
    // TODO: Implémenter la sauvegarde des surlignages
  }

  /// Récupère les surlignages d'une prédication
  Future<List<Map<String, dynamic>>> getHighlights(String sermonId) async {
    // TODO: Implémenter la récupération des surlignages
    return [];
  }

  /// Marque une position de lecture
  Future<void> saveBookmark(String sermonId, int position, String? note) async {
    // TODO: Implémenter la sauvegarde des marque-pages
  }

  /// Récupère les marque-pages d'une prédication
  Future<List<Map<String, dynamic>>> getBookmarks(String sermonId) async {
    // TODO: Implémenter la récupération des marque-pages
    return [];
  }

  /// Génère des données de démonstration étendues
  List<Sermon> _generateDemoSermons() {
    return [
      Sermon(
        id: '1',
        title: 'La Foi qui était une fois donnée aux Saints',
        date: '14 Juillet 1963',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 2, minutes: 15),
        year: 1963,
        keywords: ['foi', 'saints', 'révélation'],
        description: 'Une prédication puissante sur la foi authentique et la révélation divine dans les derniers jours.',
        createdAt: DateTime.now()),
      Sermon(
        id: '2',
        title: 'Les Noces de l\'Agneau',
        date: '21 Décembre 1965',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 1, minutes: 45),
        year: 1965,
        keywords: ['épouse', 'agneau', 'mariage'],
        description: 'Message prophétique sur l\'Épouse de Christ et les préparatifs pour les noces éternelles.',
        isFavorite: true,
        createdAt: DateTime.now()),
      Sermon(
        id: '3',
        title: 'La Parole parlée',
        date: '26 Décembre 1965',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 1, minutes: 30),
        year: 1965,
        keywords: ['parole', 'création', 'dieu'],
        description: 'Enseignement sur la puissance créatrice de la Parole de Dieu manifestée dans la création.',
        createdAt: DateTime.now()),
      Sermon(
        id: '4',
        title: 'Avoir Foi en Dieu',
        date: '27 Novembre 1955',
        location: 'Shreveport, Louisiana',
        duration: const Duration(hours: 1, minutes: 20),
        year: 1955,
        keywords: ['foi', 'confiance', 'miracles'],
        description: 'Instructions pratiques sur comment développer et maintenir une foi authentique en Dieu.',
        createdAt: DateTime.now()),
      Sermon(
        id: '5',
        title: 'L\'Âge de l\'Église de Laodicée',
        date: '11 Décembre 1960',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 2, minutes: 30),
        year: 1960,
        series: 'Les Sept Âges de l\'Église',
        keywords: ['laodicée', 'église', 'âge', 'prophétie'],
        description: 'Étude prophétique approfondie du septième et dernier âge de l\'église selon Apocalypse.',
        createdAt: DateTime.now()),
      Sermon(
        id: '6',
        title: 'Questions et Réponses',
        date: '30 Août 1964',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 1, minutes: 50),
        year: 1964,
        keywords: ['questions', 'réponses', 'doctrine', 'enseignement'],
        description: 'Session de questions-réponses abordant diverses questions doctrinales et pratiques.',
        isFavorite: true,
        createdAt: DateTime.now()),
      Sermon(
        id: '7',
        title: 'La Guérison Divine',
        date: '22 Mai 1954',
        location: 'Louisville, Kentucky',
        duration: const Duration(minutes: 55),
        year: 1954,
        keywords: ['guérison', 'divine', 'miracles', 'foi'],
        description: 'Enseignement fondamental sur les principes bibliques de la guérison divine.',
        createdAt: DateTime.now()),
      Sermon(
        id: '8',
        title: 'L\'Esprit de Vérité',
        date: '18 Janvier 1963',
        location: 'Phoenix, Arizona',
        duration: const Duration(hours: 1, minutes: 40),
        year: 1963,
        keywords: ['esprit', 'vérité', 'saint-esprit', 'révélation'],
        description: 'Message sur le rôle crucial du Saint-Esprit dans la révélation de la vérité divine.',
        createdAt: DateTime.now()),
      Sermon(
        id: '9',
        title: 'Christ est révélé dans Sa propre Parole',
        date: '22 Août 1965',
        location: 'Jeffersonville, Indiana',
        duration: const Duration(hours: 2, minutes: 10),
        year: 1965,
        keywords: ['christ', 'révélation', 'parole', 'logos'],
        description: 'Révélation profonde de Christ comme Logos éternel manifesté dans les Écritures.',
        createdAt: DateTime.now()),
      Sermon(
        id: '10',
        title: 'Le Septième Sceau',
        date: '24 Mars 1963',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 1, minutes: 55),
        year: 1963,
        series: 'Les Sept Sceaux',
        keywords: ['sceau', 'apocalypse', 'mystère', 'révélation'],
        description: 'Révélation du mystère du septième sceau selon le livre de l\'Apocalypse.',
        isFavorite: true,
        createdAt: DateTime.now()),
    ];
  }

  /// Vide le cache
  void clearCache() {
    _cachedSermons = null;
  }
}
