import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';

class AppointmentNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String notificationsCollection = 'appointment_notifications';

  /// Crée une notification pour un rendez-vous
  static Future<void> createNotification({
    required String userId,
    required String appointmentId,
    required String type, // 'new_appointment', 'confirmed', 'cancelled', 'reminder'
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection(notificationsCollection).add({
        'userId': userId,
        'appointmentId': appointmentId,
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la création de la notification: $e');
    }
  }

  /// Notification lors de la création d'un nouveau rendez-vous
  static Future<void> notifyNewAppointment(AppointmentModel appointment) async {
    // Notification au responsable
    await createNotification(
      userId: appointment.responsableId,
      appointmentId: appointment.id,
      type: 'new_appointment',
      title: 'Nouvelle demande de rendez-vous',
      message: 'Une nouvelle demande de rendez-vous a été reçue pour le ${_formatDate(appointment.dateTime)}',
      data: {
        'motif': appointment.motif,
        'dateTime': appointment.dateTime.toIso8601String(),
      },
    );
  }

  /// Notification lors de la confirmation d'un rendez-vous
  static Future<void> notifyAppointmentConfirmed(AppointmentModel appointment) async {
    // Notification au membre
    await createNotification(
      userId: appointment.membreId,
      appointmentId: appointment.id,
      type: 'confirmed',
      title: 'Rendez-vous confirmé',
      message: 'Votre rendez-vous du ${_formatDate(appointment.dateTime)} a été confirmé',
      data: {
        'motif': appointment.motif,
        'dateTime': appointment.dateTime.toIso8601String(),
        'lieu': appointment.lieu,
      },
    );
  }

  /// Notification lors de l'annulation d'un rendez-vous
  static Future<void> notifyAppointmentCancelled(AppointmentModel appointment, String reason) async {
    // Notification au membre si c'est le responsable qui annule
    await createNotification(
      userId: appointment.membreId,
      appointmentId: appointment.id,
      type: 'cancelled',
      title: 'Rendez-vous annulé',
      message: 'Votre rendez-vous du ${_formatDate(appointment.dateTime)} a été annulé. Raison: $reason',
      data: {
        'motif': appointment.motif,
        'dateTime': appointment.dateTime.toIso8601String(),
        'reason': reason,
      },
    );

    // Notification au responsable si c'est le membre qui annule
    await createNotification(
      userId: appointment.responsableId,
      appointmentId: appointment.id,
      type: 'cancelled',
      title: 'Rendez-vous annulé par le membre',
      message: 'Le rendez-vous du ${_formatDate(appointment.dateTime)} a été annulé par le membre',
      data: {
        'motif': appointment.motif,
        'dateTime': appointment.dateTime.toIso8601String(),
        'reason': reason,
      },
    );
  }

  /// Notification de rappel avant le rendez-vous
  static Future<void> notifyAppointmentReminder(AppointmentModel appointment, String reminderType) async {
    String title;
    String message;

    switch (reminderType) {
      case 'reminder_24h':
        title = 'Rappel: Rendez-vous demain';
        message = 'N\'oubliez pas votre rendez-vous demain à ${_formatTime(appointment.dateTime)}';
        break;
      case 'reminder_1h':
        title = 'Rappel: Rendez-vous dans 1 heure';
        message = 'Votre rendez-vous commence dans 1 heure (${_formatTime(appointment.dateTime)})';
        break;
      default:
        title = 'Rappel de rendez-vous';
        message = 'Vous avez un rendez-vous prévu le ${_formatDate(appointment.dateTime)}';
    }

    // Notification au membre
    await createNotification(
      userId: appointment.membreId,
      appointmentId: appointment.id,
      type: 'reminder',
      title: title,
      message: message,
      data: {
        'motif': appointment.motif,
        'dateTime': appointment.dateTime.toIso8601String(),
        'lieu': appointment.lieu,
        'reminderType': reminderType,
      },
    );

    // Notification au responsable aussi
    await createNotification(
      userId: appointment.responsableId,
      appointmentId: appointment.id,
      type: 'reminder',
      title: 'Rendez-vous à venir',
      message: 'Rendez-vous prévu le ${_formatDate(appointment.dateTime)} à ${_formatTime(appointment.dateTime)}',
      data: {
        'motif': appointment.motif,
        'dateTime': appointment.dateTime.toIso8601String(),
        'lieu': appointment.lieu,
        'reminderType': reminderType,
      },
    );
  }

  /// Récupère les notifications non lues pour un utilisateur
  static Stream<List<Map<String, dynamic>>> getUnreadNotifications(String userId) {
    return _firestore
        .collection(notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  /// Marque une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Erreur lors de la mise à jour de la notification: $e');
    }
  }

  /// Marque toutes les notifications d'un utilisateur comme lues
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la mise à jour des notifications: $e');
    }
  }

  /// Compte les notifications non lues
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Supprime les anciennes notifications (plus de 30 jours)
  static Future<void> cleanupOldNotifications() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = await _firestore
          .collection(notificationsCollection)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors du nettoyage des notifications: $e');
    }
  }

  // Méthodes utilitaires
  static String _formatDate(DateTime date) {
    final days = ['', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    final months = ['', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                   'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    
    return '${days[date.weekday]} ${date.day} ${months[date.month]}';
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}