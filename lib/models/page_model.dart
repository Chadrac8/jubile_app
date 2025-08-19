import 'package:cloud_firestore/cloud_firestore.dart';
import 'component_action_model.dart';

class CustomPageModel {
  final String id;
  final String title;
  final String description;
  final String slug; // URL personnalisée
  final String? iconName;
  final String? coverImageUrl;
  final int displayOrder;
  final String status; // 'draft', 'published', 'archived'
  final String visibility; // 'public', 'members', 'groups', 'roles'
  final List<String> visibilityTargets; // Group IDs ou Role IDs si restricted
  final DateTime? publishDate;
  final DateTime? unpublishDate;
  final List<PageComponent> components;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;

  CustomPageModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.slug,
    this.iconName,
    this.coverImageUrl,
    this.displayOrder = 0,
    this.status = 'draft',
    this.visibility = 'public',
    this.visibilityTargets = const [],
    this.publishDate,
    this.unpublishDate,
    this.components = const [],
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
  });

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'published':
        return 'Publié';
      case 'archived':
        return 'Archivé';
      default:
        return status;
    }
  }

  String get visibilityLabel {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'members':
        return 'Membres connectés';
      case 'groups':
        return 'Groupes spécifiques';
      case 'roles':
        return 'Rôles spécifiques';
      default:
        return visibility;
    }
  }

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isArchived => status == 'archived';
  
  bool get isVisible {
    if (status != 'published') return false;
    if (publishDate != null && DateTime.now().isBefore(publishDate!)) return false;
    if (unpublishDate != null && DateTime.now().isAfter(unpublishDate!)) return false;
    return true;
  }

  factory CustomPageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomPageModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      slug: data['slug'] ?? '',
      iconName: data['iconName'],
      coverImageUrl: data['coverImageUrl'],
      displayOrder: data['displayOrder'] ?? 0,
      status: data['status'] ?? 'draft',
      visibility: data['visibility'] ?? 'public',
      visibilityTargets: List<String>.from(data['visibilityTargets'] ?? []),
      publishDate: data['publishDate']?.toDate(),
      unpublishDate: data['unpublishDate']?.toDate(),
      components: (data['components'] as List<dynamic>?)
          ?.map((c) => PageComponent.fromMap(c))
          .toList() ?? [],
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'slug': slug,
      'iconName': iconName,
      'coverImageUrl': coverImageUrl,
      'displayOrder': displayOrder,
      'status': status,
      'visibility': visibility,
      'visibilityTargets': visibilityTargets,
      'publishDate': publishDate,
      'unpublishDate': unpublishDate,
      'components': components.map((c) => c.toMap()).toList(),
      'settings': settings,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  CustomPageModel copyWith({
    String? title,
    String? description,
    String? slug,
    String? iconName,
    String? coverImageUrl,
    int? displayOrder,
    String? status,
    String? visibility,
    List<String>? visibilityTargets,
    DateTime? publishDate,
    DateTime? unpublishDate,
    List<PageComponent>? components,
    Map<String, dynamic>? settings,
    DateTime? updatedAt,
    String? lastModifiedBy,
  }) {
    return CustomPageModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      iconName: iconName ?? this.iconName,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      visibilityTargets: visibilityTargets ?? this.visibilityTargets,
      publishDate: publishDate ?? this.publishDate,
      unpublishDate: unpublishDate ?? this.unpublishDate,
      components: components ?? this.components,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class PageComponent {
  final String id;
  final String type; // 'text', 'image', 'button', 'video', 'list', 'form', 'scripture', 'banner', 'map', 'grid_container', 'webview'
  final String name;
  final Map<String, dynamic> data;
  final Map<String, dynamic> styling;
  final Map<String, dynamic> settings;
  final List<String> visibleForRoles;
  final List<String> visibleForGroups;
  final DateTime? visibleFromDate;
  final DateTime? visibleToDate;
  final int order;
  final ComponentAction? action; // Nouvelle propriété pour les actions cliquables
  final List<PageComponent> children; // Composants enfants pour les containers

  PageComponent({
    required this.id,
    required this.type,
    required this.name,
    this.data = const {},
    this.styling = const {},
    this.settings = const {},
    this.visibleForRoles = const [],
    this.visibleForGroups = const [],
    this.visibleFromDate,
    this.visibleToDate,
    required this.order,
    this.action,
    this.children = const [],
  });

  String get typeLabel {
    switch (type) {
      case 'text':
        return 'Texte';
      case 'image':
        return 'Image';
      case 'button':
        return 'Bouton';
      case 'video':
        return 'Vidéo';
      case 'list':
        return 'Liste';
      case 'form':
        return 'Formulaire';
      case 'scripture':
        return 'Verset biblique';
      case 'banner':
        return 'Bannière';
      case 'map':
        return 'Carte';
      case 'grid_container':
        return 'Grid Container';
      default:
        return type;
    }
  }

  bool isVisibleForUser(List<String> userRoles, List<String> userGroups) {
    // Vérifier les rôles
    if (visibleForRoles.isNotEmpty && 
        !visibleForRoles.any((role) => userRoles.contains(role))) {
      return false;
    }

    // Vérifier les groupes
    if (visibleForGroups.isNotEmpty && 
        !visibleForGroups.any((group) => userGroups.contains(group))) {
      return false;
    }

    // Vérifier les dates
    final now = DateTime.now();
    if (visibleFromDate != null && now.isBefore(visibleFromDate!)) {
      return false;
    }
    if (visibleToDate != null && now.isAfter(visibleToDate!)) {
      return false;
    }

    return true;
  }

  factory PageComponent.fromMap(Map<String, dynamic> map) {
    return PageComponent(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      styling: Map<String, dynamic>.from(map['styling'] ?? {}),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      visibleForRoles: List<String>.from(map['visibleForRoles'] ?? []),
      visibleForGroups: List<String>.from(map['visibleForGroups'] ?? []),
      visibleFromDate: map['visibleFromDate']?.toDate(),
      visibleToDate: map['visibleToDate']?.toDate(),
      order: map['order'] ?? 0,
      action: map['action'] != null 
          ? ComponentAction.fromJson(Map<String, dynamic>.from(map['action']))
          : null,
      children: (map['children'] as List<dynamic>?)
          ?.map((c) => PageComponent.fromMap(c))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'data': data,
      'styling': styling,
      'settings': settings,
      'visibleForRoles': visibleForRoles,
      'visibleForGroups': visibleForGroups,
      'visibleFromDate': visibleFromDate,
      'visibleToDate': visibleToDate,
      'order': order,
      'action': action?.toJson(),
      'children': children.map((c) => c.toMap()).toList(),
    };
  }

  PageComponent copyWith({
    String? name,
    Map<String, dynamic>? data,
    Map<String, dynamic>? styling,
    Map<String, dynamic>? settings,
    List<String>? visibleForRoles,
    List<String>? visibleForGroups,
    DateTime? visibleFromDate,
    DateTime? visibleToDate,
    int? order,
    ComponentAction? action,
    List<PageComponent>? children,
  }) {
    return PageComponent(
      id: id,
      type: type,
      name: name ?? this.name,
      data: data ?? this.data,
      styling: styling ?? this.styling,
      settings: settings ?? this.settings,
      visibleForRoles: visibleForRoles ?? this.visibleForRoles,
      visibleForGroups: visibleForGroups ?? this.visibleForGroups,
      visibleFromDate: visibleFromDate ?? this.visibleFromDate,
      visibleToDate: visibleToDate ?? this.visibleToDate,
      order: order ?? this.order,
      action: action ?? this.action,
      children: children ?? this.children,
    );
  }
}

class PageTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? iconName;
  final String? previewImageUrl;
  final List<PageComponent> components;
  final Map<String, dynamic> defaultSettings;
  final bool isBuiltIn;
  final DateTime createdAt;
  final String? createdBy;

  PageTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.iconName,
    this.previewImageUrl,
    this.components = const [],
    this.defaultSettings = const {},
    this.isBuiltIn = false,
    required this.createdAt,
    this.createdBy,
  });

  factory PageTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PageTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      iconName: data['iconName'],
      previewImageUrl: data['previewImageUrl'],
      components: (data['components'] as List<dynamic>?)
          ?.map((c) => PageComponent.fromMap(c))
          .toList() ?? [],
      defaultSettings: Map<String, dynamic>.from(data['defaultSettings'] ?? {}),
      isBuiltIn: data['isBuiltIn'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'iconName': iconName,
      'previewImageUrl': previewImageUrl,
      'components': components.map((c) => c.toMap()).toList(),
      'defaultSettings': defaultSettings,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}

class PageStatistics {
  final String pageId;
  final int totalViews;
  final int uniqueViews;
  final Map<String, int> viewsByDate;
  final Map<String, int> viewsByRole;
  final Map<String, int> componentInteractions;
  final DateTime lastUpdated;

  PageStatistics({
    required this.pageId,
    required this.totalViews,
    required this.uniqueViews,
    required this.viewsByDate,
    required this.viewsByRole,
    required this.componentInteractions,
    required this.lastUpdated,
  });

  factory PageStatistics.fromMap(Map<String, dynamic> data) {
    return PageStatistics(
      pageId: data['pageId'] ?? '',
      totalViews: data['totalViews'] ?? 0,
      uniqueViews: data['uniqueViews'] ?? 0,
      viewsByDate: Map<String, int>.from(data['viewsByDate'] ?? {}),
      viewsByRole: Map<String, int>.from(data['viewsByRole'] ?? {}),
      componentInteractions: Map<String, int>.from(data['componentInteractions'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(data['lastUpdated'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pageId': pageId,
      'totalViews': totalViews,
      'uniqueViews': uniqueViews,
      'viewsByDate': viewsByDate,
      'viewsByRole': viewsByRole,
      'componentInteractions': componentInteractions,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}