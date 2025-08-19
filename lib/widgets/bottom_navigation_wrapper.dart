import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_config_model.dart';

import '../models/person_model.dart';
import '../services/app_config_firebase_service.dart';

import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';

import '../pages/member_dashboard_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/people_home_page.dart';

import '../pages/member_groups_page.dart';
import '../pages/member_events_page.dart';
import '../pages/member_services_page.dart';
import '../pages/member_forms_page.dart';
import '../pages/member_tasks_page.dart';

import '../pages/member_calendar_page.dart';
import '../pages/member_notifications_page.dart';
import '../pages/member_settings_page.dart';
import '../pages/member_pages_view.dart';
import '../pages/member_appointments_page.dart';
import '../pages/member_profile_page.dart';
import '../pages/member_prayer_wall_page.dart';
import '../pages/member_songs_page.dart';
import '../pages/blog_home_page.dart';



import '../pages/member_dynamic_lists_page.dart';
import '../models/page_model.dart';
import '../services/pages_firebase_service.dart';

class BottomNavigationWrapper extends StatefulWidget {
  final String initialRoute;

  const BottomNavigationWrapper({
    super.key,
    this.initialRoute = 'dashboard',
  });

  @override
  State<BottomNavigationWrapper> createState() => _BottomNavigationWrapperState();
}

class _BottomNavigationWrapperState extends State<BottomNavigationWrapper> {
  String _currentRoute = 'dashboard';
  AppConfigModel? _appConfig;

  PersonModel? _currentUser;
  List<String> _userRoles = [];
  List<String> _userGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      // Charger la configuration de l'app
      final config = await AppConfigFirebaseService.getAppConfig();
      
      // Charger l'utilisateur actuel et ses rôles/groupes
      await _loadUserData();
      
      setState(() {
        _appConfig = config;
        _isLoading = false;
      });
      

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        // Charger les données de la personne
        final person = await AuthService.getCurrentUserProfile();
        if (person != null) {
          _currentUser = person;
          _userRoles = person.roles;
          
          // TODO: Charger les groupes de l'utilisateur
          // Implémenter la logique pour récupérer les groupes
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }



  Widget _getPageForRoute(String route) {
    // Routes par défaut
    switch (route) {
      case 'dashboard':
        return const MemberDashboardPage();

      case 'groups':
        return const MemberGroupsPage();
      case 'events':
        return const MemberEventsPage();
      case 'services':
        return const MemberServicesPage();
      case 'forms':
        return const MemberFormsPage();
      case 'tasks':
        return const MemberTasksPage();


      // case 'automation':
      //   return const MemberAutomationPage();
      // case 'reports':
      //   return const MemberReportsPage();
      case 'appointments':
        return const MemberAppointmentsPage();
      case 'prayers':
        return const MemberPrayerWallPage();
      case 'songs':
        return const MemberSongsPage();
      case 'blog':
        return const BlogHomePage();
      case 'calendar':
        return const MemberCalendarPage();
      case 'notifications':
        return const MemberNotificationsPage();
      case 'settings':
        return const MemberSettingsPage();
      case 'pages':
        return const MemberPagesView();
      case 'dynamic_lists':
        return const MemberDynamicListsPage();
      default:
        // Check if it's a custom page route
        if (route.startsWith('custom_page/')) {
          final slug = route.substring('custom_page/'.length);
          return CustomPageDirectView(pageSlug: slug);
        }
        return const MemberDashboardPage();
    }
  }

  IconData _getIconForModule(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'groups':
        return Icons.groups;
      case 'event':
        return Icons.event;
      case 'church':
        return Icons.church;
      case 'assignment':
        return Icons.assignment;
      case 'task_alt':
        return Icons.task_alt;
      case 'library_music':
        return Icons.library_music;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'event_available':
        return Icons.event_available;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'notifications':
        return Icons.notifications;
      case 'settings':
        return Icons.settings;
      case 'web':
        return Icons.web;
      case 'dashboard':
        return Icons.dashboard;
      case 'prayer_hands':
        return Icons.favorite;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'article':
        return Icons.article;
      case 'list_alt':
        return Icons.list_alt;
      default:
        return Icons.apps;
    }
  }



  void _showMoreMenu() {
    final secondaryModules = _appConfig?.secondaryModules ?? [];
    final secondaryPages = _appConfig?.secondaryPages ?? [];
    final allSecondaryItems = <dynamic>[...secondaryModules, ...secondaryPages];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.more_horiz, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Plus de modules',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (allSecondaryItems.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.apps, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun module ou page secondaire configuré',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: allSecondaryItems.length,
                      itemBuilder: (context, index) {
                        final item = allSecondaryItems[index];
                        if (item is ModuleConfig) {
                          return _buildModuleCard(item);
                        } else if (item is PageConfig) {
                          return _buildPageCard(item);
                        }
                        return Container();
                      },
                    ),
                  ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(ModuleConfig module) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _currentRoute = module.route;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForModule(module.iconName),
              size: 32,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 8),
            Text(
              module.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard(PageConfig page) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _currentRoute = page.route;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForModule(page.iconName),
              size: 32,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 8),
            Text(
              page.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_appConfig == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur de configuration'),
        ),
      );
    }

    final primaryModules = _appConfig!.primaryBottomNavModules.take(4).toList();
    final secondaryModules = _appConfig!.secondaryModules;
    final customMoreItems = <dynamic>[];
    final hasMoreModules = secondaryModules.isNotEmpty;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _getPageForRoute(_currentRoute),
      bottomNavigationBar: _buildBottomNavigationBar(primaryModules),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF850606),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Image.asset(
          'assets/logo_jt.png',
          height: 32,
          width: 32,
        ),
      ),
      centerTitle: true,
      title: Text(
        _getPageTitle(),
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        // Icônes Bible, Play, Notifications
        IconButton(
          icon: const Icon(Icons.menu_book, color: Colors.white),
          tooltip: 'Bible',
          onPressed: () {
            // TODO: Naviguer vers la Bible
          },
        ),
        IconButton(
          icon: const Icon(Icons.play_circle_fill, color: Colors.white),
          tooltip: 'Play',
          onPressed: () {
            // TODO: Action Play
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          tooltip: 'Notifications',
          onPressed: () {
            // TODO: Naviguer vers les notifications
          },
        ),
        // Icône Mon profil
        IconButton(
          onPressed: _showProfileMenu,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: _currentUser?.profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _currentUser!.profileImageUrl!,
                      width: 32,
                      height: 32,
                    ),
                  )
                : Icon(Icons.person, color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  String _getPageTitle() {
    // Check if it's a custom page route
    if (_currentRoute.startsWith('custom_page/')) {
      final slug = _currentRoute.substring('custom_page/'.length);
      final page = _appConfig?.customPages.firstWhere(
        (p) => p.slug == slug,
        orElse: () => PageConfig(id: '', title: 'Page personnalisée', description: '', iconName: 'web', route: '', slug: slug),
      );
      return page?.title ?? 'Page personnalisée';
    }
    
    switch (_currentRoute) {
      case 'dashboard':
        return 'Accueil';
      case 'groups':
        return 'Mes Groupes';
      case 'events':
        return 'Événements';
      case 'services':
        return 'Mes Services';
      case 'forms':
        return 'Formulaires';
      case 'tasks':
        return 'Mes Tâches';

      case 'automation':
        return 'Automatisations';

      case 'calendar':
        return 'Calendrier';
      case 'appointments':
        return 'Mes Rendez-vous';
      case 'pages':
        return 'Pages';
      case 'prayers':
        return 'Mur de Prière';
      case 'songs':
        return 'Recueil des Chants';
      case 'blog':
        return 'Blog';
      case 'notifications':
        return 'Notifications';
      case 'settings':
        return 'Paramètres';
      case 'dynamic_lists':
        return 'Listes Dynamiques';
      default:
        return 'ChurchFlow';
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileMenuSheet(
        currentUser: _currentUser,
        onNavigate: (route) {
          Navigator.pop(context);
          setState(() {
            _currentRoute = route;
          });
        },
        onEditProfile: () {
          Navigator.pop(context);
          _navigateToEditProfile();
        },
      ),
    );
  }

  void _navigateToEditProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfilePage(person: _currentUser),
        ),
      );
    }
  }

  Widget _buildBottomNavigationBar(List<ModuleConfig> primaryModules) {
    final primaryPages = _appConfig?.primaryBottomNavPages ?? [];
    final allPrimaryItems = <dynamic>[...primaryModules, ...primaryPages];
    
    // Sort by order
    allPrimaryItems.sort((a, b) {
      final orderA = a is ModuleConfig ? a.order : (a as PageConfig).order;
      final orderB = b is ModuleConfig ? b.order : (b as PageConfig).order;
      return orderA.compareTo(orderB);
    });
    
    // Déterminer combien d'éléments primaires on peut afficher
    final secondaryModules = _appConfig?.secondaryModules ?? [];
    final secondaryPages = _appConfig?.secondaryPages ?? [];
    final hasMoreItems = secondaryModules.isNotEmpty || secondaryPages.isNotEmpty;
    
    // Toujours afficher jusqu'à 4 éléments principaux, le reste va dans "Plus"
    final maxPrimaryItems = 4;
    final finalItems = allPrimaryItems.take(maxPrimaryItems).toList();
    final allRoutes = <String>[];
    
    // Debug info
    print('=== DEBUG BOTTOM NAV ===');
    print('Primary modules count: ${primaryModules.length}');
    print('Primary pages count: ${primaryPages.length}');
    print('Total primary items: ${allPrimaryItems.length}');
    print('Has more items: $hasMoreItems');
    print('Max primary items: $maxPrimaryItems');
    print('Final items count: ${finalItems.length}');
    
    // Debug les pages personnalisées en détail
    print('--- DEBUG CUSTOM PAGES ---');
    final allCustomPages = _appConfig?.customPages ?? [];
    print('Total custom pages: ${allCustomPages.length}');
    for (var page in allCustomPages) {
      print('Page: ${page.title}');
      print('  - ID: ${page.id}');
      print('  - Route: ${page.route}');
      print('  - Enabled for members: ${page.isEnabledForMembers}');
      print('  - Primary in bottom nav: ${page.isPrimaryInBottomNav}');
      print('  - Order: ${page.order}');
    }
    print('Primary pages (enabled): ${primaryPages.length}');
    for (var page in primaryPages) {
      print('  - ${page.title} (order: ${page.order})');
    }
    print('=======================');
    
    if (finalItems.isEmpty) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
        ],
      );
    }
    
    // Construire les BottomNavigationBarItem
    final navItems = <BottomNavigationBarItem>[];
    
    for (final item in finalItems) {
      if (item is ModuleConfig) {
        navItems.add(BottomNavigationBarItem(
          icon: Icon(_getIconForModule(item.iconName)),
          label: item.name,
        ));
        allRoutes.add(item.route);
      } else if (item is PageConfig) {
        navItems.add(BottomNavigationBarItem(
          icon: Icon(_getIconForModule(item.iconName)),
          label: item.title,
        ));
        allRoutes.add(item.route);
      }
    }
    
    // Ajouter "Plus" si nécessaire
    if (hasMoreItems) {
      navItems.add(BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz),
        label: 'Plus',
      ));
      allRoutes.add('more');
    }
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(allRoutes),
      onTap: (index) {
        if (allRoutes[index] == 'more') {
          _showMoreMenu();
        } else {
          setState(() {
            _currentRoute = allRoutes[index];
          });
        }
      },
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryColor,
      items: navItems,
    );
  }

  int _getCurrentIndex(List<String> routes) {
    final index = routes.indexWhere((route) => route == _currentRoute);
    return index != -1 ? index : 0;
  }
}

class _ProfileMenuSheet extends StatelessWidget {
  final PersonModel? currentUser;
  final Function(String) onNavigate;
  final VoidCallback onEditProfile;

  const _ProfileMenuSheet({
    required this.currentUser,
    required this.onNavigate,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header avec profil
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Photo de profil
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: currentUser?.profileImageUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: currentUser!.profileImageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                                size: 30,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                                size: 30,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Informations utilisateur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.fullName ?? 'Utilisateur',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        if (currentUser?.roles.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentUser!.roles.join(' • '),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Bouton éditer
                  IconButton(
                    onPressed: onEditProfile,
                    icon: const Icon(
                      Icons.edit,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'Éditer mon profil',
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Menu items relatifs au profil
            ..._buildProfileMenuItems(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProfileMenuItems(BuildContext context) {
    final profileModules = [
      {
        'title': 'Mes Informations',
        'subtitle': 'Voir et modifier mes informations personnelles',
        'icon': Icons.person_outline,
        'action': () => onEditProfile(),
      },
      {
        'title': 'Mes Groupes',
        'subtitle': 'Groupes auxquels je participe',
        'icon': Icons.groups_outlined,
        'action': () => onNavigate('groups'),
      },
      {
        'title': 'Mes Services',
        'subtitle': 'Services et affectations',
        'icon': Icons.church_outlined,
        'action': () => onNavigate('services'),
      },
      {
        'title': 'Mes Tâches',
        'subtitle': 'Tâches qui me sont assignées',
        'icon': Icons.task_alt_outlined,
        'action': () => onNavigate('tasks'),
      },
      {
        'title': 'Mes Rendez-vous',
        'subtitle': 'Gérer mes rendez-vous',
        'icon': Icons.event_available_outlined,
        'action': () => onNavigate('appointments'),
      },
      {
        'title': 'Mon Calendrier',
        'subtitle': 'Vue d\'ensemble de mes activités',
        'icon': Icons.calendar_today_outlined,
        'action': () => onNavigate('calendar'),
      },
      {
        'title': 'Recueil des Chants',
        'subtitle': 'Parcourir les chants et favoris',
        'icon': Icons.music_note_outlined,
        'action': () => onNavigate('songs'),
      },
      {
        'title': 'Notifications',
        'subtitle': 'Centre de notifications',
        'icon': Icons.notifications_outlined,
        'action': () => onNavigate('notifications'),
      },
      {
        'title': 'Paramètres',
        'subtitle': 'Configuration de l\'application',
        'icon': Icons.settings_outlined,
        'action': () => onNavigate('settings'),
      },
    ];

    return profileModules.map((module) => _buildMenuItem(
      title: module['title'] as String,
      subtitle: module['subtitle'] as String,
      icon: module['icon'] as IconData,
      onTap: module['action'] as VoidCallback,
    )).toList();
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textTertiaryColor,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

// Widget pour afficher directement une page personnalisée
class CustomPageDirectView extends StatefulWidget {
  final String pageSlug;
  
  const CustomPageDirectView({
    super.key,
    required this.pageSlug,
  });

  @override
  @override
  State<CustomPageDirectView> createState() => _CustomPageDirectViewState();
}

class _CustomPageDirectViewState extends State<CustomPageDirectView> {
  CustomPageModel? _page;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final page = await PagesFirebaseService.getPageBySlug(widget.pageSlug);
      
      if (page != null && page.isVisible) {
        setState(() {
          _page = page;
          _isLoading = false;
        });
        
        // Enregistrer la vue de la page
        try {
          await PagesFirebaseService.recordPageView(page.id, null);
        } catch (e) {
          // Erreur silencieuse pour les statistiques
        }
      } else {
        setState(() {
          _errorMessage = 'Page non trouvée ou non disponible';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPage,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_page == null) {
      return const Scaffold(
        body: Center(
          child: Text('Page non trouvée'),
        ),
      );
    }

    // Retourner directement le contenu de la page sans navigation wrapper
    return MemberPageDetailView(page: _page!);
  }
}