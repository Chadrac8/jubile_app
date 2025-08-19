import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de déclencheurs (triggers) disponibles
enum AutomationTrigger {
  personAdded('person_added', 'Nouvelle personne ajoutée'),
  groupJoined('group_joined', 'Inscription à un groupe'),
  eventRegistered('event_registered', 'Inscription à un événement'),
  serviceAssigned('service_assigned', 'Assignation à un service'),
  dateScheduled('date_scheduled', 'Date planifiée'),
  fieldChanged('field_changed', 'Champ modifié'),
  prayerRequest('prayer_request', 'Demande de prière'),
  taskCompleted('task_completed', 'Tâche terminée'),
  blogPostPublished('blog_post_published', 'Article publié'),
  appointmentBooked('appointment_booked', 'Rendez-vous réservé');

  const AutomationTrigger(this.value, this.label);
  final String value;
  final String label;

  static AutomationTrigger fromString(String value) {
    return AutomationTrigger.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AutomationTrigger.personAdded,
    );
  }
}

/// Types d\'actions disponibles
enum AutomationAction {
  sendEmail('send_email', 'Envoyer un email'),
  sendNotification('send_notification', 'Envoyer une notification'),
  assignTask('assign_task', 'Assigner une tâche'),
  addToGroup('add_to_group', 'Ajouter à un groupe'),
  updateField('update_field', 'Mettre à jour un champ'),
  createEvent('create_event', 'Créer un événement'),
  scheduleFollowUp('schedule_follow_up', 'Planifier un suivi'),
  logActivity('log_activity', 'Enregistrer une activité'),
  sendSMS('send_sms', 'Envoyer un SMS'),
  createAppointment('create_appointment', 'Créer un rendez-vous');

  const AutomationAction(this.value, this.label);
  final String value;
  final String label;

  static AutomationAction fromString(String value) {
    return AutomationAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AutomationAction.sendEmail,
    );
  }
}

/// Statut d\'une automatisation
enum AutomationStatus {
  active('active', 'Active'),
  inactive('inactive', 'Inactive'),
  draft('draft', 'Brouillon'),
  error('error', 'Erreur');

  const AutomationStatus(this.value, this.label);
  final String value;
  final String label;

  static AutomationStatus fromString(String value) {
    return AutomationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AutomationStatus.draft,
    );
  }
}

/// Condition pour l\'exécution d\'une automatisation
class AutomationCondition {
  final String field;
  final String operator; // equals, contains, greater_than, less_than, etc.
  final dynamic value;
  final String? logicalOperator; // and, or

  const AutomationCondition({
    required this.field,
    required this.operator,
    required this.value,
    this.logicalOperator,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'operator': operator,
      'value': value,
      'logicalOperator': logicalOperator,
    };
  }

  factory AutomationCondition.fromMap(Map<String, dynamic> map) {
    return AutomationCondition(
      field: map['field'] ?? '',
      operator: map['operator'] ?? 'equals',
      value: map['value'],
      logicalOperator: map['logicalOperator'],
    );
  }
}

/// Configuration d\'une action d\'automatisation
class AutomationActionConfig {
  final AutomationAction action;
  final Map<String, dynamic> parameters;
  final int? delayMinutes; // Délai avant exécution
  final bool enabled;

  const AutomationActionConfig({
    required this.action,
    this.parameters = const {},
    this.delayMinutes,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action.value,
      'parameters': parameters,
      'delayMinutes': delayMinutes,
      'enabled': enabled,
    };
  }

  factory AutomationActionConfig.fromMap(Map<String, dynamic> map) {
    return AutomationActionConfig(
      action: AutomationAction.fromString(map['action'] ?? ''),
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      delayMinutes: map['delayMinutes'],
      enabled: map['enabled'] ?? true,
    );
  }

  AutomationActionConfig copyWith({
    AutomationAction? action,
    Map<String, dynamic>? parameters,
    int? delayMinutes,
    bool? enabled,
  }) {
    return AutomationActionConfig(
      action: action ?? this.action,
      parameters: parameters ?? this.parameters,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Modèle principal d\'automatisation
class Automation {
  final String? id;
  final String name;
  final String description;
  final AutomationTrigger trigger;
  final Map<String, dynamic> triggerConfig;
  final List<AutomationCondition> conditions;
  final List<AutomationActionConfig> actions;
  final AutomationStatus status;
  final bool isRecurring;
  final String? schedule; // Cron expression pour la récurrence
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final int executionCount;
  final int successCount;
  final int failureCount;
  final DateTime? lastExecutedAt;
  final String? lastError;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const Automation({
    this.id,
    required this.name,
    required this.description,
    required this.trigger,
    this.triggerConfig = const {},
    this.conditions = const [],
    this.actions = const [],
    this.status = AutomationStatus.draft,
    this.isRecurring = false,
    this.schedule,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.executionCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.lastExecutedAt,
    this.lastError,
    this.tags = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'trigger': trigger.value,
      'triggerConfig': triggerConfig,
      'conditions': conditions.map((c) => c.toMap()).toList(),
      'actions': actions.map((a) => a.toMap()).toList(),
      'status': status.value,
      'isRecurring': isRecurring,
      'schedule': schedule,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'executionCount': executionCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'lastExecutedAt': lastExecutedAt != null ? Timestamp.fromDate(lastExecutedAt!) : null,
      'lastError': lastError,
      'tags': tags,
      'metadata': metadata,
    };
  }

  factory Automation.fromMap(Map<String, dynamic> map, String id) {
    return Automation(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      trigger: AutomationTrigger.fromString(map['trigger'] ?? ''),
      triggerConfig: Map<String, dynamic>.from(map['triggerConfig'] ?? {}),
      conditions: (map['conditions'] as List<dynamic>?)
          ?.map((c) => AutomationCondition.fromMap(Map<String, dynamic>.from(c)))
          .toList() ?? [],
      actions: (map['actions'] as List<dynamic>?)
          ?.map((a) => AutomationActionConfig.fromMap(Map<String, dynamic>.from(a)))
          .toList() ?? [],
      status: AutomationStatus.fromString(map['status'] ?? ''),
      isRecurring: map['isRecurring'] ?? false,
      schedule: map['schedule'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      executionCount: map['executionCount'] ?? 0,
      successCount: map['successCount'] ?? 0,
      failureCount: map['failureCount'] ?? 0,
      lastExecutedAt: (map['lastExecutedAt'] as Timestamp?)?.toDate(),
      lastError: map['lastError'],
      tags: List<String>.from(map['tags'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Automation copyWith({
    String? id,
    String? name,
    String? description,
    AutomationTrigger? trigger,
    Map<String, dynamic>? triggerConfig,
    List<AutomationCondition>? conditions,
    List<AutomationActionConfig>? actions,
    AutomationStatus? status,
    bool? isRecurring,
    String? schedule,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? executionCount,
    int? successCount,
    int? failureCount,
    DateTime? lastExecutedAt,
    String? lastError,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Automation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trigger: trigger ?? this.trigger,
      triggerConfig: triggerConfig ?? this.triggerConfig,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      executionCount: executionCount ?? this.executionCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      lastError: lastError ?? this.lastError,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Calcule le taux de succès de l\'automatisation
  double get successRate {
    if (executionCount == 0) return 0.0;
    return (successCount / executionCount) * 100;
  }

  /// Vérifie si l\'automatisation est active
  bool get isActive => status == AutomationStatus.active;

  /// Vérifie si l\'automatisation a des erreurs
  bool get hasErrors => status == AutomationStatus.error || lastError != null;

  @override
  String toString() {
    return 'Automation(id: $id, name: $name, status: ${status.label}, executions: $executionCount)';
  }
}