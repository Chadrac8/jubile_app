import 'automation.dart';

/// Catégorie de template d\'automatisation
enum TemplateCategory {
  welcome('welcome', 'Accueil', 'Automatisations pour accueillir de nouveaux membres'),
  followUp('follow_up', 'Suivi', 'Automatisations de suivi et relance'),
  communication('communication', 'Communication', 'Automatisations de communication'),
  events('events', 'Événements', 'Automatisations liées aux événements'),
  services('services', 'Services', 'Automatisations pour les services religieux'),
  administration('administration', 'Administration', 'Automatisations administratives'),
  pastoral('pastoral', 'Pastoral', 'Automatisations pour le soin pastoral'),
  growth('growth', 'Croissance', 'Automatisations pour la croissance de l\'église');

  const TemplateCategory(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;
}

/// Template prédéfini d\'automatisation
class AutomationTemplate {
  final String id;
  final String name;
  final String description;
  final TemplateCategory category;
  final AutomationTrigger trigger;
  final Map<String, dynamic> triggerConfig;
  final List<AutomationCondition> conditions;
  final List<AutomationActionConfig> actions;
  final List<String> tags;
  final bool isPopular;
  final int usageCount;
  final String iconName;
  final String? instructionsMarkdown;

  const AutomationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.trigger,
    this.triggerConfig = const {},
    this.conditions = const [],
    this.actions = const [],
    this.tags = const [],
    this.isPopular = false,
    this.usageCount = 0,
    this.iconName = 'auto_awesome',
    this.instructionsMarkdown,
  });

  /// Crée une automatisation à partir de ce template
  Automation createAutomation({
    required String createdBy,
    String? customName,
    String? customDescription,
  }) {
    return Automation(
      name: customName ?? name,
      description: customDescription ?? description,
      trigger: trigger,
      triggerConfig: Map<String, dynamic>.from(triggerConfig),
      conditions: conditions.map((c) => AutomationCondition(
        field: c.field,
        operator: c.operator,
        value: c.value,
        logicalOperator: c.logicalOperator,
      )).toList(),
      actions: actions.map((a) => AutomationActionConfig(
        action: a.action,
        parameters: Map<String, dynamic>.from(a.parameters),
        delayMinutes: a.delayMinutes,
        enabled: a.enabled,
      )).toList(),
      status: AutomationStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      tags: List<String>.from(tags),
    );
  }
}

/// Collection de templates prédéfinis
class AutomationTemplates {
  static final List<AutomationTemplate> _templates = [
    // 1. Accueil nouveau membre
    AutomationTemplate(
      id: 'welcome_new_member',
      name: 'Accueil nouveau membre',
      description: 'Envoie un email de bienvenue et assigne un mentor quand une nouvelle personne est ajoutée',
      category: TemplateCategory.welcome,
      trigger: AutomationTrigger.personAdded,
      actions: [
        AutomationActionConfig(
          action: AutomationAction.sendEmail,
          parameters: {
            'template': 'welcome_new_member',
            'subject': 'Bienvenue dans notre église !',
            'includeChurchInfo': true,
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.assignTask,
          parameters: {
            'title': 'Contacter nouveau membre: {{person.name}}',
            'description': 'Prendre contact avec le nouveau membre dans les 48h',
            'assignToRole': 'mentor',
            'dueInDays': 2,
          },
          delayMinutes: 30,
        ),
        AutomationActionConfig(
          action: AutomationAction.logActivity,
          parameters: {
            'type': 'welcome_sent',
            'description': 'Email de bienvenue envoyé automatiquement',
          },
        ),
      ],
      tags: ['bienvenue', 'nouveau', 'mentor'],
      isPopular: true,
      usageCount: 245,
      iconName: 'waving_hand',
      instructionsMarkdown: '''
## Configuration requise
- Template d\'email "welcome_new_member" configuré
- Rôle "mentor" avec des utilisateurs assignés
- Champs personnalisés activés sur les personnes

## Personnalisations possibles
- Modifier le délai avant assignation de tâche
- Ajouter des conditions (âge, statut familial, etc.)
- Personnaliser le template d\'email
''',
    ),

    // 2. Suivi absence service
    AutomationTemplate(
      id: 'follow_up_service_absence',
      name: 'Suivi absence service',
      description: 'Crée une tâche de suivi pastoral après 3 absences consécutives aux services',
      category: TemplateCategory.pastoral,
      trigger: AutomationTrigger.serviceAssigned,
      conditions: [
        AutomationCondition(
          field: 'consecutive_absences',
          operator: 'greater_than',
          value: 2,
        ),
      ],
      actions: [
        AutomationActionConfig(
          action: AutomationAction.assignTask,
          parameters: {
            'title': 'Suivi pastoral: {{person.name}}',
            'description': 'Membre absent depuis 3 services consécutifs. Prendre contact pour s\'assurer que tout va bien.',
            'assignToRole': 'pasteur',
            'priority': 'high',
            'category': 'pastoral_care',
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.sendNotification,
          parameters: {
            'message': '{{person.name}} nécessite un suivi pastoral (3+ absences)',
            'recipients': ['pasteur', 'diacre'],
          },
        ),
      ],
      tags: ['pastoral', 'suivi', 'absence'],
      isPopular: true,
      usageCount: 89,
      iconName: 'favorite_border',
    ),

    // 3. Rappel événement
    AutomationTemplate(
      id: 'event_reminder',
      name: 'Rappel événement',
      description: 'Envoie un rappel automatique 24h avant un événement aux inscrits',
      category: TemplateCategory.events,
      trigger: AutomationTrigger.dateScheduled,
      triggerConfig: {
        'hoursBeforeEvent': 24,
        'eventTypes': ['conference', 'formation', 'sortie'],
      },
      actions: [
        AutomationActionConfig(
          action: AutomationAction.sendEmail,
          parameters: {
            'template': 'event_reminder',
            'subject': 'Rappel: {{event.name}} demain',
            'includeEventDetails': true,
            'includeDirections': true,
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.sendNotification,
          parameters: {
            'title': 'Événement demain',
            'message': '{{event.name}} a lieu demain à {{event.time}}',
            'includeMapLink': true,
          },
        ),
      ],
      tags: ['événement', 'rappel', 'notification'],
      isPopular: true,
      usageCount: 156,
      iconName: 'schedule',
    ),

    // 4. Suivi demande de prière
    AutomationTemplate(
      id: 'prayer_request_follow_up',
      name: 'Suivi demande de prière',
      description: 'Programme un suivi automatique 1 semaine après une demande de prière',
      category: TemplateCategory.pastoral,
      trigger: AutomationTrigger.prayerRequest,
      actions: [
        AutomationActionConfig(
          action: AutomationAction.logActivity,
          parameters: {
            'type': 'prayer_received',
            'description': 'Demande de prière reçue: {{prayer.subject}}',
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.assignTask,
          parameters: {
            'title': 'Suivi prière: {{prayer.subject}}',
            'description': 'Prendre des nouvelles concernant la demande de prière',
            'assignToRole': 'pasteur',
            'dueInDays': 7,
          },
          delayMinutes: 10080, // 7 jours
        ),
        AutomationActionConfig(
          action: AutomationAction.sendEmail,
          parameters: {
            'template': 'prayer_confirmation',
            'subject': 'Votre demande de prière a été reçue',
            'personalMessage': true,
          },
        ),
      ],
      tags: ['prière', 'pastoral', 'suivi'],
      usageCount: 78,
      iconName: 'volunteer_activism',
    ),

    // 5. Anniversaire membre
    AutomationTemplate(
      id: 'birthday_greeting',
      name: 'Vœux d\'anniversaire',
      description: 'Envoie automatiquement des vœux d\'anniversaire aux membres',
      category: TemplateCategory.communication,
      trigger: AutomationTrigger.dateScheduled,
      triggerConfig: {
        'scheduleType': 'birthday',
        'sendTime': '09:00',
      },
      actions: [
        AutomationActionConfig(
          action: AutomationAction.sendEmail,
          parameters: {
            'template': 'birthday_wishes',
            'subject': 'Joyeux anniversaire {{person.firstName}} !',
            'personalMessage': true,
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.logActivity,
          parameters: {
            'type': 'birthday_wishes_sent',
            'description': 'Vœux d\'anniversaire envoyés automatiquement',
          },
        ),
      ],
      tags: ['anniversaire', 'vœux', 'communication'],
      usageCount: 203,
      iconName: 'cake',
    ),

    // 6. Intégration nouveau groupe
    AutomationTemplate(
      id: 'new_group_member_integration',
      name: 'Intégration nouveau membre de groupe',
      description: 'Actions d\'intégration quand quelqu\'un rejoint un groupe',
      category: TemplateCategory.welcome,
      trigger: AutomationTrigger.groupJoined,
      actions: [
        AutomationActionConfig(
          action: AutomationAction.sendEmail,
          parameters: {
            'template': 'group_welcome',
            'subject': 'Bienvenue dans le groupe {{group.name}}',
            'includeGroupInfo': true,
            'includeLeaderContact': true,
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.assignTask,
          parameters: {
            'title': 'Accueillir nouveau membre: {{person.name}}',
            'description': 'Prendre contact avec le nouveau membre du groupe',
            'assignTo': '{{group.leader}}',
            'dueInDays': 3,
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.updateField,
          parameters: {
            'field': 'integration_status',
            'value': 'in_progress',
            'target': 'person',
          },
        ),
      ],
      tags: ['groupe', 'intégration', 'nouveau'],
      usageCount: 134,
      iconName: 'group_add',
    ),

    // 7. Rappel tâche en retard
    AutomationTemplate(
      id: 'overdue_task_reminder',
      name: 'Rappel tâche en retard',
      description: 'Envoie des rappels pour les tâches en retard',
      category: TemplateCategory.administration,
      trigger: AutomationTrigger.dateScheduled,
      triggerConfig: {
        'scheduleType': 'overdue_tasks',
        'checkFrequency': 'daily',
      },
      conditions: [
        AutomationCondition(
          field: 'task.status',
          operator: 'not_equals',
          value: 'completed',
        ),
        AutomationCondition(
          field: 'task.due_date',
          operator: 'less_than',
          value: 'today',
          logicalOperator: 'and',
        ),
      ],
      actions: [
        AutomationActionConfig(
          action: AutomationAction.sendNotification,
          parameters: {
            'title': 'Tâche en retard',
            'message': '{{task.title}} était due le {{task.dueDate}}',
            'recipient': '{{task.assignedTo}}',
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.sendNotification,
          parameters: {
            'title': 'Tâche en retard dans votre équipe',
            'message': '{{task.title}} assignée à {{task.assignedTo}} est en retard',
            'recipient': '{{task.supervisor}}',
          },
          delayMinutes: 60,
        ),
      ],
      tags: ['tâche', 'retard', 'rappel'],
      usageCount: 67,
      iconName: 'schedule_send',
    ),

    // 8. Suivi visite première fois
    AutomationTemplate(
      id: 'first_time_visitor_follow_up',
      name: 'Suivi visiteur première fois',
      description: 'Processus complet de suivi pour les visiteurs première fois',
      category: TemplateCategory.welcome,
      trigger: AutomationTrigger.personAdded,
      conditions: [
        AutomationCondition(
          field: 'person.visitor_status',
          operator: 'equals',
          value: 'first_time',
        ),
      ],
      actions: [
        AutomationActionConfig(
          action: AutomationAction.sendEmail,
          parameters: {
            'template': 'first_visit_thanks',
            'subject': 'Merci pour votre visite !',
            'includeNextSteps': true,
          },
        ),
        AutomationActionConfig(
          action: AutomationAction.assignTask,
          parameters: {
            'title': 'Appeler visiteur première fois: {{person.name}}',
            'description': 'Contacter dans les 24h pour remercier et répondre aux questions',
            'assignToRole': 'accueil',
            'dueInHours': 24,
            'priority': 'high',
          },
          delayMinutes: 120, // 2h après la visite
        ),
        AutomationActionConfig(
          action: AutomationAction.scheduleFollowUp,
          parameters: {
            'type': 'second_visit_invitation',
            'delayDays': 7,
            'message': 'Inviter pour le prochain dimanche',
          },
          delayMinutes: 10080, // 1 semaine
        ),
      ],
      tags: ['visiteur', 'première fois', 'accueil'],
      isPopular: true,
      usageCount: 189,
      iconName: 'how_to_reg',
    ),
  ];

  /// Obtient tous les templates
  static List<AutomationTemplate> get all => List.unmodifiable(_templates);

  /// Obtient les templates par catégorie
  static List<AutomationTemplate> getByCategory(TemplateCategory category) {
    return _templates.where((t) => t.category == category).toList();
  }

  /// Obtient les templates populaires
  static List<AutomationTemplate> get popular {
    return _templates.where((t) => t.isPopular).toList();
  }

  /// Obtient un template par ID
  static AutomationTemplate? getById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Recherche des templates
  static List<AutomationTemplate> search(String query) {
    if (query.isEmpty) return all;
    
    final lowerQuery = query.toLowerCase();
    return _templates.where((t) => 
      t.name.toLowerCase().contains(lowerQuery) ||
      t.description.toLowerCase().contains(lowerQuery) ||
      t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  /// Obtient les templates par tags
  static List<AutomationTemplate> getByTags(List<String> tags) {
    return _templates.where((t) => 
      tags.any((tag) => t.tags.contains(tag))
    ).toList();
  }

  /// Obtient toutes les catégories utilisées
  static List<TemplateCategory> get categories {
    return TemplateCategory.values;
  }

  /// Obtient tous les tags disponibles
  static List<String> get allTags {
    final tags = <String>{};
    for (final template in _templates) {
      tags.addAll(template.tags);
    }
    return tags.toList()..sort();
  }
}