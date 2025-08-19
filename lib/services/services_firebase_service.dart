import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';
import '../models/person_model.dart';

class ServicesFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String servicesCollection = 'services';
  static const String serviceSheetsCollection = 'service_sheets';
  static const String teamsCollection = 'teams';
  static const String positionsCollection = 'positions';
  static const String serviceAssignmentsCollection = 'service_assignments';
  static const String personAvailabilityCollection = 'person_availability';
  static const String serviceActivityLogsCollection = 'service_activity_logs';

  // Service CRUD Operations
  static Future<String> createService(ServiceModel service) async {
    try {
      final docRef = await _firestore.collection(servicesCollection).add(service.toFirestore());
      await _logServiceActivity(docRef.id, 'service_created', {
        'name': service.name,
        'type': service.type,
        'dateTime': service.dateTime.toIso8601String(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du service: $e');
    }
  }

  static Future<void> updateService(ServiceModel service) async {
    try {
      await _firestore.collection(servicesCollection)
          .doc(service.id)
          .update(service.toFirestore());
      await _logServiceActivity(service.id, 'service_updated', {
        'name': service.name,
        'status': service.status,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du service: $e');
    }
  }

  static Future<void> deleteService(String serviceId) async {
    try {
      // Delete related assignments first
      final assignmentsQuery = await _firestore
          .collection(serviceAssignmentsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in assignmentsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete service sheets
      final sheetsQuery = await _firestore
          .collection(serviceSheetsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .get();
      
      for (final doc in sheetsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete the service
      batch.delete(_firestore.collection(servicesCollection).doc(serviceId));
      
      await batch.commit();
      await _logServiceActivity(serviceId, 'service_deleted', {});
    } catch (e) {
      throw Exception('Erreur lors de la suppression du service: $e');
    }
  }

  static Future<ServiceModel?> getService(String serviceId) async {
    try {
      final doc = await _firestore.collection(servicesCollection).doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du service: $e');
    }
  }

  static Stream<List<ServiceModel>> getServicesStream({
    String? searchQuery,
    List<String>? typeFilters,
    List<String>? statusFilters,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    try {
      Query query = _firestore.collection(servicesCollection);

      // Apply type filters
      if (typeFilters != null && typeFilters.isNotEmpty) {
        query = query.where('type', whereIn: typeFilters);
      }

      // Apply status filters
      if (statusFilters != null && statusFilters.isNotEmpty) {
        query = query.where('status', whereIn: statusFilters);
      }

      // Apply date range filters
      if (startDate != null) {
        query = query.where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('dateTime', descending: false).limit(limit);

      return query.snapshots().map((snapshot) {
        List<ServiceModel> services = snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList();

        // Apply text search filter on client side
        if (searchQuery != null && searchQuery.isNotEmpty) {
          services = services.where((service) {
            return service.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (service.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                service.location.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();
        }

        return services;
      });
    } catch (e) {
      throw Exception('Erreur lors du chargement des services: $e');
    }
  }

  // Service Sheet Management
  static Future<String> createServiceSheet(ServiceSheetModel sheet) async {
    try {
      final docRef = await _firestore.collection(serviceSheetsCollection).add(sheet.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la feuille de service: $e');
    }
  }

  static Future<void> updateServiceSheet(ServiceSheetModel sheet) async {
    try {
      await _firestore.collection(serviceSheetsCollection)
          .doc(sheet.id)
          .update(sheet.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la feuille de service: $e');
    }
  }

  static Future<ServiceSheetModel?> getServiceSheet(String serviceId) async {
    try {
      final query = await _firestore
          .collection(serviceSheetsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return ServiceSheetModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la feuille de service: $e');
    }
  }

  // Team Management
  static Future<String> createTeam(TeamModel team) async {
    try {
      final docRef = await _firestore.collection(teamsCollection).add(team.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'équipe: $e');
    }
  }

  static Future<void> updateTeam(TeamModel team) async {
    try {
      await _firestore
          .collection(teamsCollection)
          .doc(team.id)
          .update(team.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'équipe: $e');
    }
  }

  static Stream<List<TeamModel>> getTeamsStream() {
    return _getTeamsStreamWithFallback();
  }

  // Méthode principale optimisée avec fallback
  static Stream<List<TeamModel>> _getTeamsStreamWithFallback() {
    try {
      // Essayer avec index composite optimisé: isActive + name
      return _firestore
          .collection(teamsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TeamModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Fallback pour getTeamsStream: $e');
      // Fallback avec tri côté client
      return _getTeamsStreamSimple();
    }
  }

  // Méthode de fallback simple
  static Stream<List<TeamModel>> _getTeamsStreamSimple() {
    return _firestore
        .collection(teamsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final teams = snapshot.docs
              .map((doc) => TeamModel.fromFirestore(doc))
              .toList();
          
          // Tri côté client par nom
          teams.sort((a, b) => a.name.compareTo(b.name));
          return teams;
        });
  }

  // Position Management
  static Future<String> createPosition(PositionModel position) async {
    try {
      final docRef = await _firestore.collection(positionsCollection).add(position.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la position: $e');
    }
  }

  static Stream<List<PositionModel>> getPositionsForTeam(String teamId) {
    return _getPositionsForTeamWithFallback(teamId);
  }

  // Méthode principale optimisée avec fallback pour positions d'équipe
  static Stream<List<PositionModel>> _getPositionsForTeamWithFallback(String teamId) {
    try {
      // Essayer avec index composite optimisé: teamId + isActive + name
      return _firestore
          .collection(positionsCollection)
          .where('teamId', isEqualTo: teamId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PositionModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Fallback pour getPositionsForTeam: $e');
      // Fallback avec tri côté client
      return _getPositionsForTeamSimple(teamId);
    }
  }

  // Méthode de fallback simple pour positions d'équipe
  static Stream<List<PositionModel>> _getPositionsForTeamSimple(String teamId) {
    return _firestore
        .collection(positionsCollection)
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
          final positions = snapshot.docs
              .map((doc) => PositionModel.fromFirestore(doc))
              .where((pos) => pos.isActive) // Filtrage côté client
              .toList();
          
          // Tri côté client par nom
          positions.sort((a, b) => a.name.compareTo(b.name));
          return positions;
        });
  }

  static Stream<List<PositionModel>> getAllPositionsStream() {
    return _getAllPositionsStreamWithFallback();
  }

  // Méthode Future optimisée pour obtenir toutes les positions en une seule fois
  static Future<List<PositionModel>> getAllPositionsList() async {
    try {
      // Essayer avec index simple: isActive + name
      final snapshot = await _firestore
          .collection(positionsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      return snapshot.docs
          .map((doc) => PositionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Fallback pour getAllPositionsList: $e');
      // Fallback avec tri côté client
      final snapshot = await _firestore
          .collection(positionsCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final positions = snapshot.docs
          .map((doc) => PositionModel.fromFirestore(doc))
          .toList();
      
      // Tri côté client par nom
      positions.sort((a, b) => a.name.compareTo(b.name));
      return positions;
    }
  }

  // Méthode principale optimisée avec fallback pour toutes les positions
  static Stream<List<PositionModel>> _getAllPositionsStreamWithFallback() {
    try {
      // Essayer avec index simple: isActive + name
      return _firestore
          .collection(positionsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PositionModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Fallback pour getAllPositionsStream: $e');
      // Fallback avec tri côté client
      return _getAllPositionsStreamSimple();
    }
  }

  // Méthode de fallback simple pour toutes les positions
  static Stream<List<PositionModel>> _getAllPositionsStreamSimple() {
    return _firestore
        .collection(positionsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final positions = snapshot.docs
              .map((doc) => PositionModel.fromFirestore(doc))
              .toList();
          
          // Tri côté client par nom
          positions.sort((a, b) => a.name.compareTo(b.name));
          return positions;
        });
  }

  // Assignment Management
  static Future<String> createAssignment(ServiceAssignmentModel assignment) async {
    try {
      final docRef = await _firestore.collection(serviceAssignmentsCollection).add(assignment.toFirestore());
      await _logServiceActivity(assignment.serviceId, 'assignment_created', {
        'positionId': assignment.positionId,
        'personId': assignment.personId,
        'status': assignment.status,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'affectation: $e');
    }
  }

  static Future<void> updateAssignment(ServiceAssignmentModel assignment) async {
    try {
      await _firestore.collection(serviceAssignmentsCollection)
          .doc(assignment.id)
          .update(assignment.toFirestore());
      await _logServiceActivity(assignment.serviceId, 'assignment_updated', {
        'assignmentId': assignment.id,
        'status': assignment.status,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'affectation: $e');
    }
  }

  static Future<void> removeAssignment(String assignmentId) async {
    try {
      await _firestore.collection(serviceAssignmentsCollection).doc(assignmentId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'affectation: $e');
    }
  }

  static Stream<List<ServiceAssignmentModel>> getServiceAssignmentsStream(String serviceId) {
    try {
      return _firestore
          .collection(serviceAssignmentsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ServiceAssignmentModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors du chargement des affectations: $e');
    }
  }

  static Future<List<ServiceAssignmentModel>> getPersonAssignments(String personId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection(serviceAssignmentsCollection)
          .where('personId', isEqualTo: personId);

      final assignments = await query.get();
      List<ServiceAssignmentModel> result = assignments.docs
          .map((doc) => ServiceAssignmentModel.fromFirestore(doc))
          .toList();

      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        // This would require additional service date lookup
        // For now, return all assignments
      }

      return result;
    } catch (e) {
      throw Exception('Erreur lors du chargement des affectations de la personne: $e');
    }
  }

  // Nouvelle méthode pour récupérer toutes les assignations en une seule requête
  static Future<List<ServiceAssignmentModel>> getAllAssignments({int limit = 100}) async {
    try {
      final query = _firestore
          .collection(serviceAssignmentsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ServiceAssignmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement de toutes les assignations: $e');
    }
  }

  // Méthode pour récupérer les assignations d'une liste de services
  static Future<List<ServiceAssignmentModel>> getAssignmentsForServices(List<String> serviceIds) async {
    try {
      if (serviceIds.isEmpty) return [];
      
      // Firestore limite les requêtes "in" à 10 éléments
      final List<ServiceAssignmentModel> allAssignments = [];
      
      // Traiter par groupes de 10
      for (int i = 0; i < serviceIds.length; i += 10) {
        final batch = serviceIds.skip(i).take(10).toList();
        
        final query = _firestore
            .collection(serviceAssignmentsCollection)
            .where('serviceId', whereIn: batch);

        final snapshot = await query.get();
        final batchAssignments = snapshot.docs
            .map((doc) => ServiceAssignmentModel.fromFirestore(doc))
            .toList();
        
        allAssignments.addAll(batchAssignments);
      }
      
      return allAssignments;
    } catch (e) {
      throw Exception('Erreur lors du chargement des assignations pour les services: $e');
    }
  }

  // Méthode pour récupérer les assignations d'une liste de positions
  static Future<List<ServiceAssignmentModel>> getServiceAssignmentsByPositionIds(List<String> positionIds) async {
    try {
      if (positionIds.isEmpty) return [];
      
      // Firestore limite les requêtes "in" à 10 éléments
      final List<ServiceAssignmentModel> allAssignments = [];
      
      // Traiter par groupes de 10
      for (int i = 0; i < positionIds.length; i += 10) {
        final batch = positionIds.skip(i).take(10).toList();
        
        final query = _firestore
            .collection(serviceAssignmentsCollection)
            .where('positionId', whereIn: batch)
            .orderBy('createdAt', descending: true);

        final snapshot = await query.get();
        final batchAssignments = snapshot.docs
            .map((doc) => ServiceAssignmentModel.fromFirestore(doc))
            .toList();
        
        allAssignments.addAll(batchAssignments);
      }
      
      return allAssignments;
    } catch (e) {
      throw Exception('Erreur lors du chargement des assignations pour les positions: $e');
    }
  }

  // Availability Management
  static Future<String> createAvailability(PersonAvailabilityModel availability) async {
    try {
      final docRef = await _firestore.collection(personAvailabilityCollection).add(availability.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la disponibilité: $e');
    }
  }

  static Stream<List<PersonAvailabilityModel>> getPersonAvailabilityStream(String personId) {
    try {
      return _firestore
          .collection(personAvailabilityCollection)
          .where('personId', isEqualTo: personId)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PersonAvailabilityModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors du chargement des disponibilités: $e');
    }
  }

  // Service Templates
  static Future<String> duplicateService(String originalServiceId, String newName, DateTime newDate) async {
    try {
      final originalService = await getService(originalServiceId);
      if (originalService == null) {
        throw Exception('Service original non trouvé');
      }

      // Create new service
      final newService = originalService.copyWith(
        name: newName,
        dateTime: newDate,
        status: 'brouillon',
        updatedAt: DateTime.now(),
        lastModifiedBy: _auth.currentUser?.uid,
      );

      final newServiceId = await createService(newService);

      // Copy service sheet if exists
      final originalSheet = await getServiceSheet(originalServiceId);
      if (originalSheet != null) {
        final newSheet = ServiceSheetModel(
          id: '',
          serviceId: newServiceId,
          title: originalSheet.title,
          items: originalSheet.items,
          notes: originalSheet.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: _auth.currentUser?.uid,
        );
        await createServiceSheet(newSheet);
      }

      return newServiceId;
    } catch (e) {
      throw Exception('Erreur lors de la duplication du service: $e');
    }
  }

  // Statistics
  static Future<ServiceStatisticsModel> getServiceStatistics(String serviceId) async {
    try {
      final assignments = await _firestore
          .collection(serviceAssignmentsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .get();

      int totalAssignments = assignments.docs.length;
      int acceptedAssignments = 0;
      int declinedAssignments = 0;
      int pendingAssignments = 0;
      Map<String, int> assignmentsByTeam = {};
      Map<String, int> assignmentsByPosition = {};

      for (final doc in assignments.docs) {
        final assignment = ServiceAssignmentModel.fromFirestore(doc);
        
        switch (assignment.status) {
          case 'accepted':
          case 'confirmed':
            acceptedAssignments++;
            break;
          case 'declined':
            declinedAssignments++;
            break;
          default:
            pendingAssignments++;
        }

        // Count by position
        assignmentsByPosition[assignment.positionId] = 
            (assignmentsByPosition[assignment.positionId] ?? 0) + 1;
      }

      double responseRate = totalAssignments > 0 
          ? (acceptedAssignments + declinedAssignments) / totalAssignments 
          : 0.0;

      return ServiceStatisticsModel(
        serviceId: serviceId,
        totalAssignments: totalAssignments,
        acceptedAssignments: acceptedAssignments,
        declinedAssignments: declinedAssignments,
        pendingAssignments: pendingAssignments,
        assignmentsByTeam: assignmentsByTeam,
        assignmentsByPosition: assignmentsByPosition,
        responseRate: responseRate,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Search and Filter
  static Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final services = await _firestore
          .collection(servicesCollection)
          .orderBy('dateTime', descending: true)
          .limit(100)
          .get();

      return services.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .where((service) =>
              service.name.toLowerCase().contains(query.toLowerCase()) ||
              (service.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              service.location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche de services: $e');
    }
  }

  // Export Functions
  static Future<List<Map<String, dynamic>>> exportServiceAssignments(String serviceId) async {
    try {
      final assignments = await _firestore
          .collection(serviceAssignmentsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .get();

      List<Map<String, dynamic>> exportData = [];
      for (final doc in assignments.docs) {
        final assignment = ServiceAssignmentModel.fromFirestore(doc);
        exportData.add({
          'ServiceID': assignment.serviceId,
          'PositionID': assignment.positionId,
          'PersonID': assignment.personId,
          'Status': assignment.statusLabel,
          'Notes': assignment.notes ?? '',
          'AssignedAt': assignment.createdAt.toIso8601String(),
          'RespondedAt': assignment.respondedAt?.toIso8601String() ?? '',
        });
      }
      return exportData;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des affectations: $e');
    }
  }

  // Reminder Functions
  static Future<void> sendReminder(String assignmentId) async {
    try {
      // Update last reminder sent timestamp
      await _firestore.collection(serviceAssignmentsCollection)
          .doc(assignmentId)
          .update({
            'lastReminderSent': Timestamp.fromDate(DateTime.now()),
          });
      
      // Here you would integrate with your notification system
      // For now, just log the activity
      await _logServiceActivity('', 'reminder_sent', {
        'assignmentId': assignmentId,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du rappel: $e');
    }
  }

  // Batch Operations
  static Future<void> assignTeamToService(String serviceId, String teamId) async {
    try {
      // Vérifier les positions de l'équipe avec fallback
      final positions = await _getTeamPositionsWithFallback(teamId);

      if (positions.isEmpty) {
        throw Exception('Aucune position trouvée pour cette équipe');
      }

      // Simply update the service to include this team
      final service = await getService(serviceId);
      if (service == null) {
        throw Exception('Service non trouvé');
      }

      final updatedTeamIds = List<String>.from(service.teamIds);
      if (!updatedTeamIds.contains(teamId)) {
        updatedTeamIds.add(teamId);
        
        await updateService(service.copyWith(
          teamIds: updatedTeamIds,
          updatedAt: DateTime.now(),
          lastModifiedBy: _auth.currentUser?.uid,
        ));
      }

      await _logServiceActivity(serviceId, 'team_assigned', {'teamId': teamId});
    } catch (e) {
      throw Exception('Erreur lors de l\'affectation de l\'équipe: $e');
    }
  }

  // Méthode helper pour récupérer les positions d'une équipe avec fallback
  static Future<List<PositionModel>> _getTeamPositionsWithFallback(String teamId) async {
    try {
      // Essayer avec index composite optimisé
      final snapshot = await _firestore
          .collection(positionsCollection)
          .where('teamId', isEqualTo: teamId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => PositionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Fallback pour _getTeamPositionsWithFallback: $e');
      // Fallback avec filtrage côté client
      final snapshot = await _firestore
          .collection(positionsCollection)
          .where('teamId', isEqualTo: teamId)
          .get();

      return snapshot.docs
          .map((doc) => PositionModel.fromFirestore(doc))
          .where((pos) => pos.isActive)
          .toList();
    }
  }

  static Future<void> archiveService(String serviceId) async {
    try {
      await updateService(
        (await getService(serviceId))!.copyWith(
          status: 'archive',
          updatedAt: DateTime.now(),
          lastModifiedBy: _auth.currentUser?.uid,
        )
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'archivage du service: $e');
    }
  }

  // Get available persons for service assignment
  static Future<List<PersonModel>> getAvailablePersonsForAssignment() async {
    try {
      final snapshot = await _firestore
          .collection('persons')
          .where('isActive', isEqualTo: true)
          .orderBy('lastName')
          .limit(100)
          .get();
      
      return snapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des personnes: $e');
      return [];
    }
  }

  // Helper Functions
  static Future<void> _logServiceActivity(String serviceId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(serviceActivityLogsCollection).add({
        'serviceId': serviceId,
        'action': action,
        'details': details,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Log errors but don't throw to avoid breaking main operations
      print('Error logging service activity: $e');
    }
  }

  // Predefined Data Creation
  static Future<void> createDefaultTeamsAndPositions() async {
    try {
      // Create default teams
      final defaultTeams = [
        {'name': 'Louange', 'description': 'Équipe de louange et musique', 'color': '#FF6B6B'},
        {'name': 'Accueil', 'description': 'Équipe d\'accueil et hôtesses', 'color': '#4ECDC4'},
        {'name': 'Technique', 'description': 'Équipe technique et son', 'color': '#45B7D1'},
        {'name': 'Prédication', 'description': 'Équipe de prédication', 'color': '#96CEB4'},
        {'name': 'Enfants', 'description': 'Équipe d\'animation enfants', 'color': '#FFEAA7'},
      ];

      for (final teamData in defaultTeams) {
        final team = TeamModel(
          id: '',
          name: teamData['name'] as String,
          description: teamData['description'] as String,
          color: teamData['color'] as String,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final teamId = await createTeam(team);

        // Create positions for each team
        final positions = _getDefaultPositionsForTeam(teamData['name'] as String);
        for (final positionData in positions) {
          final position = PositionModel(
            id: '',
            teamId: teamId,
            name: positionData['name'] as String,
            description: positionData['description'] as String,
            isLeaderPosition: positionData['isLeader'] as bool,
            maxAssignments: positionData['maxAssignments'] as int,
            createdAt: DateTime.now(),
          );
          
          await createPosition(position);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la création des équipes par défaut: $e');
    }
  }

  static List<Map<String, dynamic>> _getDefaultPositionsForTeam(String teamName) {
    switch (teamName) {
      case 'Louange':
        return [
          {'name': 'Chef de louange', 'description': 'Responsable de l\'équipe de louange', 'isLeader': true, 'maxAssignments': 1},
          {'name': 'Guitariste', 'description': 'Guitariste principal', 'isLeader': false, 'maxAssignments': 2},
          {'name': 'Bassiste', 'description': 'Joueur de basse', 'isLeader': false, 'maxAssignments': 1},
          {'name': 'Batteur', 'description': 'Batteur', 'isLeader': false, 'maxAssignments': 1},
          {'name': 'Chanteur', 'description': 'Chanteur/Choriste', 'isLeader': false, 'maxAssignments': 3},
        ];
      case 'Accueil':
        return [
          {'name': 'Responsable accueil', 'description': 'Responsable de l\'équipe d\'accueil', 'isLeader': true, 'maxAssignments': 1},
          {'name': 'Hôte/Hôtesse', 'description': 'Accueil des visiteurs', 'isLeader': false, 'maxAssignments': 4},
          {'name': 'Placier', 'description': 'Aide à l\'installation', 'isLeader': false, 'maxAssignments': 2},
        ];
      case 'Technique':
        return [
          {'name': 'Régisseur', 'description': 'Responsable technique', 'isLeader': true, 'maxAssignments': 1},
          {'name': 'Ingénieur son', 'description': 'Gestion du son', 'isLeader': false, 'maxAssignments': 1},
          {'name': 'Projectionniste', 'description': 'Gestion de la projection', 'isLeader': false, 'maxAssignments': 1},
          {'name': 'Éclairagiste', 'description': 'Gestion de l\'éclairage', 'isLeader': false, 'maxAssignments': 1},
        ];
      case 'Prédication':
        return [
          {'name': 'Prédicateur', 'description': 'Orateur principal', 'isLeader': true, 'maxAssignments': 1},
          {'name': 'Lecteur', 'description': 'Lecture des textes', 'isLeader': false, 'maxAssignments': 1},
        ];
      case 'Enfants':
        return [
          {'name': 'Responsable enfants', 'description': 'Responsable de l\'animation enfants', 'isLeader': true, 'maxAssignments': 1},
          {'name': 'Animateur', 'description': 'Animation des activités', 'isLeader': false, 'maxAssignments': 3},
        ];
      default:
        return [];
    }
  }

  // Additional methods for team and position management
  static Future<TeamModel?> getTeam(String teamId) async {
    try {
      final doc = await _firestore.collection(teamsCollection).doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'équipe: $e');
    }
  }

  static Future<void> deleteTeam(String teamId) async {
    try {
      // Get all positions for this team
      final positions = await getPositionsForTeam(teamId).first;
      
      // Delete all positions first
      for (final position in positions) {
        await deletePosition(position.id);
      }
      
      // Then delete the team
      await _firestore.collection(teamsCollection).doc(teamId).delete();
      
      await _logServiceActivity(teamId, 'team_deleted', {
        'teamId': teamId,
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'équipe: $e');
    }
  }

  static Future<List<PositionModel>> getPositionsForTeamAsList(String teamId) async {
    try {
      return await _getTeamPositionsWithFallback(teamId);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des positions: $e');
    }
  }

  static Future<PositionModel?> getPosition(String positionId) async {
    try {
      final doc = await _firestore.collection(positionsCollection).doc(positionId).get();
      if (doc.exists) {
        return PositionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la position: $e');
    }
  }

  static Future<void> updatePosition(PositionModel position) async {
    try {
      await _firestore.collection(positionsCollection)
          .doc(position.id)
          .update(position.toFirestore());
      
      await _logServiceActivity(position.teamId, 'position_updated', {
        'positionId': position.id,
        'positionName': position.name,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la position: $e');
    }
  }

  static Future<void> deletePosition(String positionId) async {
    try {
      // Get the position to log team info
      final doc = await _firestore.collection(positionsCollection).doc(positionId).get();
      final position = PositionModel.fromFirestore(doc);
      
      // Delete related assignments first
      final assignments = await _firestore.collection(serviceAssignmentsCollection)
          .where('positionId', isEqualTo: positionId)
          .get();
      
      for (final assignmentDoc in assignments.docs) {
        await assignmentDoc.reference.delete();
      }
      
      // Delete the position
      await _firestore.collection(positionsCollection).doc(positionId).delete();
      
      await _logServiceActivity(position.teamId, 'position_deleted', {
        'positionId': positionId,
        'positionName': position.name,
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la position: $e');
    }
  }
}