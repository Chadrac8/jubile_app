import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../message/models/branham_sermon_model.dart';

/// Service audio avec support de lecture en arrière-plan pour les prédications Branham
class BranhamBackgroundAudioService extends BaseAudioHandler with SeekHandler {
  static final BranhamBackgroundAudioService _instance = BranhamBackgroundAudioService._internal();
  factory BranhamBackgroundAudioService() => _instance;
  BranhamBackgroundAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  BranhamSermon? _currentSermon;
  Duration _lastSavedPosition = Duration.zero;

  // Clés pour SharedPreferences
  static const String _currentSermonIdKey = 'current_sermon_id';
  static const String _currentPositionKey = 'current_position_ms';

  /// Initialiser le service audio en arrière-plan
  static Future<BranhamBackgroundAudioService> init() async {
    return await AudioService.init(
      builder: () => BranhamBackgroundAudioService._instance,
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.jubile.tabernacle.audio',
        androidNotificationChannelName: 'Prédications Branham',
        androidNotificationChannelDescription: 'Lecteur audio pour les prédications de William Branham',
        androidNotificationOngoing: false, 
        androidShowNotificationBadge: true,
        androidNotificationIcon: 'drawable/ic_notification',
        androidNotificationClickStartsActivity: true,
        androidStopForegroundOnPause: true, // Changé à true pour être cohérent avec androidNotificationOngoing: false
        androidResumeOnClick: true,
        fastForwardInterval: const Duration(seconds: 30),
        rewindInterval: const Duration(seconds: 10),
        preloadArtwork: true));
  }

  @override
  Future<void> onTaskRemoved() async {
    // Continuer la lecture même quand l'app est fermée
    // Ne pas arrêter la lecture - garder le service actif
    if (_player.playing) {
      // L'audio continue à jouer en arrière-plan
      return;
    }
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Ne pas arrêter quand la notification est supprimée
    // Garder le service audio actif
  }

  /// Lire une prédication
  Future<void> playSermon(BranhamSermon sermon) async {
    try {
      // Si c'est la même prédication, juste reprendre la lecture
      if (_currentSermon?.id == sermon.id && _player.audioSource != null) {
        await play();
        return;
      }

      // Nouvelle prédication
      _currentSermon = sermon;
      
      final url = sermon.audioStreamUrl ?? sermon.audioDownloadUrl;
      if (url == null || url.isEmpty) {
        throw Exception('Aucune URL audio disponible pour cette prédication');
      }

      // Créer les métadonnées pour la notification
      final mediaItem = MediaItem(
        id: sermon.id,
        album: "Prédications de William Branham",
        title: sermon.title,
        artist: "William Marrion Branham",
        duration: sermon.duration,
        artUri: sermon.imageUrl != null 
            ? Uri.parse(sermon.imageUrl!) 
            : null,
        genre: sermon.series,
        extras: {
          'date': sermon.date,
          'location': sermon.location,
          'language': sermon.language,
        });

      // Définir l'élément média actuel
      this.mediaItem.add(mediaItem);

      // Configurer le lecteur audio
      await _player.setUrl(url);
      
      // Charger la position sauvegardée pour cette prédication
      _lastSavedPosition = await _loadSavedPosition(sermon.id);
      
      // Écouter les changements d'état du lecteur
      _listenToPlayerState();
      
      // Aller à la position sauvegardée si elle existe
      if (_lastSavedPosition > Duration.zero) {
        await _player.seek(_lastSavedPosition);
      }
      
      // Démarrer la lecture
      await _player.play();
      
    } catch (e) {
      // Signaler l'erreur
      playbackState.add(playbackState.value.copyWith(
        controls: [MediaControl.play],
        systemActions: const {MediaAction.seek},
        processingState: AudioProcessingState.error,
        errorMessage: 'Erreur de lecture: $e'));
      rethrow;
    }
  }

  /// Écouter les changements d'état du lecteur
  void _listenToPlayerState() {
    // État de lecture
    _player.playingStream.listen((playing) {
      if (!playing) {
        // Sauvegarder la position quand la lecture s'arrête
        _lastSavedPosition = _player.position;
        _savePosition();
      }
      _updatePlaybackState();
    });

    // Position actuelle - sauvegarder toutes les 10 secondes
    _player.positionStream.listen((position) {
      _lastSavedPosition = position;
      // Sauvegarder la position toutes les 10 secondes pour éviter les pertes
      if (position.inSeconds % 10 == 0) {
        _savePosition();
      }
      _updatePlaybackState();
    });

    // Durée totale
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
      _updatePlaybackState();
    });

    // État du processus
    _player.processingStateStream.listen((state) {
      _updatePlaybackState();
    });
  }

  /// Mettre à jour l'état de lecture
  void _updatePlaybackState() {
    final playing = _player.playing;
    final processingState = _player.processingState;
    final position = _player.position;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.playPause,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.fastForward,
        MediaAction.rewind,
      },
      androidCompactActionIndices: const [1, 2, 3], // rewind, play/pause, fastForward
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[processingState]!,
      playing: playing,
      updatePosition: position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0));
  }

  @override
  Future<void> play() async {
    print('🎵 BranhamBackgroundAudioService.play() called');
    print('🎵 Current state - playing: ${_player.playing}, position: ${_player.position}');
    // Si on reprend la lecture et qu'une position était sauvegardée, la restaurer
    if (_lastSavedPosition > Duration.zero && _player.position != _lastSavedPosition) {
      print('🎵 Restoring saved position: $_lastSavedPosition');
      await _player.seek(_lastSavedPosition);
    }
    await _player.play();
    print('🎵 Play command sent to AudioPlayer');
  }

  @override
  Future<void> pause() async {
    print('🎵 BranhamBackgroundAudioService.pause() called');
    // Sauvegarder la position actuelle avant de mettre en pause
    _lastSavedPosition = _player.position;
    print('🎵 Saving position: $_lastSavedPosition');
    await _savePosition();
    await _player.pause();
    print('🎵 Pause command sent to AudioPlayer');
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _lastSavedPosition = position;
    await _savePosition();
  }

  /// Sauvegarder la position actuelle dans SharedPreferences
  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentSermon != null) {
        await prefs.setString(_currentSermonIdKey, _currentSermon!.id);
        await prefs.setInt(_currentPositionKey, _lastSavedPosition.inMilliseconds);
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de la position: $e');
    }
  }

  /// Restaurer la position sauvegardée depuis SharedPreferences
  Future<Duration> _loadSavedPosition(String sermonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSermonId = prefs.getString(_currentSermonIdKey);
      if (savedSermonId == sermonId) {
        final positionMs = prefs.getInt(_currentPositionKey) ?? 0;
        return Duration(milliseconds: positionMs);
      }
    } catch (e) {
      print('Erreur lors du chargement de la position: $e');
    }
    return Duration.zero;
  }

  @override
  Future<void> stop() async {
    // Nettoyer la position sauvegardée quand on arrête complètement
    await _clearSavedPosition();
    await _player.stop();
    await super.stop();
  }

  /// Nettoyer la position sauvegardée
  Future<void> _clearSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentSermonIdKey);
      await prefs.remove(_currentPositionKey);
      _lastSavedPosition = Duration.zero;
    } catch (e) {
      print('Erreur lors du nettoyage de la position: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    // TODO: Implémenter la lecture de la prédication suivante
    // Pour l'instant, on ne fait rien
  }

  @override
  Future<void> skipToPrevious() async {
    // TODO: Implémenter la lecture de la prédication précédente
    // Pour l'instant, on ne fait rien
  }

  @override
  Future<void> fastForward() async {
    await seek(_player.position + const Duration(seconds: 30));
  }

  @override
  Future<void> rewind() async {
    await seek(_player.position - const Duration(seconds: 10));
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Obtenir les streams du lecteur
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get speedStream => _player.speedStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  /// Obtenir la prédication actuelle
  BranhamSermon? get currentSermon => _currentSermon;

  /// Obtenir la position actuelle
  Duration get position => _player.position;

  /// Obtenir la durée totale
  Duration? get duration => _player.duration;

  /// Vérifier si en cours de lecture
  bool get playing => _player.playing;

  /// Obtenir la vitesse de lecture
  double get speed => _player.speed;

  /// Libérer les ressources
  Future<void> dispose() async {
    await _player.dispose();
    await super.stop();
  }
}
