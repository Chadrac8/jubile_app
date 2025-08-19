import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/person_model.dart';

class EventsFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String eventsCollection = 'events';
  static const String eventFormsCollection = 'event_forms';
  static const String eventRegistrationsCollection = 'event_registrations';
  static const String eventActivityLogsCollection = 'event_activity_logs';

  // Event CRUD Operations
  static Future<String> createEvent(EventModel event) async {
    try {
      final docRef = await _firestore.collection(eventsCollection).add(event.toFirestore());
      
      await _logEventActivity(docRef.id, 'event_created', {
        'title': event.title,
        'type': event.type,
        'startDate': event.startDate.toIso8601String(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'événement: $e');
    }
  }

  static Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(eventsCollection)
          .doc(event.id)
          .update(event.toFirestore());
      
      await _logEventActivity(event.id, 'event_updated', {
        'title': event.title,
        'status': event.status,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'événement: $e');
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete event
      batch.delete(_firestore.collection(eventsCollection).doc(eventId));
      
      // Delete related forms
      final forms = await _firestore
          .collection(eventFormsCollection)
          .where('eventId', isEqualTo: eventId)
          .get();
      
      for (final form in forms.docs) {
        batch.delete(form.reference);
      }
      
      // Delete related registrations
      final registrations = await _firestore
          .collection(eventRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .get();
      
      for (final registration in registrations.docs) {
        batch.delete(registration.reference);
      }
      
      await batch.commit();
      
      await _logEventActivity(eventId, 'event_deleted', {});
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'événement: $e');
    }
  }

  static Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection(eventsCollection).doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'événement: $e');
    }
  }

  static Stream<List<EventModel>> getEventsStream({
    String? searchQuery,
    List<String>? typeFilters,
    List<String>? statusFilters,
    DateTime? startDate,
    DateTime? endDate,
    String? responsibleId,
    int limit = 50,
  }) {
    try {
      Query query = _firestore
          .collection(eventsCollection)
          .orderBy('startDate', descending: false)
          .limit(limit);

      // Apply filters
      if (statusFilters != null && statusFilters.isNotEmpty) {
        query = query.where('status', whereIn: statusFilters);
      }

      if (typeFilters != null && typeFilters.isNotEmpty) {
        query = query.where('type', whereIn: typeFilters);
      }

      if (startDate != null) {
        query = query.where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (responsibleId != null) {
        query = query.where('responsibleIds', arrayContains: responsibleId);
      }

      return query.snapshots().map((snapshot) {
        var events = snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList();

        // Apply search filter client-side
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          events = events.where((event) {
            return event.title.toLowerCase().contains(searchLower) ||
                   event.description.toLowerCase().contains(searchLower) ||
                   event.location.toLowerCase().contains(searchLower) ||
                   event.typeLabel.toLowerCase().contains(searchLower);
          }).toList();
        }

        return events;
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  // Event Form Management
  static Future<String> createEventForm(EventFormModel form) async {
    try {
      final docRef = await _firestore.collection(eventFormsCollection).add(form.toFirestore());
      
      await _logEventActivity(form.eventId, 'form_created', {
        'formTitle': form.title,
        'fieldsCount': form.fields.length,
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du formulaire: $e');
    }
  }

  static Future<void> updateEventForm(EventFormModel form) async {
    try {
      await _firestore
          .collection(eventFormsCollection)
          .doc(form.id)
          .update(form.toFirestore());
      
      await _logEventActivity(form.eventId, 'form_updated', {
        'formTitle': form.title,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du formulaire: $e');
    }
  }

  static Future<EventFormModel?> getEventForm(String eventId) async {
    try {
      final query = await _firestore
          .collection(eventFormsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return EventFormModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du formulaire: $e');
    }
  }

  // Registration Management
  static Future<String> createRegistration(EventRegistrationModel registration) async {
    try {
      // Check if event has max participants limit
      final event = await getEvent(registration.eventId);
      if (event == null) {
        throw Exception('Événement non trouvé');
      }

      // Count current registrations
      final currentRegistrations = await getConfirmedRegistrationsCount(registration.eventId);
      
      String status = 'confirmed';
      if (event.maxParticipants != null && 
          currentRegistrations >= event.maxParticipants!) {
        if (event.hasWaitingList) {
          status = 'waiting';
        } else {
          throw Exception('Événement complet');
        }
      }

      final registrationWithStatus = registration.copyWith(status: status);
      final docRef = await _firestore
          .collection(eventRegistrationsCollection)
          .add(registrationWithStatus.toFirestore());
      
      await _logEventActivity(registration.eventId, 'registration_created', {
        'registrantName': registration.fullName,
        'status': status,
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  static Future<void> updateRegistration(EventRegistrationModel registration) async {
    try {
      await _firestore
          .collection(eventRegistrationsCollection)
          .doc(registration.id)
          .update(registration.toFirestore());
      
      await _logEventActivity(registration.eventId, 'registration_updated', {
        'registrantName': registration.fullName,
        'status': registration.status,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'inscription: $e');
    }
  }

  static Future<void> cancelRegistration(String registrationId) async {
    try {
      final registration = await getRegistration(registrationId);
      if (registration == null) return;

      await _firestore
          .collection(eventRegistrationsCollection)
          .doc(registrationId)
          .update({'status': 'cancelled'});
      
      // If there's a waiting list, promote the next person
      await _promoteFromWaitingList(registration.eventId);
      
      await _logEventActivity(registration.eventId, 'registration_cancelled', {
        'registrantName': registration.fullName,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de l\'inscription: $e');
    }
  }

  static Future<EventRegistrationModel?> getRegistration(String registrationId) async {
    try {
      final doc = await _firestore
          .collection(eventRegistrationsCollection)
          .doc(registrationId)
          .get();
      
      if (doc.exists) {
        return EventRegistrationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'inscription: $e');
    }
  }

  static Stream<List<EventRegistrationModel>> getEventRegistrationsStream(String eventId) {
    try {
      return _firestore
          .collection(eventRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('registrationDate', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => EventRegistrationModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des inscriptions: $e');
    }
  }

  static Future<int> getConfirmedRegistrationsCount(String eventId) async {
    try {
      final query = await _firestore
          .collection(eventRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'confirmed')
          .count()
          .get();
      
      return query.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> _promoteFromWaitingList(String eventId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null || event.maxParticipants == null) return;

      final currentConfirmed = await getConfirmedRegistrationsCount(eventId);
      if (currentConfirmed >= event.maxParticipants!) return;

      // Get first person from waiting list
      final waitingQuery = await _firestore
          .collection(eventRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'waiting')
          .orderBy('registrationDate')
          .limit(1)
          .get();
      
      if (waitingQuery.docs.isNotEmpty) {
        final waitingDoc = waitingQuery.docs.first;
        await waitingDoc.reference.update({'status': 'confirmed'});
        
        final registration = EventRegistrationModel.fromFirestore(waitingDoc);
        await _logEventActivity(eventId, 'registration_promoted', {
          'registrantName': registration.fullName,
        });
      }
    } catch (e) {
      // Log error but don't throw
      print('Erreur lors de la promotion depuis la liste d\'attente: $e');
    }
  }

  // Attendance Management
  static Future<void> markAttendance(String registrationId, bool isPresent) async {
    try {
      await _firestore
          .collection(eventRegistrationsCollection)
          .doc(registrationId)
          .update({
            'isPresent': isPresent,
            'attendanceRecordedAt': Timestamp.now(),
          });
      
      final registration = await getRegistration(registrationId);
      if (registration != null) {
        await _logEventActivity(registration.eventId, 'attendance_recorded', {
          'registrantName': registration.fullName,
          'isPresent': isPresent,
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de la présence: $e');
    }
  }

  // Statistics
  static Future<EventStatisticsModel> getEventStatistics(String eventId) async {
    try {
      final registrations = await _firestore
          .collection(eventRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .get();
      
      final registrationModels = registrations.docs
          .map((doc) => EventRegistrationModel.fromFirestore(doc))
          .toList();
      
      final total = registrationModels.length;
      final confirmed = registrationModels.where((r) => r.isConfirmed).length;
      final waiting = registrationModels.where((r) => r.isWaiting).length;
      final cancelled = registrationModels.where((r) => r.isCancelled).length;
      final present = registrationModels.where((r) => r.isPresent).length;
      
      // Group registrations by date
      final registrationsByDate = <String, int>{};
      for (final registration in registrationModels) {
        final dateKey = registration.registrationDate.toIso8601String().split('T')[0];
        registrationsByDate[dateKey] = (registrationsByDate[dateKey] ?? 0) + 1;
      }
      
      // Calculate fill rate
      final event = await getEvent(eventId);
      final fillRate = event?.maxParticipants != null 
          ? confirmed / event!.maxParticipants! 
          : 0.0;
      
      // Calculate attendance rate
      final attendanceRate = confirmed > 0 ? present / confirmed : 0.0;
      
      return EventStatisticsModel(
        eventId: eventId,
        totalRegistrations: total,
        confirmedRegistrations: confirmed,
        waitingRegistrations: waiting,
        cancelledRegistrations: cancelled,
        presentCount: present,
        registrationsByDate: registrationsByDate,
        formResponsesSummary: {}, // TODO: Implement form responses analysis
        fillRate: fillRate,
        attendanceRate: attendanceRate,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Duplicate Event
  static Future<String> duplicateEvent(String originalEventId, String newTitle, DateTime newStartDate) async {
    try {
      final originalEvent = await getEvent(originalEventId);
      if (originalEvent == null) {
        throw Exception('Événement original non trouvé');
      }
      
      final duration = originalEvent.duration;
      final newEvent = originalEvent.copyWith(
        title: newTitle,
        startDate: newStartDate,
        endDate: originalEvent.endDate != null 
            ? newStartDate.add(duration)
            : null,
        status: 'brouillon',
        updatedAt: DateTime.now(),
        lastModifiedBy: _auth.currentUser?.uid,
      );
      
      final newEventId = await createEvent(newEvent);
      
      // Duplicate form if exists
      final originalForm = await getEventForm(originalEventId);
      if (originalForm != null) {
        final newForm = EventFormModel(
          id: '',
          eventId: newEventId,
          title: originalForm.title,
          description: originalForm.description,
          fields: originalForm.fields,
          confirmationMessage: originalForm.confirmationMessage,
          confirmationEmailTemplate: originalForm.confirmationEmailTemplate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createEventForm(newForm);
      }
      
      return newEventId;
    } catch (e) {
      throw Exception('Erreur lors de la duplication de l\'événement: $e');
    }
  }

  // Archive Event
  static Future<void> archiveEvent(String eventId) async {
    try {
      await _firestore
          .collection(eventsCollection)
          .doc(eventId)
          .update({
            'status': 'archive',
            'updatedAt': Timestamp.now(),
            'lastModifiedBy': _auth.currentUser?.uid,
          });
      
      await _logEventActivity(eventId, 'event_archived', {});
    } catch (e) {
      throw Exception('Erreur lors de l\'archivage de l\'événement: $e');
    }
  }

  // Search Events
  static Future<List<EventModel>> searchEvents(String query) async {
    try {
      final eventsQuery = await _firestore
          .collection(eventsCollection)
          .where('status', isNotEqualTo: 'archive')
          .get();
      
      final searchLower = query.toLowerCase();
      final events = eventsQuery.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) {
            return event.title.toLowerCase().contains(searchLower) ||
                   event.description.toLowerCase().contains(searchLower) ||
                   event.location.toLowerCase().contains(searchLower) ||
                   event.typeLabel.toLowerCase().contains(searchLower);
          })
          .toList();
      
      return events;
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'événements: $e');
    }
  }

  // Export Functions
  static Future<List<Map<String, dynamic>>> exportEventRegistrations(String eventId) async {
    try {
      final registrations = await _firestore
          .collection(eventRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .get();
      
      return registrations.docs.map((doc) {
        final registration = EventRegistrationModel.fromFirestore(doc);
        final data = {
          'Nom': registration.lastName,
          'Prénom': registration.firstName,
          'Email': registration.email,
          'Téléphone': registration.phone ?? '',
          'Statut': registration.status,
          'Date d\'inscription': registration.registrationDate.toIso8601String(),
          'Présent': registration.isPresent ? 'Oui' : 'Non',
        };
        
        // Add form responses
        registration.formResponses.forEach((key, value) {
          data[key] = value.toString();
        });
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de l\'export des inscriptions: $e');
    }
  }

  // Helper Functions
  static Future<void> _logEventActivity(String eventId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(eventActivityLogsCollection).add({
        'eventId': eventId,
        'action': action,
        'details': details,
        'timestamp': Timestamp.now(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking main operations
      print('Erreur lors de l\'enregistrement de l\'activité: $e');
    }
  }

  // Upcoming Events
  static Stream<List<EventModel>> getUpcomingEventsStream({int limit = 5}) {
    try {
      return _firestore
          .collection(eventsCollection)
          .where('status', isEqualTo: 'publie')
          .where('startDate', isGreaterThan: Timestamp.now())
          .orderBy('startDate')
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => EventModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements à venir: $e');
    }
  }

  // Check if user can register for event
  static Future<bool> canUserRegisterForEvent(String eventId, String? userId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null || !event.isPublished || !event.isRegistrationEnabled) {
        return false;
      }

      // Check if user already registered
      if (userId != null) {
        final existingRegistration = await _firestore
            .collection(eventRegistrationsCollection)
            .where('eventId', isEqualTo: eventId)
            .where('personId', isEqualTo: userId)
            .where('status', whereIn: ['confirmed', 'waiting'])
            .limit(1)
            .get();
        
        if (existingRegistration.docs.isNotEmpty) {
          return false; // Already registered
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}