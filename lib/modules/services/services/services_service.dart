import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/services/base_firebase_service.dart';
import '../models/service.dart';
import '../models/service_assignment.dart';
import '../models/service_template.dart';


/// Service pour la gestion des services religieux
class ServicesService extends BaseFirebaseService<Service> {
  static final ServicesService _instance = ServicesService._internal();
  factory ServicesService() => _instance;
  ServicesService._internal();

  @override
  String get collectionName => 'services';

  // Collections liées
  final String _assignmentsCollection = 'service_assignments';
  final String _templatesCollection = 'service_templates';

  /// Instance de Firestore
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @override
  Service fromFirestore(DocumentSnapshot doc) {
    return Service.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(Service service) {
    return service.toMap();
  }

  // ==================== CRUD DE BASE ====================

  /// Crée un nouveau service
  Future<String> createService(Service service, {String? userId}) async {
    // Générer une image si aucune n'est fournie
    String? imageUrl = service.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = await "https://images.unsplash.com/photo-1499209974431-9dddcece7f88?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTA0MTU5MDR8&ixlib=rb-4.1.0&q=80&w=1080";
    }

    final serviceWithImage = service.copyWith(
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: userId ?? 'system',
    );

    return super.create(serviceWithImage);
  }

  /// Met à jour un service
  Future<void> updateService(String id, Service service, {String? userId}) async {
    final updatedService = service.copyWith(
      updatedAt: DateTime.now(),
    );

    await super.update(id, updatedService);
  }

  // ==================== REQUÊTES SPÉCIALISÉES ====================

  /// Obtient les services à venir
  Future<List<Service>> getUpcomingServices({int? limit}) async {
    try {
      final now = DateTime.now();
      Query query = collection
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startDate');

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des services à venir: $e');
    }
  }

  /// Obtient les services passés
  Future<List<Service>> getPastServices({int? limit}) async {
    try {
      final now = DateTime.now();
      Query query = collection
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('endDate', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des services passés: $e');
    }
  }

  /// Obtient les services par type
  Future<List<Service>> getServicesByType(ServiceType type) async {
    try {
      final snapshot = await collection
          .where('type', isEqualTo: type.name)
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des services par type: $e');
    }
  }

  /// Obtient les services par date
  Future<List<Service>> getServicesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await collection
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startDate', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startDate')
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des services par date: $e');
    }
  }

  /// Obtient les services par plage de dates
  Future<List<Service>> getServicesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await collection
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startDate')
          .get();

      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des services par plage: $e');
    }
  }

  /// Recherche des services
  Future<List<Service>> searchServices(String query) async {
    try {
      if (query.trim().isEmpty) {
        return getAll();
      }

      final searchQuery = query.toLowerCase().trim();
      final allServices = await getAll();

      return allServices.where((service) {
        return service.name.toLowerCase().contains(searchQuery) ||
               service.description.toLowerCase().contains(searchQuery) ||
               service.location.toLowerCase().contains(searchQuery) ||
               service.type.displayName.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // ==================== GESTION DES ASSIGNATIONS ====================

  /// Obtient les assignations d'un service
  Future<List<ServiceAssignment>> getServiceAssignments(String serviceId) async {
    try {
      final snapshot = await firestore
          .collection(_assignmentsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('role')
          .get();

      return snapshot.docs.map((doc) => ServiceAssignment.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des assignations: $e');
    }
  }

  /// Assigne un membre à un service
  Future<String> assignMemberToService({
    required String serviceId,
    required String memberId,
    required String memberName,
    required String role,
    List<String>? responsibilities,
    bool isTeamLead = false,
    String? notes,
    String? assignedBy,
  }) async {
    try {
      // Vérifier si l'assignation existe déjà
      final existingAssignment = await firestore
          .collection(_assignmentsCollection)
          .where('serviceId', isEqualTo: serviceId)
          .where('memberId', isEqualTo: memberId)
          .where('role', isEqualTo: role)
          .get();

      if (existingAssignment.docs.isNotEmpty) {
        throw Exception('Ce membre est déjà assigné à ce rôle pour ce service');
      }

      final assignment = ServiceAssignment(
        serviceId: serviceId,
        memberId: memberId,
        memberName: memberName,
        role: role,
        responsibilities: responsibilities ?? [],
        isTeamLead: isTeamLead,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignedBy: assignedBy ?? 'system',
      );

      final docRef = await firestore
          .collection(_assignmentsCollection)
          .add(assignment.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation: $e');
    }
  }

  /// Met à jour le statut d'une assignation
  Future<void> updateAssignmentStatus(
    String assignmentId,
    AssignmentStatus status, {
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == AssignmentStatus.confirmed) {
        updateData['confirmedAt'] = Timestamp.fromDate(DateTime.now());
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .update(updateData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Supprime une assignation
  Future<void> removeAssignment(String assignmentId) async {
    try {
      await firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'assignation: $e');
    }
  }

  /// Obtient les assignations d'un membre
  Future<List<ServiceAssignment>> getMemberAssignments(String memberId) async {
    try {
      final snapshot = await firestore
          .collection(_assignmentsCollection)
          .where('memberId', isEqualTo: memberId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => ServiceAssignment.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des assignations du membre: $e');
    }
  }

  // ==================== GESTION DES MODÈLES ====================

  /// Obtient tous les modèles de services
  Future<List<ServiceTemplate>> getServiceTemplates() async {
    try {
      final snapshot = await firestore
          .collection(_templatesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => ServiceTemplate.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modèles: $e');
    }
  }

  /// Crée un modèle de service
  Future<String> createTemplate(ServiceTemplate template, {String? userId}) async {
    try {
      // Générer une image si aucune n'est fournie
      String? imageUrl = template.imageUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = await "https://images.unsplash.com/photo-1560628094-39b8c3f430ec?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTA0MTUzMjZ8&ixlib=rb-4.1.0&q=80&w=1080";
      }

      final templateWithImage = template.copyWith(
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: userId ?? 'system',
      );

      final docRef = await firestore
          .collection(_templatesCollection)
          .add(templateWithImage.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du modèle: $e');
    }
  }

  /// Crée un service à partir d'un modèle
  Future<String> createServiceFromTemplate({
    required String templateId,
    required DateTime startDate,
    String? customName,
    String? customLocation,
    Map<String, dynamic>? overrideSettings,
    String? userId,
  }) async {
    try {
      final templateDoc = await firestore
          .collection(_templatesCollection)
          .doc(templateId)
          .get();

      if (!templateDoc.exists) {
        throw Exception('Modèle introuvable');
      }

      final template = ServiceTemplate.fromFirestore(templateDoc);
    final service = template.createService(
      startDate: startDate,
      customName: customName,
      customLocation: customLocation,
      overrideSettings: overrideSettings,
    );

    return createService(service, userId: userId);
    } catch (e) {
      throw Exception('Erreur lors de la création depuis le modèle: $e');
    }
  }

  // ==================== STATISTIQUES ====================

  /// Obtient les statistiques des services
  Future<Map<String, dynamic>> getServiceStatistics() async {
    try {
      final allServices = await getAll();
      final now = DateTime.now();

      final upcoming = allServices.where((s) => s.startDate.isAfter(now)).length;
      final past = allServices.where((s) => s.endDate.isBefore(now)).length;
      final today = allServices.where((s) => s.isToday).length;
      final thisWeek = allServices.where((s) => s.isThisWeek).length;

      // Statistiques par type
      final Map<String, int> byType = {};
      for (final service in allServices) {
        byType[service.type.displayName] = (byType[service.type.displayName] ?? 0) + 1;
      }

      // Services les plus fréquents
      final Map<String, int> byLocation = {};
      for (final service in allServices) {
        byLocation[service.location] = (byLocation[service.location] ?? 0) + 1;
      }

      return {
        'total': allServices.length,
        'upcoming': upcoming,
        'past': past,
        'today': today,
        'thisWeek': thisWeek,
        'byType': byType,
        'byLocation': byLocation,
        'averageDuration': _calculateAverageDuration(allServices),
        'totalDuration': _calculateTotalDuration(allServices),
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Calcule la durée moyenne des services
  double _calculateAverageDuration(List<Service> services) {
    if (services.isEmpty) return 0.0;
    
    final totalMinutes = services
        .map((s) => s.duration.inMinutes)
        .reduce((a, b) => a + b);
    
    return totalMinutes / services.length;
  }

  /// Calcule la durée totale des services
  int _calculateTotalDuration(List<Service> services) {
    if (services.isEmpty) return 0;
    
    return services
        .map((s) => s.duration.inMinutes)
        .reduce((a, b) => a + b);
  }

  /// Obtient les statistiques des assignations
  Future<Map<String, dynamic>> getAssignmentStatistics() async {
    try {
      final snapshot = await firestore
          .collection(_assignmentsCollection)
          .get();

      final assignments = snapshot.docs
          .map((doc) => ServiceAssignment.fromFirestore(doc))
          .toList();

      final Map<String, int> byStatus = {};
      final Map<String, int> byRole = {};

      for (final assignment in assignments) {
        byStatus[assignment.status.displayName] = 
            (byStatus[assignment.status.displayName] ?? 0) + 1;
        byRole[assignment.role] = 
            (byRole[assignment.role] ?? 0) + 1;
      }

      return {
        'total': assignments.length,
        'byStatus': byStatus,
        'byRole': byRole,
        'confirmedRate': _calculateConfirmedRate(assignments),
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques d\'assignation: $e');
    }
  }

  /// Calcule le taux de confirmation des assignations
  double _calculateConfirmedRate(List<ServiceAssignment> assignments) {
    if (assignments.isEmpty) return 0.0;
    
    final confirmed = assignments
        .where((a) => a.status == AssignmentStatus.confirmed)
        .length;
    
    return (confirmed / assignments.length) * 100;
  }

  // ==================== FONCTIONS UTILITAIRES ====================

  /// Duplique un service
  Future<String> duplicateService(String serviceId, {
    DateTime? newStartDate,
    String? newName,
    String? userId,
  }) async {
    try {
      final original = await getById(serviceId);
      if (original == null) {
        throw Exception('Service introuvable');
      }

      final startDate = newStartDate ?? original.startDate.add(const Duration(days: 7));
      final endDate = startDate.add(original.duration);

      final duplicate = original.copyWith(
        id: null,
        name: newName ?? '${original.name} (Copie)',
        startDate: startDate,
        endDate: endDate,
        status: ServiceStatus.scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: userId ?? original.createdBy,
      );

      return createService(duplicate, userId: userId);
    } catch (e) {
      throw Exception('Erreur lors de la duplication: $e');
    }
  }

  /// Annule un service
  Future<void> cancelService(String serviceId, {String? reason, String? userId}) async {
    try {
      final service = await getById(serviceId);
      if (service == null) {
        throw Exception('Service introuvable');
      }

      final cancelledService = service.copyWith(
        status: ServiceStatus.cancelled,
        notes: reason != null 
            ? '${service.notes ?? ''}\n\nAnnulé: $reason'
            : service.notes,
        updatedAt: DateTime.now(),
      );

      await updateService(serviceId, cancelledService, userId: userId);
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Marque un service comme terminé
  Future<void> completeService(String serviceId, {String? notes, String? userId}) async {
    try {
      final service = await getById(serviceId);
      if (service == null) {
        throw Exception('Service introuvable');
      }

      final completedService = service.copyWith(
        status: ServiceStatus.completed,
        notes: notes != null 
            ? '${service.notes ?? ''}\n\nTerminé: $notes'
            : service.notes,
        updatedAt: DateTime.now(),
      );

      await updateService(serviceId, completedService, userId: userId);

      // Marquer toutes les assignations comme terminées
      final assignments = await getServiceAssignments(serviceId);
      for (final assignment in assignments) {
        if (assignment.status == AssignmentStatus.confirmed) {
          await updateAssignmentStatus(assignment.id!, AssignmentStatus.completed);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la finalisation: $e');
    }
  }

  /// Obtient les services d'un membre
  Future<List<Service>> getMemberServices(String memberId) async {
    try {
      final assignments = await getMemberAssignments(memberId);
      final serviceIds = assignments.map((a) => a.serviceId).toSet();

      if (serviceIds.isEmpty) return [];

      final services = <Service>[];
      for (final serviceId in serviceIds) {
        final service = await getById(serviceId);
        if (service != null) {
          services.add(service);
        }
      }

      // Trier par date
      services.sort((a, b) => b.startDate.compareTo(a.startDate));
      
      return services;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des services du membre: $e');
    }
  }
}