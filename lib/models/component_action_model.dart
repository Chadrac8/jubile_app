class ComponentAction {
  final String id;
  final ComponentActionType type;
  final String label;
  final String? url;
  final MemberPageType? memberPageType;
  final String? blogCategory;
  final String? formId;
  final String? customPageId;
  
  ComponentAction({
    required this.id,
    required this.type,
    required this.label,
    this.url,
    this.memberPageType,
    this.blogCategory,
    this.formId,
    this.customPageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'url': url,
      'memberPageType': memberPageType?.name,
      'blogCategory': blogCategory,
      'formId': formId,
      'customPageId': customPageId,
    };
  }

  factory ComponentAction.fromJson(Map<String, dynamic> json) {
    return ComponentAction(
      id: json['id'] ?? '',
      type: ComponentActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ComponentActionType.none,
      ),
      label: json['label'] ?? '',
      url: json['url'],
      memberPageType: json['memberPageType'] != null
          ? MemberPageType.values.firstWhere(
              (e) => e.name == json['memberPageType'],
              orElse: () => MemberPageType.dashboard,
            )
          : null,
      blogCategory: json['blogCategory'],
      formId: json['formId'],
      customPageId: json['customPageId'],
    );
  }

  ComponentAction copyWith({
    String? id,
    ComponentActionType? type,
    String? label,
    String? url,
    MemberPageType? memberPageType,
    String? blogCategory,
    String? formId,
    String? customPageId,
  }) {
    return ComponentAction(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      url: url ?? this.url,
      memberPageType: memberPageType ?? this.memberPageType,
      blogCategory: blogCategory ?? this.blogCategory,
      formId: formId ?? this.formId,
      customPageId: customPageId ?? this.customPageId,
    );
  }
}

enum ComponentActionType {
  none,
  externalUrl,
  internalUrl,
  memberPage,
  customPage,
  blogCategory,
  specificForm,
}

enum MemberPageType {
  dashboard,
  groups,
  events,

  forms,
  prayerWall,
  appointments,
  services,
  blog,
  profile,
  notifications,
  calendar,
  settings,
  tasks,
  reports,
}

extension MemberPageTypeExtension on MemberPageType {
  String get displayName {
    switch (this) {
      case MemberPageType.dashboard:
        return 'Tableau de bord';
      case MemberPageType.groups:
        return 'Mes Groupes';
      case MemberPageType.events:
        return 'Mes Évènements';

      case MemberPageType.forms:
        return 'Formulaires';
      case MemberPageType.prayerWall:
        return 'Mur de prière';
      case MemberPageType.appointments:
        return 'Rendez-vous';
      case MemberPageType.services:
        return 'Services';
      case MemberPageType.blog:
        return 'Articles du blog';
      case MemberPageType.profile:
        return 'Mon Profil';
      case MemberPageType.notifications:
        return 'Notifications';
      case MemberPageType.calendar:
        return 'Calendrier';
      case MemberPageType.settings:
        return 'Paramètres';
      case MemberPageType.tasks:
        return 'Tâches';
      case MemberPageType.reports:
        return 'Rapports';
    }
  }

  String get routePath {
    switch (this) {
      case MemberPageType.dashboard:
        return '/member/dashboard';
      case MemberPageType.groups:
        return '/member/groups';
      case MemberPageType.events:
        return '/member/events';

      case MemberPageType.forms:
        return '/member/forms';
      case MemberPageType.prayerWall:
        return '/member/prayer-wall';
      case MemberPageType.appointments:
        return '/member/appointments';
      case MemberPageType.services:
        return '/member/services';
      case MemberPageType.blog:
        return '/blog';
      case MemberPageType.profile:
        return '/member/profile';
      case MemberPageType.notifications:
        return '/member/notifications';
      case MemberPageType.calendar:
        return '/member/calendar';
      case MemberPageType.settings:
        return '/member/settings';
      case MemberPageType.tasks:
        return '/member/tasks';
      case MemberPageType.reports:
        return '/member/reports';
    }
  }
}