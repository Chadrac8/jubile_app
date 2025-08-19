import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour représenter un événement
class EventModule {
  final String? id;
  final String title;
  final String description;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? onlineLink;
  final bool isOnline;
  final bool isPublic;
  final bool requiresRegistration;
  final int? maxAttendees;
  final double? price;
  final String? currency;
  final String color;
  final String? bannerImageUrl;
  final List<String> organizerIds;
  final List<String> speakerIds;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final bool isActive;
  final bool isCancelled;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;

  EventModule({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.onlineLink,
    this.isOnline = false,
    this.isPublic = true,
    this.requiresRegistration = false,
    this.maxAttendees,
    this.price,
    this.currency = 'EUR',
    required this.color,
    this.bannerImageUrl,
    this.organizerIds = const [],
    this.speakerIds = const [],
    this.tags = const [],
    this.customFields = const {},
    this.isActive = true,
    this.isCancelled = false,
    this.cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastModifiedBy,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Durée de l'événement en heures
  double get durationInHours {
    return endDate.difference(startDate).inMinutes / 60.0;
  }

  /// Nombre de jours jusqu'à l'événement
  int get daysUntilEvent {
    final now = DateTime.now();
    if (startDate.isBefore(now)) return 0;
    return startDate.difference(now).inDays;
  }

  /// Statut de l'événement
  String get status {
    if (isCancelled) return 'Annulé';
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 'Terminé';
    if (startDate.isBefore(now) && endDate.isAfter(now)) return 'En cours';
    return 'À venir';
  }

  /// Vérifier si l'événement est en cours
  bool get isOngoing {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now);
  }

  /// Vérifier si l'événement est terminé
  bool get isCompleted {
    return endDate.isBefore(DateTime.now());
  }

  /// Vérifier si l'événement est à venir
  bool get isUpcoming {
    return startDate.isAfter(DateTime.now());
  }

  /// Vérifier si l'événement est gratuit
  bool get isFree {
    return price == null || price == 0;
  }

  /// Vérifier si une personne est organisatrice
  bool isOrganizer(String personId) {
    return organizerIds.contains(personId);
  }

  /// Vérifier si une personne est intervenante
  bool isSpeaker(String personId) {
    return speakerIds.contains(personId);
  }

  /// Obtenir la valeur d'un champ personnalisé
  T? getCustomField<T>(String fieldName) {
    return customFields[fieldName] as T?;
  }

  /// Format d'affichage des dates
  String get dateRangeText {
    final isSameDay = startDate.day == endDate.day && 
                      startDate.month == endDate.month && 
                      startDate.year == endDate.year;
    
    if (isSameDay) {
      return '${_formatDate(startDate)} de ${_formatTime(startDate)} à ${_formatTime(endDate)}';
    } else {
      return 'Du ${_formatDate(startDate)} ${_formatTime(startDate)} au ${_formatDate(endDate)} ${_formatTime(endDate)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Créer une copie avec des modifications
  EventModule copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? onlineLink,
    bool? isOnline,
    bool? isPublic,
    bool? requiresRegistration,
    int? maxAttendees,
    double? price,
    String? currency,
    String? color,
    String? bannerImageUrl,
    List<String>? organizerIds,
    List<String>? speakerIds,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    bool? isActive,
    bool? isCancelled,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return EventModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      onlineLink: onlineLink ?? this.onlineLink,
      isOnline: isOnline ?? this.isOnline,
      isPublic: isPublic ?? this.isPublic,
      requiresRegistration: requiresRegistration ?? this.requiresRegistration,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      organizerIds: organizerIds ?? this.organizerIds,
      speakerIds: speakerIds ?? this.speakerIds,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      isActive: isActive ?? this.isActive,
      isCancelled: isCancelled ?? this.isCancelled,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'onlineLink': onlineLink,
      'isOnline': isOnline,
      'isPublic': isPublic,
      'requiresRegistration': requiresRegistration,
      'maxAttendees': maxAttendees,
      'price': price,
      'currency': currency,
      'color': color,
      'bannerImageUrl': bannerImageUrl,
      'organizerIds': organizerIds,
      'speakerIds': speakerIds,
      'tags': tags,
      'customFields': customFields,
      'isActive': isActive,
      'isCancelled': isCancelled,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  /// Créer depuis Map Firestore
  factory EventModule.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModule(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      onlineLink: map['onlineLink'],
      isOnline: map['isOnline'] ?? false,
      isPublic: map['isPublic'] ?? true,
      requiresRegistration: map['requiresRegistration'] ?? false,
      maxAttendees: map['maxAttendees'],
      price: map['price']?.toDouble(),
      currency: map['currency'] ?? 'EUR',
      color: map['color'] ?? '#2196F3',
      bannerImageUrl: map['bannerImageUrl'],
      organizerIds: List<String>.from(map['organizerIds'] ?? []),
      speakerIds: List<String>.from(map['speakerIds'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      isActive: map['isActive'] ?? true,
      isCancelled: map['isCancelled'] ?? false,
      cancellationReason: map['cancellationReason'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastModifiedBy: map['lastModifiedBy'],
    );
  }

  @override
  String toString() {
    return 'EventModule(id: $id, title: $title, category: $category, startDate: $startDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}