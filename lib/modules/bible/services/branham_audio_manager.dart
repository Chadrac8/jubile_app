import 'package:audio_service/audio_service.dart';
import 'branham_background_audio_service.dart';
import '../../message/models/branham_sermon_model.dart';

/// Gestionnaire pour le service audio en arrière-plan des prédications Branham
class BranhamAudioManager {
  static final BranhamAudioManager _instance = BranhamAudioManager._internal();
  factory BranhamAudioManager() => _instance;
  BranhamAudioManager._internal();

  BranhamBackgroundAudioService? _audioService;
  bool _isInitialized = false;

  /// Initialiser le service audio
  Future<void> initialize() async {
    print('🎵 BranhamAudioManager.initialize() called - already initialized: $_isInitialized');
    if (_isInitialized) return;

    try {
      print('🎵 Calling BranhamBackgroundAudioService.init()...');
      _audioService = await BranhamBackgroundAudioService.init();
      _isInitialized = true;
      print('🎵 BranhamAudioManager initialized successfully');
    } catch (e) {
      print('🎵 ❌ Erreur lors de l\'initialisation du service audio: $e');
      rethrow;
    }
  }

  /// Vérifier si le service est initialisé
  bool get isInitialized => _isInitialized && _audioService != null;

  /// Obtenir le service audio (throws si non initialisé)
  BranhamBackgroundAudioService get audioService {
    if (!isInitialized) {
      throw StateError('Le service audio n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _audioService!;
  }

  /// Lire une prédication avec support arrière-plan
  Future<void> playSermon(BranhamSermon sermon) async {
    print('🎵 BranhamAudioManager.playSermon() called - isInitialized: $isInitialized');
    if (!isInitialized) {
      print('🎵 Audio service not initialized, initializing now...');
      await initialize();
    }
    
    print('🎵 Calling audioService.playSermon() with: ${sermon.title}');
    await audioService.playSermon(sermon);
  }

  /// Mettre en pause
  Future<void> pause() async {
    print('🎵 BranhamAudioManager.pause() called - isInitialized: $isInitialized');
    if (isInitialized) {
      await audioService.pause();
    } else {
      print('🎵 AudioService not initialized!');
    }
  }

  /// Reprendre la lecture
  Future<void> play() async {
    print('🎵 BranhamAudioManager.play() called - isInitialized: $isInitialized');
    if (isInitialized) {
      await audioService.play();
    } else {
      print('🎵 AudioService not initialized!');
    }
  }

  /// Arrêter la lecture
  Future<void> stop() async {
    if (isInitialized) {
      await audioService.stop();
    }
  }

  /// Aller à une position spécifique
  Future<void> seek(Duration position) async {
    if (isInitialized) {
      await audioService.seek(position);
    }
  }

  /// Changer la vitesse de lecture
  Future<void> setSpeed(double speed) async {
    if (isInitialized) {
      await audioService.setSpeed(speed);
    }
  }

  /// Avancer de 30 secondes
  Future<void> fastForward() async {
    print('🎵 BranhamAudioManager.fastForward() called - isInitialized: $isInitialized');
    if (isInitialized) {
      await audioService.fastForward();
    } else {
      print('🎵 AudioService not initialized!');
    }
  }

  /// Reculer de 10 secondes
  Future<void> rewind() async {
    print('🎵 BranhamAudioManager.rewind() called - isInitialized: $isInitialized');
    if (isInitialized) {
      await audioService.rewind();
    } else {
      print('🎵 AudioService not initialized!');
    }
  }

  /// Streams pour l'interface utilisateur
  Stream<Duration> get positionStream => 
      isInitialized ? audioService.positionStream : Stream.value(Duration.zero);

  Stream<Duration?> get durationStream => 
      isInitialized ? audioService.durationStream : Stream.value(null);

  Stream<bool> get playingStream => 
      isInitialized ? audioService.playingStream : Stream.value(false);

  Stream<double> get speedStream => 
      isInitialized ? audioService.speedStream : Stream.value(1.0);

  Stream<PlaybackState> get playbackStateStream => 
      isInitialized ? AudioService.playbackStateStream : Stream.value(PlaybackState());

  Stream<MediaItem?> get mediaItemStream => 
      isInitialized ? audioService.mediaItem : Stream.value(null);

  /// Obtenir la prédication actuelle
  BranhamSermon? get currentSermon => 
      isInitialized ? audioService.currentSermon : null;

  /// Obtenir la position actuelle
  Duration get position => 
      isInitialized ? audioService.position : Duration.zero;

  /// Obtenir la durée totale
  Duration? get duration => 
      isInitialized ? audioService.duration : null;

  /// Vérifier si en cours de lecture
  bool get playing => 
      isInitialized ? audioService.playing : false;

  /// Obtenir la vitesse de lecture
  double get speed => 
      isInitialized ? audioService.speed : 1.0;

  /// Libérer les ressources
  Future<void> dispose() async {
    if (isInitialized) {
      await audioService.dispose();
      _isInitialized = false;
      _audioService = null;
    }
  }
}
