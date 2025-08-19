class DashboardWidgetModel {
  final String id;
  final String title;
  final String type; // 'stat', 'chart', 'list', 'card'
  final String category; // 'persons', 'groups', 'events', 'services', etc.
  final bool isVisible;
  final int order;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardWidgetModel({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    this.isVisible = true,
    this.order = 0,
    this.config = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'category': category,
      'isVisible': isVisible,
      'order': order,
      'config': config,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DashboardWidgetModel.fromMap(Map<String, dynamic> map, String id) {
    return DashboardWidgetModel(
      id: id,
      title: map['title'] ?? '',
      type: map['type'] ?? 'stat',
      category: map['category'] ?? '',
      isVisible: map['isVisible'] ?? true,
      order: map['order'] ?? 0,
      config: Map<String, dynamic>.from(map['config'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  DashboardWidgetModel copyWith({
    String? title,
    String? type,
    String? category,
    bool? isVisible,
    int? order,
    Map<String, dynamic>? config,
    DateTime? updatedAt,
  }) {
    return DashboardWidgetModel(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
      config: config ?? this.config,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class DashboardStatModel {
  final String label;
  final String value;
  final String? subtitle;
  final String? icon;
  final String? color;
  final String? trend; // 'up', 'down', 'stable'
  final String? trendValue;

  DashboardStatModel({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.trend,
    this.trendValue,
  });
}

class DashboardChartModel {
  final String title;
  final String type; // 'pie', 'bar', 'line'
  final List<DashboardChartDataPoint> data;

  DashboardChartModel({
    required this.title,
    required this.type,
    required this.data,
  });
}

class DashboardChartDataPoint {
  final String label;
  final double value;
  final String? color;

  DashboardChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

class DashboardListModel {
  final String title;
  final List<DashboardListItem> items;
  final String? actionLabel;
  final Function()? onAction;

  DashboardListModel({
    required this.title,
    required this.items,
    this.actionLabel,
    this.onAction,
  });
}

class DashboardListItem {
  final String title;
  final String? subtitle;
  final String? icon;
  final String? color;
  final Function()? onTap;

  DashboardListItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });
}

// Widgets par défaut disponibles
class DefaultDashboardWidgets {
  static List<DashboardWidgetModel> getDefaultWidgets() {
    final now = DateTime.now();
    return [
      // Statistiques des personnes
      DashboardWidgetModel(
        id: 'persons_total',
        title: 'Total des Membres',
        type: 'stat',
        category: 'persons',
        order: 1,
        config: {
          'icon': 'people',
          'color': '#2196F3',
          'showTrend': true,
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'persons_active',
        title: 'Membres Actifs',
        type: 'stat',
        category: 'persons',
        order: 2,
        config: {
          'icon': 'person_check',
          'color': '#4CAF50',
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'persons_new_this_month',
        title: 'Nouveaux ce Mois',
        type: 'stat',
        category: 'persons',
        order: 3,
        config: {
          'icon': 'person_add',
          'color': '#FF9800',
          'period': 'current_month',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Statistiques des groupes
      DashboardWidgetModel(
        id: 'groups_total',
        title: 'Total des Groupes',
        type: 'stat',
        category: 'groups',
        order: 4,
        config: {
          'icon': 'groups',
          'color': '#9C27B0',
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'groups_active',
        title: 'Groupes Actifs',
        type: 'stat',
        category: 'groups',
        order: 5,
        config: {
          'icon': 'group_work',
          'color': '#673AB7',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Statistiques des événements
      DashboardWidgetModel(
        id: 'events_upcoming',
        title: 'Événements à Venir',
        type: 'stat',
        category: 'events',
        order: 6,
        config: {
          'icon': 'event',
          'color': '#3F51B5',
          'period': 'upcoming',
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'events_this_month',
        title: 'Événements ce Mois',
        type: 'stat',
        category: 'events',
        order: 7,
        config: {
          'icon': 'event_available',
          'color': '#00BCD4',
          'period': 'current_month',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Services
      DashboardWidgetModel(
        id: 'services_upcoming',
        title: 'Services à Venir',
        type: 'stat',
        category: 'services',
        order: 8,
        config: {
          'icon': 'church',
          'color': '#795548',
          'period': 'upcoming',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Tâches
      DashboardWidgetModel(
        id: 'tasks_pending',
        title: 'Tâches en Cours',
        type: 'stat',
        category: 'tasks',
        order: 9,
        config: {
          'icon': 'task',
          'color': '#FF5722',
          'status': 'pending',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Rendez-vous
      DashboardWidgetModel(
        id: 'appointments_today',
        title: 'RDV Aujourd\'hui',
        type: 'stat',
        category: 'appointments',
        order: 10,
        config: {
          'icon': 'schedule',
          'color': '#607D8B',
          'period': 'today',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Blog
      DashboardWidgetModel(
        id: 'blog_posts_published',
        title: 'Articles Publiés',
        type: 'stat',
        category: 'blog',
        order: 11,
        config: {
          'icon': 'article',
          'color': '#E91E63',
          'showTrend': true,
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'blog_posts_draft',
        title: 'Articles en Brouillon',
        type: 'stat',
        category: 'blog',
        order: 12,
        config: {
          'icon': 'drafts',
          'color': '#FF9800',
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'blog_comments_total',
        title: 'Commentaires Total',
        type: 'stat',
        category: 'blog',
        order: 13,
        config: {
          'icon': 'comment',
          'color': '#00BCD4',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Graphiques
      DashboardWidgetModel(
        id: 'persons_by_age',
        title: 'Répartition par Âge',
        type: 'chart',
        category: 'persons',
        order: 14,
        config: {
          'chartType': 'pie',
          'color': '#2196F3',
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'groups_by_type',
        title: 'Groupes par Type',
        type: 'chart',
        category: 'groups',
        order: 15,
        config: {
          'chartType': 'bar',
          'color': '#9C27B0',
        },
        createdAt: now,
        updatedAt: now,
      ),
      
      // Listes
      DashboardWidgetModel(
        id: 'recent_members',
        title: 'Membres Récents',
        type: 'list',
        category: 'persons',
        order: 16,
        config: {
          'limit': 5,
          'sortBy': 'created_desc',
        },
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetModel(
        id: 'upcoming_events',
        title: 'Prochains Événements',
        type: 'list',
        category: 'events',
        order: 17,
        config: {
          'limit': 5,
          'sortBy': 'date_asc',
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}