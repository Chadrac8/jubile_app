import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import 'reports_service.dart';

/// Service de planification automatique des rapports
class SchedulerService {
  final ReportsService _reportsService = ReportsService();
  Timer? _schedulerTimer;
  
  /// Collection pour stocker les tâches planifiées
  final scheduledTasksCollection = FirebaseFirestore.instance.collection('scheduled_report_tasks');
  
  /// Démarrer le service de planification
  void startScheduler() {
    if (_schedulerTimer != null) return;
    
    // Vérifier les tâches planifiées toutes les heures
    _schedulerTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _processScheduledReports();
    });
    
    print('📅 Service de planification des rapports démarré');
  }
  
  /// Arrêter le service de planification
  void stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    print('⏹️ Service de planification des rapports arrêté');
  }
  
  /// Planifier un rapport pour génération automatique
  Future<String> scheduleReport(String reportId, ScheduleConfig config) async {
    final scheduleData = {
      'reportId': reportId,
      'config': config.toMap(),
      'createdAt': Timestamp.now(),
      'lastExecuted': null,
      'nextExecution': _calculateNextExecution(config),
      'isActive': true,
      'executionCount': 0,
      'lastResult': null,
    };
    
    final docRef = await scheduledTasksCollection.add(scheduleData);
    
    print('📋 Rapport planifié: $reportId avec config: ${config.frequency}');
    return docRef.id;
  }
  
  /// Mettre à jour la planification d'un rapport
  Future<void> updateSchedule(String scheduleId, ScheduleConfig config) async {
    await scheduledTasksCollection.doc(scheduleId).update({
      'config': config.toMap(),
      'nextExecution': _calculateNextExecution(config),
      'updatedAt': Timestamp.now(),
    });
  }
  
  /// Désactiver la planification d'un rapport
  Future<void> disableSchedule(String scheduleId) async {
    await scheduledTasksCollection.doc(scheduleId).update({
      'isActive': false,
      'disabledAt': Timestamp.now(),
    });
  }
  
  /// Supprimer la planification d'un rapport
  Future<void> deleteSchedule(String scheduleId) async {
    await scheduledTasksCollection.doc(scheduleId).delete();
  }
  
  /// Obtenir toutes les planifications
  Future<List<ScheduledTask>> getAllSchedules() async {
    final querySnapshot = await scheduledTasksCollection
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => ScheduledTask.fromMap(doc.data(), doc.id))
        .toList();
  }
  
  /// Obtenir les planifications actives
  Future<List<ScheduledTask>> getActiveSchedules() async {
    final querySnapshot = await scheduledTasksCollection
        .where('isActive', isEqualTo: true)
        .orderBy('nextExecution')
        .get();
    
    return querySnapshot.docs
        .map((doc) => ScheduledTask.fromMap(doc.data(), doc.id))
        .toList();
  }
  
  /// Obtenir les planifications d'un rapport spécifique
  Future<List<ScheduledTask>> getSchedulesForReport(String reportId) async {
    final querySnapshot = await scheduledTasksCollection
        .where('reportId', isEqualTo: reportId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => ScheduledTask.fromMap(doc.data(), doc.id))
        .toList();
  }
  
  /// Exécuter manuellement une tâche planifiée
  Future<bool> executeScheduledTask(String scheduleId) async {
    try {
      final doc = await scheduledTasksCollection.doc(scheduleId).get();
      if (!doc.exists) return false;
      
      final task = ScheduledTask.fromMap(doc.data()!, doc.id);
      
      // Obtenir le rapport
      final report = await _reportsService.getById(task.reportId);
      if (report == null) {
        await _markTaskAsError(scheduleId, 'Rapport non trouvé');
        return false;
      }
      
      // Générer le rapport
      final reportData = await _reportsService.generateReportData(report);
      
      // Mettre à jour la tâche
      await _markTaskAsCompleted(scheduleId, task.config);
      
      print('✅ Tâche planifiée exécutée avec succès: $scheduleId');
      return true;
    } catch (e) {
      await _markTaskAsError(scheduleId, e.toString());
      print('❌ Erreur lors de l\'exécution de la tâche planifiée: $e');
      return false;
    }
  }
  
  /// Traiter les rapports planifiés (appelé périodiquement)
  Future<void> _processScheduledReports() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await scheduledTasksCollection
          .where('isActive', isEqualTo: true)
          .where('nextExecution', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();
      
      for (final doc in querySnapshot.docs) {
        final task = ScheduledTask.fromMap(doc.data(), doc.id);
        await executeScheduledTask(task.id);
      }
      
      if (querySnapshot.docs.isNotEmpty) {
        print('📊 ${querySnapshot.docs.length} tâches planifiées traitées');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement des tâches planifiées: $e');
    }
  }
  
  /// Calculer la prochaine exécution selon la configuration
  Timestamp _calculateNextExecution(ScheduleConfig config) {
    final now = DateTime.now();
    DateTime nextExecution;
    
    switch (config.frequency) {
      case ScheduleFrequency.hourly:
        nextExecution = now.add(const Duration(hours: 1));
        break;
      case ScheduleFrequency.daily:
        nextExecution = DateTime(now.year, now.month, now.day + 1, config.hour ?? 9, config.minute ?? 0);
        break;
      case ScheduleFrequency.weekly:
        final daysUntilWeekday = (config.weekday ?? 1) - now.weekday;
        final daysToAdd = daysUntilWeekday <= 0 ? daysUntilWeekday + 7 : daysUntilWeekday;
        nextExecution = DateTime(now.year, now.month, now.day + daysToAdd, config.hour ?? 9, config.minute ?? 0);
        break;
      case ScheduleFrequency.monthly:
        var nextMonth = now.month + 1;
        var nextYear = now.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        nextExecution = DateTime(nextYear, nextMonth, config.dayOfMonth ?? 1, config.hour ?? 9, config.minute ?? 0);
        break;
      case ScheduleFrequency.custom:
        nextExecution = config.customDateTime ?? now.add(const Duration(days: 1));
        break;
    }
    
    return Timestamp.fromDate(nextExecution);
  }
  
  /// Marquer une tâche comme terminée
  Future<void> _markTaskAsCompleted(String scheduleId, ScheduleConfig config) async {
    await scheduledTasksCollection.doc(scheduleId).update({
      'lastExecuted': Timestamp.now(),
      'nextExecution': _calculateNextExecution(config),
      'executionCount': FieldValue.increment(1),
      'lastResult': {
        'status': 'success',
        'timestamp': Timestamp.now(),
        'message': 'Rapport généré avec succès',
      },
    });
  }
  
  /// Marquer une tâche comme ayant échoué
  Future<void> _markTaskAsError(String scheduleId, String error) async {
    await scheduledTasksCollection.doc(scheduleId).update({
      'lastResult': {
        'status': 'error',
        'timestamp': Timestamp.now(),
        'message': error,
      },
      'failureCount': FieldValue.increment(1),
    });
  }
  
  /// Obtenir les statistiques du planificateur
  Future<Map<String, dynamic>> getSchedulerStatistics() async {
    final allTasks = await getAllSchedules();
    final activeTasks = allTasks.where((t) => t.isActive).toList();
    
    final now = DateTime.now();
    final overdueTasks = activeTasks
        .where((t) => t.nextExecution.isBefore(now))
        .length;
    
    final totalExecutions = allTasks.fold<int>(0, (sum, task) => sum + task.executionCount);
    
    return {
      'total_schedules': allTasks.length,
      'active_schedules': activeTasks.length,
      'overdue_tasks': overdueTasks,
      'total_executions': totalExecutions,
      'success_rate': _calculateSuccessRate(allTasks),
    };
  }
  
  double _calculateSuccessRate(List<ScheduledTask> tasks) {
    if (tasks.isEmpty) return 0.0;
    
    final tasksWithResults = tasks.where((t) => t.lastResult != null).toList();
    if (tasksWithResults.isEmpty) return 0.0;
    
    final successfulTasks = tasksWithResults
        .where((t) => t.lastResult!['status'] == 'success')
        .length;
    
    return (successfulTasks / tasksWithResults.length) * 100;
  }
}

/// Configuration de planification
class ScheduleConfig {
  final ScheduleFrequency frequency;
  final int? hour;
  final int? minute;
  final int? weekday; // 1 = lundi, 7 = dimanche
  final int? dayOfMonth;
  final DateTime? customDateTime;
  final bool enabled;
  
  const ScheduleConfig({
    required this.frequency,
    this.hour,
    this.minute,
    this.weekday,
    this.dayOfMonth,
    this.customDateTime,
    this.enabled = true,
  });
  
  factory ScheduleConfig.fromMap(Map<String, dynamic> data) {
    return ScheduleConfig(
      frequency: ScheduleFrequency.values.firstWhere(
        (f) => f.toString() == data['frequency'],
        orElse: () => ScheduleFrequency.daily,
      ),
      hour: data['hour'] as int?,
      minute: data['minute'] as int?,
      weekday: data['weekday'] as int?,
      dayOfMonth: data['dayOfMonth'] as int?,
      customDateTime: data['customDateTime'] != null 
          ? (data['customDateTime'] as Timestamp).toDate()
          : null,
      enabled: data['enabled'] as bool? ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.toString(),
      'hour': hour,
      'minute': minute,
      'weekday': weekday,
      'dayOfMonth': dayOfMonth,
      'customDateTime': customDateTime != null 
          ? Timestamp.fromDate(customDateTime!)
          : null,
      'enabled': enabled,
    };
  }
}

/// Fréquences de planification disponibles
enum ScheduleFrequency {
  hourly,
  daily,
  weekly,
  monthly,
  custom,
}

/// Modèle pour les tâches planifiées
class ScheduledTask {
  final String id;
  final String reportId;
  final ScheduleConfig config;
  final DateTime createdAt;
  final DateTime? lastExecuted;
  final DateTime nextExecution;
  final bool isActive;
  final int executionCount;
  final Map<String, dynamic>? lastResult;
  
  const ScheduledTask({
    required this.id,
    required this.reportId,
    required this.config,
    required this.createdAt,
    this.lastExecuted,
    required this.nextExecution,
    this.isActive = true,
    this.executionCount = 0,
    this.lastResult,
  });
  
  factory ScheduledTask.fromMap(Map<String, dynamic> data, String id) {
    return ScheduledTask(
      id: id,
      reportId: data['reportId'] as String,
      config: ScheduleConfig.fromMap(data['config'] as Map<String, dynamic>),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastExecuted: data['lastExecuted'] != null 
          ? (data['lastExecuted'] as Timestamp).toDate()
          : null,
      nextExecution: (data['nextExecution'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      executionCount: data['executionCount'] as int? ?? 0,
      lastResult: data['lastResult'] as Map<String, dynamic>?,
    );
  }
  
  /// Vérifier si la tâche est en retard
  bool get isOverdue => DateTime.now().isAfter(nextExecution);
  
  /// Obtenir le statut de la dernière exécution
  String get lastStatus {
    if (lastResult == null) return 'Jamais exécuté';
    return lastResult!['status'] == 'success' ? 'Succès' : 'Échec';
  }
}