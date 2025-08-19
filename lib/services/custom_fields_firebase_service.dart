import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/custom_field_model.dart';

class CustomFieldsFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'custom_fields';

  // Créer un nouveau champ personnalisé
  Future<String> createCustomField(CustomFieldModel field) async {
    try {
      final docRef = await _firestore.collection(_collection).add(field.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du champ personnalisé: $e');
    }
  }

  // Mettre à jour un champ personnalisé
  Future<void> updateCustomField(CustomFieldModel field) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(field.id)
          .update(field.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du champ personnalisé: $e');
    }
  }

  // Supprimer un champ personnalisé
  Future<void> deleteCustomField(String fieldId) async {
    try {
      await _firestore.collection(_collection).doc(fieldId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du champ personnalisé: $e');
    }
  }

  // Obtenir un champ personnalisé par ID
  Future<CustomFieldModel?> getCustomFieldById(String fieldId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(fieldId).get();
      if (doc.exists) {
        return CustomFieldModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du champ personnalisé: $e');
    }
  }

  // Obtenir tous les champs personnalisés (stream)
  Stream<List<CustomFieldModel>> getCustomFieldsStream() {
    return _firestore
        .collection(_collection)
        .where('isVisible', isEqualTo: true)
        .orderBy('order')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CustomFieldModel.fromFirestore(doc)).toList();
    });
  }

  // Obtenir tous les champs personnalisés (future)
  Future<List<CustomFieldModel>> getCustomFields() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isVisible', isEqualTo: true)
          .orderBy('order')
          .orderBy('createdAt')
          .get();
      
      return snapshot.docs.map((doc) => CustomFieldModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des champs personnalisés: $e');
    }
  }

  // Obtenir les champs personnalisés avec leurs valeurs pour une personne
  Future<Map<String, dynamic>> getPersonCustomFieldsWithValues(
    String personId,
    Map<String, dynamic> personCustomFields,
  ) async {
    try {
      final fields = await getCustomFields();
      final result = <String, dynamic>{};
      
      for (final field in fields) {
        result[field.name] = {
          'field': field,
          'value': personCustomFields[field.name] ?? field.defaultValue,
        };
      }
      
      return result;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des champs personnalisés: $e');
    }
  }

  // Réorganiser l'ordre des champs personnalisés
  Future<void> reorderCustomFields(List<CustomFieldModel> fields) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        final updatedField = field.copyWith(order: i, updatedAt: DateTime.now());
        batch.update(
          _firestore.collection(_collection).doc(field.id),
          updatedField.toFirestore(),
        );
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la réorganisation des champs: $e');
    }
  }

  // Valider les valeurs des champs personnalisés
  Map<String, String> validateCustomFieldValues(
    List<CustomFieldModel> fields,
    Map<String, dynamic> values,
  ) {
    final errors = <String, String>{};
    
    for (final field in fields) {
      final value = values[field.name];
      final error = field.validateValue(value);
      if (error != null) {
        errors[field.name] = error;
      }
    }
    
    return errors;
  }

  // Nettoyer les valeurs des champs personnalisés
  Map<String, dynamic> cleanCustomFieldValues(
    List<CustomFieldModel> fields,
    Map<String, dynamic> values,
  ) {
    final cleanedValues = <String, dynamic>{};
    
    for (final field in fields) {
      final value = values[field.name];
      if (value != null) {
        switch (field.type) {
          case CustomFieldType.number:
            cleanedValues[field.name] = double.tryParse(value.toString()) ?? 0;
            break;
          case CustomFieldType.boolean:
            cleanedValues[field.name] = value == true || value == 'true';
            break;
          case CustomFieldType.date:
            if (value is DateTime) {
              cleanedValues[field.name] = value;
            } else if (value is String) {
              cleanedValues[field.name] = DateTime.tryParse(value);
            }
            break;
          case CustomFieldType.multiselect:
            if (value is List) {
              cleanedValues[field.name] = value;
            } else if (value is String) {
              cleanedValues[field.name] = [value];
            }
            break;
          default:
            cleanedValues[field.name] = value.toString();
        }
      }
    }
    
    return cleanedValues;
  }

  // Obtenir les valeurs uniques pour un champ personnalisé (pour les filtres)
  Future<List<String>> getUniqueValuesForField(String fieldName) async {
    try {
      final peopleSnapshot = await FirebaseFirestore.instance
          .collection('people')
          .get();
      
      final values = <String>{};
      
      for (final doc in peopleSnapshot.docs) {
        final data = doc.data();
        final customFields = data['customFields'] as Map<String, dynamic>? ?? {};
        final value = customFields[fieldName];
        
        if (value != null) {
          if (value is List) {
            values.addAll(value.cast<String>());
          } else {
            values.add(value.toString());
          }
        }
      }
      
      return values.toList()..sort();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des valeurs uniques: $e');
    }
  }
}