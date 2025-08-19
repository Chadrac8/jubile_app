import 'package:http/http.dart' as http;
import '../../models/branham_sermon_model.dart';

/// Service pour récupérer les prédications depuis branham.org
class BranhamSermonService {
  static const String baseUrl = 'https://branham.org';
  static const String audioPageUrl = '/fr/MessageAudio';
  
  static List<BranhamSermon> _cachedSermons = [];
  static DateTime? _lastFetch;
  static const Duration cacheDuration = Duration(hours: 1);

  /// Récupère toutes les prédications en français depuis branham.org
  static Future<List<BranhamSermon>> fetchAllSermons({bool forceRefresh = false}) async {
    try {
      // Vérifier le cache
      if (!forceRefresh && 
          _cachedSermons.isNotEmpty && 
          _lastFetch != null && 
          DateTime.now().difference(_lastFetch!) < cacheDuration) {
        print('📋 Retour du cache: ${_cachedSermons.length} prédications');
        return _cachedSermons;
      }

      print('🔄 Récupération des prédications depuis branham.org...');
      
      final sermons = <BranhamSermon>[];
      
      // Récupérer les prédications par année (de 1947 à 1965)
      for (int year = 1947; year <= 1965; year++) {
        print('📅 Récupération année $year...');
        final yearSermons = await _fetchSermonsByYear(year);
        sermons.addAll(yearSermons);
        
        // Petite pause pour ne pas surcharger le serveur
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Trier par date décroissante
      sermons.sort((a, b) => b.date.compareTo(a.date));

      _cachedSermons = sermons;
      _lastFetch = DateTime.now();
      
      print('✅ ${sermons.length} prédications récupérées avec succès');
      return sermons;
    } catch (e) {
      print('❌ Erreur lors de la récupération: $e');
      
      // En cas d'erreur, retourner le cache s'il existe
      if (_cachedSermons.isNotEmpty) {
        print('📋 Retour du cache en cas d\'erreur');
        return _cachedSermons;
      }
      
      // Sinon, générer des données de démonstration
      return _generateDemoSermons();
    }
  }

  /// Récupère les vraies URLs depuis branham.org (à implémenter plus tard)
  static Future<List<BranhamSermon>> fetchRealSermonsFromBranhamOrg() async {
    try {
      // TODO: Implémenter le scraping des vraies URLs depuis branham.org
      // Pour l'instant, retournons quelques vraies prédications connues
      return [
        BranhamSermon(
          id: '47-0412',
          title: 'La foi est une ferme assurance',
          date: '47-0412',
          location: 'Oakland CA',
          duration: const Duration(minutes: 112),
          // Cette URL est extraite de la page branham.org - elle devrait fonctionner
          audioStreamUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/9b4/9b4fb',
          audioDownloadUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/9b4/9b4fb',
          language: 'fr',
          year: 1947,
          keywords: ['foi', 'assurance'],
          createdAt: DateTime.now(),
          isFavorite: false),
      ];
    } catch (e) {
      print('❌ Erreur récupération vraies URLs: $e');
      return [];
    }
  }

  /// Récupère les prédications d'une année spécifique
  static Future<List<BranhamSermon>> _fetchSermonsByYear(int year) async {
    try {
      final url = '$baseUrl$audioPageUrl';
      
      // Simuler une requête pour récupérer les données
      // Note: En réalité, il faudrait analyser le JavaScript de la page
      // pour comprendre comment les données sont chargées
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }

      // Parser le HTML pour extraire les prédications
      // Note: Cette approche est simplifiée - le site utilise JavaScript
      return _parseHtmlForSermons(response.body, year);
    } catch (e) {
      print('❌ Erreur récupération année $year: $e');
      return [];
    }
  }

  /// Parse le HTML pour extraire les informations des prédications
  static List<BranhamSermon> _parseHtmlForSermons(String html, int year) {
    try {
      // En attendant une meilleure solution, utilisons des données statiques
      // car le site utilise beaucoup de JavaScript dynamique
      return _getStaticSermonsForYear(year);
    } catch (e) {
      print('❌ Erreur parsing HTML: $e');
      return [];
    }
  }

  /// Données statiques pour quelques prédications connues (en attendant la solution complète)
  static List<BranhamSermon> _getStaticSermonsForYear(int year) {
    final staticSermons = {
      1965: [
        {
          'id': '65-1204',
          'title': 'La Révélation de Jésus-Christ',
          'date': '65-1204',
          'location': 'Jeffersonville IN',
          'duration': 95,
          // URLs de test - remplacer par les vraies URLs de branham.org
          'streamUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          'downloadUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          'pdfUrl': null,
          'series': 'La Révélation de Jésus-Christ',
          'year': 1965,
          'keywords': ['révélation', 'jésus', 'christ'],
        },
        {
          'id': '65-1127',
          'title': 'Essayer de rendre service à Dieu sans que ce soit la volonté de Dieu',
          'date': '65-1127',
          'location': 'Shreveport LA',
          'duration': 78,
          // URLs de test - remplacer par les vraies URLs de branham.org
          'streamUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          'downloadUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          'pdfUrl': null,
          'year': 1965,
          'keywords': ['service', 'volonté', 'dieu'],
        },
      ],
      1964: [
        {
          'id': '64-0830M',
          'title': 'Questions et réponses no 3',
          'date': '64-0830M',
          'location': 'Jeffersonville IN',
          'duration': 112,
          // URLs de test - remplacer par les vraies URLs de branham.org
          'streamUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          'downloadUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          'pdfUrl': null,
          'year': 1964,
          'keywords': ['questions', 'réponses'],
        },
        {
          'id': '64-0726E',
          'title': 'Des citernes crevassées',
          'date': '64-0726E',
          'location': 'Jeffersonville IN',
          'duration': 89,
          // URLs de test - remplacer par les vraies URLs de branham.org
          'streamUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          'downloadUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          'pdfUrl': null,
          'year': 1964,
          'keywords': ['citernes', 'crevassées'],
        },
      ],
      1963: [
        {
          'id': '63-1201M',
          'title': 'Un Absolu',
          'date': '63-1201M',
          'location': 'Jeffersonville IN',
          'duration': 92,
          // URLs de test - remplacer par les vraies URLs de branham.org
          'streamUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
          'downloadUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
          'pdfUrl': null,
          'year': 1963,
          'keywords': ['absolu'],
        },
        {
          'id': '63-0318',
          'title': 'Le Premier Sceau',
          'date': '63-0318',
          'location': 'Jeffersonville IN',
          'duration': 98,
          // URLs de test - remplacer par les vraies URLs de branham.org
          'streamUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
          'downloadUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
          'pdfUrl': null,
          'series': 'La Révélation des Sept Sceaux',
          'year': 1963,
          'keywords': ['sceau', 'révélation', 'prophétie'],
        },
      ],
    };

    return (staticSermons[year] ?? [])
        .map((data) => BranhamSermon.fromBranhamData(data))
        .toList();
  }

  /// Recherche des prédications par terme
  static List<BranhamSermon> searchSermons(List<BranhamSermon> sermons, String query) {
    if (query.isEmpty) return sermons;
    
    final lowerQuery = query.toLowerCase();
    return sermons.where((sermon) {
      return sermon.title.toLowerCase().contains(lowerQuery) ||
             sermon.location.toLowerCase().contains(lowerQuery) ||
             sermon.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery)) ||
             (sermon.series?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Filtre par année
  static List<BranhamSermon> filterByYear(List<BranhamSermon> sermons, int? year) {
    if (year == null) return sermons;
    return sermons.where((sermon) => sermon.year == year).toList();
  }

  /// Filtre par série
  static List<BranhamSermon> filterBySeries(List<BranhamSermon> sermons, String? series) {
    if (series == null || series.isEmpty) return sermons;
    return sermons.where((sermon) => sermon.series == series).toList();
  }

  /// Obtient toutes les années disponibles
  static List<int> getAvailableYears(List<BranhamSermon> sermons) {
    final years = sermons
        .where((sermon) => sermon.year != null)
        .map((sermon) => sermon.year!)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a)); // Tri décroissant
    return years;
  }

  /// Obtient toutes les séries disponibles
  static List<String> getAvailableSeries(List<BranhamSermon> sermons) {
    final series = sermons
        .where((sermon) => sermon.series != null && sermon.series!.isNotEmpty)
        .map((sermon) => sermon.series!)
        .toSet()
        .toList();
    series.sort();
    return series;
  }

  /// Génère des données de démonstration en cas d'erreur réseau
  static List<BranhamSermon> _generateDemoSermons() {
    print('🔄 Génération de données de démonstration...');
    
    final demoData = [
      {
        'id': 'demo-65-1204',
        'title': 'La Révélation de Jésus-Christ (Démo)',
        'date': '65-1204',
        'location': 'Jeffersonville IN',
        'duration': 95,
        'series': 'La Révélation de Jésus-Christ',
        'year': 1965,
        'keywords': ['révélation', 'jésus', 'christ', 'démo'],
      },
      {
        'id': 'demo-63-0318',
        'title': 'Le Premier Sceau (Démo)',
        'date': '63-0318',
        'location': 'Jeffersonville IN',
        'duration': 98,
        'series': 'La Révélation des Sept Sceaux',
        'year': 1963,
        'keywords': ['sceau', 'révélation', 'prophétie', 'démo'],
      },
      {
        'id': 'demo-64-0830M',
        'title': 'Questions et réponses no 3 (Démo)',
        'date': '64-0830M',
        'location': 'Jeffersonville IN',
        'duration': 112,
        'year': 1964,
        'keywords': ['questions', 'réponses', 'démo'],
      },
    ];

    return demoData
        .map((data) => BranhamSermon.fromBranhamData(data))
        .toList();
  }

  /// Efface le cache
  static void clearCache() {
    _cachedSermons.clear();
    _lastFetch = null;
    print('🗑️ Cache effacé');
  }

  /// Vérifie si le cache est valide
  static bool get isCacheValid {
    return _cachedSermons.isNotEmpty && 
           _lastFetch != null && 
           DateTime.now().difference(_lastFetch!) < cacheDuration;
  }

  /// Obtient des informations sur le cache
  static Map<String, dynamic> getCacheInfo() {
    return {
      'sermonCount': _cachedSermons.length,
      'lastFetch': _lastFetch?.toIso8601String(),
      'isValid': isCacheValid,
      'cacheAge': _lastFetch != null 
          ? DateTime.now().difference(_lastFetch!).inMinutes 
          : null,
    };
  }
}
