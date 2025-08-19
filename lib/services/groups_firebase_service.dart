
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../models/person_model.dart';



class GroupsFirebaseService {
  // === CRUD pour les ressources de groupe ===
  static Future<void> updateGroupResource(String groupId, String resourceId, Map<String, dynamic> resourceData) async {
    await _firestore.collection(groupsCollection)
        .doc(groupId)
        .collection('resources')
        .doc(resourceId)
        .update({
      ...resourceData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logGroupActivity(groupId, 'resource_updated', {'title': resourceData['title']});
  }

  static Future<void> deleteGroupResource(String groupId, String resourceId) async {
    await _firestore.collection(groupsCollection)
        .doc(groupId)
        .collection('resources')
        .doc(resourceId)
        .delete();
    await _logGroupActivity(groupId, 'resource_deleted', {'resourceId': resourceId});
  }

  static Future<Map<String, dynamic>?> getGroupResource(String groupId, String resourceId) async {
    final doc = await _firestore.collection(groupsCollection)
        .doc(groupId)
        .collection('resources')
        .doc(resourceId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  // === Gestion des ressources de groupe ===
  static Future<void> addGroupResource(String groupId, Map<String, dynamic> resourceData) async {
    await _firestore.collection(groupsCollection)
        .doc(groupId)
        .collection('resources')
        .add({
      ...resourceData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logGroupActivity(groupId, 'resource_added', {'title': resourceData['title']});
  }

  static Stream<List<Map<String, dynamic>>> getGroupResourcesStream(String groupId) {
    return _firestore.collection(groupsCollection)
        .doc(groupId)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String groupsCollection = 'groups';
  static const String groupMembersCollection = 'group_members';
  static const String groupMeetingsCollection = 'group_meetings';
  static const String groupAttendanceCollection = 'group_attendance';

  // Group CRUD Operations
  static Future<String> createGroup(GroupModel group) async {
    try {
      final docRef = await _firestore.collection(groupsCollection).add(group.toFirestore());
      await _logGroupActivity(docRef.id, 'create', {'name': group.name});
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du groupe: $e');
    }
  }

  static Future<void> updateGroup(GroupModel group) async {
    try {
      await _firestore.collection(groupsCollection).doc(group.id).update(group.toFirestore());
      await _logGroupActivity(group.id, 'update', {'name': group.name});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du groupe: $e');
    }
  }

  static Future<void> deleteGroup(String groupId) async {
    try {
      final batch = _firestore.batch();
      
      // Mark group as inactive instead of deleting
      batch.update(
        _firestore.collection(groupsCollection).doc(groupId),
        {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()}
      );
      
      // Remove all active members
      final membersQuery = await _firestore
          .collection(groupMembersCollection)
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'active')
          .get();
      
      for (final doc in membersQuery.docs) {
        batch.update(doc.reference, {
          'status': 'removed',
          'leftAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      await _logGroupActivity(groupId, 'delete', {});
    } catch (e) {
      throw Exception('Erreur lors de la suppression du groupe: $e');
    }
  }

  static Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection(groupsCollection).doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du groupe: $e');
    }
  }

  static Stream<List<GroupModel>> getGroupsStream({
    String? searchQuery,
    List<String>? typeFilters,
    List<String>? dayFilters,
    bool? activeOnly,
    int limit = 50,
  }) {
    Query query = _firestore.collection(groupsCollection);
    
    if (activeOnly == true) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    if (typeFilters != null && typeFilters.isNotEmpty) {
      query = query.where('type', whereIn: typeFilters);
    }
    
    if (dayFilters != null && dayFilters.isNotEmpty) {
      final dayNumbers = dayFilters.map((day) => _dayNameToNumber(day)).toList();
      query = query.where('dayOfWeek', whereIn: dayNumbers);
    }
    
    query = query.orderBy('name').limit(limit);
    
    return query.snapshots().map((snapshot) {
      List<GroupModel> groups = snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
      
      // Client-side filtering for search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        groups = groups.where((group) =>
          group.name.toLowerCase().contains(lowerQuery) ||
          group.description.toLowerCase().contains(lowerQuery) ||
          group.type.toLowerCase().contains(lowerQuery)
        ).toList();
      }
      
      return groups;
    });
  }

  // Group Members Management
  static Future<String> addMemberToGroup(String groupId, String personId, String role) async {
    try {
      final now = DateTime.now();
      final groupMember = GroupMemberModel(
        id: '',
        groupId: groupId,
        personId: personId,
        role: role,
        status: 'active',
        joinedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      
      final docRef = await _firestore.collection(groupMembersCollection).add(groupMember.toFirestore());
      await _logGroupActivity(groupId, 'member_added', {'personId': personId, 'role': role});
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du membre: $e');
    }
  }

  static Future<void> removeMemberFromGroup(String memberId) async {
    try {
      await _firestore.collection(groupMembersCollection).doc(memberId).update({
        'status': 'removed',
        'leftAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final memberDoc = await _firestore.collection(groupMembersCollection).doc(memberId).get();
      if (memberDoc.exists) {
        final memberData = memberDoc.data() as Map<String, dynamic>;
        await _logGroupActivity(memberData['groupId'], 'member_removed', {'personId': memberData['personId']});
      }
    } catch (e) {
      throw Exception('Erreur lors du retrait du membre: $e');
    }
  }

  static Future<void> updateMemberRole(String memberId, String newRole) async {
    try {
      await _firestore.collection(groupMembersCollection).doc(memberId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final memberDoc = await _firestore.collection(groupMembersCollection).doc(memberId).get();
      if (memberDoc.exists) {
        final memberData = memberDoc.data() as Map<String, dynamic>;
        await _logGroupActivity(memberData['groupId'], 'member_role_updated', {
          'personId': memberData['personId'],
          'newRole': newRole
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  static Stream<List<GroupMemberModel>> getGroupMembersStream(String groupId) {
    return _firestore
        .collection(groupMembersCollection)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .orderBy('role')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupMemberModel.fromFirestore(doc))
            .toList());
  }

  static Future<List<PersonModel>> getGroupMembersWithPersonData(String groupId) async {
    try {
      final membersSnapshot = await _firestore
          .collection(groupMembersCollection)
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'active')
          .get();
      
      if (membersSnapshot.docs.isEmpty) return [];
      
      final personIds = membersSnapshot.docs
          .map((doc) => doc.data()['personId'] as String)
          .toList();
      
      List<PersonModel> allPersons = [];
      
      // Firestore whereIn limite à 10 éléments, donc on fait des batches
      for (int i = 0; i < personIds.length; i += 10) {
        final batch = personIds.skip(i).take(10).toList();
        final personsSnapshot = await _firestore
            .collection('persons')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        final batchPersons = personsSnapshot.docs
            .map((doc) => PersonModel.fromFirestore(doc))
            .toList();
        
        allPersons.addAll(batchPersons);
      }
      
      return allPersons;
    } catch (e) {
      print('Erreur dans getGroupMembersWithPersonData: $e');
      throw Exception('Erreur lors de la récupération des membres: $e');
    }
  }

  // Group Meetings Management
  static Future<String> createMeeting(GroupMeetingModel meeting) async {
    try {
      final docRef = await _firestore.collection(groupMeetingsCollection).add(meeting.toFirestore());
      await _logGroupActivity(meeting.groupId, 'meeting_created', {'title': meeting.title, 'date': meeting.date.toIso8601String()});
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réunion: $e');
    }
  }

  static Future<void> updateMeeting(GroupMeetingModel meeting) async {
    try {
      await _firestore.collection(groupMeetingsCollection).doc(meeting.id).update(meeting.toFirestore());
      await _logGroupActivity(meeting.groupId, 'meeting_updated', {'title': meeting.title});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la réunion: $e');
    }
  }

  static Stream<List<GroupMeetingModel>> getGroupMeetingsStream(String groupId) {
    return _firestore
        .collection(groupMeetingsCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupMeetingModel.fromFirestore(doc))
            .toList());
  }

  static Future<GroupMeetingModel?> getNextMeeting(String groupId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(groupMeetingsCollection)
          .where('groupId', isEqualTo: groupId)
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('date')
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return GroupMeetingModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la prochaine réunion pour le groupe $groupId: $e');
      // Retourner null au lieu de lancer une exception pour éviter de casser l'interface
      return null;
    }
  }

  // Attendance Management
  static Future<void> recordAttendance(String meetingId, List<String> presentMemberIds, List<String> absentMemberIds) async {
    try {
      final batch = _firestore.batch();
      
      // Update meeting with attendance
      final meetingRef = _firestore.collection(groupMeetingsCollection).doc(meetingId);
      batch.update(meetingRef, {
        'presentMemberIds': presentMemberIds,
        'absentMemberIds': absentMemberIds,
        'isCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Create individual attendance records
      final now = DateTime.now();
      for (final personId in presentMemberIds) {
        final attendanceRef = _firestore.collection(groupAttendanceCollection).doc();
        final attendance = GroupAttendanceModel(
          id: attendanceRef.id,
          groupId: '',
          meetingId: meetingId,
          personId: personId,
          isPresent: true,
          recordedAt: now,
          recordedBy: _auth.currentUser?.uid,
        );
        batch.set(attendanceRef, attendance.toFirestore());
      }
      
      for (final personId in absentMemberIds) {
        final attendanceRef = _firestore.collection(groupAttendanceCollection).doc();
        final attendance = GroupAttendanceModel(
          id: attendanceRef.id,
          groupId: '',
          meetingId: meetingId,
          personId: personId,
          isPresent: false,
          recordedAt: now,
          recordedBy: _auth.currentUser?.uid,
        );
        batch.set(attendanceRef, attendance.toFirestore());
      }
      
      await batch.commit();
      
      // Get group ID for logging
      final meetingDoc = await meetingRef.get();
      if (meetingDoc.exists) {
        final meetingData = meetingDoc.data() as Map<String, dynamic>;
        await _logGroupActivity(meetingData['groupId'], 'attendance_recorded', {
          'meetingId': meetingId,
          'presentCount': presentMemberIds.length,
          'absentCount': absentMemberIds.length,
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement des présences: $e');
    }
  }

  static Future<List<GroupAttendanceModel>> getMeetingAttendance(String meetingId) async {
    try {
      final snapshot = await _firestore
          .collection(groupAttendanceCollection)
          .where('meetingId', isEqualTo: meetingId)
          .get();
      
      return snapshot.docs
          .map((doc) => GroupAttendanceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des présences: $e');
    }
  }

  // Absence Management
  static Future<void> reportAbsence(String groupId, String meetingId, String personId, String reason) async {
    try {
      final now = DateTime.now();
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Créer un document de notification d'absence
      final absenceNotificationRef = _firestore.collection('absence_notifications').doc();
      await absenceNotificationRef.set({
        'id': absenceNotificationRef.id,
        'groupId': groupId,
        'meetingId': meetingId,
        'personId': personId,
        'reason': reason,
        'status': 'signalée', // signalée, vue, traitée
        'reportedAt': FieldValue.serverTimestamp(),
        'reportedBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Optionnel: Marquer directement la personne comme absente pour cette réunion
      // si la réunion n'a pas encore eu lieu
      final meetingDoc = await _firestore.collection(groupMeetingsCollection).doc(meetingId).get();
      if (meetingDoc.exists) {
        final meetingData = meetingDoc.data() as Map<String, dynamic>;
        final meetingDate = (meetingData['date'] as Timestamp).toDate();
        
        // Si la réunion est dans le futur, on peut pré-marquer l'absence
        if (meetingDate.isAfter(now)) {
          final currentAbsentIds = List<String>.from(meetingData['absentMemberIds'] ?? []);
          if (!currentAbsentIds.contains(personId)) {
            currentAbsentIds.add(personId);
            await _firestore.collection(groupMeetingsCollection).doc(meetingId).update({
              'absentMemberIds': currentAbsentIds,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await _logGroupActivity(groupId, 'absence_reported', {
        'meetingId': meetingId,
        'personId': personId,
        'reason': reason,
      });
    } catch (e) {
      throw Exception('Erreur lors du signalement d\'absence: $e');
    }
  }

  static Future<void> cancelAbsenceReport(String groupId, String meetingId, String personId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Supprimer la notification d'absence
      final absenceQuery = await _firestore
          .collection('absence_notifications')
          .where('groupId', isEqualTo: groupId)
          .where('meetingId', isEqualTo: meetingId)
          .where('personId', isEqualTo: personId)
          .where('status', isEqualTo: 'signalée')
          .get();

      for (final doc in absenceQuery.docs) {
        await doc.reference.delete();
      }

      // Retirer de la liste des absents si la réunion n'a pas encore eu lieu
      final meetingDoc = await _firestore.collection(groupMeetingsCollection).doc(meetingId).get();
      if (meetingDoc.exists) {
        final meetingData = meetingDoc.data() as Map<String, dynamic>;
        final meetingDate = (meetingData['date'] as Timestamp).toDate();
        
        if (meetingDate.isAfter(DateTime.now())) {
          final currentAbsentIds = List<String>.from(meetingData['absentMemberIds'] ?? []);
          currentAbsentIds.remove(personId);
          await _firestore.collection(groupMeetingsCollection).doc(meetingId).update({
            'absentMemberIds': currentAbsentIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await _logGroupActivity(groupId, 'absence_cancelled', {
        'meetingId': meetingId,
        'personId': personId,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du signalement d\'absence: $e');
    }
  }

  static Future<bool> hasReportedAbsence(String groupId, String meetingId, String personId) async {
    try {
      final absenceQuery = await _firestore
          .collection('absence_notifications')
          .where('groupId', isEqualTo: groupId)
          .where('meetingId', isEqualTo: meetingId)
          .where('personId', isEqualTo: personId)
          .where('status', isEqualTo: 'signalée')
          .get();

      return absenceQuery.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du signalement d\'absence: $e');
      return false;
    }
  }

  // Statistics
  static Future<GroupStatisticsModel> getGroupStatistics(String groupId) async {
    try {
      // Get total and active members with person data
      final membersSnapshot = await _firestore
          .collection(groupMembersCollection)
          .where('groupId', isEqualTo: groupId)
          .get();
      
      final totalMembers = membersSnapshot.docs.length;
      final activeMembers = membersSnapshot.docs
          .where((doc) => (doc.data()['status'] ?? '') == 'active')
          .length;
      
      // Get member person data
      final Map<String, PersonModel> membersData = {};
      for (final memberDoc in membersSnapshot.docs) {
        final memberData = memberDoc.data();
        final personId = memberData['personId'] as String;
        try {
          final personDoc = await _firestore
              .collection('persons')
              .doc(personId)
              .get();
          if (personDoc.exists) {
            membersData[personId] = PersonModel.fromFirestore(personDoc);
          }
        } catch (e) {
          print('Erreur lors du chargement de la personne $personId: $e');
        }
      }
      
      // Get total meetings
      final meetingsSnapshot = await _firestore
          .collection(groupMeetingsCollection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('date', descending: false)
          .get();
      
      final totalMeetings = meetingsSnapshot.docs.length;
      final completedMeetings = meetingsSnapshot.docs
          .where((doc) => (doc.data()['isCompleted'] ?? false) == true)
          .toList();
      
      // Calculate attendance statistics per person
      final Map<String, PersonAttendanceStats> memberAttendance = {};
      
      for (final personId in membersData.keys) {
        final person = membersData[personId]!;
        int presentCount = 0;
        int absentCount = 0;
        final Map<String, bool> meetingAttendance = {};
        DateTime? lastAttendance;
        int consecutiveAbsences = 0;
        bool stillCounting = true;
        
        // Go through meetings in reverse order to count consecutive absences
        final reversedMeetings = completedMeetings.reversed.toList();
        
        for (final meeting in reversedMeetings) {
          final meetingData = meeting.data();
          final meetingId = meeting.id;
          final presentIds = List<String>.from(meetingData['presentMemberIds'] ?? []);
          final absentIds = List<String>.from(meetingData['absentMemberIds'] ?? []);
          
          bool wasPresent = presentIds.contains(personId);
          bool wasAbsent = absentIds.contains(personId);
          
          if (wasPresent || wasAbsent) {
            meetingAttendance[meetingId] = wasPresent;
            
            if (wasPresent) {
              presentCount++;
              if (lastAttendance == null) {
                lastAttendance = (meetingData['date'] as Timestamp).toDate();
              }
              if (stillCounting) {
                stillCounting = false; // Stop counting consecutive absences
              }
            } else {
              absentCount++;
              if (stillCounting) {
                consecutiveAbsences++;
              }
            }
          }
        }
        
        final totalPersonMeetings = presentCount + absentCount;
        final attendanceRate = totalPersonMeetings > 0 
            ? presentCount / totalPersonMeetings 
            : 0.0;
        
        memberAttendance[personId] = PersonAttendanceStats(
          personId: personId,
          personName: person.fullName,
          totalMeetings: totalPersonMeetings,
          presentCount: presentCount,
          absentCount: absentCount,
          attendanceRate: attendanceRate,
          meetingAttendance: meetingAttendance,
          lastAttendance: lastAttendance,
          consecutiveAbsences: consecutiveAbsences,
        );
      }
      
      // Calculate overall average attendance
      double averageAttendance = 0.0;
      if (completedMeetings.isNotEmpty) {
        double totalAttendanceRate = 0.0;
        for (final meeting in completedMeetings) {
          final data = meeting.data();
          final present = (data['presentMemberIds'] as List?)?.length ?? 0;
          final absent = (data['absentMemberIds'] as List?)?.length ?? 0;
          final total = present + absent;
          if (total > 0) {
            totalAttendanceRate += present / total;
          }
        }
        averageAttendance = totalAttendanceRate / completedMeetings.length;
      }
      
      // Monthly attendance (last 6 months)
      final Map<String, double> monthlyAttendance = {};
      final now = DateTime.now();
      
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        // Calculate attendance rate for this month
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        
        final monthMeetings = completedMeetings.where((meeting) {
          final meetingDate = (meeting.data()['date'] as Timestamp).toDate();
          return meetingDate.isAfter(monthStart) && meetingDate.isBefore(monthEnd);
        }).toList();
        
        double monthAttendance = 0.0;
        if (monthMeetings.isNotEmpty) {
          double monthTotal = 0.0;
          for (final meeting in monthMeetings) {
            final data = meeting.data();
            final present = (data['presentMemberIds'] as List?)?.length ?? 0;
            final absent = (data['absentMemberIds'] as List?)?.length ?? 0;
            final total = present + absent;
            if (total > 0) {
              monthTotal += present / total;
            }
          }
          monthAttendance = monthTotal / monthMeetings.length;
        }
        
        monthlyAttendance[monthKey] = monthAttendance;
      }
      
      return GroupStatisticsModel(
        groupId: groupId,
        totalMembers: totalMembers,
        activeMembers: activeMembers,
        totalMeetings: totalMeetings,
        averageAttendance: averageAttendance,
        monthlyAttendance: monthlyAttendance,
        memberAttendance: memberAttendance,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Search and Filters
  static Future<List<GroupModel>> searchGroups(String query) async {
    try {
      final snapshot = await _firestore
          .collection(groupsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .where((group) =>
              group.name.toLowerCase().contains(lowerQuery) ||
              group.description.toLowerCase().contains(lowerQuery) ||
              group.type.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Export Functions
  static Future<List<Map<String, dynamic>>> exportGroupMembers(String groupId) async {
    try {
      final members = await getGroupMembersWithPersonData(groupId);
      final group = await getGroup(groupId);
      
      return members.map((person) => {
        'Groupe': group?.name ?? '',
        'Prénom': person.firstName,
        'Nom': person.lastName,
        'Email': person.email,
        'Téléphone': person.phone ?? '',
        'Statut': person.isActive ? 'Actif' : 'Inactif',
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de l\'export: $e');
    }
  }

  // Helper Functions
  static Future<void> _logGroupActivity(String groupId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection('group_activity_logs').add({
        'groupId': groupId,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Log activity failure shouldn't break the main operation
      print('Failed to log group activity: $e');
    }
  }

  static int _dayNameToNumber(String dayName) {
    const dayMap = {
      'Lundi': 1,
      'Mardi': 2,
      'Mercredi': 3,
      'Jeudi': 4,
      'Vendredi': 5,
      'Samedi': 6,
      'Dimanche': 7,
    };
    return dayMap[dayName] ?? 1;
  }

  // Bulk Operations
  static Future<void> duplicateGroup(String originalGroupId, String newName) async {
    try {
      final originalGroup = await getGroup(originalGroupId);
      if (originalGroup == null) throw Exception('Groupe original introuvable');
      
      final now = DateTime.now();
      final newGroup = originalGroup.copyWith(
        name: newName,
        updatedAt: now,
        lastModifiedBy: _auth.currentUser?.uid,
      );
      
      await createGroup(newGroup);
    } catch (e) {
      throw Exception('Erreur lors de la duplication: $e');
    }
  }

  static Future<void> archiveGroup(String groupId) async {
    try {
      await _firestore.collection(groupsCollection).doc(groupId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid,
      });
      await _logGroupActivity(groupId, 'archived', {});
    } catch (e) {
      throw Exception('Erreur lors de l\'archivage: $e');
    }
  }
}