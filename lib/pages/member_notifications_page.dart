import 'package:flutter/material.dart';
import '../theme.dart';

class MemberNotificationsPage extends StatefulWidget {
  const MemberNotificationsPage({super.key});

  @override
  State<MemberNotificationsPage> createState() => _MemberNotificationsPageState();
}

class _MemberNotificationsPageState extends State<MemberNotificationsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _sampleNotifications = [
    {
      'id': '1',
      'type': 'service',
      'title': 'Nouvelle affectation de service',
      'message': 'Vous avez été assigné à l\'équipe Louange pour le culte du dimanche 15 décembre.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
      'icon': Icons.church,
      'color': Colors.purple,
    },
    {
      'id': '2',
      'type': 'group',
      'title': 'Prochaine réunion de groupe',
      'message': 'Rappel : Réunion du groupe de prière demain à 19h30 en salle B.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
      'isRead': false,
      'icon': Icons.groups,
      'color': AppTheme.secondaryColor,
    },
    {
      'id': '3',
      'type': 'event',
      'title': 'Nouvel événement disponible',
      'message': 'Inscription ouverte pour la conférence "La famille selon Dieu" du 20 décembre.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
      'icon': Icons.event,
      'color': AppTheme.tertiaryColor,
    },
    {
      'id': '4',
      'type': 'form',
      'title': 'Formulaire à remplir',
      'message': 'Le formulaire d\'évaluation du culte de novembre est maintenant disponible.',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'icon': Icons.assignment,
      'color': Colors.teal,
    },
    {
      'id': '5',
      'type': 'announcement',
      'title': 'Annonce de l\'église',
      'message': 'Changement d\'horaire : Le culte de dimanche prochain commencera à 10h15.',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'isRead': true,
      'icon': Icons.campaign,
      'color': AppTheme.warningColor,
    },
  ];

  final Map<String, String> _filterLabels = {
    'all': 'Toutes',
    'service': 'Services',
    'group': 'Groupes',
    'event': 'Événements',
    'form': 'Formulaires',
    'announcement': 'Annonces',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  void _markAsRead(String notificationId) {
    setState(() {
      final notification = _sampleNotifications.firstWhere(
        (n) => n['id'] == notificationId,
        orElse: () => {},
      );
      if (notification.isNotEmpty) {
        notification['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (final notification in _sampleNotifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _sampleNotifications.removeWhere((n) => n['id'] == notificationId);
    });
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'all') {
      return _sampleNotifications;
    }
    return _sampleNotifications.where((n) => n['type'] == _selectedFilter).toList();
  }

  int get _unreadCount {
    return _sampleNotifications.where((n) => !n['isRead']).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Tout marquer comme lu',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildFilterSelector(),
                  Expanded(
                    child: _buildNotificationsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterLabels.length,
        itemBuilder: (context, index) {
          final entry = _filterLabels.entries.elementAt(index);
          final isSelected = _selectedFilter == entry.key;
          final count = entry.key == 'all' 
              ? _sampleNotifications.length 
              : _sampleNotifications.where((n) => n['type'] == entry.key).length;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.value),
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = entry.key;
                });
              },
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList() {
    final notifications = _filteredNotifications;
    
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all' 
                  ? 'Aucune notification'
                  : 'Aucune notification de ce type',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vos notifications apparaîtront ici',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;
    final title = notification['title'] as String;
    final message = notification['message'] as String;
    final timestamp = notification['timestamp'] as DateTime;
    final icon = notification['icon'] as IconData;
    final color = notification['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
          _handleNotificationTap(type);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isRead 
                ? null 
                : Border.all(
                    color: color.withOpacity(0.3),
                    width: 2,
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        height: 1.4,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const Spacer(),
                        _buildTypeChip(type, color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.textSecondaryColor,
                  size: 20,
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'mark_read':
                      _markAsRead(notification['id']);
                      break;
                    case 'delete':
                      _deleteNotification(notification['id']);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 18),
                          SizedBox(width: 8),
                          Text('Marquer comme lu'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getTypeLabel(type),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'service':
        return 'Service';
      case 'group':
        return 'Groupe';
      case 'event':
        return 'Événement';
      case 'form':
        return 'Formulaire';
      case 'announcement':
        return 'Annonce';
      default:
        return type;
    }
  }

  void _handleNotificationTap(String type) {
    // TODO: Naviguer vers la page appropriée selon le type
    switch (type) {
      case 'service':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => MemberServicesPage()));
        break;
      case 'group':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => MemberGroupsPage()));
        break;
      case 'event':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => MemberEventsPage()));
        break;
      case 'form':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => MemberFormsPage()));
        break;
      case 'announcement':
        // Afficher les détails de l'annonce
        break;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}