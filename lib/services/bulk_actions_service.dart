import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';

/// Types d'actions en lot disponibles
enum BulkActionType {
  email,
  sms,
  roleAssignment,
  tagAssignment,
  statusUpdate,
}

/// Résultat d'une action en lot
class BulkActionResult {
  final bool success;
  final int successCount;
  final int totalCount;
  final List<String> errors;

  BulkActionResult({
    required this.success,
    required this.successCount,
    required this.totalCount,
    required this.errors,
  });
}

/// Service de gestion des actions en lot sur les personnes
class BulkActionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Attribuer un rôle à plusieurs personnes
  Future<BulkActionResult> assignRole({
    required List<PersonModel> people,
    required String roleId,
  }) async {
    try {
      final results = <String, bool>{};
      final errors = <String>[];
      
      for (final person in people) {
        try {
          // Ajouter le rôle à la liste des rôles de la personne
          final updatedRoles = List<String>.from(person.roles ?? []);
          if (!updatedRoles.contains(roleId)) {
            updatedRoles.add(roleId);
            
            final updatedPerson = person.copyWith(roles: updatedRoles);
            await FirebaseService.updatePerson(updatedPerson);
            results[person.id] = true;
          } else {
            results[person.id] = true; // Déjà assigné
          }
        } catch (e) {
          results[person.id] = false;
          errors.add('\${person.fullName}: \$e');
        }
      }
      
      await _recordBulkAction(
        type: BulkActionType.roleAssignment,
        peopleIds: people.map((p) => p.id).toList(),
        parameters: {'roleId': roleId},
        results: results,
      );
      
      return BulkActionResult(
        success: errors.isEmpty,
        successCount: results.values.where((v) => v).length,
        totalCount: people.length,
        errors: errors,
      );
    } catch (e) {
      return BulkActionResult(
        success: false,
        successCount: 0,
        totalCount: people.length,
        errors: ['Erreur générale: \$e'],
      );
    }
  }

  /// Ajouter un tag à plusieurs personnes
  Future<BulkActionResult> addTag({
    required List<PersonModel> people,
    required String tag,
  }) async {
    try {
      final results = <String, bool>{};
      final errors = <String>[];
      
      for (final person in people) {
        try {
          // Ajouter le tag à la liste des tags de la personne
          final updatedTags = List<String>.from(person.tags ?? []);
          if (!updatedTags.contains(tag)) {
            updatedTags.add(tag);
            
            final updatedPerson = person.copyWith(tags: updatedTags);
            await FirebaseService.updatePerson(updatedPerson);
            results[person.id] = true;
          } else {
            results[person.id] = true; // Déjà ajouté
          }
        } catch (e) {
          results[person.id] = false;
          errors.add('\${person.fullName}: \$e');
        }
      }
      
      await _recordBulkAction(
        type: BulkActionType.tagAssignment,
        peopleIds: people.map((p) => p.id).toList(),
        parameters: {'tag': tag},
        results: results,
      );
      
      return BulkActionResult(
        success: errors.isEmpty,
        successCount: results.values.where((v) => v).length,
        totalCount: people.length,
        errors: errors,
      );
    } catch (e) {
      return BulkActionResult(
        success: false,
        successCount: 0,
        totalCount: people.length,
        errors: ['Erreur générale: \$e'],
      );
    }
  }

  /// Mettre à jour le statut de plusieurs personnes
  Future<BulkActionResult> updateStatus({
    required List<PersonModel> people,
    required bool isActive,
  }) async {
    try {
      final results = <String, bool>{};
      final errors = <String>[];
      
      for (final person in people) {
        try {
          if (person.isActive != isActive) {
            final updatedPerson = person.copyWith(isActive: isActive);
            await FirebaseService.updatePerson(updatedPerson);
            results[person.id] = true;
          } else {
            results[person.id] = true; // Déjà dans le bon état
          }
        } catch (e) {
          results[person.id] = false;
          errors.add('\${person.fullName}: \$e');
        }
      }
      
      await _recordBulkAction(
        type: BulkActionType.statusUpdate,
        peopleIds: people.map((p) => p.id).toList(),
        parameters: {'isActive': isActive},
        results: results,
      );
      
      return BulkActionResult(
        success: errors.isEmpty,
        successCount: results.values.where((v) => v).length,
        totalCount: people.length,
        errors: errors,
      );
    } catch (e) {
      return BulkActionResult(
        success: false,
        successCount: 0,
        totalCount: people.length,
        errors: ['Erreur générale: \$e'],
      );
    }
  }

  /// Enregistrer une action en lot dans l'historique
  Future<void> _recordBulkAction({
    required BulkActionType type,
    required List<String> peopleIds,
    required Map<String, dynamic> parameters,
    required Map<String, bool> results,
  }) async {
    try {
      await _firestore.collection('bulk_actions_history').add({
        'type': type.toString().split('.').last,
        'peopleIds': peopleIds,
        'parameters': parameters,
        'results': results,
        'executedAt': Timestamp.now(),
        'executedBy': 'current_user_id', // Remplacer par l'ID de l'utilisateur actuel
        'successCount': results.values.where((v) => v).length,
        'totalCount': peopleIds.length,
      });
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'action en lot: \$e');
    }
  }

  /// Obtenir l'historique des actions en lot
  Future<List<Map<String, dynamic>>> getBulkActionsHistory({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bulk_actions_history')
          .orderBy('executedAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: \$e');
      return [];
    }
  }
}