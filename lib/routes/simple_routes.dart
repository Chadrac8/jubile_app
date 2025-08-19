import 'package:flutter/material.dart';

// Pages de base
import '../pages/member_dashboard_page.dart';
import '../pages/member_profile_page.dart';
import '../pages/member_notifications_page.dart';
import '../pages/member_settings_page.dart';
import '../pages/member_calendar_page.dart';

// Pages modules
import '../pages/member_groups_page.dart';
import '../pages/member_events_page.dart';
import '../pages/member_services_page.dart';
import '../pages/member_forms_page.dart';
import '../pages/member_tasks_page.dart';

import '../pages/member_appointments_page.dart';
import '../pages/member_prayer_wall_page.dart';
import '../pages/member_pages_view.dart';


import '../pages/blog_home_page.dart';

// Pages admin
import '../pages/people_home_page.dart';
import '../pages/groups_home_page.dart';
import '../pages/events_home_page.dart';
import '../pages/services_home_page.dart';
import '../pages/forms_home_page.dart';
import '../pages/tasks_home_page.dart';

import '../pages/appointments_admin_page.dart';
import '../pages/prayers_home_page.dart';
import '../pages/pages_home_page.dart';


import '../pages/admin/admin_dashboard_page.dart';

// Vues modulaires rapports
// import '../modules/reports/views/report_detail_view.dart';
import '../modules/reports/views/report_form_view.dart';

// Auth
import '../auth/login_page.dart';
import '../pages/initial_profile_setup_page.dart';

// Utils et diagnostic
// import '../utils/index_checker.dart';
// import '../pages/demo_image_picker_page.dart';
// import '../pages/demo_video_component_page.dart';
// import '../pages/demo_audio_component_page.dart';
// import '../pages/demo_integrated_players_page.dart';
// import '../pages/media_player_demo_page.dart';
// import '../pages/media_integration_test_page.dart';
// import '../pages/demo_cover_image_page.dart';
// import '../pages/test_actions_sans_icones_page.dart';
// import '../pages/test_grid_container_page.dart';
// import '../pages/test_grid_container_debug_page.dart';
// import '../pages/test_grid_container_fix_page.dart';
// import '../pages/test_grid_icon_text_alignment_page.dart';
// import '../pages/test_grid_container_add_page.dart';
// import '../pages/test_webview_component_page.dart';
// import '../pages/test_webview_fix_page.dart';
// import '../pages/test_component_actions_page.dart';

/// Système de routes pour l'application ChurchFlow
class SimpleRoutes {
  /// Map des routes disponibles
  static final Map<String, WidgetBuilder> routes = {
    // Routes principales
    '/': (context) => const MemberDashboardPage(),
    '/login': (context) => const LoginPage(),
    '/profile-setup': (context) => const InitialProfileSetupPage(),
    
    // Navigation membre
    '/member/dashboard': (context) => const MemberDashboardPage(),
    '/member/profile': (context) => const MemberProfilePage(),
    '/member/notifications': (context) => const MemberNotificationsPage(),
    '/member/settings': (context) => const MemberSettingsPage(),
    '/member/calendar': (context) => const MemberCalendarPage(),
    
    // Modules membre
    '/member/groups': (context) => const MemberGroupsPage(),
    '/member/events': (context) => const MemberEventsPage(),
    '/member/services': (context) => const MemberServicesPage(),
    '/member/forms': (context) => const MemberFormsPage(),
    '/member/tasks': (context) => const MemberTasksPage(),

    '/member/appointments': (context) => const MemberAppointmentsPage(),
    '/member/prayers': (context) => const MemberPrayerWallPage(),
    '/member/pages': (context) => const MemberPagesView(),
    // '/member/automation': (context) => const MemberAutomationPage(),
    // '/member/reports': (context) => const MemberReportsPage(),
    
    // Blog et public
    '/blog': (context) => const BlogHomePage(),
    
    // Admin
    '/admin/dashboard': (context) => const AdminDashboardPage(),
    '/admin/people': (context) => const PeopleHomePage(),
    '/admin/groups': (context) => const GroupsHomePage(),
    '/admin/events': (context) => const EventsHomePage(),
    '/admin/services': (context) => const ServicesHomePage(),
    '/admin/forms': (context) => const FormsHomePage(),
    '/admin/tasks': (context) => const TasksHomePage(),

    '/admin/appointments': (context) => const AppointmentsAdminPage(),
    '/admin/prayers': (context) => const PrayersHomePage(),
    '/admin/pages': (context) => const PagesHomePage(),
    // '/admin/automation': (context) => const AutomationHomePage(),
    // '/admin/reports': (context) => const ReportsHomePage(),
    
    // Routes modulaires rapports
    '/reports/form': (context) => const ReportFormView(),
    
    // Diagnostic et utilitaires
    // '/diagnostic/indexes': (context) => const IndexDiagnosticPage(),
    // '/demo/image-picker': (context) => const DemoImagePickerPage(),
    // '/demo/video-component': (context) => const DemoVideoComponentPage(),
    // '/demo/audio-component': (context) => const DemoAudioComponentPage(),
    // '/demo/integrated-players': (context) => const DemoIntegratedPlayersPage(),
    // '/demo/media-players': (context) => const MediaPlayerDemoPage(),
    // '/test/media-integration': (context) => const MediaIntegrationTestPage(),
    // '/demo/cover-image': (context) => const DemoCoverImagePage(),
    // '/test/actions-sans-icones': (context) => const TestActionsSansIconesPage(),
    // '/test/grid-container': (context) => const TestGridContainerPage(),
    // '/test/grid-container-debug': (context) => const TestGridContainerDebugPage(),
    // '/test/grid-container-fix': (context) => const TestGridContainerFixPage(),
    // '/test/grid-icon-text-alignment': (context) => const TestGridIconTextAlignmentPage(),
    // '/test/grid-container-add': (context) => const TestGridContainerAddPage(),
    // '/test/webview-component': (context) => const TestWebViewComponentPage(),
    // '/test/component-actions': (context) => const TestComponentActionsPage(),
    // '/test/webview-fix': (context) => const TestWebViewFixPage(),
  };

  /// Générateur de routes avec fallback
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Vérifier si la route existe dans notre map
    if (routes.containsKey(settings.name)) {
      return MaterialPageRoute(
        builder: routes[settings.name]!,
        settings: settings,
      );
    }

    // Route par défaut si la route n'existe pas
    return MaterialPageRoute(
      builder: (context) => const MemberDashboardPage(),
      settings: settings,
    );
  }

  /// Vérifier si une route existe
  static bool routeExists(String routeName) {
    return routes.containsKey(routeName);
  }

  /// Navigation sécurisée vers une route
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (routeExists(routeName)) {
      return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page non disponible: $routeName'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  /// Remplacer la route actuelle
  static Future<T?> replaceTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (routeExists(routeName)) {
      return Navigator.of(context).pushReplacementNamed<T, dynamic>(
        routeName, 
        arguments: arguments
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page non disponible: $routeName'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  /// Navigation avec nettoyage de la pile
  static Future<T?> navigateAndClearStack<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (routeExists(routeName)) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        routeName,
        (route) => false,
        arguments: arguments,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page non disponible: $routeName'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
}