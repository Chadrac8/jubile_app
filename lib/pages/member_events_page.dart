import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';


class MemberEventsPage extends StatefulWidget {
  const MemberEventsPage({super.key});

  @override
  State<MemberEventsPage> createState() => _MemberEventsPageState();
}

class _MemberEventsPageState extends State<MemberEventsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<EventModel> _myEvents = [];
  List<EventModel> _availableEvents = [];
  List<EventRegistrationModel> _myRegistrations = [];
  bool _isLoading = true;
  String _selectedTab = 'my_events';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEventsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadEventsData() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Charger tous les événements publics futurs
      final events = await EventsFirebaseService.getEventsStream(
        statusFilters: ['publie'],
        startDate: DateTime.now(),
        limit: 100,
      ).first.catchError((e) {
        print('Erreur chargement événements: $e');
        return <EventModel>[];
      });

      final myEvents = <EventModel>[];
      final availableEvents = <EventModel>[];
      final registrations = <EventRegistrationModel>[];

      // Pour chaque événement, vérifier si l'utilisateur est inscrit
      for (final event in events) {
        try {
          final eventRegistrations = await EventsFirebaseService.getEventRegistrationsStream(event.id)
              .first
              .timeout(const Duration(seconds: 5))
              .catchError((e) {
            print('Erreur chargement inscriptions pour ${event.id}: $e');
            return <EventRegistrationModel>[];
          });

          final myRegistration = eventRegistrations
              .where((r) => r.personId == user.uid)
              .isNotEmpty 
              ? eventRegistrations.firstWhere((r) => r.personId == user.uid)
              : null;

          if (myRegistration != null) {
            myEvents.add(event);
            registrations.add(myRegistration);
          } else {
            availableEvents.add(event);
          }
        } catch (e) {
          print('Erreur traitement événement ${event.id}: $e');
          // En cas d'erreur, considérer comme disponible
          availableEvents.add(event);
        }
      }

      if (mounted) {
        setState(() {
          _myEvents = myEvents;
          _availableEvents = availableEvents;
          _myRegistrations = registrations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur générale chargement événements: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des événements'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _registerForEvent(EventModel event) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      // Créer l'inscription
      final registration = EventRegistrationModel(
        id: '',
        eventId: event.id,
        personId: user.uid,
        firstName: user.displayName?.split(' ').first ?? 'Prénom',
        lastName: user.displayName?.split(' ').last ?? 'Nom',
        email: user.email ?? '',
        registrationDate: DateTime.now(),
      );

      await EventsFirebaseService.createRegistration(registration);
      
      setState(() {
        _myEvents.add(event);
        _availableEvents.remove(event);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription à "${event.title}" confirmée'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _unregisterFromEvent(EventModel event) async {
    final registration = _myRegistrations.firstWhere(
      (r) => r.eventId == event.id,
      orElse: () => EventRegistrationModel(
        id: '',
        eventId: '',
        firstName: '',
        lastName: '',
        email: '',
        registrationDate: DateTime.now(),
      ),
    );

    if (registration.id.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'inscription'),
        content: Text(
          'Voulez-vous vraiment annuler votre inscription à "${event.title}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await EventsFirebaseService.cancelRegistration(registration.id);
        
        setState(() {
          _myEvents.remove(event);
          _availableEvents.add(event);
          _myRegistrations.remove(registration);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription annulée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'annulation : $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Événements'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildTabSelector(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadEventsData,
                      child: _selectedTab == 'my_events'
                          ? _buildMyEventsList()
                          : _buildAvailableEventsList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'my_events',
              'Mes Événements',
              Icons.event,
              _myEvents.length,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'available',
              'Disponibles',
              Icons.explore,
              _availableEvents.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String title, IconData icon, int count) {
    final isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyEventsList() {
    if (_myEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun événement inscrit',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explorez les événements disponibles pour participer aux activités de l\'église',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedTab = 'available'),
              icon: const Icon(Icons.explore),
              label: const Text('Explorer les événements'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myEvents.length,
      itemBuilder: (context, index) {
        final event = _myEvents[index];
        EventRegistrationModel? registration;
        try {
          registration = _myRegistrations.firstWhere(
            (r) => r.eventId == event.id,
          );
        } catch (e) {
          registration = null;
        }
        return _buildMyEventCard(event, registration);
      },
    );
  }

  Widget _buildAvailableEventsList() {
    if (_availableEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successColor,
            ),
            SizedBox(height: 16),
            Text(
              'Vous êtes inscrit à tous les événements !',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableEvents.length,
      itemBuilder: (context, index) {
        final event = _availableEvents[index];
        return _buildAvailableEventCard(event);
      },
    );
  }

  Widget _buildMyEventCard(EventModel event, EventRegistrationModel? registration) {
    if (registration == null) {
      return const SizedBox.shrink();
    }
    final eventColor = _getEventColor(event.type);
    final isUpcoming = event.startDate.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  eventColor,
                  eventColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Image de fond
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildEventImage(event),
                ),
                // Overlay avec dégradé
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        eventColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Badge de statut
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: registration.isConfirmed
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      registration.isConfirmed ? 'Confirmé' : 'En attente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Contenu
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        event.typeLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date et lieu
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatEventDateTime(event),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Voir détails de l'événement
                        },
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Détails'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: eventColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isUpcoming
                            ? () => _unregisterFromEvent(event)
                            : null,
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Se désinscrire'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableEventCard(EventModel event) {
    final eventColor = _getEventColor(event.type);
    final isRegistrationOpen = event.isRegistrationEnabled &&
        (event.closeDate == null || event.closeDate!.isAfter(DateTime.now()));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getEventIcon(event.type),
                    color: eventColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        event.typeLabel,
                        style: TextStyle(
                          color: eventColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                event.description,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Date et lieu
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatEventDateTime(event),
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.location,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isRegistrationOpen
                    ? () => _registerForEvent(event)
                    : null,
                icon: Icon(isRegistrationOpen ? Icons.add : Icons.lock),
                label: Text(isRegistrationOpen ? 'S\'inscrire' : 'Inscriptions fermées'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRegistrationOpen ? eventColor : AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(EventModel event) {
    final imageUrl = "https://images.unsplash.com/photo-1618347991384-a4e195e722c5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDgzNjQ5OTV8&ixlib=rb-4.1.0&q=80&w=1080";

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 140,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.event,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'celebration':
        return Colors.purple;
      case 'bapteme':
        return Colors.blue;
      case 'formation':
        return Colors.green;
      case 'sortie':
        return Colors.orange;
      case 'conference':
        return Colors.indigo;
      case 'reunion':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'celebration':
        return Icons.celebration;
      case 'bapteme':
        return Icons.water_drop;
      case 'formation':
        return Icons.school;
      case 'sortie':
        return Icons.directions_walk;
      case 'conference':
        return Icons.mic;
      case 'reunion':
        return Icons.groups;
      default:
        return Icons.event;
    }
  }

  String _getEventImageKeyword(String type) {
    switch (type) {
      case 'celebration':
        return 'Church Celebration Worship';
      case 'bapteme':
        return 'Church Baptism Water';
      case 'formation':
        return 'Church Training Education';
      case 'sortie':
        return 'Church Outing Community';
      case 'conference':
        return 'Church Conference Speaking';
      case 'reunion':
        return 'Church Meeting Prayer';
      default:
        return 'Church Event Community';
    }
  }

  String _formatEventDateTime(EventModel event) {
    final now = DateTime.now();
    final eventDate = event.startDate;
    final difference = eventDate.difference(now).inDays;
    
    String dateStr;
    if (difference == 0) {
      dateStr = 'Aujourd\'hui';
    } else if (difference == 1) {
      dateStr = 'Demain';
    } else if (difference < 7) {
      dateStr = 'Dans $difference jours';
    } else {
      dateStr = '${eventDate.day}/${eventDate.month}/${eventDate.year}';
    }
    
    final timeStr = '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr à $timeStr';
  }
}