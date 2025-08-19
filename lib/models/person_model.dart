import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_model.dart';

class PersonModel {
  final String id;
  final String? uid; // Firebase Auth UID - null pour les personnes créées manuellement
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? birthDate;
  final String? address;
  final String? gender;
  final String? maritalStatus;
  final List<String> children;
  final String? profileImageUrl;
  final String? privateNotes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? familyId;
  final List<String> roles;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? lastModifiedBy;

  PersonModel({
    required this.id,
    this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.birthDate,
    this.address,
    this.gender,
    this.maritalStatus,
    this.children = const [],
    this.profileImageUrl,
    this.privateNotes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.familyId,
    this.roles = const [],
    this.tags = const [],
    this.customFields = const {},
    this.lastModifiedBy,
  });

  String get fullName => '$firstName $lastName';

  String get displayInitials {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  String? get formattedBirthDate {
    if (birthDate == null) return null;
    return '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';
  }

  // Méthode pour vérifier si la personne a une permission spécifique
  bool hasPermission(String permission, List<RoleModel> allRoles) {
    // Admin système a toutes les permissions
    for (String roleId in roles) {
      try {
        final role = allRoles.firstWhere((r) => r.id == roleId);
        if (role.isActive && (role.permissions.contains(permission) || role.permissions.contains('system_admin'))) {
          return true;
        }
      } catch (e) {
        // Role not found, continue to next role
        continue;
      }
    }
    return false;
  }

  // Méthode pour obtenir toutes les permissions de la personne
  List<String> getAllPermissions(List<RoleModel> allRoles) {
    final Set<String> permissions = {};
    for (String roleId in roles) {
      try {
        final role = allRoles.firstWhere((r) => r.id == roleId);
        if (role.isActive) {
          permissions.addAll(role.permissions);
        }
      } catch (e) {
        // Role not found, continue to next role
        continue;
      }
    }
    return permissions.toList();
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  factory PersonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonModel(
      id: doc.id,
      uid: data['uid'],
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      birthDate: data['birthDate']?.toDate(),
      address: data['address'],
      gender: data['gender'],
      maritalStatus: data['maritalStatus'],
      children: List<String>.from(data['children'] ?? []),
      profileImageUrl: data['profileImageUrl'],
      privateNotes: data['privateNotes'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      familyId: data['familyId'],
      roles: List<String>.from(data['roles'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'address': address,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'children': children,
      'profileImageUrl': profileImageUrl,
      'privateNotes': privateNotes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'familyId': familyId,
      'roles': roles,
      'tags': tags,
      'customFields': customFields,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  PersonModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? address,
    String? gender,
    String? maritalStatus,
    List<String>? children,
    String? profileImageUrl,
    String? privateNotes,
    bool? isActive,
    DateTime? updatedAt,
    String? familyId,
    List<String>? roles,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    String? lastModifiedBy,
  }) {
    return PersonModel(
      id: id,
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      children: children ?? this.children,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      privateNotes: privateNotes ?? this.privateNotes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      familyId: familyId ?? this.familyId,
      roles: roles ?? this.roles,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class FamilyModel {
  final String id;
  final String name;
  final String? headOfFamilyId;
  final List<String> memberIds;
  final String? address;
  final String? homePhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyModel({
    required this.id,
    required this.name,
    this.headOfFamilyId,
    this.memberIds = const [],
    this.address,
    this.homePhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      id: doc.id,
      name: data['name'] ?? '',
      headOfFamilyId: data['headOfFamilyId'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      address: data['address'],
      homePhone: data['homePhone'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'headOfFamilyId': headOfFamilyId,
      'memberIds': memberIds,
      'address': address,
      'homePhone': homePhone,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}


class WorkflowModel {
  final String id;
  final String name;
  final String description;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> triggerConditions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String category;
  final String color;
  final String icon;

  WorkflowModel({
    required this.id,
    required this.name,
    required this.description,
    this.steps = const [],
    this.triggerConditions = const {},
    this.isActive = true,
    required this.createdAt,
    DateTime? updatedAt,
    this.createdBy = '',
    this.category = 'Général',
    this.color = '#2196F3',
    this.icon = 'track_changes',
  }) : updatedAt = updatedAt ?? createdAt;

  factory WorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkflowModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      steps: (data['steps'] as List<dynamic>?)
          ?.map((step) => WorkflowStep.fromMap(step))
          .toList() ?? [],
      triggerConditions: Map<String, dynamic>.from(data['triggerConditions'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      category: data['category'] ?? 'Général',
      color: data['color'] ?? '#2196F3',
      icon: data['icon'] ?? 'track_changes',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'steps': steps.map((step) => step.toMap()).toList(),
      'triggerConditions': triggerConditions,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'category': category,
      'color': color,
      'icon': icon,
    };
  }

  WorkflowModel copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkflowStep>? steps,
    Map<String, dynamic>? triggerConditions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? category,
    String? color,
    String? icon,
  }) {
    return WorkflowModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      triggerConditions: triggerConditions ?? this.triggerConditions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

class WorkflowStep {
  final String id;
  final String name;
  final String description;
  final int order;
  final bool isRequired;
  final int estimatedDuration; // En minutes
  final String? assignedTo; // ID de la personne responsable
  final String? assignedToName; // Nom de la personne responsable pour affichage

  WorkflowStep({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    this.isRequired = false,
    this.estimatedDuration = 30,
    this.assignedTo,
    this.assignedToName,
  });

  factory WorkflowStep.fromMap(Map<String, dynamic> map) {
    return WorkflowStep(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
      isRequired: map['isRequired'] ?? false,
      estimatedDuration: map['estimatedDuration'] ?? 30,
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'isRequired': isRequired,
      'estimatedDuration': estimatedDuration,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
    };
  }

  WorkflowStep copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    bool? isRequired,
    int? estimatedDuration,
    String? assignedTo,
    String? assignedToName,
  }) {
    return WorkflowStep(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      isRequired: isRequired ?? this.isRequired,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
    );
  }
}

class PersonWorkflowModel {
  final String id;
  final String personId;
  final String workflowId;
  final int currentStep;
  final List<String> completedSteps;
  final String notes;
  final DateTime startDate;
  final DateTime lastUpdated;
  final String status; // 'pending', 'in_progress', 'completed', 'paused'
  final DateTime? completedDate;

  PersonWorkflowModel({
    required this.id,
    required this.personId,
    required this.workflowId,
    this.currentStep = 0,
    this.completedSteps = const [],
    this.notes = '',
    required this.startDate,
    required this.lastUpdated,
    this.status = 'pending',
    this.completedDate,
  });

  factory PersonWorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonWorkflowModel(
      id: doc.id,
      personId: data['personId'] ?? '',
      workflowId: data['workflowId'] ?? '',
      currentStep: data['currentStep'] ?? 0,
      completedSteps: List<String>.from(data['completedSteps'] ?? []),
      notes: data['notes'] ?? '',
      startDate: data['startDate']?.toDate() ?? DateTime.now(),
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      completedDate: data['completedDate']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personId': personId,
      'workflowId': workflowId,
      'currentStep': currentStep,
      'completedSteps': completedSteps,
      'notes': notes,
      'startDate': startDate,
      'lastUpdated': lastUpdated,
      'status': status,
      'completedDate': completedDate,
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';
  bool get isPaused => status == 'paused';

  PersonWorkflowModel copyWith({
    String? id,
    String? personId,
    String? workflowId,
    int? currentStep,
    List<String>? completedSteps,
    String? notes,
    DateTime? startDate,
    DateTime? lastUpdated,
    String? status,
    DateTime? completedDate,
  }) {
    return PersonWorkflowModel(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      workflowId: workflowId ?? this.workflowId,
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}