import 'package:cloud_firestore/cloud_firestore.dart';

class PageConfig {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String route;
  final bool isEnabledForMembers;
  final bool isPrimaryInBottomNav;
  final int order;
  final String slug;
  final String visibility;
  final List<String> visibilityTargets;

  PageConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.route,
    this.isEnabledForMembers = false,
    this.isPrimaryInBottomNav = false,
    this.order = 0,
    required this.slug,
    this.visibility = 'public',
    this.visibilityTargets = const [],
  });

  factory PageConfig.fromMap(Map<String, dynamic> data) {
    return PageConfig(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'web',
      route: data['route'] ?? '',
      isEnabledForMembers: data['isEnabledForMembers'] ?? false,
      isPrimaryInBottomNav: data['isPrimaryInBottomNav'] ?? false,
      order: data['order'] ?? 0,
      slug: data['slug'] ?? '',
      visibility: data['visibility'] ?? 'public',
      visibilityTargets: List<String>.from(data['visibilityTargets'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'route': route,
      'isEnabledForMembers': isEnabledForMembers,
      'isPrimaryInBottomNav': isPrimaryInBottomNav,
      'order': order,
      'slug': slug,
      'visibility': visibility,
      'visibilityTargets': visibilityTargets,
    };
  }

  PageConfig copyWith({
    bool? isEnabledForMembers,
    bool? isPrimaryInBottomNav,
    int? order,
  }) {
    return PageConfig(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      route: route,
      isEnabledForMembers: isEnabledForMembers ?? this.isEnabledForMembers,
      isPrimaryInBottomNav: isPrimaryInBottomNav ?? this.isPrimaryInBottomNav,
      order: order ?? this.order,
      slug: slug,
      visibility: visibility,
      visibilityTargets: visibilityTargets,
    );
  }
}

class ModuleConfig {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String route;
  final String category; // 'core', 'ministry', 'management', 'tools'
  final bool isEnabledForMembers;
  final bool isPrimaryInBottomNav;
  final int order;
  final bool isBuiltIn;

  ModuleConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.route,
    required this.category,
    this.isEnabledForMembers = true,
    this.isPrimaryInBottomNav = false,
    this.order = 0,
    this.isBuiltIn = true,
  });

  factory ModuleConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModuleConfig(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'apps',
      route: data['route'] ?? '',
      category: data['category'] ?? 'tools',
      isEnabledForMembers: data['isEnabledForMembers'] ?? true,
      isPrimaryInBottomNav: data['isPrimaryInBottomNav'] ?? false,
      order: data['order'] ?? 0,
      isBuiltIn: data['isBuiltIn'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'route': route,
      'category': category,
      'isEnabledForMembers': isEnabledForMembers,
      'isPrimaryInBottomNav': isPrimaryInBottomNav,
      'order': order,
      'isBuiltIn': isBuiltIn,
    };
  }

  ModuleConfig copyWith({
    bool? isEnabledForMembers,
    bool? isPrimaryInBottomNav,
    int? order,
  }) {
    return ModuleConfig(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      route: route,
      category: category,
      isEnabledForMembers: isEnabledForMembers ?? this.isEnabledForMembers,
      isPrimaryInBottomNav: isPrimaryInBottomNav ?? this.isPrimaryInBottomNav,
      order: order ?? this.order,
      isBuiltIn: isBuiltIn,
    );
  }
}

class AppConfigModel {
  final String id;
  final List<ModuleConfig> modules;
  final List<PageConfig> customPages;
  final Map<String, dynamic> generalSettings;
  final DateTime lastUpdated;
  final String? lastUpdatedBy;

  AppConfigModel({
    required this.id,
    required this.modules,
    this.customPages = const [],
    this.generalSettings = const {},
    required this.lastUpdated,
    this.lastUpdatedBy,
  });

  List<ModuleConfig> get enabledModulesForMembers => 
      modules.where((m) => m.isEnabledForMembers).toList();

  List<ModuleConfig> get primaryBottomNavModules => 
      modules.where((m) => m.isEnabledForMembers && m.isPrimaryInBottomNav)
             .toList()..sort((a, b) => a.order.compareTo(b.order));

  List<ModuleConfig> get secondaryModules => 
      modules.where((m) => m.isEnabledForMembers && !m.isPrimaryInBottomNav)
             .toList()..sort((a, b) => a.name.compareTo(b.name));

  List<PageConfig> get enabledPagesForMembers => 
      customPages.where((p) => p.isEnabledForMembers).toList();

  List<PageConfig> get primaryBottomNavPages => 
      customPages.where((p) => p.isEnabledForMembers && p.isPrimaryInBottomNav)
                 .toList()..sort((a, b) => a.order.compareTo(b.order));

  List<PageConfig> get secondaryPages => 
      customPages.where((p) => p.isEnabledForMembers && !p.isPrimaryInBottomNav)
                 .toList()..sort((a, b) => a.title.compareTo(b.title));

  factory AppConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final modulesData = data['modules'] as List<dynamic>? ?? [];
    final pagesData = data['customPages'] as List<dynamic>? ?? [];
    
    return AppConfigModel(
      id: doc.id,
      modules: modulesData.map((m) => ModuleConfig(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        iconName: m['iconName'] ?? 'apps',
        route: m['route'] ?? '',
        category: m['category'] ?? 'tools',
        isEnabledForMembers: m['isEnabledForMembers'] ?? true,
        isPrimaryInBottomNav: m['isPrimaryInBottomNav'] ?? false,
        order: m['order'] ?? 0,
        isBuiltIn: m['isBuiltIn'] ?? true,
      )).toList(),
      customPages: pagesData.map((p) => PageConfig.fromMap(p)).toList(),
      generalSettings: Map<String, dynamic>.from(data['generalSettings'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      lastUpdatedBy: data['lastUpdatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'modules': modules.map((m) => {
        'id': m.id,
        'name': m.name,
        'description': m.description,
        'iconName': m.iconName,
        'route': m.route,
        'category': m.category,
        'isEnabledForMembers': m.isEnabledForMembers,
        'isPrimaryInBottomNav': m.isPrimaryInBottomNav,
        'order': m.order,
        'isBuiltIn': m.isBuiltIn,
      }).toList(),
      'customPages': customPages.map((p) => p.toMap()).toList(),
      'generalSettings': generalSettings,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastUpdatedBy': lastUpdatedBy,
    };
  }


}