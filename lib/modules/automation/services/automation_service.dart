import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/automation.dart';
import '../models/automation_execution.dart';
import '../models/automation_template.dart';

/// Service pour la gestion des automatisations
class AutomationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'automations';

  /// Service pour les exécutions d'automatisations
  final AutomationExecutionService executionService = AutomationExecutionService();

  /// Service pour les actions d'automatisation
  final AutomationActionService actionService = AutomationActionService();

  /// Référence à la collection Firestore
  CollectionReference get collection => _firestore.collection(collectionName);

  /// Convertir un document Firestore en objet Automation
  Automation fromFirestore(DocumentSnapshot doc) {
    return Automation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Convertir un objet Automation en données Firestore
  Map<String, dynamic> toFirestore(Automation automation) {
    return automation.toMap();
  }

  /// Initialise le service
  Future<void> initialize() async {
    await executionService.initialize();
    await actionService.initialize();
    print('AutomationService initialisé');
  }

  /// Libère les ressources
  Future<void> dispose() async {
    await executionService.dispose();
    await actionService.dispose();
    print('AutomationService fermé');
  }

  /// Récupérer toutes les automatisations
  Future<List<Automation>> getAll() async {
    try {
      final snapshot = await collection.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des automatisations: $e');
      return [];
    }
  }

  /// Récupérer une automatisation par ID
  Future<Automation?> getById(String id) async {
    try {
      final doc = await collection.doc(id).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'automatisation $id: $e');
      return null;
    }
  }

  /// Créer une nouvelle automatisation
  Future<String> create(Automation automation) async {
    try {
      final docRef = await collection.add(toFirestore(automation));
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'automatisation: $e');
      rethrow;
    }
  }

  /// Mettre à jour une automatisation
  Future<void> update(String id, Automation automation) async {
    try {
      await collection.doc(id).update(toFirestore(automation));
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'automatisation $id: $e');
      rethrow;
    }
  }

  /// Supprimer une automatisation
  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e) {
      print('Erreur lors de la suppression de l\'automatisation $id: $e');
      rethrow;
    }
  }

  /// Crée une nouvelle automatisation
  Future<String> createAutomation(Automation automation) async {
    final automationWithTimestamp = automation.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await create(automationWithTimestamp);
  }

  /// Met à jour une automatisation
  Future<void> updateAutomation(String id, Automation automation) async {
    final updatedAutomation = automation.copyWith(
      updatedAt: DateTime.now(),
    );
    await update(id, updatedAutomation);
  }

  /// Active une automatisation
  Future<void> activateAutomation(String id) async {
    final automation = await getById(id);
    if (automation != null) {
      await updateAutomation(id, automation.copyWith(
        status: AutomationStatus.active,
      ));
    }
  }

  /// Désactive une automatisation
  Future<void> deactivateAutomation(String id) async {
    final automation = await getById(id);
    if (automation != null) {
      await updateAutomation(id, automation.copyWith(
        status: AutomationStatus.inactive,
      ));
    }
  }

  /// Obtient les automatisations actives
  Future<List<Automation>> getActiveAutomations() async {
    try {
      final querySnapshot = await collection
          .where('status', isEqualTo: AutomationStatus.active.value)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des automatisations actives: $e');
      return [];
    }
  }

  /// Obtient les automatisations par déclencheur
  Future<List<Automation>> getAutomationsByTrigger(AutomationTrigger trigger) async {
    try {
      final querySnapshot = await collection
          .where('trigger', isEqualTo: trigger.value)
          .where('status', isEqualTo: AutomationStatus.active.value)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des automatisations par déclencheur: $e');
      return [];
    }
  }

  /// Obtient les automatisations par statut
  Future<List<Automation>> getAutomationsByStatus(AutomationStatus status) async {
    try {
      final querySnapshot = await collection
          .where('status', isEqualTo: status.value)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des automatisations par statut: $e');
      return [];
    }
  }

  /// Recherche des automatisations
  Future<List<Automation>> searchAutomations(String query) async {
    if (query.isEmpty) return await getAll();

    try {
      // Recherche par nom (limitation de Firestore pour la recherche textuelle)
      final querySnapshot = await collection
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la recherche d\'automatisations: $e');
      return [];
    }
  }

  /// Obtient les automatisations avec tags
  Future<List<Automation>> getAutomationsByTags(List<String> tags) async {
    if (tags.isEmpty) return [];

    try {
      final querySnapshot = await collection
          .where('tags', arrayContainsAny: tags)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des automatisations par tags: $e');
      return [];
    }
  }

  /// Déclenche manuellement une automatisation
  Future<String> triggerAutomation(
    String automationId, 
    Map<String, dynamic> triggerData,
    {String? triggeredBy}
  ) async {
    final automation = await getById(automationId);
    if (automation == null) {
      throw Exception('Automatisation non trouvée');
    }

    if (!automation.isActive) {
      throw Exception('Automatisation inactive');
    }

    // Crée une exécution
    final execution = AutomationExecution(
      automationId: automationId,
      automationName: automation.name,
      triggeredAt: DateTime.now(),
      triggerData: triggerData,
      triggeredBy: triggeredBy ?? 'manual',
      isManual: true,
    );

    final executionId = await executionService.createExecution(execution);
    
    // Démarre l'exécution en arrière-plan
    _executeAutomation(executionId, automation, execution);

    return executionId;
  }

  /// Exécute une automatisation (méthode privée)
  Future<void> _executeAutomation(
    String executionId,
    Automation automation, 
    AutomationExecution execution
  ) async {
    try {
      // Met à jour le statut à "en cours"
      final runningExecution = execution.copyWith(
        status: ExecutionStatus.running,
        startedAt: DateTime.now(),
      );
      await executionService.updateExecution(executionId, runningExecution);

      // Vérifie les conditions
      if (!await _checkConditions(automation.conditions, execution.triggerData)) {
        final skippedExecution = runningExecution.copyWith(
          status: ExecutionStatus.completed,
          completedAt: DateTime.now(),
        );
        await executionService.updateExecution(executionId, skippedExecution);
        return;
      }

      // Exécute les actions
      final actionExecutions = <ActionExecution>[];
      bool hasErrors = false;

      for (final actionConfig in automation.actions) {
        if (!actionConfig.enabled) continue;

        // Attendre le délai si configuré
        if (actionConfig.delayMinutes != null && actionConfig.delayMinutes! > 0) {
          await Future.delayed(Duration(minutes: actionConfig.delayMinutes!));
        }

        final actionExecution = await _executeAction(
          actionConfig, 
          execution.triggerData,
          execution.context
        );
        
        actionExecutions.add(actionExecution);
        
        if (actionExecution.isFailed) {
          hasErrors = true;
        }
      }

      // Met à jour l'exécution finale
      final finalStatus = hasErrors ? ExecutionStatus.failed : ExecutionStatus.completed;
      final completedExecution = runningExecution.copyWith(
        status: finalStatus,
        completedAt: DateTime.now(),
        actionExecutions: actionExecutions,
      );
      await executionService.updateExecution(executionId, completedExecution);

      // Met à jour les statistiques de l'automatisation
      await _updateAutomationStats(automation.id!, finalStatus == ExecutionStatus.completed);

    } catch (e) {
      // Gère les erreurs d'exécution
      final failedExecution = execution.copyWith(
        status: ExecutionStatus.failed,
        completedAt: DateTime.now(),
        error: e.toString(),
      );
      await executionService.updateExecution(executionId, failedExecution);
      await _updateAutomationStats(automation.id!, false);
    }
  }

  /// Vérifie les conditions d'une automatisation
  Future<bool> _checkConditions(
    List<AutomationCondition> conditions, 
    Map<String, dynamic> data
  ) async {
    if (conditions.isEmpty) return true;

    bool result = true;
    String? lastLogicalOperator;

    for (final condition in conditions) {
      final conditionResult = await _evaluateCondition(condition, data);
      
      if (lastLogicalOperator == null) {
        result = conditionResult;
      } else if (lastLogicalOperator == 'and') {
        result = result && conditionResult;
      } else if (lastLogicalOperator == 'or') {
        result = result || conditionResult;
      }
      
      lastLogicalOperator = condition.logicalOperator;
    }

    return result;
  }

  /// Évalue une condition individuelle
  Future<bool> _evaluateCondition(
    AutomationCondition condition, 
    Map<String, dynamic> data
  ) async {
    final fieldValue = _getFieldValue(condition.field, data);
    final conditionValue = condition.value;

    switch (condition.operator) {
      case 'equals':
        return fieldValue == conditionValue;
      case 'not_equals':
        return fieldValue != conditionValue;
      case 'contains':
        return fieldValue?.toString().contains(conditionValue.toString()) ?? false;
      case 'not_contains':
        return !(fieldValue?.toString().contains(conditionValue.toString()) ?? false);
      case 'greater_than':
        if (fieldValue is num && conditionValue is num) {
          return fieldValue > conditionValue;
        }
        return false;
      case 'less_than':
        if (fieldValue is num && conditionValue is num) {
          return fieldValue < conditionValue;
        }
        return false;
      case 'greater_equal':
        if (fieldValue is num && conditionValue is num) {
          return fieldValue >= conditionValue;
        }
        return false;
      case 'less_equal':
        if (fieldValue is num && conditionValue is num) {
          return fieldValue <= conditionValue;
        }
        return false;
      case 'is_empty':
        return fieldValue == null || fieldValue.toString().isEmpty;
      case 'is_not_empty':
        return fieldValue != null && fieldValue.toString().isNotEmpty;
      default:
        return false;
    }
  }

  /// Récupère la valeur d'un champ dans les données
  dynamic _getFieldValue(String fieldPath, Map<String, dynamic> data) {
    final parts = fieldPath.split('.');
    dynamic value = data;
    
    for (final part in parts) {
      if (value is Map<String, dynamic>) {
        value = value[part];
      } else {
        return null;
      }
    }
    
    return value;
  }

  /// Exécute une action
  Future<ActionExecution> _executeAction(
    AutomationActionConfig actionConfig,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    final startTime = DateTime.now();
    
    try {
      final result = await actionService.executeAction(
        actionConfig.action,
        actionConfig.parameters,
        triggerData,
        context
      );

      return ActionExecution(
        actionType: actionConfig.action.value,
        parameters: actionConfig.parameters,
        status: ExecutionStatus.completed,
        startedAt: startTime,
        completedAt: DateTime.now(),
        result: result,
      );
    } catch (e) {
      return ActionExecution(
        actionType: actionConfig.action.value,
        parameters: actionConfig.parameters,
        status: ExecutionStatus.failed,
        startedAt: startTime,
        completedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Met à jour les statistiques d'une automatisation
  Future<void> _updateAutomationStats(String automationId, bool success) async {
    final automation = await getById(automationId);
    if (automation == null) return;

    final updatedAutomation = automation.copyWith(
      executionCount: automation.executionCount + 1,
      successCount: success ? automation.successCount + 1 : automation.successCount,
      failureCount: success ? automation.failureCount : automation.failureCount + 1,
      lastExecutedAt: DateTime.now(),
    );

    await updateAutomation(automationId, updatedAutomation);
  }

  /// Crée une automatisation à partir d'un template
  Future<String> createFromTemplate(String templateId, String createdBy) async {
    final template = AutomationTemplates.getById(templateId);
    if (template == null) {
      throw Exception('Template non trouvé');
    }

    final automation = template.createAutomation(createdBy: createdBy);
    return await createAutomation(automation);
  }

  /// Obtient les statistiques des automatisations
  Future<Map<String, dynamic>> getAutomationStats() async {
    try {
      final allAutomations = await getAll();
      
      final stats = {
        'total': allAutomations.length,
        'active': allAutomations.where((a) => a.isActive).length,
        'inactive': allAutomations.where((a) => a.status == AutomationStatus.inactive).length,
        'draft': allAutomations.where((a) => a.status == AutomationStatus.draft).length,
        'error': allAutomations.where((a) => a.hasErrors).length,
        'totalExecutions': allAutomations.fold<int>(0, (sum, a) => sum + a.executionCount),
        'totalSuccesses': allAutomations.fold<int>(0, (sum, a) => sum + a.successCount),
        'totalFailures': allAutomations.fold<int>(0, (sum, a) => sum + a.failureCount),
        'averageSuccessRate': _calculateAverageSuccessRate(allAutomations),
        'triggerBreakdown': _getTriggerBreakdown(allAutomations),
        'actionBreakdown': _getActionBreakdown(allAutomations),
      };

      return stats;
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  double _calculateAverageSuccessRate(List<Automation> automations) {
    if (automations.isEmpty) return 0.0;
    
    final automationsWithExecutions = automations.where((a) => a.executionCount > 0);
    if (automationsWithExecutions.isEmpty) return 0.0;
    
    final totalRate = automationsWithExecutions.fold<double>(
      0.0, 
      (sum, a) => sum + a.successRate
    );
    
    return totalRate / automationsWithExecutions.length;
  }

  Map<String, int> _getTriggerBreakdown(List<Automation> automations) {
    final breakdown = <String, int>{};
    for (final automation in automations) {
      final trigger = automation.trigger.label;
      breakdown[trigger] = (breakdown[trigger] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> _getActionBreakdown(List<Automation> automations) {
    final breakdown = <String, int>{};
    for (final automation in automations) {
      for (final action in automation.actions) {
        final actionType = action.action.label;
        breakdown[actionType] = (breakdown[actionType] ?? 0) + 1;
      }
    }
    return breakdown;
  }
}

/// Service pour les exécutions d'automatisations
class AutomationExecutionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'automation_executions';

  /// Référence à la collection Firestore
  CollectionReference get collection => _firestore.collection(collectionName);

  /// Convertir un document Firestore en objet AutomationExecution
  AutomationExecution fromFirestore(DocumentSnapshot doc) {
    return AutomationExecution.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Convertir un objet AutomationExecution en données Firestore
  Map<String, dynamic> toFirestore(AutomationExecution execution) {
    return execution.toMap();
  }

  Future<void> initialize() async {
    print('AutomationExecutionService initialisé');
  }

  Future<void> dispose() async {
    print('AutomationExecutionService fermé');
  }

  /// Récupérer une exécution par ID
  Future<AutomationExecution?> getById(String id) async {
    try {
      final doc = await collection.doc(id).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'exécution $id: $e');
      return null;
    }
  }

  /// Créer une nouvelle exécution
  Future<String> create(AutomationExecution execution) async {
    try {
      final docRef = await collection.add(toFirestore(execution));
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'exécution: $e');
      rethrow;
    }
  }

  /// Mettre à jour une exécution
  Future<void> update(String id, AutomationExecution execution) async {
    try {
      await collection.doc(id).update(toFirestore(execution));
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'exécution $id: $e');
      rethrow;
    }
  }

  Future<String> createExecution(AutomationExecution execution) async {
    return await create(execution);
  }

  Future<void> updateExecution(String id, AutomationExecution execution) async {
    await update(id, execution);
  }

  /// Obtient les exécutions d'une automatisation
  Future<List<AutomationExecution>> getExecutionsByAutomation(String automationId) async {
    try {
      final querySnapshot = await collection
          .where('automationId', isEqualTo: automationId)
          .orderBy('triggeredAt', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des exécutions: $e');
      return [];
    }
  }

  /// Obtient les exécutions récentes
  Future<List<AutomationExecution>> getRecentExecutions({int limit = 50}) async {
    try {
      final querySnapshot = await collection
          .orderBy('triggeredAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des exécutions récentes: $e');
      return [];
    }
  }
}

/// Service pour l'exécution des actions
class AutomationActionService {
  Future<void> initialize() async {
    print('AutomationActionService initialisé');
  }

  Future<void> dispose() async {
    print('AutomationActionService fermé');
  }

  /// Exécute une action d'automatisation
  Future<Map<String, dynamic>> executeAction(
    AutomationAction action,
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    print('Exécution de l\'action: ${action.label}');
    
    switch (action) {
      case AutomationAction.sendEmail:
        return await _sendEmail(parameters, triggerData, context);
      case AutomationAction.sendNotification:
        return await _sendNotification(parameters, triggerData, context);
      case AutomationAction.assignTask:
        return await _assignTask(parameters, triggerData, context);
      case AutomationAction.addToGroup:
        return await _addToGroup(parameters, triggerData, context);
      case AutomationAction.updateField:
        return await _updateField(parameters, triggerData, context);
      case AutomationAction.createEvent:
        return await _createEvent(parameters, triggerData, context);
      case AutomationAction.scheduleFollowUp:
        return await _scheduleFollowUp(parameters, triggerData, context);
      case AutomationAction.logActivity:
        return await _logActivity(parameters, triggerData, context);
      case AutomationAction.sendSMS:
        return await _sendSMS(parameters, triggerData, context);
      case AutomationAction.createAppointment:
        return await _createAppointment(parameters, triggerData, context);
    }
  }

  Future<Map<String, dynamic>> _sendEmail(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour l'envoi d'email
    await Future.delayed(const Duration(seconds: 1));
    return {
      'status': 'sent',
      'recipient': parameters['recipient'] ?? triggerData['person']?['email'],
      'subject': parameters['subject'] ?? 'Notification automatique',
    };
  }

  Future<Map<String, dynamic>> _sendNotification(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour l'envoi de notification
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'status': 'sent',
      'message': parameters['message'] ?? 'Notification automatique',
    };
  }

  Future<Map<String, dynamic>> _assignTask(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour l'assignation de tâche
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'status': 'assigned',
      'taskId': 'task_${DateTime.now().millisecondsSinceEpoch}',
      'title': parameters['title'] ?? 'Tâche automatique',
    };
  }

  Future<Map<String, dynamic>> _addToGroup(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour l'ajout à un groupe
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'status': 'added',
      'groupId': parameters['groupId'],
      'personId': triggerData['person']?['id'],
    };
  }

  Future<Map<String, dynamic>> _updateField(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour la mise à jour de champ
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'status': 'updated',
      'field': parameters['field'],
      'newValue': parameters['value'],
    };
  }

  Future<Map<String, dynamic>> _createEvent(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour la création d'événement
    await Future.delayed(const Duration(seconds: 1));
    return {
      'status': 'created',
      'eventId': 'event_${DateTime.now().millisecondsSinceEpoch}',
      'title': parameters['title'] ?? 'Événement automatique',
    };
  }

  Future<Map<String, dynamic>> _scheduleFollowUp(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour la planification de suivi
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'status': 'scheduled',
      'followUpId': 'followup_${DateTime.now().millisecondsSinceEpoch}',
      'scheduledFor': DateTime.now().add(Duration(days: parameters['delayDays'] ?? 7)).toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _logActivity(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour l'enregistrement d'activité
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'status': 'logged',
      'activityId': 'activity_${DateTime.now().millisecondsSinceEpoch}',
      'type': parameters['type'] ?? 'automation',
    };
  }

  Future<Map<String, dynamic>> _sendSMS(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour l'envoi de SMS
    await Future.delayed(const Duration(milliseconds: 700));
    return {
      'status': 'sent',
      'recipient': parameters['recipient'] ?? triggerData['person']?['phone'],
      'message': parameters['message'] ?? 'SMS automatique',
    };
  }

  Future<Map<String, dynamic>> _createAppointment(
    Map<String, dynamic> parameters,
    Map<String, dynamic> triggerData,
    Map<String, dynamic> context
  ) async {
    // Implémentation simulée pour la création de rendez-vous
    await Future.delayed(const Duration(milliseconds: 900));
    return {
      'status': 'created',
      'appointmentId': 'appointment_${DateTime.now().millisecondsSinceEpoch}',
      'title': parameters['title'] ?? 'Rendez-vous automatique',
    };
  }
}