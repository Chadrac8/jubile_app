import 'package:flutter/material.dart';
import '../../compatibility/app_theme_bridge.dart';
import '../services/roles_firebase_service.dart';
import '../auth/auth_service.dart';

/// Middleware pour protéger l'accès aux pages
class RouteGuard {
  static Future<bool> canAccess({
    required String permission,
    List<String>? roles,
    bool requireAllRoles = false,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      // Vérifier la permission si spécifiée
      if (permission.isNotEmpty) {
        final hasPermission = await RolesFirebaseService.currentUserHasPermission(permission);
        if (!hasPermission) return false;
      }

      // Vérifier les rôles si spécifiés
      if (roles != null && roles.isNotEmpty) {
        final userRoles = await AuthService.getCurrentUserRoles();
        
        if (requireAllRoles) {
          return roles.every((role) => userRoles.contains(role));
        } else {
          return roles.any((role) => userRoles.contains(role));
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Page wrapper qui protège l'accès
  static Widget protectedRoute({
    required Widget page,
    required String permission,
    List<String>? roles,
    bool requireAllRoles = false,
    Widget? unauthorizedPage,
  }) {
    return FutureBuilder<bool>(
      future: canAccess(
        permission: permission,
        roles: roles,
        requireAllRoles: requireAllRoles),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator()));
        }

        if (snapshot.data == true) {
          return page;
        }

        return unauthorizedPage ?? _buildUnauthorizedPage(context);
      });
  }

  static Widget _buildUnauthorizedPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès refusé'),
        backgroundColor: Theme.of(context).colorScheme.errorColor,
        foregroundColor: Theme.of(context).colorScheme.surfaceColor),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 100,
                color: Theme.of(context).colorScheme.textTertiaryColor),
              const SizedBox(height: 24),
              Text(
                'Accès non autorisé',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.textTertiaryColor),
                textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Vous n\'avez pas les permissions nécessaires pour accéder à cette page.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.textTertiaryColor),
                textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour')),
            ]))));
  }
}

/// Classe pour définir les permissions requises pour les routes
class RoutePermissions {
  // Personnes
  static const String viewPersons = 'read_persons';
  static const String editPersons = 'write_persons';
  static const String deletePersons = 'delete_persons';
  static const String manageFamilies = 'manage_families';

  // Groupes
  static const String viewGroups = 'read_groups';
  static const String editGroups = 'write_groups';
  static const String deleteGroups = 'delete_groups';
  static const String manageGroupMeetings = 'manage_group_meetings';

  // Événements
  static const String viewEvents = 'read_events';
  static const String editEvents = 'write_events';
  static const String deleteEvents = 'delete_events';
  static const String manageEventRegistrations = 'manage_event_registrations';

  // Services
  static const String viewServices = 'read_services';
  static const String editServices = 'write_services';
  static const String deleteServices = 'delete_services';
  static const String manageServiceAssignments = 'manage_service_assignments';

  // Formulaires
  static const String viewForms = 'read_forms';
  static const String editForms = 'write_forms';
  static const String deleteForms = 'delete_forms';
  static const String viewFormResponses = 'view_form_responses';

  // Tâches
  static const String viewTasks = 'read_tasks';
  static const String editTasks = 'write_tasks';
  static const String deleteTasks = 'delete_tasks';
  static const String manageTaskAssignments = 'manage_task_assignments';

  // Pages
  static const String viewPages = 'read_pages';
  static const String editPages = 'write_pages';
  static const String deletePages = 'delete_pages';
  static const String managePageVisibility = 'manage_page_visibility';

  // Rendez-vous
  static const String viewAppointments = 'read_appointments';
  static const String editAppointments = 'write_appointments';
  static const String manageAllAppointments = 'manage_all_appointments';
  static const String manageAvailability = 'manage_availability';

  // Administration
  static const String viewStatistics = 'view_statistics';
  static const String manageRoles = 'manage_roles';
  static const String managePermissions = 'manage_permissions';
  static const String systemAdmin = 'system_admin';
}

/// Extension pour faciliter l'utilisation des guards
extension RouteGuardExtension on Widget {
  Widget requirePermission(
    String permission, {
    Widget? fallback,
    bool showFallbackOnDenied = true,
  }) {
    return RouteGuard.protectedRoute(
      page: this,
      permission: permission,
      unauthorizedPage: fallback);
  }

  Widget requireRole(
    List<String> roles, {
    bool requireAll = false,
    Widget? fallback,
  }) {
    return RouteGuard.protectedRoute(
      page: this,
      permission: '',
      roles: roles,
      requireAllRoles: requireAll,
      unauthorizedPage: fallback);
  }

  Widget requirePermissionAndRole(
    String permission,
    List<String> roles, {
    bool requireAllRoles = false,
    Widget? fallback,
  }) {
    return RouteGuard.protectedRoute(
      page: this,
      permission: permission,
      roles: roles,
      requireAllRoles: requireAllRoles,
      unauthorizedPage: fallback);
  }
}
