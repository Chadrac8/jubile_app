import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'todo', 'in_progress', 'completed', 'cancelled'
  final List<String> assigneeIds;
  final String createdBy;
  final List<String> tags;
  final List<String> attachmentUrls;
  final String? linkedToType; // 'group', 'event', 'person', 'service', 'form'
  final String? linkedToId;
  final String? taskListId;
  final bool isRecurring;
  final Map<String, dynamic>? recurrencePattern;
  final DateTime? completedAt;
  final String? completedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;
  final int order; // Pour l'ordre dans les listes

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = 'medium',
    this.status = 'todo',
    this.assigneeIds = const [],
    required this.createdBy,
    this.tags = const [],
    this.attachmentUrls = const [],
    this.linkedToType,
    this.linkedToId,
    this.taskListId,
    this.isRecurring = false,
    this.recurrencePattern,
    this.completedAt,
    this.completedBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastModifiedBy,
    this.order = 0,
  });

  String get priorityLabel {
    switch (priority) {
      case 'low': return 'Basse';
      case 'medium': return 'Moyenne';
      case 'high': return 'Haute';
      default: return 'Moyenne';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'todo': return 'À faire';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminé';
      case 'cancelled': return 'Annulé';
      default: return 'À faire';
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inDays <= 1 && difference.inDays >= 0;
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate']?.toDate(),
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'todo',
      assigneeIds: List<String>.from(data['assigneeIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      linkedToType: data['linkedToType'],
      linkedToId: data['linkedToId'],
      taskListId: data['taskListId'],
      isRecurring: data['isRecurring'] ?? false,
      recurrencePattern: data['recurrencePattern'],
      completedAt: data['completedAt']?.toDate(),
      completedBy: data['completedBy'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      lastModifiedBy: data['lastModifiedBy'],
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'priority': priority,
      'status': status,
      'assigneeIds': assigneeIds,
      'createdBy': createdBy,
      'tags': tags,
      'attachmentUrls': attachmentUrls,
      'linkedToType': linkedToType,
      'linkedToId': linkedToId,
      'taskListId': taskListId,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'completedAt': completedAt,
      'completedBy': completedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastModifiedBy': lastModifiedBy,
      'order': order,
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? status,
    List<String>? assigneeIds,
    List<String>? tags,
    List<String>? attachmentUrls,
    String? linkedToType,
    String? linkedToId,
    String? taskListId,
    bool? isRecurring,
    Map<String, dynamic>? recurrencePattern,
    DateTime? completedAt,
    String? completedBy,
    DateTime? updatedAt,
    String? lastModifiedBy,
    int? order,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      createdBy: createdBy,
      tags: tags ?? this.tags,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      linkedToType: linkedToType ?? this.linkedToType,
      linkedToId: linkedToId ?? this.linkedToId,
      taskListId: taskListId ?? this.taskListId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      order: order ?? this.order,
    );
  }
}

class TaskListModel {
  final String id;
  final String name;
  final String description;
  final String ownerId; // Responsable de la liste
  final String visibility; // 'public', 'private', 'group', 'role'
  final List<String> visibilityTargets; // Group IDs ou Role IDs
  final String status; // 'active', 'archived'
  final String? color;
  final String? iconName;
  final List<String> memberIds; // Membres ayant accès
  final int taskCount;
  final int completedTaskCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;

  TaskListModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    this.visibility = 'private',
    this.visibilityTargets = const [],
    this.status = 'active',
    this.color,
    this.iconName,
    this.memberIds = const [],
    this.taskCount = 0,
    this.completedTaskCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastModifiedBy,
  });

  String get visibilityLabel {
    switch (visibility) {
      case 'public': return 'Publique';
      case 'private': return 'Privée';
      case 'group': return 'Groupe';
      case 'role': return 'Rôle';
      default: return 'Privée';
    }
  }

  double get progressPercentage {
    if (taskCount == 0) return 0.0;
    return completedTaskCount / taskCount;
  }

  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';

  factory TaskListModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskListModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      visibility: data['visibility'] ?? 'private',
      visibilityTargets: List<String>.from(data['visibilityTargets'] ?? []),
      status: data['status'] ?? 'active',
      color: data['color'],
      iconName: data['iconName'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      taskCount: data['taskCount'] ?? 0,
      completedTaskCount: data['completedTaskCount'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'visibility': visibility,
      'visibilityTargets': visibilityTargets,
      'status': status,
      'color': color,
      'iconName': iconName,
      'memberIds': memberIds,
      'taskCount': taskCount,
      'completedTaskCount': completedTaskCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  TaskListModel copyWith({
    String? name,
    String? description,
    String? visibility,
    List<String>? visibilityTargets,
    String? status,
    String? color,
    String? iconName,
    List<String>? memberIds,
    int? taskCount,
    int? completedTaskCount,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return TaskListModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
      visibility: visibility ?? this.visibility,
      visibilityTargets: visibilityTargets ?? this.visibilityTargets,
      status: status ?? this.status,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      memberIds: memberIds ?? this.memberIds,
      taskCount: taskCount ?? this.taskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class TaskCommentModel {
  final String id;
  final String taskId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastModifiedBy;

  TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.lastModifiedBy,
  });

  factory TaskCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCommentModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'authorId': authorId,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastModifiedBy': lastModifiedBy,
    };
  }
}

class TaskReminderModel {
  final String id;
  final String taskId;
  final String userId;
  final DateTime reminderDate;
  final String type; // 'due_soon', 'overdue', 'assigned'
  final bool isRead;
  final DateTime createdAt;

  TaskReminderModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.reminderDate,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory TaskReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskReminderModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      reminderDate: data['reminderDate']?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'assigned',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'reminderDate': reminderDate,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}

class TaskTemplateModel {
  final String id;
  final String name;
  final String description;
  final String type; // 'task', 'task_list'
  final List<Map<String, dynamic>> taskTemplates; // Pour les listes
  final Map<String, dynamic> defaultData;
  final String category;
  final bool isBuiltIn;
  final DateTime createdAt;
  final String? createdBy;

  TaskTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.taskTemplates = const [],
    this.defaultData = const {},
    required this.category,
    this.isBuiltIn = false,
    required this.createdAt,
    this.createdBy,
  });

  factory TaskTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskTemplateModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'task',
      taskTemplates: List<Map<String, dynamic>>.from(data['taskTemplates'] ?? []),
      defaultData: Map<String, dynamic>.from(data['defaultData'] ?? {}),
      category: data['category'] ?? '',
      isBuiltIn: data['isBuiltIn'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'taskTemplates': taskTemplates,
      'defaultData': defaultData,
      'category': category,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}

class TaskStatisticsModel {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int dueSoonTasks;
  final Map<String, int> tasksByPriority;
  final Map<String, int> tasksByStatus;
  final Map<String, int> tasksCompletedByDate;
  final double averageCompletionTime;
  final DateTime lastUpdated;

  TaskStatisticsModel({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.dueSoonTasks,
    required this.tasksByPriority,
    required this.tasksByStatus,
    required this.tasksCompletedByDate,
    required this.averageCompletionTime,
    required this.lastUpdated,
  });

  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
}