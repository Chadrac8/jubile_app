import '../../../shared/services/base_firebase_service.dart';
import '../models/report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsService extends BaseFirebaseService<Report> {
  @override
  String get collectionName => 'reports';

  @override
  Report fromFirestore(DocumentSnapshot doc) {
    return Report.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Map<String, dynamic> toFirestore(Report item) {
    return item.toMap();
  }

  /// Service pour les données de rapport
  final reportDataCollection = FirebaseFirestore.instance.collection('report_data');

  /// Rechercher par nom
  Future<List<Report>> searchByName(String query) async {
    if (query.isEmpty) return await getAll();
    
    final querySnapshot = await collection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    
    return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtenir les rapports actifs uniquement
  Future<List<Report>> getActive() async {
    final querySnapshot = await collection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtenir les rapports par type
  Future<List<Report>> getByType(String type) async {
    final querySnapshot = await collection
        .where('type', isEqualTo: type)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtenir les rapports créés par un utilisateur
  Future<List<Report>> getByCreator(String userId) async {
    final querySnapshot = await collection
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtenir les rapports publics
  Future<List<Report>> getPublicReports() async {
    final querySnapshot = await collection
        .where('isPublic', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtenir les rapports partagés avec un utilisateur
  Future<List<Report>> getSharedWith(String userId) async {
    final querySnapshot = await collection
        .where('sharedWith', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Obtenir les rapports nécessitant une régénération
  Future<List<Report>> getReportsToRegenerate() async {
    final querySnapshot = await collection
        .where('isActive', isEqualTo: true)
        .get();
    
    final reports = querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    return reports.where((report) => report.shouldRegenerate()).toList();
  }

  /// Marquer un rapport comme généré
  Future<void> markAsGenerated(String reportId) async {
    await collection.doc(reportId).update({
      'lastGenerated': Timestamp.now(),
      'generationCount': FieldValue.increment(1),
    });
  }

  /// Partager un rapport avec des utilisateurs
  Future<void> shareReport(String reportId, List<String> userIds) async {
    await collection.doc(reportId).update({
      'sharedWith': FieldValue.arrayUnion(userIds),
    });
  }

  /// Retirer le partage d'un rapport
  Future<void> unshareReport(String reportId, List<String> userIds) async {
    await collection.doc(reportId).update({
      'sharedWith': FieldValue.arrayRemove(userIds),
    });
  }

  /// Générer les données d'un rapport
  Future<ReportData> generateReportData(Report report) async {
    try {
      // Simuler la génération de données (à remplacer par la logique réelle)
      final data = await _generateMockData(report);
      
      final reportData = ReportData(
        reportId: report.id,
        generatedAt: DateTime.now(),
        data: data,
        summary: _generateSummary(data, report.type),
        rows: _generateRows(data, report.dataColumns),
        totalRows: (data['rows'] as List?)?.length ?? 0,
        metadata: {
          'report_name': report.name,
          'report_type': report.type,
          'generation_time': DateTime.now().millisecondsSinceEpoch,
          'parameters': report.parameters,
        },
      );

      // Sauvegarder les données du rapport
      await reportDataCollection.doc('${report.id}_${DateTime.now().millisecondsSinceEpoch}').set(reportData.toMap());
      
      // Marquer le rapport comme généré
      await markAsGenerated(report.id);
      
      return reportData;
    } catch (e) {
      throw Exception('Erreur lors de la génération du rapport: $e');
    }
  }

  /// Obtenir les données générées d'un rapport
  Future<List<ReportData>> getReportData(String reportId, {int limit = 10}) async {
    final querySnapshot = await reportDataCollection
        .where('reportId', isEqualTo: reportId)
        .orderBy('generatedAt', descending: true)
        .limit(limit)
        .get();
    
    return querySnapshot.docs.map((doc) => ReportData.fromMap(doc.data())).toList();
  }

  /// Obtenir la dernière génération d'un rapport
  Future<ReportData?> getLatestReportData(String reportId) async {
    final data = await getReportData(reportId, limit: 1);
    return data.isNotEmpty ? data.first : null;
  }

  /// Supprimer les anciennes données de rapport
  Future<void> cleanupOldReportData(String reportId, {int keepLast = 5}) async {
    final querySnapshot = await reportDataCollection
        .where('reportId', isEqualTo: reportId)
        .orderBy('generatedAt', descending: true)
        .get();
    
    if (querySnapshot.docs.length > keepLast) {
      final docsToDelete = querySnapshot.docs.skip(keepLast);
      for (final doc in docsToDelete) {
        await doc.reference.delete();
      }
    }
  }

  /// Obtenir les statistiques des rapports
  Future<Map<String, dynamic>> getReportsStatistics() async {
    final allReports = await getAll();
    final activeReports = allReports.where((r) => r.isActive).toList();
    
    final typeCount = <String, int>{};
    final frequencyCount = <String, int>{};
    var totalGenerations = 0;
    
    for (final report in activeReports) {
      typeCount[report.type] = (typeCount[report.type] ?? 0) + 1;
      frequencyCount[report.frequency] = (frequencyCount[report.frequency] ?? 0) + 1;
      totalGenerations += report.generationCount;
    }
    
    return {
      'total_reports': allReports.length,
      'active_reports': activeReports.length,
      'inactive_reports': allReports.length - activeReports.length,
      'total_generations': totalGenerations,
      'average_generations': activeReports.isNotEmpty ? totalGenerations / activeReports.length : 0,
      'reports_by_type': typeCount,
      'reports_by_frequency': frequencyCount,
      'reports_needing_regeneration': (await getReportsToRegenerate()).length,
    };
  }

  /// Créer un rapport à partir d'un template
  Future<String> createFromTemplate(String templateId, Map<String, dynamic> customizations) async {
    final template = ReportTemplate.getTemplate(templateId);
    if (template == null) {
      throw Exception('Template non trouvé: $templateId');
    }
    
    final reportData = {
      'name': customizations['name'] ?? template.name,
      'description': customizations['description'] ?? template.description,
      'type': template.type,
      'createdAt': Timestamp.now(),
      'createdBy': customizations['createdBy'] ?? 'current_user',
      'isActive': true,
      'parameters': {...template.defaultParameters, ...?customizations['parameters']},
      'chartType': customizations['chartType'] ?? template.chartType,
      'dataColumns': customizations['dataColumns'] ?? template.dataColumns,
      'filters': customizations['filters'],
      'frequency': customizations['frequency'] ?? 'monthly',
      'generationCount': 0,
      'sharedWith': [],
      'isPublic': customizations['isPublic'] ?? false,
    };
    
    final docRef = await collection.add(reportData);
    return docRef.id;
  }

  /// Dupliquer un rapport
  Future<String> duplicateReport(String reportId, String newName) async {
    final report = await getById(reportId);
    if (report == null) {
      throw Exception('Rapport non trouvé: $reportId');
    }
    
    final duplicateData = report.toMap();
    duplicateData['name'] = newName;
    duplicateData['createdAt'] = Timestamp.now();
    duplicateData['lastGenerated'] = null;
    duplicateData['generationCount'] = 0;
    
    final docRef = await collection.add(duplicateData);
    return docRef.id;
  }

  /// Méthodes privées pour la génération de données mockées
  Future<Map<String, dynamic>> _generateMockData(Report report) async {
    // Simulation de données selon le type de rapport
    switch (report.type) {
      case 'attendance':
        return _generateAttendanceData(report);
      case 'financial':
        return _generateFinancialData(report);
      case 'membership':
        return _generateMembershipData(report);
      case 'event':
        return _generateEventData(report);
      default:
        return _generateCustomData(report);
    }
  }

  Map<String, dynamic> _generateAttendanceData(Report report) {
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      rows.add({
        'month': '${month.month}/${month.year}',
        'total_services': 4 + (i % 2),
        'average_attendance': 85 + (i * 2) + (i % 10),
        'max_attendance': 120 + (i * 3),
        'growth_rate': ((i % 3) - 1) * 5.5,
      });
    }
    
    return {
      'rows': rows.reversed.toList(),
      'chart_data': rows.map((row) => {
        'label': row['month'],
        'value': row['average_attendance'],
      }).toList(),
    };
  }

  Map<String, dynamic> _generateFinancialData(Report report) {
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final baseAmount = 5000 + (i * 200);
      rows.add({
        'month': '${month.month}/${month.year}',
        'total_donations': baseAmount + (i % 5) * 500,
        'donor_count': 25 + (i % 8),
        'average_donation': (baseAmount / (25 + (i % 8))).round(),
        'growth_rate': ((i % 4) - 1.5) * 8.0,
      });
    }
    
    return {
      'rows': rows.reversed.toList(),
      'chart_data': rows.map((row) => {
        'label': row['month'],
        'value': row['total_donations'],
      }).toList(),
    };
  }

  Map<String, dynamic> _generateMembershipData(Report report) {
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now();
    var totalMembers = 150;
    
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final newMembers = 3 + (i % 4);
      totalMembers += newMembers;
      
      rows.add({
        'month': '${month.month}/${month.year}',
        'new_members': newMembers,
        'total_members': totalMembers,
        'retention_rate': 94.5 + (i % 3) * 1.2,
        'active_members': (totalMembers * 0.85).round(),
      });
    }
    
    return {
      'rows': rows,
      'chart_data': rows.map((row) => {
        'label': row['month'],
        'value': row['total_members'],
      }).toList(),
    };
  }

  Map<String, dynamic> _generateEventData(Report report) {
    final events = ['Culte de Pâques', 'Retraite d\'été', 'Soirée jeunes', 'Conférence', 'Barbecue familial'];
    final rows = <Map<String, dynamic>>[];
    
    for (int i = 0; i < events.length; i++) {
      final registered = 50 + (i * 15);
      final attended = (registered * (0.8 + (i % 3) * 0.05)).round();
      
      rows.add({
        'event_name': events[i],
        'date': DateTime.now().subtract(Duration(days: i * 30)).toString().substring(0, 10),
        'registered': registered,
        'attended': attended,
        'attendance_rate': ((attended / registered) * 100).round(),
        'satisfaction': 4.2 + (i % 3) * 0.2,
      });
    }
    
    return {
      'rows': rows,
      'chart_data': rows.map((row) => {
        'label': row['event_name'],
        'value': row['attended'],
      }).toList(),
    };
  }

  Map<String, dynamic> _generateCustomData(Report report) {
    final rows = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 10; i++) {
      rows.add({
        'item': 'Élément ${i + 1}',
        'value': 10 + (i * 5) + (i % 7),
        'percentage': ((10 + (i * 5)) / 100 * 100).round(),
        'status': i % 2 == 0 ? 'Actif' : 'En cours',
      });
    }
    
    return {
      'rows': rows,
      'chart_data': rows.map((row) => {
        'label': row['item'],
        'value': row['value'],
      }).toList(),
    };
  }

  Map<String, dynamic> _generateSummary(Map<String, dynamic> data, String type) {
    final rows = List<Map<String, dynamic>>.from(data['rows'] ?? []);
    if (rows.isEmpty) return {};
    
    switch (type) {
      case 'attendance':
        final avgAttendance = rows.map<num>((r) => r['average_attendance'] ?? 0).reduce((a, b) => a + b) / rows.length;
        return {
          'total_services': rows.length,
          'average_attendance': avgAttendance.round(),
          'trend': 'Croissant',
        };
      case 'financial':
        final totalDonations = rows.map<num>((r) => r['total_donations'] ?? 0).reduce((a, b) => a + b);
        return {
          'total_donations': totalDonations,
          'average_monthly': (totalDonations / rows.length).round(),
          'trend': 'Stable',
        };
      case 'membership':
        final currentMembers = rows.isNotEmpty ? rows.last['total_members'] ?? 0 : 0;
        return {
          'current_members': currentMembers,
          'growth_this_year': rows.map<num>((r) => r['new_members'] ?? 0).reduce((a, b) => a + b),
          'trend': 'Croissant',
        };
      default:
        return {
          'total_items': rows.length,
          'summary': 'Données personnalisées',
        };
    }
  }

  List<Map<String, dynamic>> _generateRows(Map<String, dynamic> data, List<String> columns) {
    final sourceRows = List<Map<String, dynamic>>.from(data['rows'] ?? []);
    if (columns.isEmpty) return sourceRows;
    
    return sourceRows.map((row) {
      final filteredRow = <String, dynamic>{};
      for (final column in columns) {
        if (row.containsKey(column)) {
          filteredRow[column] = row[column];
        }
      }
      return filteredRow;
    }).toList();
  }
}