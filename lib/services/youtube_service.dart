import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  // Clé API YouTube (à remplacer par une vraie clé pour la production)
  // Pour cette implémentation, nous utiliserons des méthodes sans API
  
  /// Extrait l'ID de la vidéo YouTube depuis différents formats d'URL
  static String extractVideoId(String url) {
    if (url.isEmpty) return '';
    
    // Patterns pour différents formats YouTube
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)'),
      RegExp(r'youtube\.com\/embed\/([^&\n?#]+)'),
      RegExp(r'youtube\.com\/v\/([^&\n?#]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }
    
    return '';
  }
  
  /// Extrait l'ID de la playlist YouTube
  static String extractPlaylistId(String url) {
    if (url.isEmpty) return '';
    
    final patterns = [
      RegExp(r'[?&]list=([^&\n?#]+)'),
      RegExp(r'youtube\.com\/playlist\?list=([^&\n?#]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }
    
    return '';
  }
  
  /// Détermine le type de contenu YouTube
  static YouTubeContentType getContentType(String url) {
    if (url.isEmpty) return YouTubeContentType.unknown;
    
    final playlistId = extractPlaylistId(url);
    final videoId = extractVideoId(url);
    
    if (playlistId.isNotEmpty && videoId.isNotEmpty) {
      return YouTubeContentType.videoInPlaylist;
    } else if (playlistId.isNotEmpty) {
      return YouTubeContentType.playlist;
    } else if (videoId.isNotEmpty) {
      return YouTubeContentType.video;
    }
    
    return YouTubeContentType.unknown;
  }
  
  /// Génère l'URL de la miniature pour une vidéo
  static String getVideoThumbnail(String videoId, {YouTubeThumbnailQuality quality = YouTubeThumbnailQuality.maxres}) {
    if (videoId.isEmpty) return '';
    
    String qualityString;
    switch (quality) {
      case YouTubeThumbnailQuality.default_:
        qualityString = 'default';
        break;
      case YouTubeThumbnailQuality.medium:
        qualityString = 'mqdefault';
        break;
      case YouTubeThumbnailQuality.high:
        qualityString = 'hqdefault';
        break;
      case YouTubeThumbnailQuality.standard:
        qualityString = 'sddefault';
        break;
      case YouTubeThumbnailQuality.maxres:
        qualityString = 'maxresdefault';
        break;
    }
    
    return 'https://img.youtube.com/vi/$videoId/$qualityString.jpg';
  }
  
  /// Génère l'URL de la miniature pour une playlist
  static String getPlaylistThumbnail(String playlistId) {
    if (playlistId.isEmpty) return '';
    // YouTube ne fournit pas directement de miniatures de playlist
    // On utilise une image générique ou on pourrait récupérer la première vidéo
    return 'https://img.youtube.com/vi//maxresdefault.jpg'; // Image par défaut
  }
  
  /// Valide si une URL YouTube est correcte
  static bool isValidYouTubeUrl(String url) {
    if (url.isEmpty) return false;
    
    final youtubePatterns = [
      RegExp(r'^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/'),
    ];
    
    return youtubePatterns.any((pattern) => pattern.hasMatch(url));
  }
  
  /// Génère l'URL d'embed pour une vidéo
  static String getEmbedUrl(String videoId, {bool autoplay = false, bool loop = false}) {
    if (videoId.isEmpty) return '';
    
    final params = <String>[];
    if (autoplay) params.add('autoplay=1');
    if (loop) params.add('loop=1&playlist=$videoId');
    
    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    return 'https://www.youtube.com/embed/$videoId$queryString';
  }
  
  /// Génère l'URL d'embed pour une playlist
  static String getPlaylistEmbedUrl(String playlistId, {bool autoplay = false, bool loop = false}) {
    if (playlistId.isEmpty) return '';
    
    final params = <String>['listType=playlist', 'list=$playlistId'];
    if (autoplay) params.add('autoplay=1');
    if (loop) params.add('loop=1');
    
    return 'https://www.youtube.com/embed/videoseries?${params.join('&')}';
  }
  
  /// Extrait les informations basiques d'une URL YouTube
  static YouTubeUrlInfo parseYouTubeUrl(String url) {
    final contentType = getContentType(url);
    final videoId = extractVideoId(url);
    final playlistId = extractPlaylistId(url);
    
    return YouTubeUrlInfo(
      originalUrl: url,
      contentType: contentType,
      videoId: videoId,
      playlistId: playlistId,
      isValid: isValidYouTubeUrl(url),
    );
  }
  
  /// Génère une URL de visualisation standard
  static String getWatchUrl(String videoId, {String? playlistId}) {
    if (videoId.isEmpty) return '';
    
    String url = 'https://www.youtube.com/watch?v=$videoId';
    if (playlistId != null && playlistId.isNotEmpty) {
      url += '&list=$playlistId';
    }
    
    return url;
  }
  
  /// Génère une URL de playlist
  static String getPlaylistUrl(String playlistId) {
    if (playlistId.isEmpty) return '';
    return 'https://www.youtube.com/playlist?list=$playlistId';
  }
}

enum YouTubeContentType {
  unknown,
  video,
  playlist,
  videoInPlaylist,
}

enum YouTubeThumbnailQuality {
  default_,
  medium,
  high,
  standard,
  maxres,
}

class YouTubeUrlInfo {
  final String originalUrl;
  final YouTubeContentType contentType;
  final String videoId;
  final String playlistId;
  final bool isValid;
  
  const YouTubeUrlInfo({
    required this.originalUrl,
    required this.contentType,
    required this.videoId,
    required this.playlistId,
    required this.isValid,
  });
  
  String get displayType {
    switch (contentType) {
      case YouTubeContentType.video:
        return 'Vidéo';
      case YouTubeContentType.playlist:
        return 'Playlist';
      case YouTubeContentType.videoInPlaylist:
        return 'Vidéo dans playlist';
      case YouTubeContentType.unknown:
        return 'Inconnu';
    }
  }
  
  String get thumbnailUrl {
    if (videoId.isNotEmpty) {
      return YouTubeService.getVideoThumbnail(videoId);
    } else if (playlistId.isNotEmpty) {
      return YouTubeService.getPlaylistThumbnail(playlistId);
    }
    return '';
  }
  
  String get embedUrl {
    if (contentType == YouTubeContentType.playlist) {
      return YouTubeService.getPlaylistEmbedUrl(playlistId);
    } else if (videoId.isNotEmpty) {
      return YouTubeService.getEmbedUrl(videoId);
    }
    return '';
  }
  
  String get watchUrl {
    if (contentType == YouTubeContentType.playlist) {
      return YouTubeService.getPlaylistUrl(playlistId);
    } else if (videoId.isNotEmpty) {
      return YouTubeService.getWatchUrl(videoId, playlistId: playlistId.isEmpty ? null : playlistId);
    }
    return originalUrl;
  }
  
  @override
  String toString() {
    return 'YouTubeUrlInfo(type: $displayType, videoId: $videoId, playlistId: $playlistId, valid: $isValid)';
  }
}