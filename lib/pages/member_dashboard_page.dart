import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/person_model.dart';
import '../models/group_model.dart';
import '../models/event_model.dart';
import '../models/service_model.dart';
import '../models/form_model.dart';
import '../models/appointment_model.dart';
import '../services/firebase_service.dart';
import '../services/groups_firebase_service.dart';
import '../services/events_firebase_service.dart';
import '../services/services_firebase_service.dart';
import '../services/forms_firebase_service.dart';
import '../services/appointments_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import '../widgets/admin_navigation_wrapper.dart';
import '../widgets/appointment_card.dart';
import '../widgets/appointment_notifications_widget.dart';
import '../widgets/my_assigned_workflows_widget.dart';

import 'member_profile_page.dart';
import 'member_groups_page.dart';
import 'member_events_page.dart';
import 'member_services_page.dart';
import 'member_forms_page.dart';
import 'member_tasks_page.dart';
import 'member_songs_page.dart';

import 'member_notifications_page.dart';
import 'member_calendar_page.dart';
import 'member_settings_page.dart';
import 'member_pages_view.dart';
import 'member_appointments_page.dart';
import 'appointment_detail_page.dart';

import '../routes/simple_routes.dart';

class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  PersonModel? _currentUser;
  List<GroupModel> _userGroups = [];
  List<EventModel> _upcomingEvents = [];
  List<ServiceAssignmentModel> _pendingServices = [];
  List<FormModel> _availableForms = [];
  List<AppointmentModel> _upcomingAppointments = [];
  int _unreadNotifications = 0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _dashboardModules = [

    {
      'title': 'Mes Groupes',
      'subtitle': 'Groupes et communautés',
      'icon': Icons.groups,
      'color': Theme.of(context).colorScheme.secondaryColor,
      'route': 'groups',
    },
    {
      'title': 'Mes Événements',
      'subtitle': 'Événements à venir',
      'icon': Icons.event,
      'color': Theme.of(context).colorScheme.tertiaryColor,
      'route': 'events',
    },
    {
      'title': 'Mes Services',
      'subtitle': 'Affectations et planning',
      'icon': Icons.church,
      'color': Colors.purple,
      'route': 'services',
    },
    {
      'title': 'Formulaires',
      'subtitle': 'Formulaires à remplir',
      'icon': Icons.assignment,
      'color': Colors.teal,
      'route': 'forms',
    },
    {
      'title': 'Mes Tâches',
      'subtitle': 'Tâches assignées et listes',
      'icon': Icons.task_alt,
      'color': Colors.indigo,
      'route': 'tasks',
    },

    {
      'title': 'Mes Rendez-vous',
      'subtitle': 'Prendre et gérer mes RDV',
      'icon': Icons.event_available,
      'color': Colors.indigo,
      'route': 'appointments',
    },
    {
      'title': 'Calendrier',
      'subtitle': 'Mon agenda personnel',
      'icon': Icons.calendar_today,
      'color': Colors.indigo,
      'route': 'calendar',
    },
    {
      'title': 'Pages',
      'subtitle': 'Contenus personnalisés',
      'icon': Icons.web,
      'color': Colors.purple,
      'route': 'pages',
    },
    {
      'title': 'Recueil des chants',
      'subtitle': 'Chants et cantiques',
      'icon': Icons.music_note,
      'color': Colors.deepOrange,
      'route': 'songs',
    },

  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      // Charger les informations de l'utilisateur
      final userData = await AuthService.getCurrentUserProfile();
      if (userData != null) {
        setState(() {
          _currentUser = userData;
        });
      }

      // Charger les données en parallèle
      final futures = await Future.wait([
        _loadUserGroups(),
        _loadUpcomingEvents(),
        _loadPendingServices(),
        _loadAvailableForms(),
        _loadUpcomingAppointments(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement : $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadUserGroups() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final groupsStream = GroupsFirebaseService.getGroupsStream(limit: 3);
      await for (final groups in groupsStream.take(1)) {
        setState(() {
          _userGroups = groups ?? [];
        });
        break;
      }
    } catch (e) {
      print('Erreur chargement groupes: $e');
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final eventsStream = EventsFirebaseService.getUpcomingEventsStream(limit: 3);
      await for (final events in eventsStream.take(1)) {
        setState(() {
          _upcomingEvents = events ?? [];
        });
        break;
      }
    } catch (e) {
      print('Erreur chargement événements: $e');
    }
  }

  Future<void> _loadPendingServices() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final assignments = await ServicesFirebaseService.getPersonAssignments(
        user.uid,
        startDate: DateTime.now(),
      );
      final pending = assignments?.where((a) => a.status == 'invited').toList() ?? [];
      setState(() {
        _pendingServices = pending;
      });
    } catch (e) {
      print('Erreur chargement services: $e');
    }
  }

  Future<void> _loadAvailableForms() async {
    try {
      final forms = await FormsFirebaseService.getFormsStream(
        statusFilter: 'publie',
        limit: 3,
      ).first;
      
      setState(() {
        _availableForms = forms;
      });
    } catch (e) {
      print('Erreur lors du chargement des formulaires: $e');
    }
  }

  Future<void> _loadUpcomingAppointments() async {
    try {
      if (_currentUser != null) {
        final appointments = await AppointmentsFirebaseService.getUpcomingAppointments(
          membreId: _currentUser!.id,
          limit: 3,
        );
        
        setState(() {
          _upcomingAppointments = appointments;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des rendez-vous: $e');
    }
  }

  void _navigateToModule(String route) {
    Widget page;
    switch (route) {
      case 'profile':
        // Seulement naviguer si nous avons un utilisateur courant
        if (_currentUser != null) {
          page = MemberProfilePage(person: _currentUser!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil non disponible. Veuillez vous reconnecter.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        break;
      case 'groups':
        page = const MemberGroupsPage();
        break;
      case 'events':
        page = const MemberEventsPage();
        break;
      case 'services':
        page = const MemberServicesPage();
        break;
      case 'forms':
        page = const MemberFormsPage();
        break;
      case 'tasks':
        page = const MemberTasksPage();
        break;

      case 'appointments':
        page = const MemberAppointmentsPage();
        break;
      case 'calendar':
        page = const MemberCalendarPage();
        break;
      case 'pages':
        page = const MemberPagesView();
        break;
      case 'songs':
        page = const MemberSongsPage();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.textPrimaryColor,
        actions: [
          // Toggle to admin view
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminNavigationWrapper(),
                  ),
                );
              },
              tooltip: 'Vue Administrateur',
              iconSize: 20,
            ),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Theme.of(context).colorScheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemberNotificationsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemberSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(),
                        const SizedBox(height: 24),
                        const AppointmentNotificationsWidget(),
                        _buildAnnouncementsBanner(),
                        const SizedBox(height: 24),
                        _buildRemindersBanner(),
                        const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 20),
            _buildMyFollowUpsSection(),
            const SizedBox(height: 20),
            _buildModulesGrid(),
            const SizedBox(height: 20),
            if (_upcomingAppointments.isNotEmpty) ...[
              _buildUpcomingAppointments(),
              const SizedBox(height: 20),
            ],
            _buildUpcomingSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryColor,
              Theme.of(context).colorScheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildProfileAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${_currentUser?.firstName ?? 'Membre'} !',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_currentUser?.roles.isNotEmpty == true)
                    Text(
                      _currentUser?.roles.join(', ') ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_upcomingEvents.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Prochain : ${_upcomingEvents.first.title}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: (_currentUser?.profileImageUrl != null && _currentUser!.profileImageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: _currentUser!.profileImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingAvatar(),
                errorWidget: (context, url, error) => _buildFallbackAvatar(),
              )
            : _buildFallbackAvatar(),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final imageUrl = "https://pixabay.com/get/gd8d11dfb9c3bc9a1585c8ff0939d1b7e79707b3539b69b28509fb2b6cb159919bdc616032dc99dd505442fae239f4eaa1212f5b7e2bf2ac47176e9d09306b3e8_1280.jpg";

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
        child: Icon(
          Icons.person,
          size: 40,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
        child: Icon(
          Icons.person,
          size: 40,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsBanner() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.secondaryColor.withOpacity(0.1),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.campaign,
              color: Theme.of(context).colorScheme.secondaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annonces de l\'église',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nouvelle série de prédications sur l\'amour de Dieu - Dimanche 10h',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersBanner() {
    final hasReminders = _pendingServices.isNotEmpty || _availableForms.isNotEmpty;
    
    if (!hasReminders) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.warningColor.withOpacity(0.1),
          border: Border.all(
            color: Theme.of(context).colorScheme.warningColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rappels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pendingServices.isNotEmpty)
              _buildReminderItem(
                'Services en attente de confirmation',
                '${_pendingServices.length} affectation(s) à confirmer',
                Icons.church,
              ),
            if (_availableForms.isNotEmpty)
              _buildReminderItem(
                'Formulaires à remplir',
                '${_availableForms.length} formulaire(s) disponible(s)',
                Icons.assignment,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.warningColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Mes Groupes',
            _userGroups.length.toString(),
            Icons.groups,
            Theme.of(context).colorScheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rendez-vous',
            _upcomingAppointments.length.toString(),
            Icons.event_available,
            Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Services',
            _pendingServices.length.toString(),
            Icons.church,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modules',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _dashboardModules.length,
          itemBuilder: (context, index) {
            final module = _dashboardModules[index];
            return _buildModuleCard(module);
          },
        ),
      ],
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToModule(module['route']),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                module['color'],
                module['color'].withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                module['icon'],
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                module['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                module['subtitle'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes prochains rendez-vous',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MemberAppointmentsPage()),
              ),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_upcomingAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun rendez-vous prévu',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MemberAppointmentsPage()),
                    ),
                    child: const Text('Prendre rendez-vous'),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_upcomingAppointments.map((appointment) => AppointmentCard(
            appointment: appointment,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailPage(appointment: appointment),
              ),
            ),
            isCompact: true,
          ))),
      ],
    );
  }

  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'À venir',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildUpcomingEvents(),
        if (_userGroups.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildUpcomingMeetings(),
        ],
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.tertiaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Événements à venir',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_upcomingEvents.take(3).where((event) => event != null).map((event) => _buildEventItem(event))),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(EventModel event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
                Text(
                  _formatEventDate(event.startDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMeetings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: Theme.of(context).colorScheme.secondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mes groupes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_userGroups.take(3).where((group) => group != null).map((group) => _buildGroupItem(group))),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupItem(GroupModel group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(int.parse(group.color.replaceFirst('#', '0xFF'))),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${group.dayName} à ${group.time}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getAppointmentIcon(appointment.lieu),
              color: Colors.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.motif,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAppointmentDate(appointment.dateTime),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getAppointmentStatusColor(appointment.statut).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              appointment.statutLabel,
              style: TextStyle(
                color: _getAppointmentStatusColor(appointment.statut),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAppointmentIcon(String lieu) {
    switch (lieu) {
      case 'en_personne':
        return Icons.location_on;
      case 'appel_video':
        return Icons.video_call;
      case 'telephone':
        return Icons.phone;
      default:
        return Icons.event;
    }
  }

  Color _getAppointmentStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Theme.of(context).colorScheme.warningColor;
      case 'confirme':
        return Theme.of(context).colorScheme.successColor;
      case 'refuse':
        return Theme.of(context).colorScheme.errorColor;
      case 'termine':
        return Theme.of(context).colorScheme.primaryColor;
      case 'annule':
        return Theme.of(context).colorScheme.textTertiaryColor;
      default:
        return Theme.of(context).colorScheme.textTertiaryColor;
    }
  }

  String _formatAppointmentDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    
    if (diff == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      return 'Demain à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
    } else if (diff < 7) {
      return 'Dans $diff jours à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMyFollowUpsSection() {
    if (_currentUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.track_changes,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes Suivis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Suivis dont je suis responsable',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200, // Hauteur fixe pour permettre le scroll si nécessaire
              child: MyAssignedWorkflowsWidget(
                personId: _currentUser!.id,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    
    if (diff == 0) {
      return 'Aujourd\'hui';
    } else if (diff == 1) {
      return 'Demain';
    } else if (diff < 7) {
      return 'Dans $diff jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}