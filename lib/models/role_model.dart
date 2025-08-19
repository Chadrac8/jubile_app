import 'package:cloud_firestore/cloud_firestore.dart';

class RoleModel {
  final String id;
  final String name;
  final String description;
  final String color;
  final List<String> permissions;
  final String icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  final Map<String, dynamic>? customFields;

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.permissions,
    required this.icon,
    required this.isActive,
    required this.createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.customFields,
  }) : updatedAt = updatedAt ?? createdAt;

  // Factory constructor pour créer un rôle depuis Firestore
  factory RoleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return RoleModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      color: data['color'] ?? '#4CAF50',
      permissions: List<String>.from(data['permissions'] ?? []),
      icon: data['icon'] ?? 'person',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      customFields: data['customFields'],
    );
  }

  // Factory constructor pour créer un rôle depuis Map
  factory RoleModel.fromMap(Map<String, dynamic> data) {
    return RoleModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      color: data['color'] ?? '#4CAF50',
      permissions: List<String>.from(data['permissions'] ?? []),
      icon: data['icon'] ?? 'person',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      customFields: data['customFields'],
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'permissions': permissions,
      'icon': icon,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'customFields': customFields,
    };
  }

  // Convertir en Map pour mise à jour
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'permissions': permissions,
      'icon': icon,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': lastModifiedBy,
      'customFields': customFields,
    };
  }

  // Créer une copie avec des modifications
  RoleModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    List<String>? permissions,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    Map<String, dynamic>? customFields,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      permissions: permissions ?? this.permissions,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      customFields: customFields ?? this.customFields,
    );
  }

  // Méthodes utilitaires
  String get fullName => name.isNotEmpty ? name : 'Rôle sans nom';
  
  String get shortDescription => description.length > 50 
      ? '${description.substring(0, 50)}...' 
      : description;

  bool hasPermission(String permission) {
    return permissions.contains(permission) || permissions.contains('system_admin');
  }

  bool get isSystemAdmin => permissions.contains('system_admin');

  String get permissionSummary {
    if (permissions.isEmpty) return 'Aucune permission';
    if (permissions.contains('system_admin')) return 'Accès administrateur complet';
    
    final count = permissions.length;
    return '$count permission${count > 1 ? 's' : ''}';
  }

  @override
  String toString() {
    return 'RoleModel(id: $id, name: $name, permissions: ${permissions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Classe pour les permissions prédéfinies
class PermissionDefinition {
  final String key;
  final String label;
  final String description;
  final String category;
  final String icon;

  const PermissionDefinition({
    required this.key,
    required this.label,
    required this.description,
    required this.category,
    required this.icon,
  });
}

// Constantes pour les permissions
class Permissions {
  static const List<PermissionDefinition> all = [
    // Personnes
    PermissionDefinition(
      key: 'read_persons',
      label: 'Voir les personnes',
      description: 'Consulter la liste des personnes et leurs informations',
      category: 'Personnes',
      icon: 'people',
    ),
    PermissionDefinition(
      key: 'write_persons',
      label: 'Modifier les personnes',
      description: 'Ajouter et modifier les informations des personnes',
      category: 'Personnes',
      icon: 'person_add',
    ),
    PermissionDefinition(
      key: 'delete_persons',
      label: 'Supprimer les personnes',
      description: 'Supprimer des personnes du système',
      category: 'Personnes',
      icon: 'person_remove',
    ),
    PermissionDefinition(
      key: 'manage_families',
      label: 'Gérer les familles',
      description: 'Créer et modifier les liens familiaux',
      category: 'Personnes',
      icon: 'family_restroom',
    ),
    
    // Groupes
    PermissionDefinition(
      key: 'read_groups',
      label: 'Voir les groupes',
      description: 'Consulter la liste des groupes et leurs informations',
      category: 'Groupes',
      icon: 'group',
    ),
    PermissionDefinition(
      key: 'write_groups',
      label: 'Modifier les groupes',
      description: 'Créer et modifier les groupes',
      category: 'Groupes',
      icon: 'edit',
    ),
    PermissionDefinition(
      key: 'delete_groups',
      label: 'Supprimer les groupes',
      description: 'Supprimer des groupes du système',
      category: 'Groupes',
      icon: 'delete',
    ),
    PermissionDefinition(
      key: 'manage_group_meetings',
      label: 'Gérer les réunions',
      description: 'Planifier et gérer les réunions de groupe',
      category: 'Groupes',
      icon: 'event',
    ),
    
    // Événements
    PermissionDefinition(
      key: 'read_events',
      label: 'Voir les événements',
      description: 'Consulter la liste des événements',
      category: 'Événements',
      icon: 'event',
    ),
    PermissionDefinition(
      key: 'write_events',
      label: 'Modifier les événements',
      description: 'Créer et modifier les événements',
      category: 'Événements',
      icon: 'edit_calendar',
    ),
    PermissionDefinition(
      key: 'delete_events',
      label: 'Supprimer les événements',
      description: 'Supprimer des événements du système',
      category: 'Événements',
      icon: 'delete',
    ),
    PermissionDefinition(
      key: 'manage_event_registrations',
      label: 'Gérer les inscriptions',
      description: 'Gérer les inscriptions aux événements',
      category: 'Événements',
      icon: 'how_to_reg',
    ),
    
    // Services
    PermissionDefinition(
      key: 'read_services',
      label: 'Voir les services',
      description: 'Consulter la planification des services',
      category: 'Services',
      icon: 'church',
    ),
    PermissionDefinition(
      key: 'write_services',
      label: 'Modifier les services',
      description: 'Créer et modifier les services religieux',
      category: 'Services',
      icon: 'edit',
    ),
    PermissionDefinition(
      key: 'delete_services',
      label: 'Supprimer les services',
      description: 'Supprimer des services du système',
      category: 'Services',
      icon: 'delete',
    ),
    PermissionDefinition(
      key: 'manage_service_assignments',
      label: 'Gérer les assignations',
      description: 'Assigner des personnes aux services',
      category: 'Services',
      icon: 'assignment_ind',
    ),
    
    // Administration
    PermissionDefinition(
      key: 'manage_roles',
      label: 'Gérer les rôles',
      description: 'Créer et modifier les rôles du système',
      category: 'Administration',
      icon: 'admin_panel_settings',
    ),
    PermissionDefinition(
      key: 'manage_permissions',
      label: 'Gérer les permissions',
      description: 'Assigner des permissions aux utilisateurs',
      category: 'Administration',
      icon: 'security',
    ),
    PermissionDefinition(
      key: 'system_admin',
      label: 'Administration système',
      description: 'Accès complet à toutes les fonctionnalités',
      category: 'Administration',
      icon: 'admin_panel_settings',
    ),
    PermissionDefinition(
      key: 'view_statistics',
      label: 'Voir les statistiques',
      description: 'Consulter les rapports et statistiques',
      category: 'Administration',
      icon: 'analytics',
    ),
  ];

  static Map<String, List<PermissionDefinition>> get byCategory {
    final Map<String, List<PermissionDefinition>> categories = {};
    for (final permission in all) {
      categories.putIfAbsent(permission.category, () => []);
      categories[permission.category]!.add(permission);
    }
    return categories;
  }

  static PermissionDefinition? findByKey(String key) {
    try {
      return all.firstWhere((permission) => permission.key == key);
    } catch (e) {
      return null;
    }
  }
}