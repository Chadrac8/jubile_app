import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';

class RolesFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String rolesCollection = 'roles';
  static const String personsCollection = 'persons';
  static const String roleAssignmentsCollection = 'role_assignments';
  static const String permissionsCollection = 'permissions';

  // Permissions disponibles dans le système
  static const List<String> availablePermissions = [
    'read_persons',
    'write_persons',
    'delete_persons',
    'manage_families',
    'read_groups',
    'write_groups',
    'delete_groups',
    'manage_group_meetings',
    'read_events',
    'write_events',
    'delete_events',
    'manage_event_registrations',
    'read_services',
    'write_services',
    'delete_services',
    'manage_service_assignments',
    'read_forms',
    'write_forms',
    'delete_forms',
    'view_form_responses',
    'read_tasks',
    'write_tasks',
    'delete_tasks',
    'manage_task_assignments',

    'read_pages',
    'write_pages',
    'delete_pages',
    'manage_page_visibility',
    'read_appointments',
    'write_appointments',
    'manage_all_appointments',
    'manage_availability',
    'view_statistics',
    'manage_roles',
    'manage_permissions',
    'system_admin',
  ];

  // Role CRUD Operations
  static Future<String> createRole(RoleModel role) async {
    try {
      final docRef = await _firestore.collection(rolesCollection).add(role.toFirestore());
      await _logRoleActivity(docRef.id, 'role_created', {
        'roleName': role.name,
        'permissions': role.permissions,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du rôle: $e');
    }
  }

  static Future<void> updateRole(RoleModel role) async {
    try {
      await _firestore.collection(rolesCollection).doc(role.id).update(role.toFirestore());
      await _logRoleActivity(role.id, 'role_updated', {
        'roleName': role.name,
        'permissions': role.permissions,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  static Future<void> deleteRole(String roleId) async {
    try {
      // Vérifier que le rôle n'est pas assigné à des utilisateurs
      final personsWithRole = await _firestore
          .collection(personsCollection)
          .where('roles', arrayContains: roleId)
          .get();

      if (personsWithRole.docs.isNotEmpty) {
        throw Exception('Ce rôle est assigné à ${personsWithRole.docs.length} personne(s). Retirez d\'abord le rôle de ces personnes.');
      }

      final role = await getRole(roleId);
      await _firestore.collection(rolesCollection).doc(roleId).delete();
      
      if (role != null) {
        await _logRoleActivity(roleId, 'role_deleted', {
          'roleName': role.name,
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression du rôle: $e');
    }
  }

  static Future<RoleModel?> getRole(String roleId) async {
    try {
      final doc = await _firestore.collection(rolesCollection).doc(roleId).get();
      if (doc.exists) {
        return RoleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du rôle: $e');
    }
  }

  static Stream<List<RoleModel>> getRolesStream({
    String? searchQuery,
    bool? activeOnly,
    int limit = 50,
  }) {
    try {
      Query query = _firestore.collection(rolesCollection);

      if (activeOnly == true) {
        query = query.where('isActive', isEqualTo: true);
      }

      query = query.orderBy('name');

      if (limit > 0) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        final roles = snapshot.docs
            .map((doc) => RoleModel.fromFirestore(doc))
            .toList();

        if (searchQuery != null && searchQuery.isNotEmpty) {
          return roles.where((role) =>
              role.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (role.description.isNotEmpty && role.description.toLowerCase().contains(searchQuery.toLowerCase()))).toList();
        }

        return roles;
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rôles: $e');
    }
  }

  // Permission Management
  static Future<List<String>> getUserPermissions(String userId) async {
    try {
      final userDoc = await _firestore.collection(personsCollection).doc(userId).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRoles = List<String>.from(userData['roles'] ?? []);

      final Set<String> permissions = {};

      for (String roleId in userRoles) {
        final role = await getRole(roleId);
        if (role != null && role.isActive) {
          permissions.addAll(role.permissions);
        }
      }

      return permissions.toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des permissions: $e');
    }
  }

  static Future<bool> userHasPermission(String userId, String permission) async {
    try {
      final permissions = await getUserPermissions(userId);
      return permissions.contains(permission) || permissions.contains('system_admin');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> currentUserHasPermission(String permission) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return await userHasPermission(user.uid, permission);
  }

  // Role Assignment
  static Future<void> assignRoleToPersons(List<String> personIds, String roleId) async {
    try {
      final role = await getRole(roleId);
      if (role == null) {
        throw Exception('Rôle introuvable');
      }

      final batch = _firestore.batch();

      for (String personId in personIds) {
        final personRef = _firestore.collection(personsCollection).doc(personId);
        batch.update(personRef, {
          'roles': FieldValue.arrayUnion([roleId]),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': _auth.currentUser?.uid,
        });
      }

      await batch.commit();

      await _logRoleActivity(roleId, 'role_assigned', {
        'roleName': role.name,
        'personIds': personIds,
        'personCount': personIds.length,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation du rôle: $e');
    }
  }

  static Future<void> removeRoleFromPersons(List<String> personIds, String roleId) async {
    try {
      final role = await getRole(roleId);
      if (role == null) {
        throw Exception('Rôle introuvable');
      }

      final batch = _firestore.batch();

      for (String personId in personIds) {
        final personRef = _firestore.collection(personsCollection).doc(personId);
        batch.update(personRef, {
          'roles': FieldValue.arrayRemove([roleId]),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': _auth.currentUser?.uid,
        });
      }

      await batch.commit();

      await _logRoleActivity(roleId, 'role_removed', {
        'roleName': role.name,
        'personIds': personIds,
        'personCount': personIds.length,
      });
    } catch (e) {
      throw Exception('Erreur lors du retrait du rôle: $e');
    }
  }

  static Future<void> updatePersonRoles(String personId, List<String> newRoleIds) async {
    try {
      await _firestore.collection(personsCollection).doc(personId).update({
        'roles': newRoleIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid,
      });

      await _logRoleActivity('', 'person_roles_updated', {
        'personId': personId,
        'newRoles': newRoleIds,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des rôles: $e');
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getRoleStatistics() async {
    try {
      final rolesSnapshot = await _firestore.collection(rolesCollection).get();
      final personsSnapshot = await _firestore.collection(personsCollection).get();

      final Map<String, int> roleUsage = {};
      int totalActiveRoles = 0;
      int totalInactiveRoles = 0;

      // Compter les rôles actifs/inactifs
      for (var doc in rolesSnapshot.docs) {
        final role = RoleModel.fromFirestore(doc);
        if (role.isActive) {
          totalActiveRoles++;
        } else {
          totalInactiveRoles++;
        }
        roleUsage[role.id] = 0;
      }

      // Compter l'usage des rôles
      for (var doc in personsSnapshot.docs) {
        final person = PersonModel.fromFirestore(doc);
        for (String roleId in person.roles) {
          roleUsage[roleId] = (roleUsage[roleId] ?? 0) + 1;
        }
      }

      return {
        'totalRoles': rolesSnapshot.docs.length,
        'activeRoles': totalActiveRoles,
        'inactiveRoles': totalInactiveRoles,
        'roleUsage': roleUsage,
        'totalPersons': personsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // People with specific role
  static Stream<List<PersonModel>> getPersonsWithRole(String roleId) {
    return _firestore
        .collection(personsCollection)
        .where('roles', arrayContains: roleId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PersonModel.fromFirestore(doc))
            .toList());
  }

  // Search and Filter
  static Future<List<RoleModel>> searchRoles(String query) async {
    try {
      final snapshot = await _firestore.collection(rolesCollection).get();
      final roles = snapshot.docs
          .map((doc) => RoleModel.fromFirestore(doc))
          .where((role) =>
              role.name.toLowerCase().contains(query.toLowerCase()) ||
              (role.description.isNotEmpty && role.description.toLowerCase().contains(query.toLowerCase())))
          .toList();
      return roles;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Default Roles Creation
  static Future<void> createDefaultRoles() async {
    try {
      final existingRoles = await _firestore.collection(rolesCollection).get();
      if (existingRoles.docs.isNotEmpty) return; // Rôles déjà créés

      final defaultRoles = [
        RoleModel(
          id: '',
          name: 'Administrateur',
          description: 'Accès complet à toutes les fonctionnalités du système',
          color: '#FF5722',
          permissions: ['system_admin'],
          icon: 'admin_panel_settings',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        RoleModel(
          id: '',
          name: 'Pasteur',
          description: 'Responsable pastoral avec accès étendu',
          color: '#9C27B0',
          permissions: [
            'read_persons', 'write_persons', 'manage_families',
            'read_groups', 'write_groups', 'manage_group_meetings',
            'read_events', 'write_events', 'manage_event_registrations',
            'read_services', 'write_services', 'manage_service_assignments',
            'read_appointments', 'write_appointments', 'manage_all_appointments',
            'view_statistics',
          ],
          icon: 'church',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        RoleModel(
          id: '',
          name: 'Leader',
          description: 'Responsable de groupe ou ministère',
          color: '#3F51B5',
          permissions: [
            'read_persons', 'read_groups', 'write_groups', 'manage_group_meetings',
            'read_events', 'read_services', 'read_tasks', 'write_tasks',
          ],
          icon: 'supervisor_account',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        RoleModel(
          id: '',
          name: 'Secrétaire',
          description: 'Gestion administrative et documentation',
          color: '#607D8B',
          permissions: [
            'read_persons', 'write_persons', 'manage_families',
            'read_groups', 'read_events', 'write_events',
            'read_forms', 'write_forms', 'view_form_responses',
          ],
          icon: 'description',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        RoleModel(
          id: '',
          name: 'Membre',
          description: 'Membre standard de la communauté',
          color: '#4CAF50',
          permissions: ['read_persons', 'read_groups', 'read_events'],
          icon: 'person',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      for (var role in defaultRoles) {
        await createRole(role);
      }
    } catch (e) {
      throw Exception('Erreur lors de la création des rôles par défaut: $e');
    }
  }

  // Utility methods
  static String getPermissionLabel(String permission) {
    const permissionLabels = {
      'read_persons': 'Voir les personnes',
      'write_persons': 'Modifier les personnes',
      'delete_persons': 'Supprimer les personnes',
      'manage_families': 'Gérer les familles',
      'read_groups': 'Voir les groupes',
      'write_groups': 'Modifier les groupes',
      'delete_groups': 'Supprimer les groupes',
      'manage_group_meetings': 'Gérer les réunions de groupe',
      'read_events': 'Voir les événements',
      'write_events': 'Modifier les événements',
      'delete_events': 'Supprimer les événements',
      'manage_event_registrations': 'Gérer les inscriptions événements',
      'read_services': 'Voir les services',
      'write_services': 'Modifier les services',
      'delete_services': 'Supprimer les services',
      'manage_service_assignments': 'Gérer les assignations services',
      'read_forms': 'Voir les formulaires',
      'write_forms': 'Modifier les formulaires',
      'delete_forms': 'Supprimer les formulaires',
      'view_form_responses': 'Voir les réponses formulaires',
      'read_tasks': 'Voir les tâches',
      'write_tasks': 'Modifier les tâches',
      'delete_tasks': 'Supprimer les tâches',
      'manage_task_assignments': 'Gérer les assignations tâches',

      'read_pages': 'Voir les pages',
      'write_pages': 'Modifier les pages',
      'delete_pages': 'Supprimer les pages',
      'manage_page_visibility': 'Gérer la visibilité des pages',
      'read_appointments': 'Voir les rendez-vous',
      'write_appointments': 'Modifier les rendez-vous',
      'manage_all_appointments': 'Gérer tous les rendez-vous',
      'manage_availability': 'Gérer les disponibilités',
      'view_statistics': 'Voir les statistiques',
      'manage_roles': 'Gérer les rôles',
      'manage_permissions': 'Gérer les permissions',
      'system_admin': 'Administration système',
    };

    return permissionLabels[permission] ?? permission;
  }

  static Map<String, List<String>> getPermissionCategories() {
    return {
      'Personnes': [
        'read_persons',
        'write_persons',
        'delete_persons',
        'manage_families',
      ],
      'Groupes': [
        'read_groups',
        'write_groups',
        'delete_groups',
        'manage_group_meetings',
      ],
      'Événements': [
        'read_events',
        'write_events',
        'delete_events',
        'manage_event_registrations',
      ],
      'Services': [
        'read_services',
        'write_services',
        'delete_services',
        'manage_service_assignments',
      ],
      'Formulaires': [
        'read_forms',
        'write_forms',
        'delete_forms',
        'view_form_responses',
      ],
      'Tâches': [
        'read_tasks',
        'write_tasks',
        'delete_tasks',
        'manage_task_assignments',
      ],

      'Pages': [
        'read_pages',
        'write_pages',
        'delete_pages',
        'manage_page_visibility',
      ],
      'Rendez-vous': [
        'read_appointments',
        'write_appointments',
        'manage_all_appointments',
        'manage_availability',
      ],
      'Administration': [
        'view_statistics',
        'manage_roles',
        'manage_permissions',
        'system_admin',
      ],
    };
  }

  // Activity logging
  static Future<void> _logRoleActivity(String roleId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection('role_activity_logs').add({
        'roleId': roleId,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Log silently, don't throw
      print('Erreur lors du logging: $e');
    }
  }
}