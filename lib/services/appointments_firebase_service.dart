import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';
import '../models/person_model.dart';
import 'appointment_notification_service.dart';

class AppointmentsFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String appointmentsCollection = 'appointments';
  static const String disponibilitesCollection = 'disponibilites';
  static const String appointmentRemindersCollection = 'appointment_reminders';
  static const String appointmentActivityLogsCollection = 'appointment_activity_logs';

  // Appointment CRUD Operations
  static Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _firestore.collection(appointmentsCollection).add(appointment.toFirestore());
      
      // Log activity
      await _logAppointmentActivity(
        docRef.id,
        'appointment_created',
        {
          'membreId': appointment.membreId,
          'responsableId': appointment.responsableId,
          'dateTime': appointment.dateTime.toIso8601String(),
          'motif': appointment.motif,
        },
      );

      // Create reminder for 24h before
      await _createReminder(docRef.id, appointment.dateTime.subtract(Duration(hours: 24)), 'reminder_24h');
      
      // Create reminder for 1h before
      await _createReminder(docRef.id, appointment.dateTime.subtract(Duration(hours: 1)), 'reminder_1h');

      // Notify new appointment
      final appointmentWithId = appointment.copyWith(id: docRef.id);
      await AppointmentNotificationService.notifyNewAppointment(appointmentWithId);

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du rendez-vous: $e');
    }
  }

  static Future<void> updateAppointment(AppointmentModel appointment) async {
    try {
      await _firestore
          .collection(appointmentsCollection)
          .doc(appointment.id)
          .update(appointment.toFirestore());

      await _logAppointmentActivity(
        appointment.id,
        'appointment_updated',
        {
          'statut': appointment.statut,
          'updatedBy': appointment.lastModifiedBy,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rendez-vous: $e');
    }
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      // Delete reminders
      final reminders = await _firestore
          .collection(appointmentRemindersCollection)
          .where('appointmentId', isEqualTo: appointmentId)
          .get();
      
      for (final doc in reminders.docs) {
        await doc.reference.delete();
      }

      // Delete appointment
      await _firestore.collection(appointmentsCollection).doc(appointmentId).delete();

      await _logAppointmentActivity(
        appointmentId,
        'appointment_deleted',
        {'deletedBy': _auth.currentUser?.uid},
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression du rendez-vous: $e');
    }
  }

  static Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      final doc = await _firestore.collection(appointmentsCollection).doc(appointmentId).get();
      if (doc.exists) {
        return AppointmentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du rendez-vous: $e');
    }
  }

  static Stream<List<AppointmentModel>> getAppointmentsStream({
    String? membreId,
    String? responsableId,
    List<String>? statusFilters,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    Query query = _firestore.collection(appointmentsCollection);

    if (membreId != null) {
      query = query.where('membreId', isEqualTo: membreId);
    }

    if (responsableId != null) {
      query = query.where('responsableId', isEqualTo: responsableId);
    }

    if (statusFilters != null && statusFilters.isNotEmpty) {
      query = query.where('statut', whereIn: statusFilters);
    }

    if (startDate != null) {
      query = query.where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('dateTime', descending: false).limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList());
  }

  // Disponibilités CRUD Operations
  static Future<String> createDisponibilite(DisponibiliteModel disponibilite) async {
    try {
      final docRef = await _firestore.collection(disponibilitesCollection).add(disponibilite.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la disponibilité: $e');
    }
  }

  static Future<void> updateDisponibilite(DisponibiliteModel disponibilite) async {
    try {
      await _firestore
          .collection(disponibilitesCollection)
          .doc(disponibilite.id)
          .update(disponibilite.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la disponibilité: $e');
    }
  }

  static Future<void> deleteDisponibilite(String disponibiliteId) async {
    try {
      await _firestore.collection(disponibilitesCollection).doc(disponibiliteId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la disponibilité: $e');
    }
  }

  static Stream<List<DisponibiliteModel>> getDisponibilitesStream(String responsableId) {
    return _firestore
        .collection(disponibilitesCollection)
        .where('responsableId', isEqualTo: responsableId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DisponibiliteModel.fromFirestore(doc)).toList());
  }

  // Available Slots Generation
  static Future<List<DateTime>> getAvailableSlots(
    String responsableId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get all disponibilités for the responsable
      final disponibilites = await _firestore
          .collection(disponibilitesCollection)
          .where('responsableId', isEqualTo: responsableId)
          .where('isActive', isEqualTo: true)
          .get();

      // Get existing appointments in the date range
      final existingAppointments = await _firestore
          .collection(appointmentsCollection)
          .where('responsableId', isEqualTo: responsableId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('statut', whereIn: ['en_attente', 'confirme'])
          .get();

      final List<DateTime> blockedSlots = existingAppointments.docs
          .map((doc) => (doc.data()['dateTime'] as Timestamp).toDate())
          .toList();

      final List<DateTime> availableSlots = [];

      for (final doc in disponibilites.docs) {
        final disponibilite = DisponibiliteModel.fromFirestore(doc);
        final slots = _generateSlotsForDisponibilite(disponibilite, startDate, endDate);
        availableSlots.addAll(slots);
      }

      // Remove blocked slots and past slots
      final now = DateTime.now();
      return availableSlots
          .where((slot) => !blockedSlots.contains(slot) && slot.isAfter(now))
          .toSet()
          .toList()
        ..sort();

    } catch (e) {
      throw Exception('Erreur lors de la récupération des créneaux disponibles: $e');
    }
  }

  static List<DateTime> _generateSlotsForDisponibilite(
    DisponibiliteModel disponibilite,
    DateTime startDate,
    DateTime endDate,
  ) {
    final List<DateTime> slots = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      bool shouldIncludeDate = false;

      if (disponibilite.isPonctuel && disponibilite.dateSpecifique != null) {
        shouldIncludeDate = _isSameDay(currentDate, disponibilite.dateSpecifique!);
      } else if (disponibilite.isRecurrenceHebdo) {
        final dayName = _getDayName(currentDate.weekday);
        shouldIncludeDate = disponibilite.jours.contains(dayName);
      }

      if (shouldIncludeDate) {
        for (final creneau in disponibilite.creneaux) {
          slots.addAll(creneau.generateSlots(currentDate));
        }
      }

      currentDate = currentDate.add(Duration(days: 1));
    }

    return slots;
  }

  // Appointment Status Management
  static Future<void> confirmAppointment(String appointmentId, {String? notes}) async {
    try {
      await _firestore.collection(appointmentsCollection).doc(appointmentId).update({
        'statut': 'confirme',
        'dateConfirmation': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (notes != null) 'notesPrivees': notes,
      });

      await _logAppointmentActivity(
        appointmentId,
        'appointment_confirmed',
        {'notes': notes},
      );

      // Get appointment data for notification
      final appointment = await getAppointment(appointmentId);
      if (appointment != null) {
        await AppointmentNotificationService.notifyAppointmentConfirmed(appointment);
      }
    } catch (e) {
      throw Exception('Erreur lors de la confirmation: $e');
    }
  }

  static Future<void> rejectAppointment(String appointmentId, String raison) async {
    final appointment = await getAppointment(appointmentId);
    if (appointment == null) throw Exception('Rendez-vous introuvable');

    final updatedAppointment = appointment.copyWith(
      statut: 'refuse',
      raisonAnnulation: raison,
      dateAnnulation: DateTime.now(),
      updatedAt: DateTime.now(),
      lastModifiedBy: _auth.currentUser?.uid,
    );

    await updateAppointment(updatedAppointment);

    await _logAppointmentActivity(
      appointmentId,
      'appointment_rejected',
      {'rejectedBy': _auth.currentUser?.uid, 'raison': raison},
    );
  }

  static Future<void> cancelAppointment(String appointmentId, String raison) async {
    try {
      await _firestore.collection(appointmentsCollection).doc(appointmentId).update({
        'statut': 'annule',
        'dateAnnulation': FieldValue.serverTimestamp(),
        'raisonAnnulation': raison,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAppointmentActivity(
        appointmentId,
        'appointment_cancelled',
        {'raison': raison},
      );

      // Get appointment data for notification
      final appointment = await getAppointment(appointmentId);
      if (appointment != null) {
        await AppointmentNotificationService.notifyAppointmentCancelled(appointment, raison);
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  static Future<void> completeAppointment(String appointmentId, {String? notes}) async {
    final appointment = await getAppointment(appointmentId);
    if (appointment == null) throw Exception('Rendez-vous introuvable');

    final updatedAppointment = appointment.copyWith(
      statut: 'termine',
      notesPrivees: notes,
      updatedAt: DateTime.now(),
      lastModifiedBy: _auth.currentUser?.uid,
    );

    await updateAppointment(updatedAppointment);

    await _logAppointmentActivity(
      appointmentId,
      'appointment_completed',
      {'completedBy': _auth.currentUser?.uid, 'notes': notes},
    );
  }

  // Get responsables (persons with leadership roles)
  static Future<List<PersonModel>> getResponsables() async {
    try {
      // Get persons with leadership roles
      final responsables = await FirebaseFirestore.instance
          .collection('persons')
          .where('isActive', isEqualTo: true)
          .where('roles', arrayContainsAny: ['pasteur', 'leader', 'responsable'])
          .get();

      return responsables.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des responsables: $e');
    }
  }

  // Statistics
  static Future<AppointmentStatisticsModel> getAppointmentStatistics({String? responsableId}) async {
    try {
      Query query = _firestore.collection(appointmentsCollection);
      
      if (responsableId != null) {
        query = query.where('responsableId', isEqualTo: responsableId);
      }

      final appointments = await query.get();
      
      int total = appointments.docs.length;
      int pending = 0, confirmed = 0, completed = 0, cancelled = 0;
      Map<String, int> byMonth = {};
      Map<String, int> byResponsable = {};
      Map<String, int> byLieu = {};

      for (final doc in appointments.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final statut = data['statut'] ?? '';
        final dateTime = (data['dateTime'] as Timestamp).toDate();
        final responsable = data['responsableId'] ?? '';
        final lieu = data['lieu'] ?? '';

        switch (statut) {
          case 'en_attente':
            pending++;
            break;
          case 'confirme':
            confirmed++;
            break;
          case 'termine':
            completed++;
            break;
          case 'annule':
          case 'refuse':
            cancelled++;
            break;
        }

        final monthKey = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}';
        byMonth[monthKey] = (byMonth[monthKey] ?? 0) + 1;
        byResponsable[responsable] = (byResponsable[responsable] ?? 0) + 1;
        byLieu[lieu] = (byLieu[lieu] ?? 0) + 1;
      }

      return AppointmentStatisticsModel(
        totalAppointments: total,
        pendingAppointments: pending,
        confirmedAppointments: confirmed,
        completedAppointments: completed,
        cancelledAppointments: cancelled,
        appointmentsByMonth: byMonth,
        appointmentsByResponsable: byResponsable,
        appointmentsByLieu: byLieu,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Helper methods
  static Future<void> _createReminder(String appointmentId, DateTime reminderDate, String type) async {
    try {
      await _firestore.collection(appointmentRemindersCollection).add({
        'appointmentId': appointmentId,
        'reminderDate': Timestamp.fromDate(reminderDate),
        'type': type,
        'isSent': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Log error but don't throw - reminders are not critical
      print('Erreur lors de la création du rappel: $e');
    }
  }

  static Future<void> _logAppointmentActivity(String appointmentId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(appointmentActivityLogsCollection).add({
        'appointmentId': appointmentId,
        'action': action,
        'details': details,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Log error but don't throw - activity logs are not critical
      print('Erreur lors de l\'enregistrement de l\'activité: $e');
    }
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'lundi';
      case 2: return 'mardi';
      case 3: return 'mercredi';
      case 4: return 'jeudi';
      case 5: return 'vendredi';
      case 6: return 'samedi';
      case 7: return 'dimanche';
      default: return '';
    }
  }

  // Upcoming appointments for dashboard
  static Future<List<AppointmentModel>> getUpcomingAppointments({
    String? membreId,
    String? responsableId,
    int limit = 5,
  }) async {
    try {
      Query query = _firestore.collection(appointmentsCollection);

      if (membreId != null) {
        query = query.where('membreId', isEqualTo: membreId);
      }

      if (responsableId != null) {
        query = query.where('responsableId', isEqualTo: responsableId);
      }

      final results = await query
          .where('dateTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .where('statut', whereIn: ['en_attente', 'confirme'])
          .orderBy('dateTime')
          .limit(limit)
          .get();

      return results.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des prochains rendez-vous: $e');
    }
  }

  // Get appointment by member and date (to prevent duplicates)
  static Future<AppointmentModel?> getAppointmentByMemberAndDate(
    String membreId,
    DateTime dateTime,
  ) async {
    try {
      final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final results = await _firestore
          .collection(appointmentsCollection)
          .where('membreId', isEqualTo: membreId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
          .where('statut', whereIn: ['en_attente', 'confirme'])
          .get();

      if (results.docs.isNotEmpty) {
        return AppointmentModel.fromFirestore(results.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}