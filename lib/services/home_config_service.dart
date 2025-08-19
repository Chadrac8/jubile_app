import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_config_model.dart';
import '../auth/auth_service.dart';

class HomeConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'home_config';
  static const String _churchInfoCollection = 'church_info';
  static const String _blogCollection = 'blog_articles';

  // Configuration de l'accueil
  static Future<HomeConfigModel> getHomeConfig() async {
    try {
      final doc = await _firestore.collection(_collectionName).doc('main').get();
      
      if (doc.exists) {
        return HomeConfigModel.fromMap(doc.data()!, doc.id);
      } else {
        // Créer une configuration par défaut
        final defaultConfig = HomeConfigModel(
          id: 'main',
          versetDuJour: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
          versetReference: 'Jean 3:16',
          sermonTitle: 'Dernier sermon',
          lastUpdated: DateTime.now());
        
        await _firestore.collection(_collectionName).doc('main').set(defaultConfig.toMap());
        return defaultConfig;
      }
    } catch (e) {
      // print('Erreur lors de la récupération de la config d\'accueil: $e');
      rethrow;
    }
  }

  static Future<void> updateHomeConfig(HomeConfigModel config) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final updatedConfig = config.copyWith(
        lastUpdated: DateTime.now(),
        lastUpdatedBy: currentUser.uid);

      await _firestore.collection(_collectionName).doc('main').set(updatedConfig.toMap());
    } catch (e) {
      // print('Erreur lors de la mise à jour de la config d\'accueil: $e');
      rethrow;
    }
  }

  // Informations de l'église
  static Future<ChurchInfoModel> getChurchInfo() async {
    try {
      final doc = await _firestore.collection(_churchInfoCollection).doc('main').get();
      
      if (doc.exists) {
        return ChurchInfoModel.fromMap(doc.data()!);
      } else {
        // Créer des infos par défaut
        final defaultInfo = ChurchInfoModel(
          name: 'Jubilé Tabernacle France',
          address: '124 Bis Rue de l\'Épidème, 59200 Tourcoing',
          phone: '+33 6 77 45 72 78',
          email: 'contact@jubiletabernacle.org',
          website: 'www.jubiletabernacle.org',
          description: 'Une église dédiée à la croissance spirituelle et à la communion fraternelle dans la ville de Tourcoing.',
          serviceHours: [
            'Dimanche 10h00 - Réunion d\'Adoration',
            'Mercredi - Réunion de prière',
          ],
          socialMedia: {
            'youtube': 'https://youtube.com/@JubileTabernacleFrance',
          });
        
        await _firestore.collection(_churchInfoCollection).doc('main').set(defaultInfo.toMap());
        return defaultInfo;
      }
    } catch (e) {
      // print('Erreur lors de la récupération des infos de l\'église: $e');
      rethrow;
    }
  }

  static Future<void> updateChurchInfo(ChurchInfoModel info) async {
    try {
      await _firestore.collection(_churchInfoCollection).doc('main').set(info.toMap());
    } catch (e) {
      // print('Erreur lors de la mise à jour des infos de l\'église: $e');
      rethrow;
    }
  }

  // Articles de blog récents
  static Future<List<BlogArticleModel>> getRecentBlogArticles({int limit = 3}) async {
    try {
      final snapshot = await _firestore
          .collection(_blogCollection)
          .where('isPublished', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BlogArticleModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // print('Erreur lors de la récupération des articles de blog: $e');
      return [];
    }
  }

  // Stream pour les mises à jour en temps réel
  static Stream<HomeConfigModel> getHomeConfigStream() {
    return _firestore
        .collection(_collectionName)
        .doc('main')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return HomeConfigModel.fromMap(doc.data()!, doc.id);
      } else {
        // Retourner une config par défaut
        return HomeConfigModel(
          id: 'main',
          versetDuJour: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
          versetReference: 'Jean 3:16',
          sermonTitle: 'Dernier sermon',
          lastUpdated: DateTime.now());
      }
    });
  }

  // Obtenir le verset du jour depuis le module Bible
  static Future<Map<String, String>> getVersetDuJour() async {
    try {
      // Essayer de récupérer le verset du jour depuis le module Bible
      final bibleDoc = await _firestore.collection('bible_config').doc('daily_verse').get();
      
      if (bibleDoc.exists) {
        final data = bibleDoc.data()!;
        return {
          'verset': data['verse'] ?? '',
          'reference': data['reference'] ?? '',
        };
      }
      
      // Fallback vers la config d'accueil
      final homeConfig = await getHomeConfig();
      return {
        'verset': homeConfig.versetDuJour,
        'reference': homeConfig.versetReference,
      };
    } catch (e) {
      // print('Erreur lors de la récupération du verset du jour: $e');
      // Retourner un verset par défaut
      return {
        'verset': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
        'reference': 'Jean 3:16',
      };
    }
  }

  static Future<Map<String, dynamic>?> getDailyVerse() async {
    try {
      final versetData = await getVersetDuJour();
      return {
        'text': versetData['verset'],
        'reference': versetData['reference'],
      };
    } catch (e) {
      // print('Erreur lors de la récupération du verset du jour: $e');
      return null;
    }
  }
}
