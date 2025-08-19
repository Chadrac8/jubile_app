import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/task_model.dart';
import '../models/person_model.dart';

class TasksFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  static const String tasksCollection = 'tasks';
  static const String taskListsCollection = 'task_lists';
  static const String taskCommentsCollection = 'task_comments';
  static const String taskRemindersCollection = 'task_reminders';
  static const String taskTemplatesCollection = 'task_templates';
  static const String taskActivityLogsCollection = 'task_activity_logs';

  // Task CRUD Operations
  static Future<String> createTask(TaskModel task) async {
    try {
      final docRef = await _firestore.collection(tasksCollection).add(task.toFirestore());
      
      // Update task list count if applicable
      if (task.taskListId != null) {
        await _updateTaskListCounts(task.taskListId!);
      }
      
      // Create reminders for assignees
      await _createTaskReminders(docRef.id, task.assigneeIds, 'assigned');
      
      // Log activity
      await _logTaskActivity(docRef.id, 'task_created', {
        'title': task.title,
        'assignees': task.assigneeIds,
        'dueDate': task.dueDate?.toIso8601String(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la tâche: $e');
    }
  }

  static Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore.collection(tasksCollection).doc(task.id).update(task.toFirestore());
      
      // Update task list counts if applicable
      if (task.taskListId != null) {
        await _updateTaskListCounts(task.taskListId!);
      }
      
      // Log activity
      await _logTaskActivity(task.id, 'task_updated', {
        'title': task.title,
        'status': task.status,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la tâche: $e');
    }
  }

  static Future<void> deleteTask(String taskId) async {
    try {
      final taskDoc = await _firestore.collection(tasksCollection).doc(taskId).get();
      if (!taskDoc.exists) return;
      
      final task = TaskModel.fromFirestore(taskDoc);
      
      // Delete task
      await _firestore.collection(tasksCollection).doc(taskId).delete();
      
      // Delete related comments
      final commentsQuery = await _firestore
          .collection(taskCommentsCollection)
          .where('taskId', isEqualTo: taskId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in commentsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Update task list counts if applicable
      if (task.taskListId != null) {
        await _updateTaskListCounts(task.taskListId!);
      }
      
      // Log activity
      await _logTaskActivity(taskId, 'task_deleted', {
        'title': task.title,
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la tâche: $e');
    }
  }

  static Future<TaskModel?> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection(tasksCollection).doc(taskId).get();
      if (!doc.exists) return null;
      return TaskModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la tâche: $e');
    }
  }

  static Stream<List<TaskModel>> getTasksStream({
    String? searchQuery,
    List<String>? assigneeIds,
    List<String>? statusFilters,
    List<String>? priorityFilters,
    String? taskListId,
    DateTime? dueBefore,
    DateTime? dueAfter,
    String? linkedToType,
    String? linkedToId,
    int limit = 100,
  }) {
    Query query = _firestore.collection(tasksCollection);

    // Apply filters
    if (assigneeIds != null && assigneeIds.isNotEmpty) {
      query = query.where('assigneeIds', arrayContainsAny: assigneeIds);
    }

    if (statusFilters != null && statusFilters.isNotEmpty) {
      query = query.where('status', whereIn: statusFilters);
    }

    if (taskListId != null) {
      query = query.where('taskListId', isEqualTo: taskListId);
    }

    if (linkedToType != null && linkedToId != null) {
      query = query.where('linkedToType', isEqualTo: linkedToType)
                   .where('linkedToId', isEqualTo: linkedToId);
    }

    if (dueBefore != null) {
      query = query.where('dueDate', isLessThanOrEqualTo: dueBefore);
    }

    if (dueAfter != null) {
      query = query.where('dueDate', isGreaterThanOrEqualTo: dueAfter);
    }

    // Simplifions la requête pour éviter les problèmes d'index
    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      var tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      // Apply client-side filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        tasks = tasks.where((task) =>
          task.title.toLowerCase().contains(lowerQuery) ||
          task.description.toLowerCase().contains(lowerQuery) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
        ).toList();
      }

      if (priorityFilters != null && priorityFilters.isNotEmpty) {
        tasks = tasks.where((task) => priorityFilters.contains(task.priority)).toList();
      }

      // Tri côté client par ordre puis par date de création
      tasks.sort((a, b) {
        // D'abord par ordre (ascending)
        int orderComparison = a.order.compareTo(b.order);
        if (orderComparison != 0) return orderComparison;
        
        // Puis par date de création (descending)
        return b.createdAt.compareTo(a.createdAt);
      });

      return tasks;
    });
  }

  // Task List CRUD Operations
  static Future<String> createTaskList(TaskListModel taskList) async {
    try {
      final docRef = await _firestore.collection(taskListsCollection).add(taskList.toFirestore());
      
      // Log activity
      await _logTaskActivity(docRef.id, 'task_list_created', {
        'name': taskList.name,
        'visibility': taskList.visibility,
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la liste: $e');
    }
  }

  static Future<void> updateTaskList(TaskListModel taskList) async {
    try {
      await _firestore.collection(taskListsCollection).doc(taskList.id).update(taskList.toFirestore());
      
      // Log activity
      await _logTaskActivity(taskList.id, 'task_list_updated', {
        'name': taskList.name,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la liste: $e');
    }
  }

  static Future<void> deleteTaskList(String taskListId) async {
    try {
      // Get all tasks in this list
      final tasksQuery = await _firestore
          .collection(tasksCollection)
          .where('taskListId', isEqualTo: taskListId)
          .get();
      
      // Update tasks to remove from list
      final batch = _firestore.batch();
      for (final doc in tasksQuery.docs) {
        batch.update(doc.reference, {'taskListId': null});
      }
      
      // Delete the list
      batch.delete(_firestore.collection(taskListsCollection).doc(taskListId));
      
      await batch.commit();
      
      // Log activity
      await _logTaskActivity(taskListId, 'task_list_deleted', {});
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la liste: $e');
    }
  }

  static Stream<List<TaskListModel>> getTaskListsStream({
    String? searchQuery,
    String? ownerId,
    List<String>? statusFilters,
    String? userId,
    int limit = 50,
  }) {
    Query query = _firestore.collection(taskListsCollection);

    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    if (statusFilters != null && statusFilters.isNotEmpty) {
      query = query.where('status', whereIn: statusFilters);
    }

    query = query.orderBy('updatedAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      var taskLists = snapshot.docs.map((doc) => TaskListModel.fromFirestore(doc)).toList();

      // Apply visibility filter for current user
      if (userId != null) {
        taskLists = taskLists.where((list) {
          if (list.ownerId == userId) return true;
          if (list.visibility == 'public') return true;
          if (list.memberIds.contains(userId)) return true;
          return false;
        }).toList();
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        taskLists = taskLists.where((list) =>
          list.name.toLowerCase().contains(lowerQuery) ||
          list.description.toLowerCase().contains(lowerQuery)
        ).toList();
      }

      return taskLists;
    });
  }

  // Task Comments
  static Future<String> addTaskComment(TaskCommentModel comment) async {
    try {
      final docRef = await _firestore.collection(taskCommentsCollection).add(comment.toFirestore());
      
      // Get task to notify assignees
      final task = await getTask(comment.taskId);
      if (task != null) {
        await _createTaskReminders(comment.taskId, task.assigneeIds, 'comment_added');
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du commentaire: $e');
    }
  }

  static Stream<List<TaskCommentModel>> getTaskCommentsStream(String taskId) {
    return _firestore
        .collection(taskCommentsCollection)
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskCommentModel.fromFirestore(doc)).toList());
  }

  // Task Status Updates
  static Future<void> updateTaskStatus(String taskId, String newStatus, {String? userId}) async {
    try {
      final updates = {
        'status': newStatus,
        'updatedAt': DateTime.now(),
        'lastModifiedBy': userId,
      };

      if (newStatus == 'completed') {
        updates['completedAt'] = DateTime.now();
        updates['completedBy'] = userId;
      } else {
        updates['completedAt'] = null;
        updates['completedBy'] = null;
      }

      await _firestore.collection(tasksCollection).doc(taskId).update(updates);
      
      // Update task list counts
      final task = await getTask(taskId);
      if (task?.taskListId != null) {
        await _updateTaskListCounts(task!.taskListId!);
      }
      
      // Log activity
      await _logTaskActivity(taskId, 'status_updated', {
        'newStatus': newStatus,
        'updatedBy': userId,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Task Assignment
  static Future<void> assignTask(String taskId, List<String> assigneeIds, {String? userId}) async {
    try {
      await _firestore.collection(tasksCollection).doc(taskId).update({
        'assigneeIds': assigneeIds,
        'updatedAt': DateTime.now(),
        'lastModifiedBy': userId,
      });
      
      // Create reminders for new assignees
      await _createTaskReminders(taskId, assigneeIds, 'assigned');
      
      // Log activity
      await _logTaskActivity(taskId, 'task_assigned', {
        'assignees': assigneeIds,
        'assignedBy': userId,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation: $e');
    }
  }

  // Task Attachments
  static Future<String> uploadTaskAttachment(Uint8List fileBytes, String fileName, String taskId) async {
    try {
      final ref = _storage.ref().child('task_attachments/$taskId/$fileName');
      await ref.putData(fileBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors du téléchargement du fichier: $e');
    }
  }

  // Move Task Between Lists
  static Future<void> moveTaskToList(String taskId, String? newTaskListId, int newOrder) async {
    try {
      final oldTask = await getTask(taskId);
      
      await _firestore.collection(tasksCollection).doc(taskId).update({
        'taskListId': newTaskListId,
        'order': newOrder,
        'updatedAt': DateTime.now(),
      });
      
      // Update counts for both lists
      if (oldTask?.taskListId != null) {
        await _updateTaskListCounts(oldTask!.taskListId!);
      }
      if (newTaskListId != null) {
        await _updateTaskListCounts(newTaskListId);
      }
      
      // Log activity
      await _logTaskActivity(taskId, 'task_moved', {
        'fromList': oldTask?.taskListId,
        'toList': newTaskListId,
        'newOrder': newOrder,
      });
    } catch (e) {
      throw Exception('Erreur lors du déplacement de la tâche: $e');
    }
  }

  // Duplicate Task
  static Future<String> duplicateTask(String originalTaskId, {String? newTitle}) async {
    try {
      final originalTask = await getTask(originalTaskId);
      if (originalTask == null) throw Exception('Tâche originale non trouvée');
      
      final duplicatedTask = originalTask.copyWith(
        title: newTitle ?? '${originalTask.title} (Copie)',
        status: 'todo',
        completedAt: null,
        completedBy: null,
        updatedAt: DateTime.now(),
      );
      
      final docRef = await _firestore.collection(tasksCollection).add(duplicatedTask.toFirestore());
      
      // Update task list count if applicable
      if (duplicatedTask.taskListId != null) {
        await _updateTaskListCounts(duplicatedTask.taskListId!);
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la duplication de la tâche: $e');
    }
  }

  // Recurring Tasks
  static Future<void> createRecurringTask(String originalTaskId) async {
    try {
      final originalTask = await getTask(originalTaskId);
      if (originalTask == null || !originalTask.isRecurring) return;
      
      final pattern = originalTask.recurrencePattern;
      if (pattern == null) return;
      
      DateTime? nextDueDate;
      if (originalTask.dueDate != null) {
        switch (pattern['frequency']) {
          case 'daily':
            final interval = pattern['interval'] as int? ?? 1;
            nextDueDate = originalTask.dueDate!.add(Duration(days: interval));
            break;
          case 'weekly':
            final interval = pattern['interval'] as int? ?? 1;
            nextDueDate = originalTask.dueDate!.add(Duration(days: 7 * interval));
            break;
          case 'monthly':
            final interval = pattern['interval'] as int? ?? 1;
            nextDueDate = DateTime(
              originalTask.dueDate!.year,
              originalTask.dueDate!.month + interval,
              originalTask.dueDate!.day,
            );
            break;
        }
      }
      
      final newTask = originalTask.copyWith(
        status: 'todo',
        dueDate: nextDueDate,
        completedAt: null,
        completedBy: null,
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection(tasksCollection).add(newTask.toFirestore());
      
      // Update task list count if applicable
      if (newTask.taskListId != null) {
        await _updateTaskListCounts(newTask.taskListId!);
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de la tâche récurrente: $e');
    }
  }

  // Statistics
  static Future<TaskStatisticsModel> getTaskStatistics({String? userId, String? taskListId}) async {
    try {
      Query query = _firestore.collection(tasksCollection);
      
      if (userId != null) {
        query = query.where('assigneeIds', arrayContains: userId);
      }
      
      if (taskListId != null) {
        query = query.where('taskListId', isEqualTo: taskListId);
      }
      
      final snapshot = await query.get();
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      
      final now = DateTime.now();
      
      return TaskStatisticsModel(
        totalTasks: tasks.length,
        completedTasks: tasks.where((t) => t.isCompleted).length,
        overdueTasks: tasks.where((t) => t.isOverdue).length,
        dueSoonTasks: tasks.where((t) => t.isDueSoon).length,
        tasksByPriority: {
          'low': tasks.where((t) => t.priority == 'low').length,
          'medium': tasks.where((t) => t.priority == 'medium').length,
          'high': tasks.where((t) => t.priority == 'high').length,
        },
        tasksByStatus: {
          'todo': tasks.where((t) => t.status == 'todo').length,
          'in_progress': tasks.where((t) => t.status == 'in_progress').length,
          'completed': tasks.where((t) => t.status == 'completed').length,
          'cancelled': tasks.where((t) => t.status == 'cancelled').length,
        },
        tasksCompletedByDate: {},
        averageCompletionTime: 0.0,
        lastUpdated: now,
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Templates
  static Future<List<TaskTemplateModel>> getTaskTemplates() async {
    try {
      final snapshot = await _firestore.collection(taskTemplatesCollection).get();
      return snapshot.docs.map((doc) => TaskTemplateModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modèles: $e');
    }
  }

  static Future<String> createFromTemplate(String templateId, Map<String, dynamic> customData) async {
    try {
      final templateDoc = await _firestore.collection(taskTemplatesCollection).doc(templateId).get();
      if (!templateDoc.exists) throw Exception('Modèle non trouvé');
      
      final template = TaskTemplateModel.fromFirestore(templateDoc);
      
      if (template.type == 'task') {
        // Create single task from template
        final taskData = {...template.defaultData, ...customData};
        final task = TaskModel(
          id: '',
          title: taskData['title'] ?? 'Nouvelle tâche',
          description: taskData['description'] ?? '',
          priority: taskData['priority'] ?? 'medium',
          createdBy: _auth.currentUser?.uid ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        return await createTask(task);
      } else {
        // Create task list with tasks from template
        final listData = {...template.defaultData, ...customData};
        final taskList = TaskListModel(
          id: '',
          name: listData['name'] ?? 'Nouvelle liste',
          description: listData['description'] ?? '',
          ownerId: _auth.currentUser?.uid ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final listId = await createTaskList(taskList);
        
        // Create tasks from template
        for (final taskTemplate in template.taskTemplates) {
          final task = TaskModel(
            id: '',
            title: taskTemplate['title'] ?? 'Nouvelle tâche',
            description: taskTemplate['description'] ?? '',
            priority: taskTemplate['priority'] ?? 'medium',
            taskListId: listId,
            createdBy: _auth.currentUser?.uid ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await createTask(task);
        }
        
        return listId;
      }
    } catch (e) {
      throw Exception('Erreur lors de la création depuis le modèle: $e');
    }
  }

  // Helper Methods
  static Future<void> _updateTaskListCounts(String taskListId) async {
    try {
      final tasksSnapshot = await _firestore
          .collection(tasksCollection)
          .where('taskListId', isEqualTo: taskListId)
          .get();
      
      final tasks = tasksSnapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      final completedTasks = tasks.where((t) => t.isCompleted).length;
      
      await _firestore.collection(taskListsCollection).doc(taskListId).update({
        'taskCount': tasks.length,
        'completedTaskCount': completedTasks,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      // Silently fail - this is not critical
    }
  }

  static Future<void> _createTaskReminders(String taskId, List<String> userIds, String type) async {
    try {
      final batch = _firestore.batch();
      for (final userId in userIds) {
        final reminderRef = _firestore.collection(taskRemindersCollection).doc();
        batch.set(reminderRef, TaskReminderModel(
          id: reminderRef.id,
          taskId: taskId,
          userId: userId,
          reminderDate: DateTime.now(),
          type: type,
          createdAt: DateTime.now(),
        ).toFirestore());
      }
      await batch.commit();
    } catch (e) {
      // Silently fail - this is not critical
    }
  }

  static Future<void> _logTaskActivity(String taskId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(taskActivityLogsCollection).add({
        'taskId': taskId,
        'action': action,
        'details': details,
        'timestamp': DateTime.now(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Silently fail - this is not critical
    }
  }

  // Reminders and Notifications
  static Stream<List<TaskReminderModel>> getUserRemindersStream(String userId) {
    return _firestore
        .collection(taskRemindersCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskReminderModel.fromFirestore(doc)).toList());
  }

  static Future<void> markReminderAsRead(String reminderId) async {
    try {
      await _firestore.collection(taskRemindersCollection).doc(reminderId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Erreur lors du marquage du rappel: $e');
    }
  }

  // Search across all tasks for a user
  static Future<List<TaskModel>> searchUserTasks(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(tasksCollection)
          .where('assigneeIds', arrayContains: userId)
          .get();
      
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      final lowerQuery = query.toLowerCase();
      
      return tasks.where((task) =>
        task.title.toLowerCase().contains(lowerQuery) ||
        task.description.toLowerCase().contains(lowerQuery) ||
        task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
      ).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Create default templates
  static Future<void> createDefaultTemplates() async {
    try {
      final templates = [
        TaskTemplateModel(
          id: '',
          name: 'Préparation d\'événement',
          description: 'Liste complète pour organiser un événement',
          type: 'task_list',
          category: 'Événements',
          isBuiltIn: true,
          taskTemplates: [
            {
              'title': 'Définir le budget',
              'description': 'Établir et valider le budget de l\'événement',
              'priority': 'high',
            },
            {
              'title': 'Réserver le lieu',
              'description': 'Contacter et réserver la salle ou l\'espace',
              'priority': 'high',
            },
            {
              'title': 'Créer les supports de communication',
              'description': 'Affiches, flyers, posts réseaux sociaux',
              'priority': 'medium',
            },
            {
              'title': 'Organiser la logistique',
              'description': 'Matériel, traiteur, décoration',
              'priority': 'medium',
            },
            {
              'title': 'Briefing équipe',
              'description': 'Réunion de préparation avec l\'équipe',
              'priority': 'medium',
            },
          ],
          defaultData: {},
          createdAt: DateTime.now(),
        ),
        TaskTemplateModel(
          id: '',
          name: 'Accueil nouveau membre',
          description: 'Processus d\'intégration d\'un nouveau membre',
          type: 'task_list',
          category: 'Membres',
          isBuiltIn: true,
          taskTemplates: [
            {
              'title': 'Appel de bienvenue',
              'description': 'Contacter le nouveau membre dans les 48h',
              'priority': 'high',
            },
            {
              'title': 'Envoyer pack de bienvenue',
              'description': 'Documents d\'information et cadeaux',
              'priority': 'medium',
            },
            {
              'title': 'Programmer visite personnelle',
              'description': 'Rencontre avec un responsable',
              'priority': 'medium',
            },
            {
              'title': 'Invitation petit groupe',
              'description': 'Proposer l\'intégration dans un groupe',
              'priority': 'low',
            },
          ],
          defaultData: {},
          createdAt: DateTime.now(),
        ),
      ];

      for (final template in templates) {
        await _firestore.collection(taskTemplatesCollection).add(template.toFirestore());
      }
    } catch (e) {
      // Silently fail - templates are not critical
    }
  }

  // Réorganiser les tâches d'une liste pour corriger les ordres
  static Future<void> reorderTasksInList(String taskListId, List<String> taskIds) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < taskIds.length; i++) {
        final taskRef = _firestore.collection(tasksCollection).doc(taskIds[i]);
        batch.update(taskRef, {'order': i});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la réorganisation des tâches: $e');
    }
  }

  // Corriger les ordres des tâches en cas de problème
  static Future<void> fixTaskOrders({String? taskListId}) async {
    try {
      Query query = _firestore.collection(tasksCollection);
      
      if (taskListId != null) {
        query = query.where('taskListId', isEqualTo: taskListId);
      }
      
      final snapshot = await query.orderBy('createdAt').get();
      final batch = _firestore.batch();
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        batch.update(snapshot.docs[i].reference, {'order': i});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la correction des ordres: $e');
    }
  }
}