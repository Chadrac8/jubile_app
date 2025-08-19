import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prayer_model.dart';
import '../auth/auth_service.dart';

class PrayersFirebaseService {
  static const String _collectionName = 'prayers';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Référence à la collection
  static CollectionReference get _collection => 
      _firestore.collection(_collectionName);

  // Créer une nouvelle prière
  static Future<String> createPrayer(PrayerModel prayer) async {
    try {
      final docRef = await _collection.add(prayer.toMap());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la prière: $e');
      rethrow;
    }
  }

  // Mettre à jour une prière
  static Future<void> updatePrayer(PrayerModel prayer) async {
    try {
      await _collection.doc(prayer.id).update(prayer.toMap());
    } catch (e) {
      print('Erreur lors de la mise à jour de la prière: $e');
      rethrow;
    }
  }

  // Supprimer une prière
  static Future<void> deletePrayer(String prayerId) async {
    try {
      await _collection.doc(prayerId).delete();
    } catch (e) {
      print('Erreur lors de la suppression de la prière: $e');
      rethrow;
    }
  }

  // Obtenir une prière par ID
  static Future<PrayerModel?> getPrayerById(String prayerId) async {
    try {
      final doc = await _collection.doc(prayerId).get();
      if (doc.exists) {
        return PrayerModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la prière: $e');
      return null;
    }
  }

  // Stream des prières avec filtres
  static Stream<List<PrayerModel>> getPrayersStream({
    PrayerType? type,
    String? category,
    bool approvedOnly = true,
    bool activeOnly = true,
    String? searchQuery,
    int limit = 50,
    String orderBy = 'createdAt',
    bool descending = true,
  }) {
    try {
      Query query = _collection;

      // Filtres
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (approvedOnly) {
        query = query.where('isApproved', isEqualTo: true);
      }
      
      if (activeOnly) {
        query = query.where('isArchived', isEqualTo: false);
      }

      // Tri et limite
      query = query.orderBy(orderBy, descending: descending);
      if (limit > 0) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        List<PrayerModel> prayers = snapshot.docs
            .map((doc) => PrayerModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        // Filtrage par recherche si nécessaire
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          prayers = prayers.where((prayer) =>
              prayer.title.toLowerCase().contains(query) ||
              prayer.content.toLowerCase().contains(query) ||
              prayer.category.toLowerCase().contains(query) ||
              prayer.tags.any((tag) => tag.toLowerCase().contains(query))
          ).toList();
        }

        return prayers;
      });
    } catch (e) {
      print('Erreur lors du stream des prières: $e');
      return Stream.value([]);
    }
  }

  // Prières de l'utilisateur connecté
  static Stream<List<PrayerModel>> getUserPrayersStream() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);

    return _collection
        .where('authorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrayerModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Ajouter une prière (compteur "Je prie pour toi")
  static Future<void> addPrayerCount(String prayerId, String userId) async {
    try {
      final prayerRef = _collection.doc(prayerId);
      await _firestore.runTransaction((transaction) async {
        final prayerDoc = await transaction.get(prayerRef);
        if (prayerDoc.exists) {
          final currentCount = prayerDoc.data() as Map<String, dynamic>;
          final prayedByUsers = List<String>.from(currentCount['prayedByUsers'] ?? []);
          
          if (!prayedByUsers.contains(userId)) {
            prayedByUsers.add(userId);
            transaction.update(prayerRef, {
              'prayerCount': FieldValue.increment(1),
              'prayedByUsers': prayedByUsers,
            });
          }
        }
      });
    } catch (e) {
      print('Erreur lors de l\'ajout de prière: $e');
      rethrow;
    }
  }

  // Retirer une prière (compteur "Je prie pour toi")
  static Future<void> removePrayerCount(String prayerId, String userId) async {
    try {
      final prayerRef = _collection.doc(prayerId);
      await _firestore.runTransaction((transaction) async {
        final prayerDoc = await transaction.get(prayerRef);
        if (prayerDoc.exists) {
          final currentCount = prayerDoc.data() as Map<String, dynamic>;
          final prayedByUsers = List<String>.from(currentCount['prayedByUsers'] ?? []);
          
          if (prayedByUsers.contains(userId)) {
            prayedByUsers.remove(userId);
            transaction.update(prayerRef, {
              'prayerCount': FieldValue.increment(-1),
              'prayedByUsers': prayedByUsers,
            });
          }
        }
      });
    } catch (e) {
      print('Erreur lors du retrait de prière: $e');
      rethrow;
    }
  }

  // Ajouter un commentaire
  static Future<void> addComment(String prayerId, PrayerComment comment) async {
    try {
      final prayerRef = _collection.doc(prayerId);
      await prayerRef.update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } catch (e) {
      print('Erreur lors de l\'ajout du commentaire: $e');
      rethrow;
    }
  }

  // Approuver une prière
  static Future<void> approvePrayer(String prayerId) async {
    try {
      await _collection.doc(prayerId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de l\'approbation de la prière: $e');
      rethrow;
    }
  }

  // Rejeter une prière
  static Future<void> rejectPrayer(String prayerId) async {
    try {
      await _collection.doc(prayerId).update({
        'isApproved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors du rejet de la prière: $e');
      rethrow;
    }
  }

  // Archiver une prière
  static Future<void> archivePrayer(String prayerId) async {
    try {
      await _collection.doc(prayerId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de l\'archivage de la prière: $e');
      rethrow;
    }
  }

  // Obtenir les statistiques des prières
  static Future<PrayerStats> getPrayerStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Récupérer toutes les prières actives
      final allPrayersSnapshot = await _collection
          .where('isArchived', isEqualTo: false)
          .get();

      final allPrayers = allPrayersSnapshot.docs
          .map((doc) => PrayerModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Calculer les statistiques
      final todayPrayers = allPrayers.where((p) => 
          p.createdAt.isAfter(today)).length;
      
      final weekPrayers = allPrayers.where((p) => 
          p.createdAt.isAfter(weekStart)).length;
      
      final monthPrayers = allPrayers.where((p) => 
          p.createdAt.isAfter(monthStart)).length;

      final totalPrayerCount = allPrayers.fold<int>(0, (sum, p) => sum + p.prayerCount);

      // Répartition par type
      final prayersByType = <String, int>{};
      for (final type in PrayerType.values) {
        prayersByType[type.label] = allPrayers.where((p) => p.type == type).length;
      }

      // Répartition par catégorie
      final prayersByCategory = <String, int>{};
      for (final prayer in allPrayers) {
        prayersByCategory[prayer.category] = 
            (prayersByCategory[prayer.category] ?? 0) + 1;
      }

      // Prières en attente d'approbation
      final pendingApproval = allPrayers.where((p) => !p.isApproved).length;

      return PrayerStats(
        totalPrayers: allPrayers.length,
        todayPrayers: todayPrayers,
        weekPrayers: weekPrayers,
        monthPrayers: monthPrayers,
        totalPrayerCount: totalPrayerCount,
        prayersByType: prayersByType,
        prayersByCategory: prayersByCategory,
        pendingApproval: pendingApproval,
      );
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return PrayerStats();
    }
  }

  // Obtenir les catégories utilisées
  static Future<List<String>> getUsedCategories() async {
    try {
      final snapshot = await _collection
          .where('isArchived', isEqualTo: false)
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      final sortedCategories = categories.toList()..sort();
      return sortedCategories;
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // Recherche de prières
  static Future<List<PrayerModel>> searchPrayers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final snapshot = await _collection
          .where('isApproved', isEqualTo: true)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final prayers = snapshot.docs
          .map((doc) => PrayerModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final searchQuery = query.toLowerCase();
      return prayers.where((prayer) =>
          prayer.title.toLowerCase().contains(searchQuery) ||
          prayer.content.toLowerCase().contains(searchQuery) ||
          prayer.category.toLowerCase().contains(searchQuery) ||
          prayer.tags.any((tag) => tag.toLowerCase().contains(searchQuery))
      ).toList();
    } catch (e) {
      print('Erreur lors de la recherche de prières: $e');
      return [];
    }
  }
}