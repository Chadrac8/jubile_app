import 'package:cloud_firestore/cloud_firestore.dart';

/// Service de base pour tous les services Firebase
/// Fournit les méthodes communes pour les opérations CRUD
abstract class BaseFirebaseService<T> {
  /// Nom de la collection dans Firestore
  String get collectionName;
  
  /// Instance de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Référence à la collection
  CollectionReference get collection => _firestore.collection(collectionName);
  
  /// Convertir les données Firestore en modèle
  T fromFirestore(DocumentSnapshot doc);
  
  /// Convertir le modèle en données Firestore
  Map<String, dynamic> toFirestore(T model);
  
  /// Créer un nouvel élément
  Future<String> create(T model) async {
    try {
      final docRef = await collection.add(toFirestore(model));
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }
  
  /// Mettre à jour un élément existant
  Future<void> update(String id, T model) async {
    try {
      await collection.doc(id).set(toFirestore(model), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }
  
  /// Supprimer un élément
  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
  
  /// Obtenir un élément par ID
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
  
  /// Obtenir tous les éléments
  Future<List<T>> getAll() async {
    try {
      final querySnapshot = await collection.get();
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération: $e');
    }
  }
  
  /// Obtenir les éléments avec une requête personnalisée
  Future<List<T>> getWhere(String field, dynamic value) async {
    try {
      final querySnapshot = await collection.where(field, isEqualTo: value).get();
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la requête: $e');
    }
  }
  
  /// Stream en temps réel de tous les éléments
  Stream<List<T>> streamAll() {
    return collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }
  
  /// Stream en temps réel d'un élément par ID
  Stream<T?> streamById(String id) {
    return collection.doc(id).snapshots().map((doc) =>
        doc.exists ? fromFirestore(doc) : null);
  }
  
  /// Stream en temps réel avec requête personnalisée
  Stream<List<T>> streamWhere(String field, dynamic value) {
    return collection.where(field, isEqualTo: value).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }
  
  /// Obtenir le nombre total d'éléments
  Future<int> getCount() async {
    try {
      final querySnapshot = await collection.get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage: $e');
    }
  }
  
  /// Recherche par texte (nécessite une implémentation spécifique)
  Future<List<T>> search(String query) async {
    // Implémentation de base - à surcharger dans les services spécifiques
    throw UnimplementedError('La recherche doit être implémentée dans le service spécifique');
  }
  
  /// Batch operations
  WriteBatch get batch => _firestore.batch();
  
  /// Commit batch operations
  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du commit batch: $e');
    }
  }
}