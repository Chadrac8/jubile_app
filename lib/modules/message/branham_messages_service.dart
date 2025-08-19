import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/branham_message.dart';

class BranhamMessagesService {
  static const String _baseUrl = 'https://branham.org';
  static const String _cacheKey = 'branham_messages_cache';
  static const String _lastUpdateKey = 'branham_messages_last_update';
  static const Duration _cacheExpiry = Duration(hours: 24);

  // Cache en mémoire pour éviter les requêtes répétées
  static List<BranhamMessage>? _cachedMessages;
  static DateTime? _lastFetchTime;

  /// Récupère toutes les prédications en français
  static Future<List<BranhamMessage>> getAllMessages({bool forceRefresh = false}) async {
    try {
      // Vérifier si on a un cache valide en mémoire
      if (!forceRefresh && _cachedMessages != null && _lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
        if (timeSinceLastFetch < _cacheExpiry) {
          return _cachedMessages!;
        }
      }

      // Vérifier le cache local
      if (!forceRefresh) {
        final cachedData = await _getCachedMessages();
        if (cachedData.isNotEmpty) {
          _cachedMessages = cachedData;
          _lastFetchTime = DateTime.now();
          return cachedData;
        }
      }

      // Récupérer les données depuis le site
      final messages = await _fetchMessagesFromWebsite();
      
      // Mettre en cache
      await _saveMessagesToCache(messages);
      _cachedMessages = messages;
      _lastFetchTime = DateTime.now();

      return messages;
    } catch (e) {
      print('Erreur lors de la récupération des messages: $e');
      
      // En cas d'erreur, essayer de retourner le cache
      final cachedData = await _getCachedMessages();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      
      // Si aucun cache, retourner des données de démonstration
      return _getDemoMessages();
    }
  }

  /// Récupère les prédications depuis le site web
  static Future<List<BranhamMessage>> _fetchMessagesFromWebsite() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fr/messageaudio'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        }).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }

      return _parseHtmlResponse(response.body);
    } catch (e) {
      print('❌ Erreur de connexion au site branham.org: $e');
      print('⚠️ Utilisation des données de démonstration à la place');
      return _getDemoMessages();
    }
  }

  /// Parse le HTML pour extraire les informations des prédications
  static List<BranhamMessage> _parseHtmlResponse(String html) {
    final List<BranhamMessage> messages = [];
    
    try {
      // Pattern pour extraire les prédications du HTML
      // Le site affiche les prédications sous cette forme :
      // FRN 47-0412   La foi est une ferme assurance   Oakland CA  112 min  4/23/2025  [download PDF file](lien) [Download Audio](lien)
      
      // Recherche des liens PDF dans le HTML
      // Pattern alternatif pour les liens directs
      final RegExp directLinkPattern = RegExp(
        r'\[download PDF file\]\(([^)]+)\)',
        multiLine: true);

      // Pattern pour extraire le contenu des lignes de prédication
      final RegExp messageLinePattern = RegExp(
        r'FRN\s+(\d{2}-\d{4})\s+([^]+?)\s+([^]+?)\s+(\d+)\s+min\s+(\d{1,2}/\d{1,2}/\d{4})',
        multiLine: true);

      final messageMatches = messageLinePattern.allMatches(html);
      final pdfMatches = directLinkPattern.allMatches(html);
      
      // Créer une liste des URLs PDF trouvées
      final List<String> pdfUrls = pdfMatches.map((match) => match.group(1) ?? '').toList();
      
      int pdfIndex = 0;
      for (final match in messageMatches) {
        try {
          final id = match.group(1) ?? '';
          final title = match.group(2)?.trim() ?? '';
          final location = match.group(3)?.trim() ?? '';
          final duration = int.tryParse(match.group(4) ?? '0') ?? 0;
          final dateString = match.group(5) ?? '';

          // Associer le PDF correspondant si disponible
          final pdfUrl = pdfIndex < pdfUrls.length ? pdfUrls[pdfIndex] : '';
          pdfIndex++;

          // Convertir la date US en format DateTime
          DateTime publishDate = DateTime.now();
          if (dateString.isNotEmpty) {
            final dateParts = dateString.split('/');
            if (dateParts.length == 3) {
              final month = int.tryParse(dateParts[0]) ?? 1;
              final day = int.tryParse(dateParts[1]) ?? 1;
              final year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
              publishDate = DateTime(year, month, day);
            }
          }

          // Construire l'URL audio (pattern standard du site)
          final audioUrl = pdfUrl.isNotEmpty 
              ? pdfUrl.replaceAll('.pdf', '.m4a').replaceAll('/repo/', '/repo/')
              : '';

          messages.add(BranhamMessage(
            id: id,
            title: title,
            date: id, // L'ID contient déjà la date au format YY-MMDD
            location: location,
            durationMinutes: duration,
            pdfUrl: pdfUrl,
            audioUrl: audioUrl,
            streamUrl: audioUrl, // Même URL pour streaming
            language: 'FRN',
            publishDate: publishDate));
        } catch (e) {
          print('Erreur lors du parsing d\'un message: $e');
          continue;
        }
      }

      print('Messages trouvés: ${messages.length}');
      
      // Si le parsing HTML échoue, utiliser des données de démonstration
      if (messages.isEmpty) {
        print('Aucun message trouvé, utilisation des données de démonstration');
        return _getDemoMessages();
      }

      return messages;
    } catch (e) {
      print('Erreur lors du parsing HTML: $e');
      return _getDemoMessages();
    }
  }

  /// Récupère les messages depuis le cache local
  static Future<List<BranhamMessage>> _getCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      
      if (lastUpdate != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        final timeSinceUpdate = DateTime.now().difference(lastUpdateTime);
        
        if (timeSinceUpdate < _cacheExpiry) {
          final cachedJson = prefs.getString(_cacheKey);
          if (cachedJson != null) {
            final List<dynamic> jsonList = json.decode(cachedJson);
            return jsonList.map((json) => BranhamMessage.fromJson(json)).toList();
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération du cache: $e');
    }
    
    return [];
  }

  /// Sauvegarde les messages en cache local
  static Future<void> _saveMessagesToCache(List<BranhamMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = messages.map((message) => message.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde en cache: $e');
    }
  }

  /// Données de démonstration en cas d'échec de récupération
  static List<BranhamMessage> _getDemoMessages() {
    return [
      BranhamMessage(
        id: '65-1204',
        title: 'L\'Amour Divin',
        date: '65-1204',
        location: 'Shreveport LA',
        durationMinutes: 125,
        pdfUrl: 'https://d2w09gj4mqt5u.cloudfront.net/repo/f6a/f6a9d237cdaa3dde1d6e5b590eac37f0c7386142e8fc061eb4160c7cfd5458fa0e791de7fe6eeb7563aaf1a04ab82943b6f00abcb1926783c6598494ee07f095.pdf',
        audioUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/9b4/9b4fb2.m4a',
        streamUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/9b4/9b4fb2.m4a',
        language: 'FRN',
        publishDate: DateTime(2024, 12, 4),
        series: ['Série principale']),
      BranhamMessage(
        id: '64-0823',
        title: 'Les Questions et Réponses',
        date: '64-0823',
        location: 'Jeffersonville IN',
        durationMinutes: 98,
        pdfUrl: 'https://d2w09gj4mqt5u.cloudfront.net/repo/d04/d0437be671c13a260b5be011e799c9a824fe24b1c36cd3bb20d322cb4177f78f6246d7b558abdae52dedd315c37111841f09a55b2e2a612a3d50ba200b74163b.pdf',
        audioUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/a2f/a2f1d3267b082edfe6951da9460bde79f1f677bee50e1c62db2485faaf0eb3adad8d9b8c3eb76b234e9d4732036e52546f4acb5a94059d1f44ecf61d80107166.m4a',
        streamUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/a2f/a2f1d3267b082edfe6951da9460bde79f1f677bee50e1c62db2485faaf0eb3adad8d9b8c3eb76b234e9d4732036e52546f4acb5a94059d1f44ecf61d80107166.m4a',
        language: 'FRN',
        publishDate: DateTime(2024, 8, 23),
        series: ['Questions & Réponses']),
      BranhamMessage(
        id: '63-0728',
        title: 'Christ est le Mystère de Dieu Révélé',
        date: '63-0728',
        location: 'Jeffersonville IN',
        durationMinutes: 142,
        pdfUrl: 'https://example.com/predication3.pdf',
        audioUrl: 'https://example.com/predication3.m4a',
        streamUrl: 'https://example.com/stream3',
        language: 'FRN',
        publishDate: DateTime(2024, 7, 28),
        series: ['Révélation']),
      BranhamMessage(
        id: '62-1014',
        title: 'L\'influence d\'une Autre',
        date: '62-1014',
        location: 'Jeffersonville IN',
        durationMinutes: 87,
        pdfUrl: 'https://example.com/predication4.pdf',
        audioUrl: 'https://example.com/predication4.m4a',
        streamUrl: 'https://example.com/stream4',
        language: 'FRN',
        publishDate: DateTime(2024, 10, 14),
        series: ['Enseignements']),
      BranhamMessage(
        id: '61-0618',
        title: 'Révélation, Chapitre Quatre #3',
        date: '61-0618',
        location: 'Jeffersonville IN',
        durationMinutes: 115,
        pdfUrl: 'https://example.com/predication5.pdf',
        audioUrl: 'https://example.com/predication5.m4a',
        streamUrl: 'https://example.com/stream5',
        language: 'FRN',
        publishDate: DateTime(2024, 6, 18),
        series: ['Révélation']),
      BranhamMessage(
        id: '47-0412',
        title: 'La foi est une ferme assurance',
        date: '47-0412',
        location: 'Oakland CA',
        durationMinutes: 112,
        pdfUrl: 'https://d2w09gj4mqt5u.cloudfront.net/repo/f6a/f6a9d237cdaa3dde1d6e5b590eac37f0c7386142e8fc061eb4160c7cfd5458fa0e791de7fe6eeb7563aaf1a04ab82943b6f00abcb1926783c6598494ee07f095.pdf',
        audioUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/9b4/9b4fb2.m4a',
        streamUrl: 'https://d21kl6o5a7faj0.cloudfront.net/repo/9b4/9b4fb2.m4a',
        language: 'FRN',
        publishDate: DateTime(2025, 4, 23),
        series: ['Foi']),
    ];
  }

  /// Vide le cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
      _cachedMessages = null;
      _lastFetchTime = null;
    } catch (e) {
      print('Erreur lors du nettoyage du cache: $e');
    }
  }

  /// Recherche dans les messages
  static List<BranhamMessage> searchMessages(List<BranhamMessage> messages, String query) {
    if (query.isEmpty) return messages;
    
    final lowerQuery = query.toLowerCase();
    return messages.where((message) {
      return message.title.toLowerCase().contains(lowerQuery) ||
             message.location.toLowerCase().contains(lowerQuery) ||
             message.date.contains(lowerQuery) ||
             message.id.contains(lowerQuery);
    }).toList();
  }

  /// Filtre les messages par décennie
  static List<BranhamMessage> filterByDecade(List<BranhamMessage> messages, String decade) {
    if (decade == 'Tous') return messages;
    
    return messages.where((message) => message.decade == decade).toList();
  }
}
