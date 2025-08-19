import 'package:cloud_firestore/cloud_firestore.dart';
import 'service.dart';

/// Modèle pour les modèles de services
class ServiceTemplate {
  final String? id;
  final String name;
  final String description;
  final ServiceType type;
  final Duration duration;
  final String location;
  final List<String> defaultRoles;
  final List<String> defaultEquipment;
  final Map<String, dynamic> defaultSettings;
  final String? notes;
  final bool isActive;
  final String? imageUrl;
  final String? colorCode;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  ServiceTemplate({
    this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.duration,
    required this.location,
    this.defaultRoles = const [],
    this.defaultEquipment = const [],
    this.defaultSettings = const {},
    this.notes,
    this.isActive = true,
    this.imageUrl,
    this.colorCode,
    this.tags = const [],
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Crée un modèle à partir d'un document Firestore
  factory ServiceTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceTemplate.fromMap(data, doc.id);
  }

  /// Crée un modèle à partir d'une map
  factory ServiceTemplate.fromMap(Map<String, dynamic> data, String id) {
    return ServiceTemplate(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ServiceType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ServiceType.worship,
      ),
      duration: Duration(minutes: data['durationMinutes'] ?? 60),
      location: data['location'] ?? '',
      defaultRoles: List<String>.from(data['defaultRoles'] ?? []),
      defaultEquipment: List<String>.from(data['defaultEquipment'] ?? []),
      defaultSettings: Map<String, dynamic>.from(data['defaultSettings'] ?? {}),
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      colorCode: data['colorCode'],
      tags: List<String>.from(data['tags'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Convertit le modèle vers une map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'durationMinutes': duration.inMinutes,
      'location': location,
      'defaultRoles': defaultRoles,
      'defaultEquipment': defaultEquipment,
      'defaultSettings': defaultSettings,
      'notes': notes,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'colorCode': colorCode,
      'tags': tags,
      'customFields': customFields,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Crée une copie modifiée du modèle
  ServiceTemplate copyWith({
    String? id,
    String? name,
    String? description,
    ServiceType? type,
    Duration? duration,
    String? location,
    List<String>? defaultRoles,
    List<String>? defaultEquipment,
    Map<String, dynamic>? defaultSettings,
    String? notes,
    bool? isActive,
    String? imageUrl,
    String? colorCode,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ServiceTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      defaultRoles: defaultRoles ?? this.defaultRoles,
      defaultEquipment: defaultEquipment ?? this.defaultEquipment,
      defaultSettings: defaultSettings ?? this.defaultSettings,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      colorCode: colorCode ?? this.colorCode,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Crée un service à partir de ce modèle
  Service createService({
    required DateTime startDate,
    String? customName,
    String? customLocation,
    Map<String, dynamic>? overrideSettings,
  }) {
    final endDate = startDate.add(duration);
    
    return Service(
      name: customName ?? name,
      description: description,
      type: type,
      startDate: startDate,
      endDate: endDate,
      location: customLocation ?? location,
      imageUrl: imageUrl,
      colorCode: colorCode,
      equipmentNeeded: List.from(defaultEquipment),
      notes: notes,
      customFields: {
        ...customFields,
        ...defaultSettings,
        if (overrideSettings != null) ...overrideSettings,
        'templateId': id,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
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

  /// Formate la durée
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  @override
  String toString() {
    return 'ServiceTemplate(id: $id, name: $name, type: $type, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Rôles prédéfinis pour les services
class ServiceRoles {
  static const List<String> defaultRoles = [
    'Pasteur',
    'Orateur',
    'Animateur de louange',
    'Musicien',
    'Choriste',
    'Technicien son',
    'Technicien éclairage',
    'Projectionniste',
    'Caméra',
    'Accueil',
    'Huissier',
    'Interprète',
    'Garderie',
    'Sécurité',
    'Nettoyage',
  ];

  static const Map<String, List<String>> rolesByServiceType = {
    'worship': [
      'Pasteur',
      'Animateur de louange',
      'Musicien',
      'Choriste',
      'Technicien son',
      'Projectionniste',
      'Accueil',
      'Huissier',
    ],
    'prayer': [
      'Animateur',
      'Intercesseur',
      'Accueil',
    ],
    'study': [
      'Enseignant',
      'Assistant',
      'Accueil',
    ],
    'youth': [
      'Responsable jeunesse',
      'Animateur',
      'Musicien',
      'Technicien son',
    ],
    'children': [
      'Responsable enfants',
      'Moniteur',
      'Assistant',
      'Garderie',
    ],
  };
}

/// Équipements prédéfinis pour les services
class ServiceEquipment {
  static const List<String> defaultEquipment = [
    'Micro-casque',
    'Micro main',
    'Console de mixage',
    'Enceintes',
    'Projecteur',
    'Écran',
    'Ordinateur',
    'Caméra',
    'Éclairage',
    'Piano',
    'Guitare',
    'Batterie',
    'Basse',
    'Violon',
    'Chaises',
    'Tables',
    'Tableau',
    'Paperboard',
  ];

  static const Map<String, List<String>> equipmentByServiceType = {
    'worship': [
      'Micro-casque',
      'Console de mixage',
      'Enceintes',
      'Projecteur',
      'Piano',
      'Guitare',
      'Batterie',
      'Éclairage',
    ],
    'prayer': [
      'Micro main',
      'Enceintes',
      'Chaises',
    ],
    'study': [
      'Micro main',
      'Projecteur',
      'Tableau',
      'Chaises',
      'Tables',
    ],
    'children': [
      'Micro main',
      'Projecteur',
      'Chaises',
      'Tables',
      'Tableau',
      'Jeux',
    ],
  };
}