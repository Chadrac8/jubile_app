import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/component_action_model.dart';
import '../services/forms_firebase_service.dart';
import '../pages/member_groups_page.dart';
import '../pages/member_events_page.dart';

import '../pages/member_forms_page.dart';
import '../pages/member_prayer_wall_page.dart';
import '../pages/member_appointments_page.dart';
import '../pages/member_services_page.dart';
import '../pages/blog_home_page.dart';
import '../pages/member_profile_page.dart';
import '../pages/member_notifications_page.dart';
import '../pages/member_calendar_page.dart';
import '../pages/member_settings_page.dart';
import '../pages/member_tasks_page.dart';

import '../pages/member_dashboard_page.dart';
import '../pages/form_detail_page.dart';
import '../pages/blog_categories_page.dart';
import '../services/pages_firebase_service.dart';
import '../pages/member_pages_view.dart';

class ComponentActionService {
  static Future<void> handleComponentAction(
    BuildContext context, 
    ComponentAction action
  ) async {
    switch (action.type) {
      case ComponentActionType.none:
        break;
      case ComponentActionType.externalUrl:
        await _handleExternalUrl(action.url);
        break;
      case ComponentActionType.internalUrl:
        await _handleInternalUrl(context, action.url);
        break;
      case ComponentActionType.memberPage:
        await _handleMemberPageNavigation(context, action.memberPageType!);
        break;
      case ComponentActionType.customPage:
        await _handleCustomPageNavigation(context, action.customPageId!);
        break;
      case ComponentActionType.blogCategory:
        await _handleBlogCategoryNavigation(context, action.blogCategory!);
        break;
      case ComponentActionType.specificForm:
        await _handleSpecificFormNavigation(context, action.formId!);
        break;
    }
  }

  static Future<void> _handleExternalUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  static Future<void> _handleInternalUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    
    try {
      // Naviguer vers une page WebView intégrée pour afficher l'URL
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _InternalWebViewPage(url: url),
        ),
      );
    } catch (e) {
      print('Error opening internal URL: $e');
      // Afficher une erreur et proposer des alternatives
      if (context.mounted) {
        _showWebViewErrorDialog(context, url, e.toString());
      }
    }
  }

  static void _showWebViewErrorDialog(BuildContext context, String url, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur WebView'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Impossible d\'ouvrir le lien dans l\'application.'),
            const SizedBox(height: 8),
            Text('URL: $url', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Erreur: $error', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _handleExternalUrl(url);
            },
            child: const Text('Ouvrir dans navigateur'),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleMemberPageNavigation(
    BuildContext context, 
    MemberPageType pageType
  ) async {
    Widget? targetPage;
    
    switch (pageType) {
      case MemberPageType.dashboard:
        targetPage = const MemberDashboardPage();
        break;
      case MemberPageType.groups:
        targetPage = const MemberGroupsPage();
        break;
      case MemberPageType.events:
        targetPage = const MemberEventsPage();
        break;

      case MemberPageType.forms:
        targetPage = const MemberFormsPage();
        break;
      case MemberPageType.prayerWall:
        targetPage = const MemberPrayerWallPage();
        break;
      case MemberPageType.appointments:
        targetPage = const MemberAppointmentsPage();
        break;
      case MemberPageType.services:
        targetPage = const MemberServicesPage();
        break;
      case MemberPageType.blog:
        targetPage = const BlogHomePage();
        break;
      case MemberPageType.profile:
        targetPage = const MemberProfilePage();
        break;
      case MemberPageType.notifications:
        targetPage = const MemberNotificationsPage();
        break;
      case MemberPageType.calendar:
        targetPage = const MemberCalendarPage();
        break;
      case MemberPageType.settings:
        targetPage = const MemberSettingsPage();
        break;
      case MemberPageType.tasks:
        targetPage = const MemberTasksPage();
        break;
      case MemberPageType.reports:
        // targetPage = const MemberReportsPage();
        break;
    }

    if (targetPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    }
  }

  static Future<void> _handleBlogCategoryNavigation(
    BuildContext context, 
    String categoryId
  ) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BlogCategoriesPage(),
      ),
    );
  }

  static Future<void> _handleSpecificFormNavigation(
    BuildContext context, 
    String formId
  ) async {
    final form = await _getFormById(formId);
    if (form != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FormDetailPage(form: form),
        ),
      );
    }
  }

  static Future<void> _handleCustomPageNavigation(
    BuildContext context, 
    String customPageId
  ) async {
    try {
      // Charger la page spécifique d'abord
      final page = await PagesFirebaseService.getPage(customPageId);
      if (page != null) {
        // Naviguer directement vers la vue détaillée de la page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemberPageDetailView(page: page),
          ),
        );
      } else {
        print('Page not found: $customPageId');
        _showPageNotFoundDialog(context, customPageId);
      }
    } catch (e) {
      print('Error navigating to custom page: $e');
      _showPageErrorDialog(context, customPageId, e.toString());
    }
  }

  static Future<dynamic> _getFormById(String formId) async {
    try {
      return await FormsFirebaseService.getForm(formId);
    } catch (e) {
      return null;
    }
  }

  /// Génère une action par défaut basée sur le type de composant
  static ComponentAction getDefaultAction(String componentType) {
    switch (componentType) {
      case 'banner':
        return ComponentAction(
          id: 'default_banner',
          type: ComponentActionType.memberPage,
          label: 'Voir mes groupes',
          memberPageType: MemberPageType.groups,
        );
      case 'button':
        return ComponentAction(
          id: 'default_button',
          type: ComponentActionType.internalUrl,
          label: 'Visiter le site',
          url: 'https://example.com',
        );
      case 'grid_icon_text':
        return ComponentAction(
          id: 'default_grid_icon',
          type: ComponentActionType.memberPage,
          label: 'Voir mes évènements',
          memberPageType: MemberPageType.events,
        );
      case 'grid_card':
        return ComponentAction(
          id: 'default_prayer_wall',
          type: ComponentActionType.memberPage,
          label: 'Mur de prière',
          memberPageType: MemberPageType.prayerWall,
        );
      case 'grid_image_card':
        return ComponentAction(
          id: 'default_image_card',
          type: ComponentActionType.memberPage,
          label: 'Mur de prière',
          memberPageType: MemberPageType.prayerWall,
        );
      default:
        return ComponentAction(
          id: 'default_none',
          type: ComponentActionType.none,
          label: 'Aucune action',
        );
    }
  }

  /// Vérifie si un composant supporte les actions cliquables
  static bool supportsActions(String componentType) {
    const supportedTypes = [
      'banner',
      'button',
      'webview',
      'grid_icon_text', 
      'grid_card',
      'grid_image_card'
    ];
    return supportedTypes.contains(componentType);
  }

  /// Récupère les icônes associées aux types d'actions
  static IconData getActionIcon(ComponentActionType type) {
    switch (type) {
      case ComponentActionType.none:
        return Icons.block;
      case ComponentActionType.externalUrl:
        return Icons.open_in_new;
      case ComponentActionType.internalUrl:
        return Icons.web;
      case ComponentActionType.memberPage:
        return Icons.navigate_next;
      case ComponentActionType.customPage:
        return Icons.pages;
      case ComponentActionType.blogCategory:
        return Icons.article;
      case ComponentActionType.specificForm:
        return Icons.assignment;
    }
  }

  /// Récupère le label du type d'action
  static String getActionTypeLabel(ComponentActionType type) {
    switch (type) {
      case ComponentActionType.none:
        return 'Aucune action';
      case ComponentActionType.externalUrl:
        return 'Lien externe';
      case ComponentActionType.internalUrl:
        return 'Lien internet (interne)';
      case ComponentActionType.memberPage:
        return 'Page membre';
      case ComponentActionType.customPage:
        return 'Page personnalisée';
      case ComponentActionType.blogCategory:
        return 'Catégorie blog';
      case ComponentActionType.specificForm:
        return 'Formulaire spécifique';
    }
  }

  /// Affiche un dialog d'erreur quand une page personnalisée n'est pas trouvée
  static void _showPageNotFoundDialog(BuildContext context, String pageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Page non trouvée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La page personnalisée demandée n\'a pas pu être trouvée.'),
            const SizedBox(height: 8),
            Text(
              'ID: $pageId',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Causes possibles:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• La page n\'est pas publiée'),
            const Text('• La page a été supprimée'),
            const Text('• Problème de connexion'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Affiche un dialog d'erreur pour les pages personnalisées
  static void _showPageErrorDialog(BuildContext context, String pageId, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur de chargement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Erreur lors du chargement de la page personnalisée:'),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $pageId',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _InternalWebViewPage extends StatefulWidget {
  final String url;

  const _InternalWebViewPage({required this.url});

  @override
  State<_InternalWebViewPage> createState() => _InternalWebViewPageState();
}

class _InternalWebViewPageState extends State<_InternalWebViewPage> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      
      _loadUrl();
    } catch (e) {
      print('Erreur lors de l\'initialisation WebView: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Erreur d\'initialisation de la WebView:\n${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadUrl() async {
    try {
      final uri = Uri.parse(widget.url);
      
      // Configuration de navigation sécurisée
      final currentController = controller;
      if (currentController != null) {
        try {
          await currentController.setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                }
              },
              onPageFinished: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = 'Erreur de chargement: ${error.description}';
                  });
                }
              },
            ),
          );
          
          await currentController.loadRequest(uri);
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Erreur lors du chargement de l\'URL:\n${e.toString()}';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'URL invalide:\n${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Web'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (_hasError) {
                _loadUrl();
              } else {
                try {
                  await controller.reload();
                } catch (e) {
                  debugPrint('Erreur lors du rechargement: $e');
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              try {
                final uri = Uri.parse(widget.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                debugPrint('Erreur lors de l\'ouverture dans le navigateur: $e');
              }
            },
          ),
        ],
      ),
      body: _hasError
          ? _buildErrorView()
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    try {
      return WebViewWidget(controller: controller);
    } catch (e) {
      return _buildWebViewError(e.toString());
    }
  }

  Widget _buildWebViewError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.web_asset_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'WebView non disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${widget.url}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Détails: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.parse(widget.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Erreur lors de l\'ouverture: $e');
                }
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Ouvrir dans le navigateur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger la page',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUrl,
              child: const Text('Réessayer'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                try {
                  final uri = Uri.parse(widget.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Erreur lors de l\'ouverture dans le navigateur: $e');
                }
              },
              child: const Text('Ouvrir dans le navigateur'),
            ),
          ],
        ),
      ),
    );
  }
}