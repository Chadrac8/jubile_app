import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'exécution d'une automatisation
enum ExecutionStatus {
  pending('pending', 'En attente'),
  running('running', 'En cours'),
  completed('completed', 'Terminée'),
  failed('failed', 'Échouée'),
  cancelled('cancelled', 'Annulée'),
  skipped('skipped', 'Ignorée');

  const ExecutionStatus(this.value, this.label);
  final String value;
  final String label;

  static ExecutionStatus fromString(String value) {
    return ExecutionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExecutionStatus.pending,
    );
  }
}

/// Détail d'exécution d'une action
class ActionExecution {
  final String actionType;
  final Map<String, dynamic> parameters;
  final ExecutionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? error;
  final Map<String, dynamic> result;
  final int retryCount;

  const ActionExecution({
    required this.actionType,
    this.parameters = const {},
    this.status = ExecutionStatus.pending,
    required this.startedAt,
    this.completedAt,
    this.error,
    this.result = const {},
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'actionType': actionType,
      'parameters': parameters,
      'status': status.value,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'error': error,
      'result': result,
      'retryCount': retryCount,
    };
  }

  factory ActionExecution.fromMap(Map<String, dynamic> map) {
    return ActionExecution(
      actionType: map['actionType'] ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      status: ExecutionStatus.fromString(map['status'] ?? ''),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      error: map['error'],
      result: Map<String, dynamic>.from(map['result'] ?? {}),
      retryCount: map['retryCount'] ?? 0,
    );
  }

  ActionExecution copyWith({
    String? actionType,
    Map<String, dynamic>? parameters,
    ExecutionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
    Map<String, dynamic>? result,
    int? retryCount,
  }) {
    return ActionExecution(
      actionType: actionType ?? this.actionType,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
      result: result ?? this.result,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Durée d'exécution de l'action
  Duration? get executionDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  /// Vérifie si l'action a réussi
  bool get isSuccessful => status == ExecutionStatus.completed && error == null;

  /// Vérifie si l'action a échoué
  bool get isFailed => status == ExecutionStatus.failed || error != null;
}

/// Journal d'exécution d'une automatisation
class AutomationExecution {
  final String? id;
  final String automationId;
  final String automationName;
  final ExecutionStatus status;
  final DateTime triggeredAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> triggerData;
  final Map<String, dynamic> executionData;
  final List<ActionExecution> actionExecutions;
  final String? error;
  final Map<String, dynamic> context;
  final String? triggeredBy; // ID de l'utilisateur ou 'system'
  final String triggerType; // Type de déclencheur
  final int retryCount;
  final bool isManual; // Exécution manuelle ou automatique

  const AutomationExecution({
    this.id,
    required this.automationId,
    required this.automationName,
    this.status = ExecutionStatus.pending,
    required this.triggeredAt,
    this.startedAt,
    this.completedAt,
    this.triggerData = const {},
    this.executionData = const {},
    this.actionExecutions = const [],
    this.error,
    this.context = const {},
    this.triggeredBy,
    this.triggerType = 'unknown',
    this.retryCount = 0,
    this.isManual = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'automationId': automationId,
      'automationName': automationName,
      'status': status.value,
      'triggeredAt': Timestamp.fromDate(triggeredAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'triggerData': triggerData,
      'executionData': executionData,
      'actionExecutions': actionExecutions.map((a) => a.toMap()).toList(),
      'error': error,
      'context': context,
      'triggeredBy': triggeredBy,
      'triggerType': triggerType,
      'retryCount': retryCount,
      'isManual': isManual,
    };
  }

  factory AutomationExecution.fromMap(Map<String, dynamic> map, String id) {
    return AutomationExecution(
      id: id,
      automationId: map['automationId'] ?? '',
      automationName: map['automationName'] ?? '',
      status: ExecutionStatus.fromString(map['status'] ?? ''),
      triggeredAt: (map['triggeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      triggerData: Map<String, dynamic>.from(map['triggerData'] ?? {}),
      executionData: Map<String, dynamic>.from(map['executionData'] ?? {}),
      actionExecutions: (map['actionExecutions'] as List<dynamic>?)
          ?.map((a) => ActionExecution.fromMap(Map<String, dynamic>.from(a)))
          .toList() ?? [],
      error: map['error'],
      context: Map<String, dynamic>.from(map['context'] ?? {}),
      triggeredBy: map['triggeredBy'],
      triggerType: map['triggerType'] ?? 'unknown',
      retryCount: map['retryCount'] ?? 0,
      isManual: map['isManual'] ?? false,
    );
  }

  AutomationExecution copyWith({
    String? id,
    String? automationId,
    String? automationName,
    ExecutionStatus? status,
    DateTime? triggeredAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? triggerData,
    Map<String, dynamic>? executionData,
    List<ActionExecution>? actionExecutions,
    String? error,
    Map<String, dynamic>? context,
    String? triggeredBy,
    String? triggerType,
    int? retryCount,
    bool? isManual,
  }) {
    return AutomationExecution(
      id: id ?? this.id,
      automationId: automationId ?? this.automationId,
      automationName: automationName ?? this.automationName,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      triggerData: triggerData ?? this.triggerData,
      executionData: executionData ?? this.executionData,
      actionExecutions: actionExecutions ?? this.actionExecutions,
      error: error ?? this.error,
      context: context ?? this.context,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      triggerType: triggerType ?? this.triggerType,
      retryCount: retryCount ?? this.retryCount,
      isManual: isManual ?? this.isManual,
    );
  }

  /// Durée totale d'exécution
  Duration? get totalExecutionDuration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Alias pour totalExecutionDuration (pour compatibilité)
  Duration? get duration => totalExecutionDuration;

  /// Durée avant le début d'exécution
  Duration? get queueDuration {
    if (startedAt == null) return null;
    return startedAt!.difference(triggeredAt);
  }

  /// Nombre d'actions réussies
  int get successfulActionsCount {
    return actionExecutions.where((a) => a.isSuccessful).length;
  }

  /// Nombre d'actions échouées
  int get failedActionsCount {
    return actionExecutions.where((a) => a.isFailed).length;
  }

  /// Vérifie si toutes les actions ont réussi
  bool get allActionsSuccessful {
    return actionExecutions.isNotEmpty && 
           actionExecutions.every((a) => a.isSuccessful);
  }

  /// Vérifie si au moins une action a échoué
  bool get hasFailedActions {
    return actionExecutions.any((a) => a.isFailed);
  }

  /// Vérifie si l'exécution est terminée
  bool get isCompleted {
    return status == ExecutionStatus.completed || 
           status == ExecutionStatus.failed || 
           status == ExecutionStatus.cancelled;
  }

  /// Vérifie si l'exécution est en cours
  bool get isRunning {
    return status == ExecutionStatus.running;
  }

  /// Message de statut lisible
  String get statusMessage {
    switch (status) {
      case ExecutionStatus.pending:
        return 'En attente d\'exécution';
      case ExecutionStatus.running:
        return 'Exécution en cours (${actionExecutions.length} actions)';
      case ExecutionStatus.completed:
        if (allActionsSuccessful) {
          return 'Exécution réussie (${successfulActionsCount} actions)';
        } else {
          return 'Exécution partielle (${successfulActionsCount}/${actionExecutions.length} actions réussies)';
        }
      case ExecutionStatus.failed:
        return 'Exécution échouée: ${error ?? "Erreur inconnue"}';
      case ExecutionStatus.cancelled:
        return 'Exécution annulée';
      case ExecutionStatus.skipped:
        return 'Exécution ignorée (conditions non remplies)';
    }
  }

  @override
  String toString() {
    return 'AutomationExecution(id: $id, automation: $automationName, status: ${status.label}, triggered: $triggeredAt)';
  }
}