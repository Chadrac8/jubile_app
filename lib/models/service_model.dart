import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final String type; // 'culte', 'repetition', 'evenement_special', 'reunion'
  final DateTime dateTime;
  final String location;
  final int durationMinutes;
  final String status; // 'brouillon', 'publie', 'archive', 'annule'
  final String? notes;
  final List<String> teamIds;
  final List<String> attachmentUrls;
  final Map<String, dynamic> customFields;
  final bool isRecurring;
  final Map<String, dynamic>? recurrencePattern;
  final String? templateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.dateTime,
    required this.location,
    this.durationMinutes = 90,
    this.status = 'brouillon',
    this.notes,
    this.teamIds = const [],
    this.attachmentUrls = const [],
    this.customFields = const {},
    this.isRecurring = false,
    this.recurrencePattern,
    this.templateId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
  });

  String get typeLabel {
    switch (type) {
      case 'culte': return 'Culte';
      case 'repetition': return 'Répétition';
      case 'evenement_special': return 'Événement spécial';
      case 'reunion': return 'Réunion';
      default: return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'brouillon': return 'Brouillon';
      case 'publie': return 'Publié';
      case 'archive': return 'Archivé';
      case 'annule': return 'Annulé';
      default: return status;
    }
  }

  bool get isPublished => status == 'publie';
  bool get isDraft => status == 'brouillon';
  bool get isArchived => status == 'archive';
  bool get isCancelled => status == 'annule';

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: data['type'] ?? 'culte',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 90,
      status: data['status'] ?? 'brouillon',
      notes: data['notes'],
      teamIds: List<String>.from(data['teamIds'] ?? []),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      isRecurring: data['isRecurring'] ?? false,
      recurrencePattern: data['recurrencePattern'],
      templateId: data['templateId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'durationMinutes': durationMinutes,
      'status': status,
      'notes': notes,
      'teamIds': teamIds,
      'attachmentUrls': attachmentUrls,
      'customFields': customFields,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'templateId': templateId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  ServiceModel copyWith({
    String? name,
    String? description,
    String? type,
    DateTime? dateTime,
    String? location,
    int? durationMinutes,
    String? status,
    String? notes,
    List<String>? teamIds,
    List<String>? attachmentUrls,
    Map<String, dynamic>? customFields,
    bool? isRecurring,
    Map<String, dynamic>? recurrencePattern,
    String? templateId,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return ServiceModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      teamIds: teamIds ?? this.teamIds,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      customFields: customFields ?? this.customFields,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class ServiceSheetModel {
  final String id;
  final String serviceId;
  final String title;
  final List<ServiceSheetItem> items;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  ServiceSheetModel({
    required this.id,
    required this.serviceId,
    required this.title,
    this.items = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  int get totalDuration => items.fold(0, (sum, item) => sum + item.durationMinutes);

  factory ServiceSheetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceSheetModel(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      title: data['title'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => ServiceSheetItem.fromMap(item))
          .toList() ?? [],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceId': serviceId,
      'title': title,
      'items': items.map((item) => item.toMap()).toList(),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }
}

class ServiceSheetItem {
  final String id;
  final String type; // 'section', 'louange', 'predication', 'annonce', 'priere', 'chant', 'lecture', 'offrande', 'autre'
  final String title;
  final String? description;
  final int order;
  final int durationMinutes;
  final String? responsiblePersonId;
  // Removed songId reference - Songs module deleted
  final List<String> attachmentUrls;
  final Map<String, dynamic> customData;

  ServiceSheetItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.order,
    this.durationMinutes = 5,
    this.responsiblePersonId,
    // this.songId, // Removed - Songs module deleted
    this.attachmentUrls = const [],
    this.customData = const {},
  });

  String get typeLabel {
    switch (type) {
      case 'section': return 'Section';
      case 'louange': return 'Louange';
      case 'predication': return 'Prédication';
      case 'annonce': return 'Annonces';
      case 'priere': return 'Prière';
      case 'chant': return 'Chant';
      case 'lecture': return 'Lecture';
      case 'offrande': return 'Offrande';
      case 'autre': return 'Autre';
      default: return type;
    }
  }

  factory ServiceSheetItem.fromMap(Map<String, dynamic> map) {
    return ServiceSheetItem(
      id: map['id'] ?? '',
      type: map['type'] ?? 'autre',
      title: map['title'] ?? '',
      description: map['description'],
      order: map['order'] ?? 0,
      durationMinutes: map['durationMinutes'] ?? 5,
      responsiblePersonId: map['responsiblePersonId'],
      // songId: map['songId'], // Removed - Songs module deleted
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      customData: Map<String, dynamic>.from(map['customData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'order': order,
      'durationMinutes': durationMinutes,
      'responsiblePersonId': responsiblePersonId,
      // 'songId': songId, // Removed - Songs module deleted
      'attachmentUrls': attachmentUrls,
      'customData': customData,
    };
  }
}

class TeamModel {
  final String id;
  final String name;
  final String description;
  final String color;
  final List<String> positionIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.positionIds = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      color: data['color'] ?? '#6F61EF',
      positionIds: List<String>.from(data['positionIds'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'positionIds': positionIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class PositionModel {
  final String id;
  final String teamId;
  final String name;
  final String description;
  final bool isLeaderPosition;
  final List<String> requiredSkills;
  final int maxAssignments; // Maximum number of people for this position per service
  final bool isActive;
  final DateTime createdAt;

  PositionModel({
    required this.id,
    required this.teamId,
    required this.name,
    required this.description,
    this.isLeaderPosition = false,
    this.requiredSkills = const [],
    this.maxAssignments = 1,
    this.isActive = true,
    required this.createdAt,
  });

  factory PositionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PositionModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      isLeaderPosition: data['isLeaderPosition'] ?? false,
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      maxAssignments: data['maxAssignments'] ?? 1,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'name': name,
      'description': description,
      'isLeaderPosition': isLeaderPosition,
      'requiredSkills': requiredSkills,
      'maxAssignments': maxAssignments,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ServiceAssignmentModel {
  final String id;
  final String serviceId;
  final String positionId;
  final String personId;
  final String status; // 'invited', 'accepted', 'declined', 'tentative', 'confirmed'
  final String? notes;
  final DateTime? respondedAt;
  final DateTime? lastReminderSent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedBy;

  ServiceAssignmentModel({
    required this.id,
    required this.serviceId,
    required this.positionId,
    required this.personId,
    this.status = 'invited',
    this.notes,
    this.respondedAt,
    this.lastReminderSent,
    required this.createdAt,
    required this.updatedAt,
    this.assignedBy,
  });

  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isPending => status == 'invited' || status == 'tentative';
  bool get isConfirmed => status == 'confirmed';

  String get statusLabel {
    switch (status) {
      case 'invited': return 'Invité';
      case 'accepted': return 'Accepté';
      case 'declined': return 'Refusé';
      case 'tentative': return 'Peut-être';
      case 'confirmed': return 'Confirmé';
      default: return status;
    }
  }

  factory ServiceAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceAssignmentModel(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      positionId: data['positionId'] ?? '',
      personId: data['personId'] ?? '',
      status: data['status'] ?? 'invited',
      notes: data['notes'],
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate() 
          : null,
      lastReminderSent: data['lastReminderSent'] != null 
          ? (data['lastReminderSent'] as Timestamp).toDate() 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      assignedBy: data['assignedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceId': serviceId,
      'positionId': positionId,
      'personId': personId,
      'status': status,
      'notes': notes,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'lastReminderSent': lastReminderSent != null ? Timestamp.fromDate(lastReminderSent!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedBy': assignedBy,
    };
  }
}

class PersonAvailabilityModel {
  final String id;
  final String personId;
  final DateTime startDate;
  final DateTime endDate;
  final String availabilityType; // 'available', 'unavailable', 'preferred', 'limited'
  final String? notes;
  final List<String> preferredTeams;
  final List<String> preferredPositions;
  final DateTime createdAt;

  PersonAvailabilityModel({
    required this.id,
    required this.personId,
    required this.startDate,
    required this.endDate,
    required this.availabilityType,
    this.notes,
    this.preferredTeams = const [],
    this.preferredPositions = const [],
    required this.createdAt,
  });

  bool get isAvailable => availabilityType == 'available';
  bool get isUnavailable => availabilityType == 'unavailable';

  String get typeLabel {
    switch (availabilityType) {
      case 'available': return 'Disponible';
      case 'unavailable': return 'Indisponible';
      case 'preferred': return 'Préféré';
      case 'limited': return 'Limité';
      default: return availabilityType;
    }
  }

  factory PersonAvailabilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonAvailabilityModel(
      id: doc.id,
      personId: data['personId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      availabilityType: data['availabilityType'] ?? 'available',
      notes: data['notes'],
      preferredTeams: List<String>.from(data['preferredTeams'] ?? []),
      preferredPositions: List<String>.from(data['preferredPositions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personId': personId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'availabilityType': availabilityType,
      'notes': notes,
      'preferredTeams': preferredTeams,
      'preferredPositions': preferredPositions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ServiceStatisticsModel {
  final String serviceId;
  final int totalAssignments;
  final int acceptedAssignments;
  final int declinedAssignments;
  final int pendingAssignments;
  final Map<String, int> assignmentsByTeam;
  final Map<String, int> assignmentsByPosition;
  final double responseRate;
  final DateTime lastUpdated;

  ServiceStatisticsModel({
    required this.serviceId,
    required this.totalAssignments,
    required this.acceptedAssignments,
    required this.declinedAssignments,
    required this.pendingAssignments,
    required this.assignmentsByTeam,
    required this.assignmentsByPosition,
    required this.responseRate,
    required this.lastUpdated,
  });

  factory ServiceStatisticsModel.fromMap(Map<String, dynamic> data) {
    return ServiceStatisticsModel(
      serviceId: data['serviceId'] ?? '',
      totalAssignments: data['totalAssignments'] ?? 0,
      acceptedAssignments: data['acceptedAssignments'] ?? 0,
      declinedAssignments: data['declinedAssignments'] ?? 0,
      pendingAssignments: data['pendingAssignments'] ?? 0,
      assignmentsByTeam: Map<String, int>.from(data['assignmentsByTeam'] ?? {}),
      assignmentsByPosition: Map<String, int>.from(data['assignmentsByPosition'] ?? {}),
      responseRate: (data['responseRate'] ?? 0.0).toDouble(),
      lastUpdated: data['lastUpdated'] is Timestamp 
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'totalAssignments': totalAssignments,
      'acceptedAssignments': acceptedAssignments,
      'declinedAssignments': declinedAssignments,
      'pendingAssignments': pendingAssignments,
      'assignmentsByTeam': assignmentsByTeam,
      'assignmentsByPosition': assignmentsByPosition,
      'responseRate': responseRate,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}