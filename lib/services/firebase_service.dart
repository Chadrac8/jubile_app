// Suppression de la déclaration hors classe (erreur de placement)
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/person_model.dart';
// import '../models/role_model.dart'; // supprimé car non utilisé

class FirebaseService {
  /// Récupère tous les suivis de personnes pour un workflow donné
  static Stream<List<PersonWorkflowModel>> getPersonWorkflowsByWorkflowId(String workflowId) {
    return _firestore.collection(personWorkflowsCollection)
        .where('workflowId', isEqualTo: workflowId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PersonWorkflowModel.fromFirestore(doc))
            .toList());
  }
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String personsCollection = 'persons';
  static const String familiesCollection = 'families';
  static const String rolesCollection = 'roles';
  static const String workflowsCollection = 'workflows';
  static const String personWorkflowsCollection = 'person_workflows';
  static const String activityLogsCollection = 'activity_logs';


  // Person CRUD Operations
  static Future<String> createPerson(PersonModel person) async {
    try {
      final docRef = await _firestore.collection(personsCollection).add(person.toFirestore());
      
      // Log activity
      await _logActivity(docRef.id, 'create', {'action': 'Person created'});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create person: \$e');
    }
  }

  // Create person with specific document ID (for user profiles)
  static Future<void> createPersonWithId(String documentId, PersonModel person) async {
    try {
      await _firestore.collection(personsCollection).doc(documentId).set(person.toFirestore());
      
      // Log activity
      await _logActivity(documentId, 'create', {'action': 'Person created with specific ID'});
    } catch (e) {
      throw Exception('Failed to create person with ID: \$e');
    }
  }

  static Future<void> updatePerson(PersonModel person) async {
    try {
      print('FirebaseService.updatePerson appelée avec ID: \\${person.id}');
      print('Données à mettre à jour: \\${person.firstName} \\${person.lastName}');
      
      final docRef = _firestore.collection(personsCollection).doc(person.id);
      print('Référence du document: \\${docRef.path}');
      
      // Vérifier si le document existe
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print('ERREUR: Le document n\'existe pas!');
        throw Exception('Document with ID ${person.id} does not exist');
      }
      
      print('Document trouvé, tentative de mise à jour...');
      final data = person.toFirestore();
      print('Données à sauvegarder: ${data.keys}');
      print('Valeurs: firstName=${data['firstName']}, lastName=${data['lastName']}, email=${data['email']}, isActive=${data['isActive']}');
      
      try {
        await docRef.update(data);
        print('Mise à jour réussie dans Firestore');
      } catch (updateError) {
        print('ERREUR DÉTAILLÉE lors de la mise à jour: $updateError');
        print('Type d\'erreur: ${updateError.runtimeType}');
        
        // Vérifier les permissions
        try {
          await docRef.get();
          print('Lecture du document réussie, problème avec les données à écrire');
        } catch (readError) {
          print('Problème de permissions ou de connectivité: $readError');
        }
        
        rethrow;
      }
      
      // Log activity
      await _logActivity(person.id, 'update', {'action': 'Person updated'});
      print('Activité loggée avec succès');
    } catch (e, stackTrace) {
      print('ERREUR dans FirebaseService.updatePerson: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to update person: $e');
    }
  }

  static Future<void> deletePerson(String personId) async {
    try {
      await _firestore.collection(personsCollection).doc(personId).delete();
      
      // Log activity
      await _logActivity(personId, 'delete', {'action': 'Person deleted'});
    } catch (e) {
      throw Exception('Failed to delete person: \$e');
    }
  }

  static Future<PersonModel?> getPerson(String personId) async {
    try {
      final doc = await _firestore.collection(personsCollection).doc(personId).get();
      if (doc.exists) {
        return PersonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get person: \$e');
    }
  }

  static Stream<List<PersonModel>> getPersonsStream({
    String? searchQuery,
    List<String>? roleFilters,
    bool? activeOnly,
    int limit = 50,
  }) {
    Query query = _firestore.collection(personsCollection);

    // Start with basic filtering
    if (activeOnly == true) {
      query = query.where('isActive', isEqualTo: true).orderBy('lastName').limit(limit * 2);
    } else {
      // Use simple orderBy to avoid index issues when not filtering by isActive
      query = query.orderBy('lastName').limit(limit * 2);
    }

    return query.snapshots().map((snapshot) {
      List<PersonModel> persons = snapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();

      // Client-side role filtering
      if (roleFilters != null && roleFilters.isNotEmpty) {
        persons = persons.where((person) {
          return person.roles.any((role) => roleFilters.contains(role));
        }).toList();
      }

      // Client-side search filtering
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        persons = persons.where((person) {
          return person.fullName.toLowerCase().contains(lowercaseQuery) ||
                 person.email.toLowerCase().contains(lowercaseQuery) ||
                 (person.phone?.toLowerCase().contains(lowercaseQuery) ?? false);
        }).toList();
      }

      // Sort by full name on client side for better results
      persons.sort((a, b) => a.fullName.compareTo(b.fullName));

      // Limit results after filtering
      return persons.take(limit).toList();
    });
  }

  /// Récupère toutes les personnes
  static Future<List<PersonModel>> getAllPersons() async {
    try {
      final snapshot = await _firestore.collection(personsCollection)
          .orderBy('lastName')
          .get();
      return snapshot.docs.map((doc) => PersonModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get all persons: $e');
    }
  }

  /// Récupère toutes les personnes actives
  static Future<List<PersonModel>> getActivePersons() async {
    try {
      final snapshot = await _firestore.collection(personsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('lastName')
          .get();
      return snapshot.docs.map((doc) => PersonModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get active persons: $e');
    }
  }

  // Family CRUD Operations
  static Future<String> createFamily(FamilyModel family) async {
    try {
      final docRef = await _firestore.collection(familiesCollection).add(family.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create family: \$e');
    }
  }

  static Future<void> updateFamily(FamilyModel family) async {
    try {
      await _firestore.collection(familiesCollection).doc(family.id).update(family.toFirestore());
    } catch (e) {
      throw Exception('Failed to update family: \$e');
    }
  }

  static Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final doc = await _firestore.collection(familiesCollection).doc(familyId).get();
      if (doc.exists) {
        return FamilyModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get family: \$e');
    }
  }

  static Stream<List<FamilyModel>> getFamiliesStream() {
    return _firestore.collection(familiesCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyModel.fromFirestore(doc))
            .toList());
  }

  static Future<void> addPersonToFamily(String personId, String familyId) async {
    try {
      final batch = _firestore.batch();
      
      // Update person
      final personRef = _firestore.collection(personsCollection).doc(personId);
      batch.update(personRef, {'familyId': familyId, 'updatedAt': DateTime.now()});
      
      // Update family member list
      final familyRef = _firestore.collection(familiesCollection).doc(familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayUnion([personId]),
        'updatedAt': DateTime.now(),
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add person to family: $e');
    }
  }

  static Future<void> removePersonFromFamily(String personId, String familyId) async {
    try {
      final batch = _firestore.batch();
      
      // Update person
      final personRef = _firestore.collection(personsCollection).doc(personId);
      batch.update(personRef, {'familyId': null, 'updatedAt': DateTime.now()});
      
      // Update family member list
      final familyRef = _firestore.collection(familiesCollection).doc(familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayRemove([personId]),
        'updatedAt': DateTime.now(),
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove person from family: $e');
    }
  }

  // Get family members
  static Future<List<PersonModel>> getFamilyMembers(String familyId) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) return [];
      
      final members = <PersonModel>[];
      for (final memberId in family.memberIds) {
        final member = await getPerson(memberId);
        if (member != null) {
          members.add(member);
        }
      }
      return members;
    } catch (e) {
      print('Error loading family members: $e');
      return [];
    }
  }

  // Get family members stream
  static Stream<List<PersonModel>> getFamilyMembersStream(String familyId) {
    return Stream.fromFuture(getFamilyMembers(familyId));
  }

  // Role Management - Now handled by RolesFirebaseService

  static Future<void> assignRoleToPersons(List<String> personIds, String roleId) async {
    try {
      final batch = _firestore.batch();
      
      for (String personId in personIds) {
        final personRef = _firestore.collection(personsCollection).doc(personId);
        batch.update(personRef, {
          'roles': FieldValue.arrayUnion([roleId]),
          'updatedAt': DateTime.now(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to assign role: \$e');
    }
  }

  // Workflow Management
  static Stream<List<WorkflowModel>> getWorkflowsStream() {
    return _firestore.collection(workflowsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkflowModel.fromFirestore(doc))
            .toList());
  }

  static Future<void> startWorkflowForPerson(String personId, String workflowId) async {
    try {
      final personWorkflow = PersonWorkflowModel(
        id: '',
        personId: personId,
        workflowId: workflowId,
        startDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      await _firestore.collection(personWorkflowsCollection).add(personWorkflow.toFirestore());
      
      await _logActivity(personId, 'workflow_start', {
        'workflowId': workflowId,
        'action': 'Workflow started'
      });
    } catch (e) {
      throw Exception('Failed to start workflow: \$e');
    }
  }

  static Stream<List<PersonWorkflowModel>> getPersonWorkflowsStream(String personId) {
    try {
      // Essayer avec l'index optimisé (personId + startDate DESC)
      return _firestore.collection(personWorkflowsCollection)
          .where('personId', isEqualTo: personId)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PersonWorkflowModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      // Fallback avec tri côté client si l'index n'est pas disponible
      print('Index error, using fallback: $e');
      return _firestore.collection(personWorkflowsCollection)
          .where('personId', isEqualTo: personId)
          .snapshots()
          .map((snapshot) {
            var workflows = snapshot.docs
                .map((doc) => PersonWorkflowModel.fromFirestore(doc))
                .toList();
            
            // Tri côté client par startDate descendant
            workflows.sort((a, b) => b.startDate.compareTo(a.startDate));
            return workflows;
          });
    }
  }

  // Méthode alternative utilisant lastUpdated pour le tri
  static Stream<List<PersonWorkflowModel>> getPersonWorkflowsStreamByLastUpdated(String personId) {
    try {
      // Essayer avec l'index optimisé (personId + lastUpdated DESC)
      return _firestore.collection(personWorkflowsCollection)
          .where('personId', isEqualTo: personId)
          .orderBy('lastUpdated', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PersonWorkflowModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      // Fallback avec tri côté client
      print('Index error for lastUpdated, using fallback: $e');
      return _firestore.collection(personWorkflowsCollection)
          .where('personId', isEqualTo: personId)
          .snapshots()
          .map((snapshot) {
            var workflows = snapshot.docs
                .map((doc) => PersonWorkflowModel.fromFirestore(doc))
                .toList();
            
            // Tri côté client par lastUpdated descendant
            workflows.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
            return workflows;
          });
    }
  }

  // Méthode pour obtenir les workflows avec filtre de statut
  static Stream<List<PersonWorkflowModel>> getPersonWorkflowsStreamWithStatus(String personId, String status) {
    try {
      // Essayer avec l'index optimisé (personId + status + startDate DESC)
      return _firestore.collection(personWorkflowsCollection)
          .where('personId', isEqualTo: personId)
          .where('status', isEqualTo: status)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PersonWorkflowModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      // Fallback avec filtrage et tri côté client
      print('Index error for status filter, using fallback: $e');
      return _firestore.collection(personWorkflowsCollection)
          .where('personId', isEqualTo: personId)
          .snapshots()
          .map((snapshot) {
            var workflows = snapshot.docs
                .map((doc) => PersonWorkflowModel.fromFirestore(doc))
                .where((workflow) => workflow.status == status)
                .toList();
            
            // Tri côté client par startDate descendant
            workflows.sort((a, b) => b.startDate.compareTo(a.startDate));
            return workflows;
          });
    }
  }

  static Future<WorkflowModel?> getWorkflow(String workflowId) async {
    try {
      final doc = await _firestore.collection(workflowsCollection).doc(workflowId).get();
      if (doc.exists) {
        return WorkflowModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting workflow: $e');
      return null;
    }
  }

  static Future<String> createWorkflow(WorkflowModel workflow) async {
    try {
      final docRef = await _firestore.collection(workflowsCollection).add(workflow.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating workflow: $e');
      throw Exception('Failed to create workflow: $e');
    }
  }

  static Future<void> updateWorkflow(String workflowId, WorkflowModel workflow) async {
    try {
      await _firestore.collection(workflowsCollection).doc(workflowId).update(workflow.toFirestore());
    } catch (e) {
      print('Error updating workflow: $e');
      throw Exception('Failed to update workflow: $e');
    }
  }

  static Future<void> updateWorkflowProgress(String personWorkflowId, List<String> completedSteps) async {
    try {
      await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).update({
        'completedSteps': completedSteps,
        'lastUpdated': DateTime.now(),
        'status': completedSteps.isNotEmpty ? 'in_progress' : 'pending',
      });
    } catch (e) {
      throw Exception('Failed to update workflow progress: $e');
    }
  }

  static Future<void> completeWorkflow(String personWorkflowId) async {
    try {
      await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).update({
        'status': 'completed',
        'completedDate': DateTime.now(),
        'lastUpdated': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to complete workflow: $e');
    }
  }

  static Future<void> markWorkflowStepAsComplete(String personId, String personWorkflowId, String stepId) async {
    try {
      final doc = await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final completedSteps = List<String>.from(data['completedSteps'] ?? []);
        
        if (!completedSteps.contains(stepId)) {
          completedSteps.add(stepId);
          
          await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).update({
            'completedSteps': completedSteps,
            'lastUpdated': DateTime.now(),
          });

          await _logActivity(personId, 'workflow_step_completed', {
            'personWorkflowId': personWorkflowId,
            'stepId': stepId,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to mark workflow step as complete: $e');
    }
  }

  static Future<void> markWorkflowStepAsIncomplete(String personId, String personWorkflowId, String stepId) async {
    try {
      final doc = await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final completedSteps = List<String>.from(data['completedSteps'] ?? []);
        
        if (completedSteps.contains(stepId)) {
          completedSteps.remove(stepId);
          
          await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).update({
            'completedSteps': completedSteps,
            'lastUpdated': DateTime.now(),
          });

          await _logActivity(personId, 'workflow_step_uncompleted', {
            'personWorkflowId': personWorkflowId,
            'stepId': stepId,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to mark workflow step as incomplete: $e');
    }
  }

  static Future<void> completeWorkflowForPerson(String personId, String personWorkflowId) async {
    try {
      // Obtenir le workflow pour marquer toutes les étapes comme terminées
      final doc = await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final workflowId = data['workflowId'];
        
        // Obtenir toutes les étapes du workflow
        final workflowDoc = await _firestore.collection(workflowsCollection).doc(workflowId).get();
        if (workflowDoc.exists) {
          final workflowData = workflowDoc.data()!;
          final steps = List<Map<String, dynamic>>.from(workflowData['steps'] ?? []);
          final allStepIds = steps.map((step) => step['id'].toString()).toList();
          
          await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).update({
            'completedSteps': allStepIds,
            'status': 'completed',
            'endDate': DateTime.now(),
            'lastUpdated': DateTime.now(),
          });

          await _logActivity(personId, 'workflow_completed', {
            'personWorkflowId': personWorkflowId,
            'workflowId': workflowId,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to complete workflow for person: $e');
    }
  }

  static Future<void> pauseWorkflowForPerson(String personId, String personWorkflowId) async {
    try {
      await _firestore.collection(personWorkflowsCollection).doc(personWorkflowId).update({
        'status': 'paused',
        'lastUpdated': DateTime.now(),
      });

      await _logActivity(personId, 'workflow_paused', {
        'personWorkflowId': personWorkflowId,
      });
    } catch (e) {
      throw Exception('Failed to pause workflow for person: $e');
    }
  }

  // Bulk Operations
  static Future<void> bulkUpdatePersons(List<String> personIds, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      
      for (String personId in personIds) {
        final personRef = _firestore.collection(personsCollection).doc(personId);
        batch.update(personRef, {
          ...updates,
          'updatedAt': DateTime.now(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update persons: \$e');
    }
  }

  static Future<void> bulkDeletePersons(List<String> personIds) async {
    try {
      final batch = _firestore.batch();
      
      for (String personId in personIds) {
        final personRef = _firestore.collection(personsCollection).doc(personId);
        batch.delete(personRef);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk delete persons: \$e');
    }
  }



  // Profile Image Management (Base64 storage in Firestore document)
  static Future<void> updatePersonProfileImage(String personId, Uint8List imageBytes) async {
    try {
      await _firestore.collection(personsCollection).doc(personId).update({
        'profileImageUrl': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update profile image: \$e');
    }
  }

  // Activity Logging
  static Future<void> _logActivity(String personId, String action, Map<String, dynamic> changes) async {
    try {
      final userId = _auth.currentUser?.uid;
      await _firestore.collection(activityLogsCollection).add({
        'personId': personId,
        'action': action,
        'changes': changes,
        'timestamp': DateTime.now(),
        'userId': userId,
      });
    } catch (e) {
      // Log activity errors shouldn't fail the main operation
      print('Failed to log activity: \$e');
    }
  }

  // Statistics
  static Future<Map<String, int>> getPersonStatistics() async {
    try {
      final snapshot = await _firestore.collection(personsCollection).get();
      final persons = snapshot.docs.map((doc) => PersonModel.fromFirestore(doc)).toList();
      
      int totalActive = persons.where((p) => p.isActive).length;
      int totalInactive = persons.where((p) => !p.isActive).length;
      int totalMale = persons.where((p) => p.gender?.toLowerCase() == 'male').length;
      int totalFemale = persons.where((p) => p.gender?.toLowerCase() == 'female').length;
      
      return {
        'total': persons.length,
        'active': totalActive,
        'inactive': totalInactive,
        'male': totalMale,
        'female': totalFemale,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: \$e');
    }
  }

  // Search and Filter
  static Future<List<PersonModel>> searchPersons(String query) async {
    try {
      final snapshot = await _firestore.collection(personsCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final persons = snapshot.docs.map((doc) => PersonModel.fromFirestore(doc)).toList();
      
      final lowercaseQuery = query.toLowerCase();
      return persons.where((person) {
        return person.fullName.toLowerCase().contains(lowercaseQuery) ||
               person.email.toLowerCase().contains(lowercaseQuery) ||
               (person.phone?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search persons: \$e');
    }
  }

  // Duplicate Detection
  static Future<List<PersonModel>> findPotentialDuplicates() async {
    try {
      final snapshot = await _firestore.collection(personsCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final persons = snapshot.docs.map((doc) => PersonModel.fromFirestore(doc)).toList();
      final duplicates = <PersonModel>[];
      
      for (int i = 0; i < persons.length; i++) {
        for (int j = i + 1; j < persons.length; j++) {
          final person1 = persons[i];
          final person2 = persons[j];
          
          // Check for potential duplicates based on email or name similarity
          if (person1.email == person2.email ||
              (person1.firstName.toLowerCase() == person2.firstName.toLowerCase() &&
               person1.lastName.toLowerCase() == person2.lastName.toLowerCase())) {
            if (!duplicates.contains(person1)) duplicates.add(person1);
            if (!duplicates.contains(person2)) duplicates.add(person2);
          }
        }
      }
      
      return duplicates;
    } catch (e) {
      throw Exception('Failed to find duplicates: \$e');
    }
  }

  // Workflow Editing and Assignment Methods
  
  /// Met à jour les informations générales d'un workflow
  static Future<void> updateWorkflowInfo(String personId, String personWorkflowId, {
    String? notes,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastUpdated': DateTime.now(),
      };
      
      if (notes != null) updates['notes'] = notes;
      if (status != null) updates['status'] = status;

      await _firestore
          .collection(personWorkflowsCollection)
          .doc(personWorkflowId)
          .update(updates);

      await _logActivity(personId, 'workflow_updated', {
        'personWorkflowId': personWorkflowId,
        'updates': updates,
      });
    } catch (e) {
      throw Exception('Failed to update workflow info: $e');
    }
  }

  /// Assigne un responsable à une étape spécifique du workflow
  static Future<void> assignStepResponsible(String personId, String personWorkflowId, String stepId, String responsibleId, String responsibleName) async {
    try {
      // Récupérer le workflow actuel dans la collection person_workflows
      final workflowDoc = await _firestore
          .collection(personWorkflowsCollection)
          .doc(personWorkflowId)
          .get();

      if (!workflowDoc.exists) {
        throw Exception('Workflow not found');
      }

      final workflowData = workflowDoc.data()!;
      final workflowId = workflowData['workflowId'] as String;

      // Récupérer le template du workflow pour obtenir les étapes
      final workflowTemplateDoc = await _firestore
          .collection('workflows')
          .doc(workflowId)
          .get();

      if (!workflowTemplateDoc.exists) {
        throw Exception('Workflow template not found');
      }

      final workflowTemplate = WorkflowModel.fromFirestore(workflowTemplateDoc);
      final updatedSteps = workflowTemplate.steps.map((step) {
        if (step.id == stepId) {
          return step.copyWith(
            assignedTo: responsibleId,
            assignedToName: responsibleName,
          );
        }
        return step;
      }).toList();

      // Mettre à jour le template du workflow avec les nouvelles assignations
      await _firestore
          .collection('workflows')
          .doc(workflowId)
          .update({
            'steps': updatedSteps.map((step) => step.toMap()).toList(),
            'updatedAt': DateTime.now(),
          });

      await _logActivity(personId, 'workflow_step_assigned', {
        'personWorkflowId': personWorkflowId,
        'stepId': stepId,
        'assignedTo': responsibleId,
        'assignedToName': responsibleName,
      });
    } catch (e) {
      throw Exception('Failed to assign step responsible: $e');
    }
  }

  /// Retire l'assignation d'un responsable à une étape
  static Future<void> unassignStepResponsible(String personId, String personWorkflowId, String stepId) async {
    try {
      // Récupérer le workflow actuel dans la collection person_workflows
      final workflowDoc = await _firestore
          .collection(personWorkflowsCollection)
          .doc(personWorkflowId)
          .get();

      if (!workflowDoc.exists) {
        throw Exception('Workflow not found');
      }

      final workflowData = workflowDoc.data()!;
      final workflowId = workflowData['workflowId'] as String;

      // Récupérer le template du workflow pour obtenir les étapes
      final workflowTemplateDoc = await _firestore
          .collection('workflows')
          .doc(workflowId)
          .get();

      if (!workflowTemplateDoc.exists) {
        throw Exception('Workflow template not found');
      }

      final workflowTemplate = WorkflowModel.fromFirestore(workflowTemplateDoc);
      final updatedSteps = workflowTemplate.steps.map((step) {
        if (step.id == stepId) {
          return step.copyWith(
            assignedTo: null,
            assignedToName: null,
          );
        }
        return step;
      }).toList();

      // Mettre à jour le template du workflow
      await _firestore
          .collection('workflows')
          .doc(workflowId)
          .update({
            'steps': updatedSteps.map((step) => step.toMap()).toList(),
            'updatedAt': DateTime.now(),
          });

      await _logActivity(personId, 'workflow_step_unassigned', {
        'personWorkflowId': personWorkflowId,
        'stepId': stepId,
      });
    } catch (e) {
      throw Exception('Failed to unassign step responsible: $e');
    }
  }

  /// Met à jour les détails d'une étape du workflow
  static Future<void> updateWorkflowStep(String personId, String personWorkflowId, String stepId, {
    String? name,
    String? description,
    int? estimatedDuration,
    bool? isRequired,
  }) async {
    try {
      // Récupérer le workflow actuel dans la collection person_workflows
      final workflowDoc = await _firestore
          .collection(personWorkflowsCollection)
          .doc(personWorkflowId)
          .get();

      if (!workflowDoc.exists) {
        throw Exception('Workflow not found');
      }

      final workflowData = workflowDoc.data()!;
      final workflowId = workflowData['workflowId'] as String;

      // Récupérer le template du workflow
      final workflowTemplateDoc = await _firestore
          .collection('workflows')
          .doc(workflowId)
          .get();

      if (!workflowTemplateDoc.exists) {
        throw Exception('Workflow template not found');
      }

      final workflowTemplate = WorkflowModel.fromFirestore(workflowTemplateDoc);
      final updatedSteps = workflowTemplate.steps.map((step) {
        if (step.id == stepId) {
          return step.copyWith(
            name: name ?? step.name,
            description: description ?? step.description,
            estimatedDuration: estimatedDuration ?? step.estimatedDuration,
            isRequired: isRequired ?? step.isRequired,
          );
        }
        return step;
      }).toList();

      // Mettre à jour le template du workflow
      await _firestore
          .collection('workflows')
          .doc(workflowId)
          .update({
            'steps': updatedSteps.map((step) => step.toMap()).toList(),
            'updatedAt': DateTime.now(),
          });

      await _logActivity(personId, 'workflow_step_updated', {
        'personWorkflowId': personWorkflowId,
        'stepId': stepId,
        'updates': {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
          if (isRequired != null) 'isRequired': isRequired,
        },
      });
    } catch (e) {
      throw Exception('Failed to update workflow step: $e');
    }
  }

  /// Récupère toutes les personnes disponibles pour assignation
  static Future<List<PersonModel>> getAvailablePersonsForAssignment() async {
    try {
      // Essayer d'abord avec tri
      final snapshot = await _firestore
          .collection(personsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('lastName')
          .get();

      final persons = snapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();
      
      // Tri local si nécessaire
      persons.sort((a, b) => a.lastName.compareTo(b.lastName));
      
      return persons;
    } catch (e) {
      // Si échec avec tri, essayer sans tri
      try {
        final snapshot = await _firestore
            .collection(personsCollection)
            .where('isActive', isEqualTo: true)
            .get();

        final persons = snapshot.docs
            .map((doc) => PersonModel.fromFirestore(doc))
            .toList();
        
        // Tri local
        persons.sort((a, b) => a.lastName.compareTo(b.lastName));
        
        return persons;
      } catch (e2) {
        throw Exception('Failed to get available persons: $e2');
      }
    }
  }

  /// Récupère les workflows assignés à une personne spécifique
  static Stream<List<PersonWorkflowModel>> getPersonAssignedWorkflows(String assignedPersonId) {
    try {
      return _firestore
          .collectionGroup('workflows')
          .where('assignedTo', isEqualTo: assignedPersonId)
          .orderBy('lastUpdated', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PersonWorkflowModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.error('Failed to get assigned workflows: $e');
    }
  }

  /// Récupère tous les suivis (workflows) où une personne est responsable d'étapes
  static Future<List<Map<String, dynamic>>> getWorkflowsWithPersonAsResponsible(String personId) async {
    try {
      final List<Map<String, dynamic>> assignedWorkflows = [];
      
      // 1. Récupérer tous les templates de workflows
      final workflowTemplates = await _firestore
          .collection(workflowsCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      // 2. Pour chaque template, vérifier s'il y a des étapes assignées à cette personne
      for (final templateDoc in workflowTemplates.docs) {
        final workflowTemplate = WorkflowModel.fromFirestore(templateDoc);
        
        // Rechercher les étapes assignées à cette personne
        final assignedSteps = workflowTemplate.steps
            .where((step) => step.assignedTo == personId)
            .toList();
        
        if (assignedSteps.isNotEmpty) {
          // 3. Pour chaque template avec des étapes assignées, 
          // récupérer les instances actives de ce workflow
          final personWorkflows = await _firestore
              .collection(personWorkflowsCollection)
              .where('workflowId', isEqualTo: workflowTemplate.id)
              .where('status', whereIn: ['active', 'in_progress', 'pending'])
              .get();
          
          // 4. Ajouter chaque instance avec les détails nécessaires
          for (final personWorkflowDoc in personWorkflows.docs) {
            final personWorkflow = PersonWorkflowModel.fromFirestore(personWorkflowDoc);
            
            // Récupérer les infos de la personne suivie
            final personDoc = await _firestore
                .collection(personsCollection)
                .doc(personWorkflow.personId)
                .get();
            
            if (personDoc.exists) {
              final person = PersonModel.fromFirestore(personDoc);
              
              assignedWorkflows.add({
                'personWorkflow': personWorkflow,
                'workflowTemplate': workflowTemplate,
                'followedPerson': person,
                'assignedSteps': assignedSteps,
                'totalSteps': workflowTemplate.steps.length,
                'completedSteps': personWorkflow.completedSteps.length,
              });
            }
          }
        }
      }
      
      // Trier par date de dernière mise à jour
      assignedWorkflows.sort((a, b) {
        final dateA = (a['personWorkflow'] as PersonWorkflowModel).lastUpdated;
        final dateB = (b['personWorkflow'] as PersonWorkflowModel).lastUpdated;
        return dateB.compareTo(dateA);
      });
      
      return assignedWorkflows;
    } catch (e) {
      throw Exception('Failed to get workflows with person as responsible: $e');
    }
  }

  static Future<void> deleteFamily(String familyId) async {
    try {
      // Remove familyId from all persons who belong to this family
      final personsQuery = await _firestore
          .collection(personsCollection)
          .where('familyId', isEqualTo: familyId)
          .get();
      final batch = _firestore.batch();
      for (final doc in personsQuery.docs) {
        batch.update(doc.reference, {'familyId': null, 'updatedAt': DateTime.now()});
      }
      // Delete the family document
      batch.delete(_firestore.collection(familiesCollection).doc(familyId));
      await batch.commit();
      await _logActivity(familyId, 'delete', {'action': 'Family deleted and members updated'});
    } catch (e) {
      throw Exception('Failed to delete family and update members: $e');
    }
  }
}