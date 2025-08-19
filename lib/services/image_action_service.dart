import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/image_action_model.dart';
import '../pages/member_groups_page.dart';
import '../pages/member_events_page.dart';

import '../pages/blog_home_page.dart';
import '../pages/member_prayer_wall_page.dart';
import '../pages/member_appointments_page.dart';
import '../pages/member_services_page.dart';
import '../pages/member_forms_page.dart';
import '../pages/member_tasks_page.dart';
import '../pages/member_dashboard_page.dart';
import '../pages/member_profile_page.dart';
import '../pages/member_calendar_page.dart';
import '../pages/form_public_page.dart';

class ImageActionService {
  static Future<void> handleImageAction(
    BuildContext context,
    ImageAction action,
  ) async {
    switch (action.type) {
      case 'url':
        await _handleUrlAction(action.url);
        break;
      case 'member_page':
        await _handleMemberPageAction(context, action);
        break;
      default:
        debugPrint('Type d\'action non supporté: ${action.type}');
    }
  }

  static Future<void> _handleUrlAction(String? url) async {
    if (url == null || url.trim().isEmpty) {
      debugPrint('URL vide ou nulle');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Impossible d\'ouvrir l\'URL: $url');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de l\'URL: $e');
    }
  }

  static Future<void> _handleMemberPageAction(
    BuildContext context,
    ImageAction action,
  ) async {
    if (action.memberPage == null) {
      debugPrint('Page membre non spécifiée');
      return;
    }

    final pageDefinition = MemberPagesRegistry.findByKey(action.memberPage!);
    if (pageDefinition == null) {
      debugPrint('Page membre non trouvée: ${action.memberPage}');
      return;
    }

    try {
      Widget? page;
      
      switch (action.memberPage!) {
        case 'my_groups':
          page = const MemberGroupsPage();
          break;
          
        case 'my_events':
          page = const MemberEventsPage();
          break;
          

          
        case 'blog_category':
          page = const BlogHomePage();
          // TODO: Implémenter la navigation vers une catégorie spécifique
          break;
          
        case 'prayer_wall':
          page = const MemberPrayerWallPage();
          break;
          
        case 'appointments':
          page = const MemberAppointmentsPage();
          break;
          
        case 'my_services':
          page = const MemberServicesPage();
          break;
          
        case 'my_forms':
          page = const MemberFormsPage();
          break;
          
        case 'specific_form':
          final formId = action.parameters?['formId'];
          if (formId != null) {
            page = FormPublicPage(formId: formId);
          }
          break;
          
        case 'my_tasks':
          page = const MemberTasksPage();
          break;
          
        case 'member_dashboard':
          page = const MemberDashboardPage();
          break;
          
        case 'member_profile':
          page = const MemberProfilePage();
          break;
          
        case 'member_calendar':
          page = const MemberCalendarPage();
          break;
          
        default:
          debugPrint('Page membre non implémentée: ${action.memberPage}');
          return;
      }

      if (page != null && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => page!,
            settings: RouteSettings(
              name: pageDefinition.route,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la navigation vers ${action.memberPage}: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de ${pageDefinition.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Valide qu'une action d'image est correctement configurée
  static bool validateImageAction(ImageAction action) {
    switch (action.type) {
      case 'url':
        return action.url != null && action.url!.trim().isNotEmpty;
        
      case 'member_page':
        if (action.memberPage == null) return false;
        
        final pageDefinition = MemberPagesRegistry.findByKey(action.memberPage!);
        if (pageDefinition == null) return false;
        
        // Vérifier les paramètres requis
        if (pageDefinition.supportedParameters != null) {
          for (final param in pageDefinition.supportedParameters!) {
            if (action.parameters?[param] == null) {
              return false;
            }
          }
        }
        
        return true;
        
      default:
        return false;
    }
  }

  /// Obtient un message d'erreur de validation
  static String? getValidationError(ImageAction action) {
    switch (action.type) {
      case 'url':
        if (action.url == null || action.url!.trim().isEmpty) {
          return 'L\'URL est requise pour cette action';
        }
        break;
        
      case 'member_page':
        if (action.memberPage == null) {
          return 'La page membre doit être sélectionnée';
        }
        
        final pageDefinition = MemberPagesRegistry.findByKey(action.memberPage!);
        if (pageDefinition == null) {
          return 'Page membre invalide: ${action.memberPage}';
        }
        
        // Vérifier les paramètres requis
        if (pageDefinition.supportedParameters != null) {
          for (final param in pageDefinition.supportedParameters!) {
            if (action.parameters?[param] == null) {
              return 'Le paramètre $param est requis pour ${pageDefinition.name}';
            }
          }
        }
        break;
        
      default:
        return 'Type d\'action non supporté: ${action.type}';
    }
    
    return null;
  }
}