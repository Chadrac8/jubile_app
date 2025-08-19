import 'package:flutter/material.dart';
import '../services/appointment_notification_service.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class AppointmentNotificationsWidget extends StatefulWidget {
  const AppointmentNotificationsWidget({super.key});

  @override
  State<AppointmentNotificationsWidget> createState() => _AppointmentNotificationsWidgetState();
}

class _AppointmentNotificationsWidgetState extends State<AppointmentNotificationsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_appointment':
        return Icons.event_available;
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_appointment':
        return Theme.of(context).colorScheme.primaryColor;
      case 'confirmed':
        return Theme.of(context).colorScheme.successColor;
      case 'cancelled':
        return Theme.of(context).colorScheme.errorColor;
      case 'reminder':
        return Theme.of(context).colorScheme.warningColor;
      default:
        return Theme.of(context).colorScheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AppointmentNotificationService.getUnreadNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).colorScheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Notifications rendez-vous',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (notifications.length > 1)
                        TextButton(
                          onPressed: () async {
                            await AppointmentNotificationService.markAllAsRead(currentUser.uid);
                          },
                          child: const Text('Tout marquer lu'),
                        ),
                    ],
                  ),
                ),
                ...notifications.take(3).map((notification) => _buildNotificationItem(notification)),
                if (notifications.length > 3)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        '+${notifications.length - 3} autres notifications',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? '';
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final createdAt = notification['createdAt'];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Marquer comme lu
          await AppointmentNotificationService.markAsRead(notification['id']);
          
          // Optionnel: Navigation vers les détails du rendez-vous
          // if (notification['appointmentId'] != null) {
          //   // Navigator.push vers AppointmentDetailPage
          // }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatRelativeTime(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.textTertiaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        dateTime = timestamp.toDate();
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays}j';
      } else {
        return 'Il y a ${(difference.inDays / 7).floor()}sem';
      }
    } catch (e) {
      return '';
    }
  }
}