import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_branham_sermon_model.dart';
import '../../models/branham_sermon_model.dart';

/// Service pour gérer les prédications de Branham depuis la vue admin
class AdminBranhamSermonService {
  static const String collectionName = 'branham_sermons';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer toutes les prédications (admin)
  static Future<List<AdminBranhamSermon>> getAllSermons() async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('displayOrder')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminBranhamSermon.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des prédications: $e');
      return [];
    }
  }

  /// Récupérer les prédications actives pour l'onglet Écouter
  static Stream<List<BranhamSermon>> getActiveSermonsStream() {
    return _firestore
        .collection(collectionName)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminBranhamSermon.fromFirestore(doc).toBranhamSermon())
          .toList();
    });
  }

  /// Récupérer les prédications actives (Future)
  static Future<List<BranhamSermon>> getActiveSermons() async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminBranhamSermon.fromFirestore(doc).toBranhamSermon())
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des prédications actives: $e');
      return [];
    }
  }

  /// Ajouter une nouvelle prédication
  static Future<String?> addSermon(AdminBranhamSermon sermon) async {
    try {
      final docRef = await _firestore.collection(collectionName).add(sermon.toFirestore());
      print('✅ Prédication ajoutée avec succès: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de la prédication: $e');
      return null;
    }
  }

  /// Mettre à jour une prédication
  static Future<bool> updateSermon(String id, AdminBranhamSermon sermon) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(id)
          .update(sermon.copyWith(updatedAt: DateTime.now()).toFirestore());
      print('✅ Prédication mise à jour: $id');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la prédication: $e');
      return false;
    }
  }

  /// Supprimer une prédication
  static Future<bool> deleteSermon(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
      print('✅ Prédication supprimée: $id');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression de la prédication: $e');
      return false;
    }
  }

  /// Activer/désactiver une prédication
  static Future<bool> toggleSermonStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(collectionName).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      print('✅ Statut de la prédication mis à jour: $id -> $isActive');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  /// Mettre à jour l'ordre d'affichage
  static Future<bool> updateDisplayOrder(String id, int newOrder) async {
    try {
      await _firestore.collection(collectionName).doc(id).update({
        'displayOrder': newOrder,
        'updatedAt': Timestamp.now(),
      });
      print('✅ Ordre d\'affichage mis à jour: $id -> $newOrder');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de l\'ordre: $e');
      return false;
    }
  }

  /// Rechercher des prédications
  static Future<List<AdminBranhamSermon>> searchSermons(String query) async {
    try {
      if (query.isEmpty) {
        return getAllSermons();
      }

      // Recherche par titre
      final titleSnapshot = await _firestore
          .collection(collectionName)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Recherche par date
      final dateSnapshot = await _firestore
          .collection(collectionName)
          .where('date', isGreaterThanOrEqualTo: query)
          .where('date', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Combiner les résultats
      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(titleSnapshot.docs);
      allDocs.addAll(dateSnapshot.docs);

      // Supprimer les doublons
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      return uniqueDocs.values
          .map((doc) => AdminBranhamSermon.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche: $e');
      return [];
    }
  }

  /// Valider une URL audio
  static Future<bool> validateAudioUrl(String url) async {
    try {
      // Vérifications basiques
      if (url.isEmpty) return false;
      
      final uri = Uri.tryParse(url);
      if (uri == null) return false;
      
      // Vérifier que c'est une URL valide
      if (!uri.hasScheme || !uri.hasAuthority) return false;
      
      // Vérifier les extensions audio courantes
      final allowedExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg'];
      final hasValidExtension = allowedExtensions.any((ext) => 
          url.toLowerCase().contains(ext));
      
      // Permettre aussi les URLs de streaming sans extension
      final isStreamingUrl = url.contains('stream') || 
          url.contains('audio') || 
          url.contains('branham') ||
          url.contains('cloudfront');
      
      return hasValidExtension || isStreamingUrl;
    } catch (e) {
      print('❌ Erreur lors de la validation de l\'URL: $e');
      return false;
    }
  }

  /// Créer des données de démonstration
  static Future<void> createDemoData() async {
    try {
      final demoSermons = [
        AdminBranhamSermon(
          id: '',
          title: 'La foi est une ferme assurance',
          date: '47-0412',
          location: 'Oakland, CA',
          audioUrl: 'https://example.com/audio/47-0412.mp3',
          description: 'Une prédication fondamentale sur la nature de la foi.',
          duration: const Duration(hours: 1, minutes: 52),
          language: 'fr',
          series: 'Les fondements de la foi',
          keywords: ['foi', 'assurance', 'fondements'],
          createdAt: DateTime.now(),
          createdBy: 'admin',
          isActive: true,
          displayOrder: 1),
        AdminBranhamSermon(
          id: '',
          title: 'Le Signe du Fils de l\'homme',
          date: '62-1230',
          location: 'Jeffersonville, IN',
          audioUrl: 'https://example.com/audio/62-1230.mp3',
          description: 'Les signes des temps et le retour du Seigneur.',
          duration: const Duration(hours: 2, minutes: 15),
          language: 'fr',
          series: 'Les signes des temps',
          keywords: ['signe', 'fils de l\'homme', 'temps'],
          createdAt: DateTime.now(),
          createdBy: 'admin',
          isActive: true,
          displayOrder: 2),
      ];

      for (var sermon in demoSermons) {
        await addSermon(sermon);
      }
      
      print('✅ Données de démonstration créées');
    } catch (e) {
      print('❌ Erreur lors de la création des données de démonstration: $e');
    }
  }
}
