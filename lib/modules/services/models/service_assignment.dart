import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les assignations dans les services
class ServiceAssignment {
  final String? id;
  final String serviceId;
  final String memberId;
  final String memberName;
  final String role;
  final AssignmentStatus status;
  final String? notes;
  final DateTime? confirmedAt;
  final bool isTeamLead;
  final List<String> responsibilities;
  final Map<String, dynamic> customData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String assignedBy;

  ServiceAssignment({
    this.id,
    required this.serviceId,
    required this.memberId,
    required this.memberName,
    required this.role,
    this.status = AssignmentStatus.pending,
    this.notes,
    this.confirmedAt,
    this.isTeamLead = false,
    this.responsibilities = const [],
    this.customData = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.assignedBy,
  });

  /// Crée une assignation à partir d'un document Firestore
  factory ServiceAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceAssignment.fromMap(data, doc.id);
  }

  /// Crée une assignation à partir d'une map
  factory ServiceAssignment.fromMap(Map<String, dynamic> data, String id) {
    return ServiceAssignment(
      id: id,
      serviceId: data['serviceId'] ?? '',
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      role: data['role'] ?? '',
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AssignmentStatus.pending,
      ),
      notes: data['notes'],
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      isTeamLead: data['isTeamLead'] ?? false,
      responsibilities: List<String>.from(data['responsibilities'] ?? []),
      customData: Map<String, dynamic>.from(data['customData'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      assignedBy: data['assignedBy'] ?? '',
    );
  }

  /// Convertit l'assignation vers une map
  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'memberId': memberId,
      'memberName': memberName,
      'role': role,
      'status': status.name,
      'notes': notes,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'isTeamLead': isTeamLead,
      'responsibilities': responsibilities,
      'customData': customData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedBy': assignedBy,
    };
  }

  /// Crée une copie modifiée de l'assignation
  ServiceAssignment copyWith({
    String? id,
    String? serviceId,
    String? memberId,
    String? memberName,
    String? role,
    AssignmentStatus? status,
    String? notes,
    DateTime? confirmedAt,
    bool? isTeamLead,
    List<String>? responsibilities,
    Map<String, dynamic>? customData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedBy,
  }) {
    return ServiceAssignment(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      role: role ?? this.role,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      isTeamLead: isTeamLead ?? this.isTeamLead,
      responsibilities: responsibilities ?? this.responsibilities,
      customData: customData ?? this.customData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedBy: assignedBy ?? this.assignedBy,
    );
  }

  /// Obtient l'icône du statut
  String get statusIcon {
    switch (status) {
      case AssignmentStatus.pending:
        return 'hourglass_empty';
      case AssignmentStatus.confirmed:
        return 'check_circle';
      case AssignmentStatus.declined:
        return 'cancel';
      case AssignmentStatus.completed:
        return 'done_all';
    }
  }

  /// Obtient la couleur du statut
  String get statusColor {
    switch (status) {
      case AssignmentStatus.pending:
        return '#FF9800';
      case AssignmentStatus.confirmed:
        return '#4CAF50';
      case AssignmentStatus.declined:
        return '#F44336';
      case AssignmentStatus.completed:
        return '#2196F3';
    }
  }

  @override
  String toString() {
    return 'ServiceAssignment(id: $id, memberName: $memberName, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceAssignment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Statuts des assignations
enum AssignmentStatus {
  pending,
  confirmed,
  declined,
  completed,
}

/// Extensions pour les statuts d'assignation
extension AssignmentStatusExtension on AssignmentStatus {
  String get displayName {
    switch (this) {
      case AssignmentStatus.pending:
        return 'En attente';
      case AssignmentStatus.confirmed:
        return 'Confirmé';
      case AssignmentStatus.declined:
        return 'Refusé';
      case AssignmentStatus.completed:
        return 'Terminé';
    }
  }

  String get description {
    switch (this) {
      case AssignmentStatus.pending:
        return 'En attente de confirmation';
      case AssignmentStatus.confirmed:
        return 'Assignation confirmée';
      case AssignmentStatus.declined:
        return 'Assignation refusée';
      case AssignmentStatus.completed:
        return 'Tâche terminée';
    }
  }
}