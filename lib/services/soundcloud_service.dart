import 'dart:convert';

/// Types de contenu SoundCloud supportés
enum SoundCloudContentType {
  unknown,
  track,      // Piste audio individuelle
  playlist,   // Playlist/Set
  user,       // Profil utilisateur
}

/// Informations extraites d'une URL SoundCloud
class SoundCloudUrlInfo {
    final String originalUrl;
    final SoundCloudContentType contentType;
    final String userName;
    final String trackSlug;
    final String playlistSlug;
    final bool isValid;

    const SoundCloudUrlInfo({
      required this.originalUrl,
      required this.contentType,
      required this.userName,
      this.trackSlug = '',
      this.playlistSlug = '',
      required this.isValid,
    });

    /// Type d'affichage pour l'interface utilisateur
    String get displayType {
      switch (contentType) {
        case SoundCloudContentType.track:
          return 'Piste Audio';
        case SoundCloudContentType.playlist:
          return 'Playlist';
        case SoundCloudContentType.user:
          return 'Profil Utilisateur';
        case SoundCloudContentType.unknown:
        default:
          return 'URL non reconnue';
      }
    }

    /// URL d'embed SoundCloud
    String get embedUrl {
      if (!isValid) return '';
      
      switch (contentType) {
        case SoundCloudContentType.track:
          return 'https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/${_getTrackId()}&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true';
        case SoundCloudContentType.playlist:
          return 'https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/playlists/${_getPlaylistId()}&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true';
        case SoundCloudContentType.user:
          return 'https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/users/${_getUserId()}&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true';
        default:
          return '';
      }
    }

    /// URL de la page SoundCloud
    String get soundCloudUrl {
      if (!isValid) return originalUrl;
      
      String baseUrl = 'https://soundcloud.com/$userName';
      switch (contentType) {
        case SoundCloudContentType.track:
          return '$baseUrl/$trackSlug';
        case SoundCloudContentType.playlist:
          return '$baseUrl/sets/$playlistSlug';
        case SoundCloudContentType.user:
          return baseUrl;
        default:
          return originalUrl;
      }
    }

    /// URL de l'avatar utilisateur (générique)
    String get avatarUrl {
      return 'https://i1.sndcdn.com/avatars-000001552142-ahvhap-large.jpg'; // Avatar par défaut SoundCloud
    }

    String _getTrackId() => '${userName}_$trackSlug'.hashCode.abs().toString();
    String _getPlaylistId() => '${userName}_$playlistSlug'.hashCode.abs().toString();
    String _getUserId() => userName.hashCode.abs().toString();

    Map<String, dynamic> toMap() {
      return {
        'originalUrl': originalUrl,
        'contentType': contentType.name,
        'userName': userName,
        'trackSlug': trackSlug,
        'playlistSlug': playlistSlug,
        'isValid': isValid,
        'displayType': displayType,
        'embedUrl': embedUrl,
        'soundCloudUrl': soundCloudUrl,
        'avatarUrl': avatarUrl,
      };
    }

    factory SoundCloudUrlInfo.fromMap(Map<String, dynamic> map) {
      SoundCloudContentType contentType = SoundCloudContentType.unknown;
      try {
        contentType = SoundCloudContentType.values.firstWhere(
          (e) => e.name == map['contentType'],
        );
      } catch (e) {
        contentType = SoundCloudContentType.unknown;
      }

      return SoundCloudUrlInfo(
        originalUrl: map['originalUrl'] ?? '',
        contentType: contentType,
        userName: map['userName'] ?? '',
        trackSlug: map['trackSlug'] ?? '',
        playlistSlug: map['playlistSlug'] ?? '',
        isValid: map['isValid'] ?? false,
      );
    }
}

/// Service pour gérer les interactions avec SoundCloud
/// 
/// Fonctionnalités :
/// - Validation des URLs SoundCloud
/// - Extraction des métadonnées
/// - Génération d'URLs d'embed
/// - Support des tracks, playlists et utilisateurs
class SoundCloudService {
  
  // Patterns RegExp pour les différents types d'URLs SoundCloud
  static final RegExp _trackPattern = RegExp(
    r'(?:https?://)?(?:www\.)?soundcloud\.com/([^/]+)/([^/?#&]+)(?:\?.*)?(?:#.*)?$',
    caseSensitive: false,
  );
  
  static final RegExp _playlistPattern = RegExp(
    r'(?:https?://)?(?:www\.)?soundcloud\.com/([^/]+)/sets/([^/?#&]+)(?:\?.*)?(?:#.*)?$',
    caseSensitive: false,
  );
  
  static final RegExp _userPattern = RegExp(
    r'(?:https?://)?(?:www\.)?soundcloud\.com/([^/?#&]+)(?:\?.*)?(?:#.*)?$',
    caseSensitive: false,
  );

  /// Valide si une URL est une URL SoundCloud valide
  static bool isValidSoundCloudUrl(String url) {
    if (url.trim().isEmpty) return false;
    
    // Normalise l'URL
    String normalizedUrl = _normalizeUrl(url);
    
    return _trackPattern.hasMatch(normalizedUrl) ||
           _playlistPattern.hasMatch(normalizedUrl) ||
           _userPattern.hasMatch(normalizedUrl);
  }

  /// Analyse une URL SoundCloud et retourne les informations extraites
  static SoundCloudUrlInfo parseSoundCloudUrl(String url) {
    if (url.trim().isEmpty) {
      return const SoundCloudUrlInfo(
        originalUrl: '',
        contentType: SoundCloudContentType.unknown,
        userName: '',
        isValid: false,
      );
    }

    String normalizedUrl = _normalizeUrl(url);

    // Test pour track
    RegExpMatch? trackMatch = _trackPattern.firstMatch(normalizedUrl);
    if (trackMatch != null) {
      return SoundCloudUrlInfo(
        originalUrl: url,
        contentType: SoundCloudContentType.track,
        userName: trackMatch.group(1)!,
        trackSlug: trackMatch.group(2)!,
        isValid: true,
      );
    }

    // Test pour playlist
    RegExpMatch? playlistMatch = _playlistPattern.firstMatch(normalizedUrl);
    if (playlistMatch != null) {
      return SoundCloudUrlInfo(
        originalUrl: url,
        contentType: SoundCloudContentType.playlist,
        userName: playlistMatch.group(1)!,
        playlistSlug: playlistMatch.group(2)!,
        isValid: true,
      );
    }

    // Test pour utilisateur
    RegExpMatch? userMatch = _userPattern.firstMatch(normalizedUrl);
    if (userMatch != null) {
      // Vérifie que ce n'est pas un autre type d'URL
      String userName = userMatch.group(1)!;
      if (!userName.contains('/') && userName.isNotEmpty) {
        return SoundCloudUrlInfo(
          originalUrl: url,
          contentType: SoundCloudContentType.user,
          userName: userName,
          isValid: true,
        );
      }
    }

    return SoundCloudUrlInfo(
      originalUrl: url,
      contentType: SoundCloudContentType.unknown,
      userName: '',
      isValid: false,
    );
  }

  /// Normalise une URL pour faciliter l'analyse
  static String _normalizeUrl(String url) {
    String normalized = url.trim();
    
    // Ajoute le protocole si manquant
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    
    // Supprime les paramètres de tracking courants
    normalized = normalized.replaceAll(RegExp(r'[?&]utm_[^&]*'), '');
    normalized = normalized.replaceAll(RegExp(r'[?&]si=[^&]*'), '');
    normalized = normalized.replaceAll(RegExp(r'[?&]t=[^&]*'), '');
    
    return normalized;
  }

  /// Détermine le type de contenu d'une URL SoundCloud
  static SoundCloudContentType getContentType(String url) {
    return parseSoundCloudUrl(url).contentType;
  }

  /// Génère une URL d'embed avec options personnalisées
  static String generateEmbedUrl(String url, {
    bool autoPlay = false,
    bool hideRelated = false,
    bool showComments = true,
    bool showUser = true,
    bool showReposts = false,
    bool showTeaser = true,
    bool visual = true,
    String color = 'ff5500',
  }) {
    final info = parseSoundCloudUrl(url);
    if (!info.isValid) return '';

    String apiUrl = '';
    switch (info.contentType) {
      case SoundCloudContentType.track:
        apiUrl = 'https://api.soundcloud.com/tracks/${info._getTrackId()}';
        break;
      case SoundCloudContentType.playlist:
        apiUrl = 'https://api.soundcloud.com/playlists/${info._getPlaylistId()}';
        break;
      case SoundCloudContentType.user:
        apiUrl = 'https://api.soundcloud.com/users/${info._getUserId()}';
        break;
      default:
        return '';
    }

    final encodedUrl = Uri.encodeComponent(apiUrl);
    
    return 'https://w.soundcloud.com/player/?url=$encodedUrl'
        '&color=%23$color'
        '&auto_play=${autoPlay.toString()}'
        '&hide_related=${hideRelated.toString()}'
        '&show_comments=${showComments.toString()}'
        '&show_user=${showUser.toString()}'
        '&show_reposts=${showReposts.toString()}'
        '&show_teaser=${showTeaser.toString()}'
        '&visual=${visual.toString()}';
  }

  /// Exemples d'URLs pour les tests et la documentation
  static const Map<String, Map<String, dynamic>> testUrls = {
    'Track standard': {
      'url': 'https://soundcloud.com/artist-name/track-name',
      'type': 'track',
      'valid': true,
      'description': 'URL standard d\'une piste audio',
    },
    'Track avec paramètres': {
      'url': 'https://soundcloud.com/artist-name/track-name?utm_source=clipboard&utm_medium=text&utm_campaign=social_sharing',
      'type': 'track',
      'valid': true,
      'description': 'URL de piste avec paramètres de tracking',
    },
    'Playlist/Set': {
      'url': 'https://soundcloud.com/artist-name/sets/playlist-name',
      'type': 'playlist',
      'valid': true,
      'description': 'URL d\'une playlist ou d\'un set',
    },
    'Profil utilisateur': {
      'url': 'https://soundcloud.com/artist-name',
      'type': 'user',
      'valid': true,
      'description': 'URL du profil d\'un utilisateur',
    },
    'URL sans protocole': {
      'url': 'soundcloud.com/artist-name/track-name',
      'type': 'track',
      'valid': true,
      'description': 'URL sans protocole HTTP/HTTPS',
    },
    'URL invalide': {
      'url': 'https://spotify.com/track/abc123',
      'type': 'unknown',
      'valid': false,
      'description': 'URL d\'une autre plateforme',
    },
    'URL malformée': {
      'url': 'soundcloud.com/',
      'type': 'unknown',
      'valid': false,
      'description': 'URL SoundCloud incomplète',
    },
  };

  /// Valide une liste d'URLs et retourne un rapport détaillé
  static Map<String, dynamic> validateUrls(List<String> urls) {
    final results = <String, SoundCloudUrlInfo>{};
    int validCount = 0;
    int invalidCount = 0;

    for (String url in urls) {
      final info = parseSoundCloudUrl(url);
      results[url] = info;
      
      if (info.isValid) {
        validCount++;
      } else {
        invalidCount++;
      }
    }

    return {
      'total': urls.length,
      'valid': validCount,
      'invalid': invalidCount,
      'results': results.map((key, value) => MapEntry(key, value.toMap())),
      'summary': {
        'tracks': results.values.where((info) => info.contentType == SoundCloudContentType.track).length,
        'playlists': results.values.where((info) => info.contentType == SoundCloudContentType.playlist).length,
        'users': results.values.where((info) => info.contentType == SoundCloudContentType.user).length,
        'unknown': results.values.where((info) => info.contentType == SoundCloudContentType.unknown).length,
      },
    };
  }

  /// Teste les performances du service avec les URLs d'exemple
  static Map<String, dynamic> performanceTest() {
    final stopwatch = Stopwatch();
    final results = <String, dynamic>{};

    // Test de validation
    stopwatch.start();
    for (int i = 0; i < 1000; i++) {
      isValidSoundCloudUrl('https://soundcloud.com/test-user/test-track');
    }
    stopwatch.stop();
    results['validation_1000_iterations_ms'] = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Test d'analyse
    stopwatch.start();
    for (int i = 0; i < 1000; i++) {
      parseSoundCloudUrl('https://soundcloud.com/test-user/test-track');
    }
    stopwatch.stop();
    results['parsing_1000_iterations_ms'] = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    // Test avec URLs diverses
    final testUrls = SoundCloudService.testUrls.values.map((v) => v['url'] as String).toList();
    stopwatch.start();
    for (String url in testUrls) {
      parseSoundCloudUrl(url);
    }
    stopwatch.stop();
    results['diverse_urls_parsing_ms'] = stopwatch.elapsedMilliseconds;

    results['test_timestamp'] = DateTime.now().toIso8601String();
    return results;
  }
}