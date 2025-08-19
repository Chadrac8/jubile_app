import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String name;
  final String? description;
  final String type; // 'attendance', 'financial', 'membership', 'event', 'custom'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic> parameters;
  final String? chartType; // 'bar', 'line', 'pie', 'table'
  final List<String> dataColumns;
  final Map<String, dynamic>? filters;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly', 'custom'
  final DateTime? lastGenerated;
  final int generationCount;
  final List<String> sharedWith;
  final bool isPublic;

  const Report({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.isActive = true,
    this.parameters = const {},
    this.chartType,
    this.dataColumns = const [],
    this.filters,
    this.frequency = 'monthly',
    this.lastGenerated,
    this.generationCount = 0,
    this.sharedWith = const [],
    this.isPublic = false,
  });

  factory Report.fromMap(Map<String, dynamic> data, String id) {
    return Report(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String?,
      type: data['type'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      createdBy: data['createdBy'] as String,
      isActive: data['isActive'] as bool? ?? true,
      parameters: data['parameters'] as Map<String, dynamic>? ?? {},
      chartType: data['chartType'] as String?,
      dataColumns: List<String>.from(data['dataColumns'] ?? []),
      filters: data['filters'] as Map<String, dynamic>?,
      frequency: data['frequency'] as String? ?? 'monthly',
      lastGenerated: data['lastGenerated'] != null ? (data['lastGenerated'] as Timestamp).toDate() : null,
      generationCount: data['generationCount'] as int? ?? 0,
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'isActive': isActive,
      'parameters': parameters,
      'chartType': chartType,
      'dataColumns': dataColumns,
      'filters': filters,
      'frequency': frequency,
      'lastGenerated': lastGenerated != null ? Timestamp.fromDate(lastGenerated!) : null,
      'generationCount': generationCount,
      'sharedWith': sharedWith,
      'isPublic': isPublic,
    };
  }

  Report copyWith({
    String? name,
    String? description,
    String? type,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? parameters,
    String? chartType,
    List<String>? dataColumns,
    Map<String, dynamic>? filters,
    String? frequency,
    DateTime? lastGenerated,
    int? generationCount,
    List<String>? sharedWith,
    bool? isPublic,
  }) {
    return Report(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      parameters: parameters ?? this.parameters,
      chartType: chartType ?? this.chartType,
      dataColumns: dataColumns ?? this.dataColumns,
      filters: filters ?? this.filters,
      frequency: frequency ?? this.frequency,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      generationCount: generationCount ?? this.generationCount,
      sharedWith: sharedWith ?? this.sharedWith,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  /// Vérifie si le rapport doit être régénéré
  bool shouldRegenerate() {
    if (lastGenerated == null) return true;
    
    final now = DateTime.now();
    final daysSinceGeneration = now.difference(lastGenerated!).inDays;
    
    switch (frequency) {
      case 'daily':
        return daysSinceGeneration >= 1;
      case 'weekly':
        return daysSinceGeneration >= 7;
      case 'monthly':
        return daysSinceGeneration >= 30;
      case 'yearly':
        return daysSinceGeneration >= 365;
      default:
        return false;
    }
  }

  /// Obtient l'icône du type de rapport
  String get typeIcon {
    switch (type) {
      case 'attendance':
        return 'people_outline';
      case 'financial':
        return 'account_balance_wallet';
      case 'membership':
        return 'group_add';
      case 'event':
        return 'event_note';
      case 'custom':
        return 'analytics';
      default:
        return 'assessment';
    }
  }

  /// Obtient la couleur du type de rapport
  String get typeColor {
    switch (type) {
      case 'attendance':
        return 'blue';
      case 'financial':
        return 'green';
      case 'membership':
        return 'purple';
      case 'event':
        return 'orange';
      case 'custom':
        return 'indigo';
      default:
        return 'grey';
    }
  }
}

/// Modèle pour les données générées du rapport
class ReportData {
  final String reportId;
  final DateTime generatedAt;
  final Map<String, dynamic> data;
  final String? chartImageUrl;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> rows;
  final int totalRows;
  final Map<String, dynamic> metadata;

  const ReportData({
    required this.reportId,
    required this.generatedAt,
    required this.data,
    this.chartImageUrl,
    this.summary = const {},
    this.rows = const [],
    this.totalRows = 0,
    this.metadata = const {},
  });

  factory ReportData.fromMap(Map<String, dynamic> data) {
    return ReportData(
      reportId: data['reportId'] as String,
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      data: data['data'] as Map<String, dynamic>,
      chartImageUrl: data['chartImageUrl'] as String?,
      summary: data['summary'] as Map<String, dynamic>? ?? {},
      rows: List<Map<String, dynamic>>.from(data['rows'] ?? []),
      totalRows: data['totalRows'] as int? ?? 0,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'data': data,
      'chartImageUrl': chartImageUrl,
      'summary': summary,
      'rows': rows,
      'totalRows': totalRows,
      'metadata': metadata,
    };
  }
}

/// Template de rapport prédéfini
class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final String type;
  final String category;
  final Map<String, dynamic> defaultParameters;
  final String? chartType;
  final List<String> dataColumns;
  final bool isBuiltIn;
  final String? sqlQuery;
  final List<String> requiredPermissions;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    this.defaultParameters = const {},
    this.chartType,
    this.dataColumns = const [],
    this.isBuiltIn = true,
    this.sqlQuery,
    this.requiredPermissions = const [],
  });

  /// Templates prédéfinis
  static const List<ReportTemplate> builtInTemplates = [
    // Rapports de présence
    ReportTemplate(
      id: 'weekly_attendance',
      name: 'Présence hebdomadaire',
      description: 'Suivi de la présence aux services dominicaux',
      type: 'attendance',
      category: 'Cultes',
      chartType: 'bar',
      dataColumns: ['date', 'service', 'attendance_count', 'registered_count'],
    ),
    ReportTemplate(
      id: 'group_attendance',
      name: 'Présence des groupes',
      description: 'Analyse de la participation aux groupes de maison',
      type: 'attendance',
      category: 'Groupes',
      chartType: 'line',
      dataColumns: ['group_name', 'meeting_date', 'attendees', 'growth_rate'],
    ),

    // Rapports financiers
    ReportTemplate(
      id: 'monthly_donations',
      name: 'Dons mensuels',
      description: 'Évolution des dons par mois',
      type: 'financial',
      category: 'Finances',
      chartType: 'bar',
      dataColumns: ['month', 'total_amount', 'donor_count', 'average_donation'],
    ),
    ReportTemplate(
      id: 'donor_analysis',
      name: 'Analyse des donateurs',
      description: 'Profil des donateurs et tendances',
      type: 'financial',
      category: 'Finances',
      chartType: 'pie',
      dataColumns: ['donor_category', 'amount', 'frequency', 'percentage'],
    ),

    // Rapports de membres
    ReportTemplate(
      id: 'membership_growth',
      name: 'Croissance des membres',
      description: 'Évolution du nombre de membres',
      type: 'membership',
      category: 'Membres',
      chartType: 'line',
      dataColumns: ['month', 'new_members', 'total_members', 'retention_rate'],
    ),
    ReportTemplate(
      id: 'age_demographics',
      name: 'Démographie par âge',
      description: 'Répartition des membres par tranche d\'âge',
      type: 'membership',
      category: 'Membres',
      chartType: 'pie',
      dataColumns: ['age_group', 'count', 'percentage'],
    ),

    // Rapports d'événements
    ReportTemplate(
      id: 'event_participation',
      name: 'Participation aux événements',
      description: 'Analyse de la participation aux événements',
      type: 'event',
      category: 'Événements',
      chartType: 'bar',
      dataColumns: ['event_name', 'date', 'registered', 'attended', 'satisfaction'],
    ),
    ReportTemplate(
      id: 'event_feedback',
      name: 'Retours d\'événements',
      description: 'Analyse des commentaires et évaluations',
      type: 'event',
      category: 'Événements',
      chartType: 'table',
      dataColumns: ['event_name', 'rating', 'feedback', 'recommendations'],
    ),

    // Rapports de ministères
    ReportTemplate(
      id: 'ministry_involvement',
      name: 'Implication dans les ministères',
      description: 'Participation aux différents ministères',
      type: 'custom',
      category: 'Ministères',
      chartType: 'bar',
      dataColumns: ['ministry', 'volunteers', 'hours', 'impact_score'],
    ),
    ReportTemplate(
      id: 'volunteer_hours',
      name: 'Heures de bénévolat',
      description: 'Suivi des heures de service bénévole',
      type: 'custom',
      category: 'Ministères',
      chartType: 'line',
      dataColumns: ['month', 'volunteer_count', 'total_hours', 'average_hours'],
    ),
  ];

  /// Obtient un template par son ID
  static ReportTemplate? getTemplate(String id) {
    try {
      return builtInTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient les templates par catégorie
  static List<ReportTemplate> getTemplatesByCategory(String category) {
    return builtInTemplates.where((template) => template.category == category).toList();
  }

  /// Obtient toutes les catégories
  static List<String> getCategories() {
    return builtInTemplates.map((template) => template.category).toSet().toList();
  }
}