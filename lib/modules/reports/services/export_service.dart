import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/report.dart';

/// Service pour l'export de données de rapports
class ExportService {
  
  /// Exporter un rapport en format CSV
  Future<String> exportToCSV(ReportData reportData, {String? filename}) async {
    final buffer = StringBuffer();
    
    // Ajouter l'en-tête du fichier
    buffer.writeln('# Rapport: ${reportData.metadata['report_name'] ?? 'Sans nom'}');
    buffer.writeln('# Généré le: ${reportData.generatedAt}');
    buffer.writeln('# Type: ${reportData.metadata['report_type'] ?? 'Inconnu'}');
    buffer.writeln('');
    
    // Ajouter le résumé
    if (reportData.summary.isNotEmpty) {
      buffer.writeln('# RÉSUMÉ');
      for (final entry in reportData.summary.entries) {
        buffer.writeln('# ${entry.key}: ${entry.value}');
      }
      buffer.writeln('');
    }
    
    // Ajouter les données
    if (reportData.rows.isNotEmpty) {
      // En-têtes des colonnes
      final headers = reportData.rows.first.keys.toList();
      buffer.writeln(headers.map((h) => _escapeCSV(h)).join(','));
      
      // Données
      for (final row in reportData.rows) {
        final values = headers.map((header) => _escapeCSV(row[header]?.toString() ?? '')).toList();
        buffer.writeln(values.join(','));
      }
    }
    
    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName = filename ?? 'rapport_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    
    return file.path;
  }
  
  /// Exporter un rapport en format JSON
  Future<String> exportToJSON(ReportData reportData, {String? filename}) async {
    final data = {
      'report_info': {
        'name': reportData.metadata['report_name'] ?? 'Sans nom',
        'generated_at': reportData.generatedAt.toIso8601String(),
        'type': reportData.metadata['report_type'] ?? 'Inconnu',
        'total_rows': reportData.totalRows,
      },
      'summary': reportData.summary,
      'data': reportData.rows,
      'metadata': reportData.metadata,
    };
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    
    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName = filename ?? 'rapport_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);
    
    return file.path;
  }
  
  /// Exporter un rapport en format HTML
  Future<String> exportToHTML(ReportData reportData, {String? filename}) async {
    final buffer = StringBuffer();
    
    // HTML de base
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="fr">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${reportData.metadata['report_name'] ?? 'Rapport'}</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_getHTMLStyles());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    
    // En-tête
    buffer.writeln('<div class="header">');
    buffer.writeln('  <h1>${reportData.metadata['report_name'] ?? 'Rapport'}</h1>');
    buffer.writeln('  <p class="meta">Généré le ${_formatDate(reportData.generatedAt)}</p>');
    buffer.writeln('  <p class="meta">Type: ${reportData.metadata['report_type'] ?? 'Inconnu'}</p>');
    buffer.writeln('</div>');
    
    // Résumé
    if (reportData.summary.isNotEmpty) {
      buffer.writeln('<div class="summary">');
      buffer.writeln('  <h2>Résumé</h2>');
      buffer.writeln('  <div class="summary-grid">');
      for (final entry in reportData.summary.entries) {
        buffer.writeln('    <div class="summary-item">');
        buffer.writeln('      <div class="summary-label">${entry.key}</div>');
        buffer.writeln('      <div class="summary-value">${entry.value}</div>');
        buffer.writeln('    </div>');
      }
      buffer.writeln('  </div>');
      buffer.writeln('</div>');
    }
    
    // Données tabulaires
    if (reportData.rows.isNotEmpty) {
      buffer.writeln('<div class="data-section">');
      buffer.writeln('  <h2>Données détaillées</h2>');
      buffer.writeln('  <table class="data-table">');
      
      // En-têtes
      final headers = reportData.rows.first.keys.toList();
      buffer.writeln('    <thead>');
      buffer.writeln('      <tr>');
      for (final header in headers) {
        buffer.writeln('        <th>${_escapeHtml(header)}</th>');
      }
      buffer.writeln('      </tr>');
      buffer.writeln('    </thead>');
      
      // Données
      buffer.writeln('    <tbody>');
      for (final row in reportData.rows) {
        buffer.writeln('      <tr>');
        for (final header in headers) {
          buffer.writeln('        <td>${_escapeHtml(row[header]?.toString() ?? '')}</td>');
        }
        buffer.writeln('      </tr>');
      }
      buffer.writeln('    </tbody>');
      buffer.writeln('  </table>');
      buffer.writeln('</div>');
    }
    
    // Footer
    buffer.writeln('<div class="footer">');
    buffer.writeln('  <p>Généré par ChurchFlow le ${_formatDate(DateTime.now())}</p>');
    buffer.writeln('</div>');
    
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName = filename ?? 'rapport_${DateTime.now().millisecondsSinceEpoch}.html';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());
    
    return file.path;
  }
  
  /// Partager un fichier exporté
  Future<void> shareExportedFile(String filePath, String title) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: title);
  }
  
  /// Obtenir les formats d'export disponibles
  List<ExportFormat> getAvailableFormats() {
    return [
      const ExportFormat(
        id: 'csv',
        name: 'CSV',
        description: 'Fichier séparé par virgules',
        extension: '.csv',
        mimeType: 'text/csv',
        icon: 'table_chart',
      ),
      const ExportFormat(
        id: 'json',
        name: 'JSON',
        description: 'Format de données structurées',
        extension: '.json',
        mimeType: 'application/json',
        icon: 'code',
      ),
      const ExportFormat(
        id: 'html',
        name: 'HTML',
        description: 'Page web avec mise en forme',
        extension: '.html',
        mimeType: 'text/html',
        icon: 'web',
      ),
    ];
  }
  
  /// Exporter dans le format spécifié
  Future<String> exportInFormat(ReportData reportData, String format, {String? filename}) async {
    switch (format.toLowerCase()) {
      case 'csv':
        return await exportToCSV(reportData, filename: filename);
      case 'json':
        return await exportToJSON(reportData, filename: filename);
      case 'html':
        return await exportToHTML(reportData, filename: filename);
      default:
        throw ArgumentError('Format d\'export non supporté: $format');
    }
  }
  
  // Méthodes utilitaires privées
  
  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
  
  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _getHTMLStyles() {
    return '''
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        margin: 0;
        padding: 20px;
        background-color: #f5f5f5;
        color: #333;
      }
      
      .header {
        background: white;
        padding: 30px;
        border-radius: 12px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        margin-bottom: 20px;
      }
      
      .header h1 {
        margin: 0 0 10px 0;
        color: #2c3e50;
        font-size: 28px;
      }
      
      .meta {
        color: #7f8c8d;
        margin: 5px 0;
        font-size: 14px;
      }
      
      .summary {
        background: white;
        padding: 30px;
        border-radius: 12px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        margin-bottom: 20px;
      }
      
      .summary h2 {
        margin: 0 0 20px 0;
        color: #2c3e50;
        font-size: 20px;
      }
      
      .summary-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 20px;
      }
      
      .summary-item {
        padding: 15px;
        background: #f8f9fa;
        border-radius: 8px;
        border-left: 4px solid #3498db;
      }
      
      .summary-label {
        font-size: 12px;
        color: #7f8c8d;
        text-transform: uppercase;
        font-weight: 600;
        margin-bottom: 5px;
      }
      
      .summary-value {
        font-size: 24px;
        font-weight: bold;
        color: #2c3e50;
      }
      
      .data-section {
        background: white;
        padding: 30px;
        border-radius: 12px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        margin-bottom: 20px;
      }
      
      .data-section h2 {
        margin: 0 0 20px 0;
        color: #2c3e50;
        font-size: 20px;
      }
      
      .data-table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 10px;
      }
      
      .data-table th {
        background: #34495e;
        color: white;
        padding: 12px;
        text-align: left;
        font-weight: 600;
        border-bottom: 2px solid #2c3e50;
      }
      
      .data-table td {
        padding: 12px;
        border-bottom: 1px solid #ecf0f1;
      }
      
      .data-table tr:nth-child(even) {
        background: #f8f9fa;
      }
      
      .data-table tr:hover {
        background: #e8f4f8;
      }
      
      .footer {
        text-align: center;
        color: #95a5a6;
        font-size: 12px;
        margin-top: 40px;
        padding: 20px;
      }
      
      @media (max-width: 768px) {
        body {
          padding: 10px;
        }
        
        .header, .summary, .data-section {
          padding: 20px;
        }
        
        .summary-grid {
          grid-template-columns: 1fr;
        }
        
        .data-table {
          font-size: 14px;
        }
        
        .data-table th,
        .data-table td {
          padding: 8px;
        }
      }
    ''';
  }
}

/// Modèle pour les formats d'export
class ExportFormat {
  final String id;
  final String name;
  final String description;
  final String extension;
  final String mimeType;
  final String icon;
  
  const ExportFormat({
    required this.id,
    required this.name,
    required this.description,
    required this.extension,
    required this.mimeType,
    required this.icon,
  });
}