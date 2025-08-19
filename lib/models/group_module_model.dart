/// Modèle pour représenter un groupe
class Group {
  final String? id;
  final String name;
  final String description;
  final String type;
  final String frequency;
  final String location;
  final String? meetingLink;
  final int dayOfWeek; // 1-7 (Monday-Sunday)
  final String time; // "19:30"
  final bool isPublic;
  final String color;
  final List<String> leaderIds;
  final List<String> memberIds;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final bool isActive;
  final String? groupImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;

  Group({
    this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.frequency,
    required this.location,
    this.meetingLink,
    required this.dayOfWeek,
    required this.time,
    this.isPublic = true,
    required this.color,
    this.leaderIds = const [],
    this.memberIds = const [],
    this.tags = const [],
    this.customFields = const {},
    this.isActive = true,
    this.groupImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastModifiedBy,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Nom du jour de la semaine
  String get dayName {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[dayOfWeek];
  }

  /// Texte de planification
  String get scheduleText => '$dayName à $time';

  /// Nombre total de membres
  int get totalMembers => memberIds.length;

  /// Nombre de responsables
  int get totalLeaders => leaderIds.length;

  /// Vérifier si une personne est responsable
  bool isLeader(String personId) {
    return leaderIds.contains(personId);
  }

  /// Vérifier si une personne est membre
  bool isMember(String personId) {
    return memberIds.contains(personId);
  }

  /// Obtenir la valeur d'un champ personnalisé
  T? getCustomField<T>(String fieldName) {
    return customFields[fieldName] as T?;
  }

  /// Créer une copie avec des modifications
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? frequency,
    String? location,
    String? meetingLink,
    int? dayOfWeek,
    String? time,
    bool? isPublic,
    String? color,
    List<String>? leaderIds,
    List<String>? memberIds,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    bool? isActive,
    String? groupImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      time: time ?? this.time,
      isPublic: isPublic ?? this.isPublic,
      color: color ?? this.color,
      leaderIds: leaderIds ?? this.leaderIds,
      memberIds: memberIds ?? this.memberIds,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      isActive: isActive ?? this.isActive,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'frequency': frequency,
      'location': location,
      'meetingLink': meetingLink,
      'dayOfWeek': dayOfWeek,
      'time': time,
      'isPublic': isPublic,
      'color': color,
      'leaderIds': leaderIds,
      'memberIds': memberIds,
      'tags': tags,
      'customFields': customFields,
      'isActive': isActive,
      'groupImageUrl': groupImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  /// Créer depuis Map de Firestore
  factory Group.fromMap(Map<String, dynamic> map, String id) {
    return Group(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      frequency: map['frequency'] ?? '',
      location: map['location'] ?? '',
      meetingLink: map['meetingLink'],
      dayOfWeek: map['dayOfWeek'] ?? 1,
      time: map['time'] ?? '',
      isPublic: map['isPublic'] ?? true,
      color: map['color'] ?? '#6F61EF',
      leaderIds: List<String>.from(map['leaderIds'] ?? []),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      isActive: map['isActive'] ?? true,
      groupImageUrl: map['groupImageUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: map['lastModifiedBy'],
    );
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, type: $type, members: $totalMembers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

/// Modèle pour les membres d'un groupe
class GroupMember {
  final String? id;
  final String groupId;
  final String personId;
  final String role; // 'leader', 'co-leader', 'member', 'guest'
  final String status; // 'active', 'pending', 'removed'
  final DateTime joinedAt;
  final DateTime? leftAt;
  final Map<String, dynamic> customFields;

  GroupMember({
    this.id,
    required this.groupId,
    required this.personId,
    this.role = 'member',
    this.status = 'active',
    DateTime? joinedAt,
    this.leftAt,
    this.customFields = const {},
  }) : joinedAt = joinedAt ?? DateTime.now();

  /// Créer une copie avec des modifications
  GroupMember copyWith({
    String? id,
    String? groupId,
    String? personId,
    String? role,
    String? status,
    DateTime? joinedAt,
    DateTime? leftAt,
    Map<String, dynamic>? customFields,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      personId: personId ?? this.personId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'personId': personId,
      'role': role,
      'status': status,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'customFields': customFields,
    };
  }

  /// Créer depuis Map de Firestore
  factory GroupMember.fromMap(Map<String, dynamic> map, String id) {
    return GroupMember(
      id: id,
      groupId: map['groupId'] ?? '',
      personId: map['personId'] ?? '',
      role: map['role'] ?? 'member',
      status: map['status'] ?? 'active',
      joinedAt: DateTime.parse(map['joinedAt'] ?? DateTime.now().toIso8601String()),
      leftAt: map['leftAt'] != null ? DateTime.parse(map['leftAt']) : null,
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'GroupMember(id: $id, groupId: $groupId, personId: $personId, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}