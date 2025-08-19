import 'package:flutter/material.dart';

/// Modèle pour un widget d'accueil personnalisable
class HomeWidgetModel {
  final String id;
  final String type;
  final String title;
  final String? description;
  final Map<String, dynamic> configuration;
  final bool isVisible;
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HomeWidgetModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.configuration,
    this.isVisible = true,
    required this.order,
    required this.createdAt,
    this.updatedAt,
  });

  factory HomeWidgetModel.fromMap(Map<String, dynamic> map) {
    return HomeWidgetModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      configuration: Map<String, dynamic>.from(map['configuration'] ?? {}),
      isVisible: map['isVisible'] ?? true,
      order: map['order'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'configuration': configuration,
      'isVisible': isVisible,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  HomeWidgetModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    Map<String, dynamic>? configuration,
    bool? isVisible,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeWidgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      configuration: configuration ?? this.configuration,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'configuration': configuration,
      'isVisible': isVisible,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HomeWidgetModel.fromJson(Map<String, dynamic> json) {
    return HomeWidgetModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      configuration: Map<String, dynamic>.from(json['configuration'] as Map),
      isVisible: json['isVisible'] as bool,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String));
  }
}

/// Types de widgets disponibles pour l'accueil
enum HomeWidgetType {
  quickAction('quick_action', 'Action rapide', 'Bouton d\'action avec redirection'),
  newsCard('news_card', 'Carte actualité', 'Affichage d\'une actualité'),
  eventCard('event_card', 'Carte événement', 'Mise en avant d\'un événement'),
  verseCard('verse_card', 'Carte verset', 'Verset du jour personnalisé'),
  sermonCard('sermon_card', 'Carte prédication', 'Prédication mise en avant'),
  donationCard('donation_card', 'Carte don', 'Widget de don'),
  linkCard('link_card', 'Carte lien', 'Lien vers une ressource externe'),
  textCard('text_card', 'Carte texte', 'Texte libre avec formatage'),
  imageCard('image_card', 'Carte image', 'Image avec lien optionnel'),
  moduleCard('module_card', 'Carte module', 'Accès direct à un module'),
  customHtml('custom_html', 'HTML personnalisé', 'Contenu HTML libre');

  const HomeWidgetType(this.value, this.label, this.description);
  
  final String value;
  final String label;
  final String description;

  static HomeWidgetType fromValue(String value) {
    return HomeWidgetType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => HomeWidgetType.textCard);
  }
}

/// Modèle pour les actions de redirection
class HomeActionModel {
  final String type; // 'internal', 'external', 'module', 'page'
  final String? route;
  final String? url;
  final String? moduleId;
  final String? pageId;
  final Map<String, dynamic>? parameters;

  HomeActionModel({
    required this.type,
    this.route,
    this.url,
    this.moduleId,
    this.pageId,
    this.parameters,
  });

  factory HomeActionModel.fromMap(Map<String, dynamic> map) {
    return HomeActionModel(
      type: map['type'] ?? 'internal',
      route: map['route'],
      url: map['url'],
      moduleId: map['moduleId'],
      pageId: map['pageId'],
      parameters: map['parameters'] != null 
          ? Map<String, dynamic>.from(map['parameters']) 
          : null);
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'route': route,
      'url': url,
      'moduleId': moduleId,
      'pageId': pageId,
      'parameters': parameters,
    };
  }
}

/// Configuration étendue de l'accueil
class ExtendedHomeConfigModel {
  final String id;
  final String? coverImageUrl;
  final String welcomeTitle;
  final String welcomeSubtitle;
  final bool showGreeting;
  final List<HomeWidgetModel> widgets;
  final Map<String, dynamic> globalSettings;
  final DateTime lastUpdated;
  final String? lastUpdatedBy;

  ExtendedHomeConfigModel({
    required this.id,
    this.coverImageUrl,
    this.welcomeTitle = 'Jubilé Tabernacle France',
    this.welcomeSubtitle = 'Votre communauté spirituelle',
    this.showGreeting = true,
    this.widgets = const [],
    this.globalSettings = const {},
    required this.lastUpdated,
    this.lastUpdatedBy,
  });

  factory ExtendedHomeConfigModel.fromMap(Map<String, dynamic> map) {
    return ExtendedHomeConfigModel(
      id: map['id'] ?? 'main',
      coverImageUrl: map['coverImageUrl'],
      welcomeTitle: map['welcomeTitle'] ?? 'Jubilé Tabernacle France',
      welcomeSubtitle: map['welcomeSubtitle'] ?? 'Votre communauté spirituelle',
      showGreeting: map['showGreeting'] ?? true,
      widgets: (map['widgets'] as List<dynamic>?)
          ?.map((widget) => HomeWidgetModel.fromMap(widget))
          .toList() ?? [],
      globalSettings: Map<String, dynamic>.from(map['globalSettings'] ?? {}),
      lastUpdated: DateTime.parse(map['lastUpdated']),
      lastUpdatedBy: map['lastUpdatedBy']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coverImageUrl': coverImageUrl,
      'welcomeTitle': welcomeTitle,
      'welcomeSubtitle': welcomeSubtitle,
      'showGreeting': showGreeting,
      'widgets': widgets.map((widget) => widget.toMap()).toList(),
      'globalSettings': globalSettings,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastUpdatedBy': lastUpdatedBy,
    };
  }

  ExtendedHomeConfigModel copyWith({
    String? id,
    String? coverImageUrl,
    String? welcomeTitle,
    String? welcomeSubtitle,
    bool? showGreeting,
    List<HomeWidgetModel>? widgets,
    Map<String, dynamic>? globalSettings,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
  }) {
    return ExtendedHomeConfigModel(
      id: id ?? this.id,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      welcomeTitle: welcomeTitle ?? this.welcomeTitle,
      welcomeSubtitle: welcomeSubtitle ?? this.welcomeSubtitle,
      showGreeting: showGreeting ?? this.showGreeting,
      widgets: widgets ?? this.widgets,
      globalSettings: globalSettings ?? this.globalSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coverImageUrl': coverImageUrl,
      'welcomeTitle': welcomeTitle,
      'welcomeSubtitle': welcomeSubtitle,
      'showGreeting': showGreeting,
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'globalSettings': globalSettings,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastUpdatedBy': lastUpdatedBy,
    };
  }

  factory ExtendedHomeConfigModel.fromJson(Map<String, dynamic> json) {
    return ExtendedHomeConfigModel(
      id: json['id'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      welcomeTitle: json['welcomeTitle'] as String,
      welcomeSubtitle: json['welcomeSubtitle'] as String,
      showGreeting: json['showGreeting'] as bool,
      widgets: (json['widgets'] as List)
          .map((w) => HomeWidgetModel.fromJson(w as Map<String, dynamic>))
          .toList(),
      globalSettings: Map<String, dynamic>.from(json['globalSettings'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      lastUpdatedBy: json['lastUpdatedBy'] as String?);
  }

  factory ExtendedHomeConfigModel.defaultConfig() {
    return ExtendedHomeConfigModel(
      id: 'default',
      coverImageUrl: null,
      welcomeTitle: 'Jubilé Tabernacle France',
      welcomeSubtitle: 'Votre communauté spirituelle',
      showGreeting: true,
      widgets: [
        HomeWidgetModel(
          id: 'welcome_quick_action',
          type: 'quick_action',
          title: 'Nouveaux membres',
          description: 'Bienvenue dans notre communauté',
          configuration: {
            'buttonText': 'Découvrir',
            'link': '/member/welcome',
            'icon': Icons.group.codePoint,
            'color': Colors.blue.toARGB32(),
          },
          isVisible: true,
          order: 0,
          createdAt: DateTime.now()),
        HomeWidgetModel(
          id: 'verse_of_day',
          type: 'verse_card',
          title: 'Verset du jour',
          description: 'Méditation quotidienne',
          configuration: {
            'content': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
            'author': 'Jean 3:16',
          },
          isVisible: true,
          order: 1,
          createdAt: DateTime.now()),
      ],
      globalSettings: {
        'defaultDarkMode': false,
        'reducedAnimations': false,
        'autoRefresh': true,
      },
      lastUpdated: DateTime.now(),
      lastUpdatedBy: null);
  }
}
