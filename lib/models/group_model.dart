import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final String frequency;
  final String location;
  final String? meetingLink;
  final int dayOfWeek; // 1-7 (Monday-Sunday)
  final String time; // "19:30"
  final bool isPublic;
  final String color;
  final List<String> leaderIds;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final bool isActive;
  final String? groupImageUrl; // Photo du groupe en base64
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.frequency,
    required this.location,
    this.meetingLink,
    required this.dayOfWeek,
    required this.time,
    this.isPublic = true,
    required this.color,
    this.leaderIds = const [],
    this.tags = const [],
    this.customFields = const {},
    this.isActive = true,
    this.groupImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastModifiedBy,
  });

  String get dayName {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[dayOfWeek];
  }

  String get scheduleText => '$dayName à $time';

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      frequency: data['frequency'] ?? '',
      location: data['location'] ?? '',
      meetingLink: data['meetingLink'],
      dayOfWeek: data['dayOfWeek'] ?? 1,
      time: data['time'] ?? '',
      isPublic: data['isPublic'] ?? true,
      color: data['color'] ?? '#6F61EF',
      leaderIds: List<String>.from(data['leaderIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      isActive: data['isActive'] ?? true,
      groupImageUrl: data['groupImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'frequency': frequency,
      'location': location,
      'meetingLink': meetingLink,
      'dayOfWeek': dayOfWeek,
      'time': time,
      'isPublic': isPublic,
      'color': color,
      'leaderIds': leaderIds,
      'tags': tags,
      'customFields': customFields,
      'isActive': isActive,
      'groupImageUrl': groupImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  GroupModel copyWith({
    String? name,
    String? description,
    String? type,
    String? frequency,
    String? location,
    String? meetingLink,
    int? dayOfWeek,
    String? time,
    bool? isPublic,
    String? color,
    List<String>? leaderIds,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    bool? isActive,
    String? groupImageUrl,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      time: time ?? this.time,
      isPublic: isPublic ?? this.isPublic,
      color: color ?? this.color,
      leaderIds: leaderIds ?? this.leaderIds,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      isActive: isActive ?? this.isActive,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class GroupMemberModel {
  final String id;
  final String groupId;
  final String personId;
  final String role; // 'leader', 'co-leader', 'member', 'guest'
  final String status; // 'active', 'pending', 'removed'
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.personId,
    required this.role,
    this.status = 'active',
    required this.joinedAt,
    this.leftAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isLeader => role == 'leader' || role == 'co-leader';

  factory GroupMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMemberModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      personId: data['personId'] ?? '',
      role: data['role'] ?? 'member',
      status: data['status'] ?? 'active',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      leftAt: data['leftAt'] != null ? (data['leftAt'] as Timestamp).toDate() : null,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'personId': personId,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class GroupMeetingModel {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final DateTime date;
  final String location;
  final String? notes;
  final String? reportNotes;
  final List<String> presentMemberIds;
  final List<String> absentMemberIds;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  GroupMeetingModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.date,
    required this.location,
    this.notes,
    this.reportNotes,
    this.presentMemberIds = const [],
    this.absentMemberIds = const [],
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  int get totalMembers => presentMemberIds.length + absentMemberIds.length;
  double get attendanceRate => totalMembers > 0 ? presentMemberIds.length / totalMembers : 0.0;

  factory GroupMeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMeetingModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      notes: data['notes'],
      reportNotes: data['reportNotes'],
      presentMemberIds: List<String>.from(data['presentMemberIds'] ?? []),
      absentMemberIds: List<String>.from(data['absentMemberIds'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'notes': notes,
      'reportNotes': reportNotes,
      'presentMemberIds': presentMemberIds,
      'absentMemberIds': absentMemberIds,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  GroupMeetingModel copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? notes,
    String? reportNotes,
    List<String>? presentMemberIds,
    List<String>? absentMemberIds,
    bool? isCompleted,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return GroupMeetingModel(
      id: id,
      groupId: groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      reportNotes: reportNotes ?? this.reportNotes,
      presentMemberIds: presentMemberIds ?? this.presentMemberIds,
      absentMemberIds: absentMemberIds ?? this.absentMemberIds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class GroupAttendanceModel {
  final String id;
  final String groupId;
  final String meetingId;
  final String personId;
  final bool isPresent;
  final String? notes;
  final DateTime recordedAt;
  final String? recordedBy;

  GroupAttendanceModel({
    required this.id,
    required this.groupId,
    required this.meetingId,
    required this.personId,
    required this.isPresent,
    this.notes,
    required this.recordedAt,
    this.recordedBy,
  });

  factory GroupAttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupAttendanceModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      meetingId: data['meetingId'] ?? '',
      personId: data['personId'] ?? '',
      isPresent: data['isPresent'] ?? false,
      notes: data['notes'],
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      recordedBy: data['recordedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'meetingId': meetingId,
      'personId': personId,
      'isPresent': isPresent,
      'notes': notes,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'recordedBy': recordedBy,
    };
  }
}

class GroupStatisticsModel {
  final String groupId;
  final int totalMembers;
  final int activeMembers;
  final int totalMeetings;
  final double averageAttendance;
  final Map<String, double> monthlyAttendance;
  final Map<String, PersonAttendanceStats> memberAttendance;
  final DateTime lastUpdated;

  GroupStatisticsModel({
    required this.groupId,
    required this.totalMembers,
    required this.activeMembers,
    required this.totalMeetings,
    required this.averageAttendance,
    required this.monthlyAttendance,
    required this.memberAttendance,
    required this.lastUpdated,
  });

  factory GroupStatisticsModel.fromMap(Map<String, dynamic> data) {
    final memberAttendanceData = data['memberAttendance'] as Map<String, dynamic>? ?? {};
    final memberAttendance = <String, PersonAttendanceStats>{};
    
    memberAttendanceData.forEach((key, value) {
      memberAttendance[key] = PersonAttendanceStats.fromMap(value);
    });

    return GroupStatisticsModel(
      groupId: data['groupId'] ?? '',
      totalMembers: data['totalMembers'] ?? 0,
      activeMembers: data['activeMembers'] ?? 0,
      totalMeetings: data['totalMeetings'] ?? 0,
      averageAttendance: (data['averageAttendance'] ?? 0.0).toDouble(),
      monthlyAttendance: Map<String, double>.from(data['monthlyAttendance'] ?? {}),
      memberAttendance: memberAttendance,
      lastUpdated: DateTime.parse(data['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    final memberAttendanceData = <String, dynamic>{};
    memberAttendance.forEach((key, value) {
      memberAttendanceData[key] = value.toMap();
    });

    return {
      'groupId': groupId,
      'totalMembers': totalMembers,
      'activeMembers': activeMembers,
      'totalMeetings': totalMeetings,
      'averageAttendance': averageAttendance,
      'monthlyAttendance': monthlyAttendance,
      'memberAttendance': memberAttendanceData,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class PersonAttendanceStats {
  final String personId;
  final String personName;
  final int totalMeetings;
  final int presentCount;
  final int absentCount;
  final double attendanceRate;
  final Map<String, bool> meetingAttendance; // meetingId -> present/absent
  final DateTime? lastAttendance;
  final int consecutiveAbsences;

  PersonAttendanceStats({
    required this.personId,
    required this.personName,
    required this.totalMeetings,
    required this.presentCount,
    required this.absentCount,
    required this.attendanceRate,
    required this.meetingAttendance,
    this.lastAttendance,
    required this.consecutiveAbsences,
  });

  factory PersonAttendanceStats.fromMap(Map<String, dynamic> data) {
    return PersonAttendanceStats(
      personId: data['personId'] ?? '',
      personName: data['personName'] ?? '',
      totalMeetings: data['totalMeetings'] ?? 0,
      presentCount: data['presentCount'] ?? 0,
      absentCount: data['absentCount'] ?? 0,
      attendanceRate: (data['attendanceRate'] ?? 0.0).toDouble(),
      meetingAttendance: Map<String, bool>.from(data['meetingAttendance'] ?? {}),
      lastAttendance: data['lastAttendance'] != null 
          ? DateTime.parse(data['lastAttendance'])
          : null,
      consecutiveAbsences: data['consecutiveAbsences'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'personName': personName,
      'totalMeetings': totalMeetings,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'attendanceRate': attendanceRate,
      'meetingAttendance': meetingAttendance,
      'lastAttendance': lastAttendance?.toIso8601String(),
      'consecutiveAbsences': consecutiveAbsences,
    };
  }

  String get attendanceLabel {
    if (attendanceRate >= 0.9) return 'Excellente';
    if (attendanceRate >= 0.7) return 'Bonne';
    if (attendanceRate >= 0.5) return 'Moyenne';
    return 'Faible';
  }

  Color get attendanceColor {
    if (attendanceRate >= 0.9) return const Color(0xFF4CAF50); // Vert
    if (attendanceRate >= 0.7) return const Color(0xFFFF9800); // Orange
    if (attendanceRate >= 0.5) return const Color(0xFFFFC107); // Jaune
    return const Color(0xFFF44336); // Rouge
  }
}