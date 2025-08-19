import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une liste dynamique
class DynamicListModel {
  final String id;
  final String name;
  final String description;
  final String sourceModule; // 'people', 'groups', 'events', etc.
  final List<DynamicListField> fields;
  final List<DynamicListFilter> filters;
  final List<DynamicListSort> sorting;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublic;
  final List<String> sharedWith; // IDs des utilisateurs avec accès
  final String category; // 'general', 'ministry', 'admin', etc.
  final bool isFavorite;
  final int viewCount;
  final DateTime? lastUsed;

  DynamicListModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sourceModule,
    required this.fields,
    this.filters = const [],
    this.sorting = const [],
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isPublic = false,
    this.sharedWith = const [],
    this.category = 'general',
    this.isFavorite = false,
    this.viewCount = 0,
    this.lastUsed,
  });

  factory DynamicListModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DynamicListModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sourceModule: data['sourceModule'] ?? 'people',
      fields: (data['fields'] as List<dynamic>?)
          ?.map((f) => DynamicListField.fromMap(f as Map<String, dynamic>))
          .toList() ?? [],
      filters: (data['filters'] as List<dynamic>?)
          ?.map((f) => DynamicListFilter.fromMap(f as Map<String, dynamic>))
          .toList() ?? [],
      sorting: (data['sorting'] as List<dynamic>?)
          ?.map((s) => DynamicListSort.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isPublic: data['isPublic'] ?? false,
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      category: data['category'] ?? 'general',
      isFavorite: data['isFavorite'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'sourceModule': sourceModule,
      'fields': fields.map((f) => f.toMap()).toList(),
      'filters': filters.map((f) => f.toMap()).toList(),
      'sorting': sorting.map((s) => s.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPublic': isPublic,
      'sharedWith': sharedWith,
      'category': category,
      'isFavorite': isFavorite,
      'viewCount': viewCount,
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
    };
  }

  DynamicListModel copyWith({
    String? name,
    String? description,
    String? sourceModule,
    List<DynamicListField>? fields,
    List<DynamicListFilter>? filters,
    List<DynamicListSort>? sorting,
    DateTime? updatedAt,
    bool? isPublic,
    List<String>? sharedWith,
    String? category,
    bool? isFavorite,
    int? viewCount,
    DateTime? lastUsed,
  }) {
    return DynamicListModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      sourceModule: sourceModule ?? this.sourceModule,
      fields: fields ?? this.fields,
      filters: filters ?? this.filters,
      sorting: sorting ?? this.sorting,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      sharedWith: sharedWith ?? this.sharedWith,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      viewCount: viewCount ?? this.viewCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

/// Champ de liste dynamique
class DynamicListField {
  final String fieldKey;
  final String displayName;
  final String fieldType; // 'text', 'number', 'date', 'boolean', 'email', etc.
  final bool isVisible;
  final int order;
  final String? format; // Format pour les dates, nombres, etc.
  final bool isClickable; // Le champ peut être cliqué pour plus d'actions

  DynamicListField({
    required this.fieldKey,
    required this.displayName,
    required this.fieldType,
    this.isVisible = true,
    this.order = 0,
    this.format,
    this.isClickable = false,
  });

  factory DynamicListField.fromMap(Map<String, dynamic> map) {
    return DynamicListField(
      fieldKey: map['fieldKey'] ?? '',
      displayName: map['displayName'] ?? '',
      fieldType: map['fieldType'] ?? 'text',
      isVisible: map['isVisible'] ?? true,
      order: map['order'] ?? 0,
      format: map['format'],
      isClickable: map['isClickable'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldKey': fieldKey,
      'displayName': displayName,
      'fieldType': fieldType,
      'isVisible': isVisible,
      'order': order,
      'format': format,
      'isClickable': isClickable,
    };
  }
}

/// Filtre de liste dynamique
class DynamicListFilter {
  final String fieldKey;
  final String operator; // 'equals', 'contains', 'startsWith', 'greaterThan', etc.
  final dynamic value;
  final String logicalOperator; // 'AND', 'OR'

  DynamicListFilter({
    required this.fieldKey,
    required this.operator,
    required this.value,
    this.logicalOperator = 'AND',
  });

  factory DynamicListFilter.fromMap(Map<String, dynamic> map) {
    return DynamicListFilter(
      fieldKey: map['fieldKey'] ?? '',
      operator: map['operator'] ?? 'equals',
      value: map['value'],
      logicalOperator: map['logicalOperator'] ?? 'AND',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldKey': fieldKey,
      'operator': operator,
      'value': value,
      'logicalOperator': logicalOperator,
    };
  }
}

/// Tri de liste dynamique
class DynamicListSort {
  final String fieldKey;
  final String direction; // 'asc', 'desc'
  final int priority; // Ordre de tri (1 = premier critère)

  DynamicListSort({
    required this.fieldKey,
    required this.direction,
    this.priority = 1,
  });

  factory DynamicListSort.fromMap(Map<String, dynamic> map) {
    return DynamicListSort(
      fieldKey: map['fieldKey'] ?? '',
      direction: map['direction'] ?? 'asc',
      priority: map['priority'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldKey': fieldKey,
      'direction': direction,
      'priority': priority,
    };
  }
}

/// Template de liste dynamique prédéfinie
class DynamicListTemplate {
  final String id;
  final String name;
  final String description;
  final String sourceModule;
  final List<DynamicListField> fields;
  final List<DynamicListFilter> filters;
  final List<DynamicListSort> sorting;
  final String category;
  final String iconName;

  DynamicListTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.sourceModule,
    required this.fields,
    this.filters = const [],
    this.sorting = const [],
    required this.category,
    this.iconName = 'list_alt',
  });

  DynamicListModel toModel(String createdBy) {
    return DynamicListModel(
      id: '',
      name: name,
      description: description,
      sourceModule: sourceModule,
      fields: fields,
      filters: filters,
      sorting: sorting,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      category: category,
    );
  }
}