class ImageAction {
  final String type; // 'url', 'member_page'
  final String? url; // Pour les liens externes
  final String? memberPage; // Pour les pages membres
  final Map<String, dynamic>? parameters; // Paramètres additionnels

  const ImageAction({
    required this.type,
    this.url,
    this.memberPage,
    this.parameters,
  });

  factory ImageAction.fromMap(Map<String, dynamic> map) {
    return ImageAction(
      type: map['type'] ?? 'url',
      url: map['url'],
      memberPage: map['memberPage'],
      parameters: map['parameters'] != null ? Map<String, dynamic>.from(map['parameters']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (url != null) 'url': url,
      if (memberPage != null) 'memberPage': memberPage,
      if (parameters != null) 'parameters': parameters,
    };
  }

  ImageAction copyWith({
    String? type,
    String? url,
    String? memberPage,
    Map<String, dynamic>? parameters,
  }) {
    return ImageAction(
      type: type ?? this.type,
      url: url ?? this.url,
      memberPage: memberPage ?? this.memberPage,
      parameters: parameters ?? this.parameters,
    );
  }
}

class MemberPageDefinition {
  final String key;
  final String name;
  final String description;
  final String route;
  final String? icon;
  final List<String>? supportedParameters;

  const MemberPageDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.route,
    this.icon,
    this.supportedParameters,
  });
}

class MemberPagesRegistry {
  static const List<MemberPageDefinition> pages = [
    MemberPageDefinition(
      key: 'my_groups',
      name: 'Mes Groupes',
      description: 'Affiche la liste des groupes du membre',
      route: '/member/groups',
      icon: 'group',
    ),
    MemberPageDefinition(
      key: 'my_events',
      name: 'Mes Évènements',
      description: 'Affiche les évènements du membre',
      route: '/member/events',
      icon: 'event',
    ),
    MemberPageDefinition(
      key: 'blog_category',
      name: 'Articles de Blog par Catégorie',
      description: 'Articles de blog d\'une catégorie spécifique',
      route: '/blog',
      icon: 'article',
      supportedParameters: ['category'],
    ),
    MemberPageDefinition(
      key: 'prayer_wall',
      name: 'Mur de Prière',
      description: 'Accès au mur de prière',
      route: '/member/prayer-wall',
      icon: 'favorite',
    ),
    MemberPageDefinition(
      key: 'appointments',
      name: 'Rendez-vous',
      description: 'Gestion des rendez-vous',
      route: '/member/appointments',
      icon: 'schedule',
    ),
    MemberPageDefinition(
      key: 'my_services',
      name: 'Mes Services',
      description: 'Services assignés au membre',
      route: '/member/services',
      icon: 'work',
    ),
    MemberPageDefinition(
      key: 'my_forms',
      name: 'Mes Formulaires',
      description: 'Formulaires disponibles pour le membre',
      route: '/member/forms',
      icon: 'assignment',
    ),
    MemberPageDefinition(
      key: 'specific_form',
      name: 'Formulaire Spécifique',
      description: 'Ouvre un formulaire particulier',
      route: '/form',
      icon: 'assignment',
      supportedParameters: ['formId'],
    ),
    MemberPageDefinition(
      key: 'my_tasks',
      name: 'Mes Tâches',
      description: 'Tâches assignées au membre',
      route: '/member/tasks',
      icon: 'task',
    ),
    MemberPageDefinition(
      key: 'member_dashboard',
      name: 'Tableau de Bord Membre',
      description: 'Tableau de bord personnalisé du membre',
      route: '/member/dashboard',
      icon: 'dashboard',
    ),
    MemberPageDefinition(
      key: 'member_profile',
      name: 'Mon Profil',
      description: 'Profil du membre connecté',
      route: '/member/profile',
      icon: 'person',
    ),
    MemberPageDefinition(
      key: 'member_calendar',
      name: 'Mon Calendrier',
      description: 'Calendrier personnel du membre',
      route: '/member/calendar',
      icon: 'calendar_today',
    ),
  ];

  static MemberPageDefinition? findByKey(String key) {
    try {
      return pages.firstWhere((page) => page.key == key);
    } catch (e) {
      return null;
    }
  }

  static List<MemberPageDefinition> get availablePages => pages;
}