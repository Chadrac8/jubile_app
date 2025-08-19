import 'package:just_audio/just_audio.dart';
import '../../models/branham_sermon_model.dart';


/// Service audio Flutter pour les prédications de Branham
class BranhamAudioPlayerService {
  static final BranhamAudioPlayerService _instance = BranhamAudioPlayerService._internal();
  factory BranhamAudioPlayerService() => _instance;
  BranhamAudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Streams pour l'état du lecteur
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get speedStream => _player.speedStream;

  Future<void> playSermon(BranhamSermon sermon) async {
    final url = sermon.audioStreamUrl ?? sermon.audioDownloadUrl;
    if (url == null || url.isEmpty) throw Exception('Aucune URL audio disponible');
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);
  Future<void> setSpeed(double speed) async => await _player.setSpeed(speed);
  Future<void> dispose() async => await _player.dispose();

  Future<void> resume() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }
}
