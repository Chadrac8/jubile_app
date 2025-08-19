import '../../models/sermon_model.dart';

/// Service pour gérer la lecture audio des prédications
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  List<Sermon>? _cachedSermons;
  Sermon? _currentSermon;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;

  /// Récupère toutes les prédications disponibles
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

  /// Lance la lecture d'une prédication
  Future<void> playSermon(Sermon sermon) async {
    try {
      _currentSermon = sermon;
      _isPlaying = true;
      
      // TODO: Implémenter la lecture audio réelle
      // await _audioPlayer.setUrl(sermon.audioUrl);
      // await _audioPlayer.play();
      
      // Simulation pour la démo
      _totalDuration = sermon.duration ?? const Duration(minutes: 45);
      _currentPosition = Duration.zero;
      
    } catch (e) {
      throw Exception('Erreur lors de la lecture: $e');
    }
  }

  /// Met en pause la lecture
  Future<void> pause() async {
    _isPlaying = false;
    // TODO: await _audioPlayer.pause();
  }

  /// Reprend la lecture
  Future<void> resume() async {
    _isPlaying = true;
    // TODO: await _audioPlayer.play();
  }

  /// Arrête la lecture
  Future<void> stop() async {
    _isPlaying = false;
    _currentPosition = Duration.zero;
    // TODO: await _audioPlayer.stop();
  }

  /// Se déplace à une position spécifique
  Future<void> seek(Duration position) async {
    _currentPosition = position;
    // TODO: await _audioPlayer.seek(position);
  }

  /// Définit la vitesse de lecture
  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    // TODO: await _audioPlayer.setSpeed(speed);
  }

  /// Recherche des prédications
  Future<List<Sermon>> searchSermons(String query) async {
    final sermons = await getAllSermons();
    final lowercaseQuery = query.toLowerCase();

    return sermons.where((sermon) =>
        sermon.title.toLowerCase().contains(lowercaseQuery) ||
        sermon.date.toLowerCase().contains(lowercaseQuery) ||
        (sermon.location?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        sermon.keywords.any((k) => k.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Récupère les prédications par année
  Future<List<Sermon>> getSermonsByYear(int year) async {
    final sermons = await getAllSermons();
    return sermons.where((s) => s.year == year).toList();
  }

  /// Récupère les prédications favorites
  Future<List<Sermon>> getFavoriteSermons() async {
    final sermons = await getAllSermons();
    return sermons.where((s) => s.isFavorite).toList();
  }

  /// Met à jour le statut favori d'une prédication
  Future<void> toggleFavorite(String sermonId) async {
    final sermons = await getAllSermons();
    final index = sermons.indexWhere((s) => s.id == sermonId);
    
    if (index != -1) {
      _cachedSermons![index] = sermons[index].copyWith(
        isFavorite: !sermons[index].isFavorite);
    }
  }

  /// Getters pour l'état actuel
  Sermon? get currentSermon => _currentSermon;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;

  /// Génère des données de démonstration
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
        description: 'Une prédication puissante sur la foi authentique.',
        createdAt: DateTime.now()),
      Sermon(
        id: '2',
        title: 'Les Noces de l\'Agneau',
        date: '21 Décembre 1965',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 1, minutes: 45),
        year: 1965,
        keywords: ['épouse', 'agneau', 'mariage'],
        description: 'Message sur l\'Épouse de Christ.',
        createdAt: DateTime.now()),
      Sermon(
        id: '3',
        title: 'La Parole parlée',
        date: '26 Décembre 1965',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 1, minutes: 30),
        year: 1965,
        keywords: ['parole', 'création', 'dieu'],
        description: 'La puissance créatrice de la Parole de Dieu.',
        isFavorite: true,
        createdAt: DateTime.now()),
      Sermon(
        id: '4',
        title: 'Avoir Foi en Dieu',
        date: '27 Novembre 1955',
        location: 'Shreveport, Louisiana',
        duration: const Duration(hours: 1, minutes: 20),
        year: 1955,
        keywords: ['foi', 'confiance', 'miracles'],
        description: 'Comment développer une foi authentique.',
        createdAt: DateTime.now()),
      Sermon(
        id: '5',
        title: 'L\'Âge de l\'Église de Laodicée',
        date: '11 Décembre 1960',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 2, minutes: 30),
        year: 1960,
        series: 'Les Sept Âges de l\'Église',
        keywords: ['laodicée', 'église', 'âge'],
        description: 'Étude prophétique du dernier âge de l\'église.',
        createdAt: DateTime.now()),
      Sermon(
        id: '6',
        title: 'Questions et Réponses',
        date: '30 Août 1964',
        location: 'Branham Tabernacle, Jeffersonville, Indiana',
        duration: const Duration(hours: 1, minutes: 50),
        year: 1964,
        keywords: ['questions', 'réponses', 'doctrine'],
        description: 'Réponses aux questions doctrinales.',
        createdAt: DateTime.now()),
      Sermon(
        id: '7',
        title: 'La Guérison Divine',
        date: '22 Mai 1954',
        location: 'Louisville, Kentucky',
        duration: const Duration(minutes: 55),
        year: 1954,
        keywords: ['guérison', 'divine', 'miracles'],
        description: 'Les principes de la guérison divine.',
        isFavorite: true,
        createdAt: DateTime.now()),
      Sermon(
        id: '8',
        title: 'L\'Esprit de Vérité',
        date: '18 Janvier 1963',
        location: 'Phoenix, Arizona',
        duration: const Duration(hours: 1, minutes: 40),
        year: 1963,
        keywords: ['esprit', 'vérité', 'saint-esprit'],
        description: 'Le rôle du Saint-Esprit dans la révélation.',
        createdAt: DateTime.now()),
    ];
  }

  /// Vide le cache (utile pour les tests ou le refresh)
  void clearCache() {
    _cachedSermons = null;
  }
}
