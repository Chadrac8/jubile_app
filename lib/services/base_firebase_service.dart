import 'package:cloud_firestore/cloud_firestore.dart';

/// Service de base pour les opérations Firestore
abstract class BaseFirebaseService<T> {
  /// Instance Firestore
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Nom de la collection Firestore
  String get collectionName;

  /// Référence à la collection
  CollectionReference get collection => firestore.collection(collectionName);

  /// Convertir un document Firestore en objet
  T fromFirestore(DocumentSnapshot doc);

  /// Créer un nouvel objet
  Future<T> create(T item) async {
    try {
      final data = (item as dynamic).toMap() as Map<String, dynamic>;
      final docRef = await collection.add(data);
      
      // Récupérer le document créé
      final doc = await docRef.get();
      return fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  /// Mettre à jour un objet existant
  Future<T> update(String id, T item) async {
    try {
      final data = (item as dynamic).toMap() as Map<String, dynamic>;
      await collection.doc(id).update(data);
      
      // Récupérer le document mis à jour
      final doc = await collection.doc(id).get();
      return fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Supprimer un objet
  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Récupérer un objet par ID
  Future<T?> getById(String id) async {
    try {
      final doc = await collection.doc(id).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  /// Récupérer tous les objets
  Future<List<T>> getAll() async {
    try {
      final querySnapshot = await collection.get();
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de tous les éléments: $e');
    }
  }

  /// Récupérer les objets avec une condition
  Future<List<T>> getWhere(String field, dynamic value) async {
    try {
      final querySnapshot = await collection.where(field, isEqualTo: value).get();
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération conditionnelle: $e');
    }
  }

  /// Stream en temps réel de tous les objets
  Stream<List<T>> getAllStream() {
    return collection.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Stream en temps réel d'un objet par ID
  Stream<T?> getByIdStream(String id) {
    return collection.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    });
  }

  /// Rechercher des objets par un champ texte
  Future<List<T>> searchByField(String field, String query) async {
    try {
      // Recherche par préfixe (limité dans Firestore)
      final querySnapshot = await collection
          .where(field, isGreaterThanOrEqualTo: query)
          .where(field, isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Récupérer les objets avec pagination
  Future<List<T>> getPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = collection;
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la pagination: $e');
    }
  }

  /// Compter le nombre d'objets
  Future<int> count() async {
    try {
      final querySnapshot = await collection.get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage: $e');
    }
  }

  /// Vérifier si un objet existe
  Future<bool> exists(String id) async {
    try {
      final doc = await collection.doc(id).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Erreur lors de la vérification d\'existence: $e');
    }
  }
}