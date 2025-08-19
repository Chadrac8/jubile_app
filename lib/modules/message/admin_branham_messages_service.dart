import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/branham_message.dart';

class AdminBranhamMessagesService {
  static const String _collectionName = 'branham_messages';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère toutes les prédications depuis Firestore
  static Future<List<BranhamMessage>> getAllMessages() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('publishDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BranhamMessage.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des messages: $e');
      return [];
    }
  }

  /// Ajoute une nouvelle prédication
  static Future<String?> addMessage(BranhamMessage message) async {
    try {
      final DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(message.toJson());

      return docRef.id;
    } catch (e) {
      print('Erreur lors de l\'ajout du message: $e');
      return null;
    }
  }

  /// Met à jour une prédication existante
  static Future<bool> updateMessage(String id, BranhamMessage message) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(message.toJson());

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du message: $e');
      return false;
    }
  }

  /// Supprime une prédication
  static Future<bool> deleteMessage(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Erreur lors de la suppression du message: $e');
      return false;
    }
  }

  /// Recherche des prédications par titre ou lieu
  static Future<List<BranhamMessage>> searchMessages(String query) async {
    try {
      final List<BranhamMessage> allMessages = await getAllMessages();
      
      return allMessages.where((message) =>
        message.title.toLowerCase().contains(query.toLowerCase()) ||
        message.location.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }

  /// Filtre les prédications par décennie
  static Future<List<BranhamMessage>> filterByDecade(String decade) async {
    try {
      final List<BranhamMessage> allMessages = await getAllMessages();
      
      return allMessages.where((message) => message.decade == decade).toList();
    } catch (e) {
      print('Erreur lors du filtrage: $e');
      return [];
    }
  }

  /// Récupère les décennies disponibles
  static Future<List<String>> getAvailableDecades() async {
    try {
      final List<BranhamMessage> allMessages = await getAllMessages();
      final Set<String> decades = allMessages
          .map((message) => message.decade)
          .where((decade) => decade.isNotEmpty)
          .toSet();
      
      final List<String> sortedDecades = decades.toList();
      sortedDecades.sort();
      
      return sortedDecades;
    } catch (e) {
      print('Erreur lors de la récupération des décennies: $e');
      return [];
    }
  }

  /// Récupère les statistiques des prédications
  static Future<Map<String, int>> getStatistics() async {
    try {
      final List<BranhamMessage> allMessages = await getAllMessages();
      
      final Map<String, int> stats = {
        'total': allMessages.length,
        'withAudio': allMessages.where((m) => m.audioUrl.isNotEmpty).length,
        'withPdf': allMessages.where((m) => m.pdfUrl.isNotEmpty).length,
      };

      // Statistiques par décennie
      final Map<String, int> decadeStats = {};
      for (final message in allMessages) {
        final decade = message.decade;
        if (decade.isNotEmpty) {
          decadeStats[decade] = (decadeStats[decade] ?? 0) + 1;
        }
      }
      
      stats.addAll(decadeStats);
      
      return stats;
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {'total': 0, 'withAudio': 0, 'withPdf': 0};
    }
  }
}
