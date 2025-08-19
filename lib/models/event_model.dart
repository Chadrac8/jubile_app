import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final String type; // 'celebration', 'bapteme', 'formation', 'sortie', 'conference', 'reunion', 'autre'
  final List<String> responsibleIds;
  final String visibility; // 'publique', 'privee', 'groupe', 'role'
  final List<String> visibilityTargets; // Group IDs or Role IDs if restricted
  final String status; // 'brouillon', 'publie', 'archive', 'annule'
  final bool isRegistrationEnabled;
  final DateTime? closeDate;
  final int? maxParticipants;
  final bool hasWaitingList;
  final bool isRecurring;
  final Map<String, dynamic>? recurrencePattern;
  final List<String> attachmentUrls;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.imageUrl,
    required this.type,
    this.responsibleIds = const [],
    this.visibility = 'publique',
    this.visibilityTargets = const [],
    this.status = 'brouillon',
    this.isRegistrationEnabled = false,
    this.closeDate,
    this.maxParticipants,
    this.hasWaitingList = false,
    this.isRecurring = false,
    this.recurrencePattern,
    this.attachmentUrls = const [],
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
  });

  String get typeLabel {
    switch (type) {
      case 'celebration': return 'Célébration';
      case 'bapteme': return 'Baptême';
      case 'formation': return 'Formation';
      case 'sortie': return 'Sortie';
      case 'conference': return 'Conférence';
      case 'reunion': return 'Réunion';
      default: return 'Autre';
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

  String get visibilityLabel {
    switch (visibility) {
      case 'publique': return 'Publique';
      case 'privee': return 'Privée';
      case 'groupe': return 'Réservée aux groupes';
      case 'role': return 'Réservée aux rôles';
      default: return visibility;
    }
  }

  bool get isPublished => status == 'publie';
  bool get isDraft => status == 'brouillon';
  bool get isArchived => status == 'archive';
  bool get isCancelled => status == 'annule';
  
  bool get isOpen {
    if (!isRegistrationEnabled) return false;
    if (closeDate == null) return true;
    return DateTime.now().isBefore(closeDate!);
  }
  
  bool get isMultiDay => endDate != null && !isSameDay(startDate, endDate!);
  
  Duration get duration {
    if (endDate != null) {
      return endDate!.difference(startDate);
    }
    return Duration(hours: 2); // Default duration
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      type: data['type'] ?? 'autre',
      responsibleIds: List<String>.from(data['responsibleIds'] ?? []),
      visibility: data['visibility'] ?? 'publique',
      visibilityTargets: List<String>.from(data['visibilityTargets'] ?? []),
      status: data['status'] ?? 'brouillon',
      isRegistrationEnabled: data['isRegistrationEnabled'] ?? false,
      maxParticipants: data['maxParticipants'],
      hasWaitingList: data['hasWaitingList'] ?? false,
      isRecurring: data['isRecurring'] ?? false,
      recurrencePattern: data['recurrencePattern'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'imageUrl': imageUrl,
      'type': type,
      'responsibleIds': responsibleIds,
      'visibility': visibility,
      'visibilityTargets': visibilityTargets,
      'status': status,
      'isRegistrationEnabled': isRegistrationEnabled,
      'maxParticipants': maxParticipants,
      'hasWaitingList': hasWaitingList,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'attachmentUrls': attachmentUrls,
      'customFields': customFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  EventModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    String? type,
    List<String>? responsibleIds,
    String? visibility,
    List<String>? visibilityTargets,
    String? status,
    bool? isRegistrationEnabled,
    int? maxParticipants,
    bool? hasWaitingList,
    bool? isRecurring,
    Map<String, dynamic>? recurrencePattern,
    List<String>? attachmentUrls,
    Map<String, dynamic>? customFields,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      responsibleIds: responsibleIds ?? this.responsibleIds,
      visibility: visibility ?? this.visibility,
      visibilityTargets: visibilityTargets ?? this.visibilityTargets,
      status: status ?? this.status,
      isRegistrationEnabled: isRegistrationEnabled ?? this.isRegistrationEnabled,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      hasWaitingList: hasWaitingList ?? this.hasWaitingList,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class EventFormModel {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final List<EventFormField> fields;
  final String confirmationMessage;
  final String? confirmationEmailTemplate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventFormModel({
    required this.id,
    required this.eventId,
    required this.title,
    this.description = '',
    this.fields = const [],
    this.confirmationMessage = 'Merci pour votre inscription !',
    this.confirmationEmailTemplate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventFormModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventFormModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fields: (data['fields'] as List? ?? [])
          .map((field) => EventFormField.fromMap(field))
          .toList(),
      confirmationMessage: data['confirmationMessage'] ?? 'Merci pour votre inscription !',
      confirmationEmailTemplate: data['confirmationEmailTemplate'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'fields': fields.map((field) => field.toMap()).toList(),
      'confirmationMessage': confirmationMessage,
      'confirmationEmailTemplate': confirmationEmailTemplate,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class EventFormField {
  final String id;
  final String label;
  final String type; // 'text', 'email', 'phone', 'number', 'select', 'checkbox', 'textarea'
  final bool isRequired;
  final List<String> options; // For select and checkbox types
  final String? placeholder;
  final String? helpText;
  final Map<String, dynamic>? validation;
  final int order;

  EventFormField({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options = const [],
    this.placeholder,
    this.helpText,
    this.validation,
    required this.order,
  });

  factory EventFormField.fromMap(Map<String, dynamic> map) {
    return EventFormField(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      isRequired: map['isRequired'] ?? false,
      options: List<String>.from(map['options'] ?? []),
      placeholder: map['placeholder'],
      helpText: map['helpText'],
      validation: map['validation'],
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'isRequired': isRequired,
      'options': options,
      'placeholder': placeholder,
      'helpText': helpText,
      'validation': validation,
      'order': order,
    };
  }
}

class EventRegistrationModel {
  final String id;
  final String eventId;
  final String? personId; // Null if external registration
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final Map<String, dynamic> formResponses;
  final String status; // 'confirmed', 'waiting', 'cancelled'
  final DateTime registrationDate;
  final bool isPresent;
  final DateTime? attendanceRecordedAt;
  final String? notes;

  EventRegistrationModel({
    required this.id,
    required this.eventId,
    this.personId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.formResponses = const {},
    this.status = 'confirmed',
    required this.registrationDate,
    this.isPresent = false,
    this.attendanceRecordedAt,
    this.notes,
  });

  String get fullName => '$firstName $lastName';

  bool get isConfirmed => status == 'confirmed';
  bool get isWaiting => status == 'waiting';
  bool get isCancelled => status == 'cancelled';

  factory EventRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventRegistrationModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      personId: data['personId'],
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      formResponses: Map<String, dynamic>.from(data['formResponses'] ?? {}),
      status: data['status'] ?? 'confirmed',
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      isPresent: data['isPresent'] ?? false,
      attendanceRecordedAt: data['attendanceRecordedAt'] != null 
          ? (data['attendanceRecordedAt'] as Timestamp).toDate() 
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'personId': personId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'formResponses': formResponses,
      'status': status,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'isPresent': isPresent,
      'attendanceRecordedAt': attendanceRecordedAt != null 
          ? Timestamp.fromDate(attendanceRecordedAt!) 
          : null,
      'notes': notes,
    };
  }

  EventRegistrationModel copyWith({
    String? status,
    bool? isPresent,
    DateTime? attendanceRecordedAt,
    String? notes,
  }) {
    return EventRegistrationModel(
      id: id,
      eventId: eventId,
      personId: personId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      formResponses: formResponses,
      status: status ?? this.status,
      registrationDate: registrationDate,
      isPresent: isPresent ?? this.isPresent,
      attendanceRecordedAt: attendanceRecordedAt ?? this.attendanceRecordedAt,
      notes: notes ?? this.notes,
    );
  }
}

class EventStatisticsModel {
  final String eventId;
  final int totalRegistrations;
  final int confirmedRegistrations;
  final int waitingRegistrations;
  final int cancelledRegistrations;
  final int presentCount;
  final Map<String, int> registrationsByDate;
  final Map<String, dynamic> formResponsesSummary;
  final double fillRate;
  final double attendanceRate;
  final DateTime lastUpdated;

  EventStatisticsModel({
    required this.eventId,
    required this.totalRegistrations,
    required this.confirmedRegistrations,
    required this.waitingRegistrations,
    required this.cancelledRegistrations,
    required this.presentCount,
    required this.registrationsByDate,
    required this.formResponsesSummary,
    required this.fillRate,
    required this.attendanceRate,
    required this.lastUpdated,
  });

  factory EventStatisticsModel.fromMap(Map<String, dynamic> data) {
    return EventStatisticsModel(
      eventId: data['eventId'] ?? '',
      totalRegistrations: data['totalRegistrations'] ?? 0,
      confirmedRegistrations: data['confirmedRegistrations'] ?? 0,
      waitingRegistrations: data['waitingRegistrations'] ?? 0,
      cancelledRegistrations: data['cancelledRegistrations'] ?? 0,
      presentCount: data['presentCount'] ?? 0,
      registrationsByDate: Map<String, int>.from(data['registrationsByDate'] ?? {}),
      formResponsesSummary: Map<String, dynamic>.from(data['formResponsesSummary'] ?? {}),
      fillRate: data['fillRate']?.toDouble() ?? 0.0,
      attendanceRate: data['attendanceRate']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(data['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'totalRegistrations': totalRegistrations,
      'confirmedRegistrations': confirmedRegistrations,
      'waitingRegistrations': waitingRegistrations,
      'cancelledRegistrations': cancelledRegistrations,
      'presentCount': presentCount,
      'registrationsByDate': registrationsByDate,
      'formResponsesSummary': formResponsesSummary,
      'fillRate': fillRate,
      'attendanceRate': attendanceRate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}