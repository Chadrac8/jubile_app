import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les services religieux
class Service {
  final String? id;
  final String name;
  final String description;
  final ServiceType type;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final ServiceStatus status;
  final String? imageUrl;
  final String? colorCode;
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final List<String> assignedMembers;
  final List<String> equipmentNeeded;
  final String? notes;
  final String? streamingUrl;
  final bool isStreamingEnabled;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Service({
    this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.status = ServiceStatus.scheduled,
    this.imageUrl,
    this.colorCode,
    this.isRecurring = false,
    this.recurrencePattern,
    this.assignedMembers = const [],
    this.equipmentNeeded = const [],
    this.notes,
    this.streamingUrl,
    this.isStreamingEnabled = false,
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Crée un service à partir d'un document Firestore
  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Service.fromMap(data, doc.id);
  }

  /// Crée un service à partir d'une map
  factory Service.fromMap(Map<String, dynamic> data, String id) {
    return Service(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ServiceType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ServiceType.worship,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      status: ServiceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ServiceStatus.scheduled,
      ),
      imageUrl: data['imageUrl'],
      colorCode: data['colorCode'],
      isRecurring: data['isRecurring'] ?? false,
      recurrencePattern: data['recurrencePattern'] != null
          ? RecurrencePattern.fromMap(data['recurrencePattern'])
          : null,
      assignedMembers: List<String>.from(data['assignedMembers'] ?? []),
      equipmentNeeded: List<String>.from(data['equipmentNeeded'] ?? []),
      notes: data['notes'],
      streamingUrl: data['streamingUrl'],
      isStreamingEnabled: data['isStreamingEnabled'] ?? false,
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Convertit le service vers une map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'status': status.name,
      'imageUrl': imageUrl,
      'colorCode': colorCode,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern?.toMap(),
      'assignedMembers': assignedMembers,
      'equipmentNeeded': equipmentNeeded,
      'notes': notes,
      'streamingUrl': streamingUrl,
      'isStreamingEnabled': isStreamingEnabled,
      'customFields': customFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Crée une copie modifiée du service
  Service copyWith({
    String? id,
    String? name,
    String? description,
    ServiceType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    ServiceStatus? status,
    String? imageUrl,
    String? colorCode,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
    List<String>? assignedMembers,
    List<String>? equipmentNeeded,
    String? notes,
    String? streamingUrl,
    bool? isStreamingEnabled,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      colorCode: colorCode ?? this.colorCode,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      assignedMembers: assignedMembers ?? this.assignedMembers,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      notes: notes ?? this.notes,
      streamingUrl: streamingUrl ?? this.streamingUrl,
      isStreamingEnabled: isStreamingEnabled ?? this.isStreamingEnabled,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Obtient le statut automatique basé sur les dates
  String get statusDisplay {
    final now = DateTime.now();
    switch (status) {
      case ServiceStatus.cancelled:
        return 'Annulé';
      case ServiceStatus.completed:
        return 'Terminé';
      case ServiceStatus.inProgress:
        return 'En cours';
      case ServiceStatus.scheduled:
        if (endDate.isBefore(now)) return 'Terminé';
        if (startDate.isBefore(now) && endDate.isAfter(now)) return 'En cours';
        return 'Planifié';
    }
  }

  /// Obtient la durée du service
  Duration get duration {
    return endDate.difference(startDate);
  }

  /// Vérifie si le service est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
           startDate.month == now.month &&
           startDate.day == now.day;
  }

  /// Vérifie si le service est dans la semaine
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return startDate.isAfter(weekStart) && startDate.isBefore(weekEnd);
  }

  /// Obtient l'icône du type de service
  String get typeIcon {
    switch (type) {
      case ServiceType.worship:
        return 'church';
      case ServiceType.prayer:
        return 'prayer';
      case ServiceType.study:
        return 'book';
      case ServiceType.youth:
        return 'youth';
      case ServiceType.children:
        return 'children';
      case ServiceType.special:
        return 'special_event';
      case ServiceType.conference:
        return 'conference';
      case ServiceType.wedding:
        return 'wedding';
      case ServiceType.funeral:
        return 'funeral';
      case ServiceType.baptism:
        return 'baptism';
    }
  }

  @override
  String toString() {
    return 'Service(id: $id, name: $name, type: $type, startDate: $startDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types de services
enum ServiceType {
  worship,
  prayer,
  study,
  youth,
  children,
  special,
  conference,
  wedding,
  funeral,
  baptism,
}

/// Statuts des services
enum ServiceStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

/// Modèle pour la récurrence
class RecurrencePattern {
  final RecurrenceType type;
  final int interval;
  final List<int> daysOfWeek;
  final DateTime? endDate;
  final int? maxOccurrences;

  RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.endDate,
    this.maxOccurrences,
  });

  factory RecurrencePattern.fromMap(Map<String, dynamic> data) {
    return RecurrencePattern(
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RecurrenceType.weekly,
      ),
      interval: data['interval'] ?? 1,
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? []),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      maxOccurrences: data['maxOccurrences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'maxOccurrences': maxOccurrences,
    };
  }
}

/// Types de récurrence
enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly,
}

/// Extensions pour les types de services
extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.worship:
        return 'Culte';
      case ServiceType.prayer:
        return 'Prière';
      case ServiceType.study:
        return 'Étude biblique';
      case ServiceType.youth:
        return 'Jeunesse';
      case ServiceType.children:
        return 'Enfants';
      case ServiceType.special:
        return 'Événement spécial';
      case ServiceType.conference:
        return 'Conférence';
      case ServiceType.wedding:
        return 'Mariage';
      case ServiceType.funeral:
        return 'Funérailles';
      case ServiceType.baptism:
        return 'Baptême';
    }
  }

  String get description {
    switch (this) {
      case ServiceType.worship:
        return 'Service de louange et prédication';
      case ServiceType.prayer:
        return 'Temps de prière collective';
      case ServiceType.study:
        return 'Étude de la Parole';
      case ServiceType.youth:
        return 'Rencontre des jeunes';
      case ServiceType.children:
        return 'École du dimanche';
      case ServiceType.special:
        return 'Événement particulier';
      case ServiceType.conference:
        return 'Conférence ou séminaire';
      case ServiceType.wedding:
        return 'Cérémonie de mariage';
      case ServiceType.funeral:
        return 'Service funèbre';
      case ServiceType.baptism:
        return 'Cérémonie de baptême';
    }
  }
}