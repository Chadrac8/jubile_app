import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/export_service.dart';

/// Dialog pour l'export de rapports
class ExportDialog extends StatefulWidget {
  final ReportData reportData;
  final String reportName;
  
  const ExportDialog({
    Key? key,
    required this.reportData,
    required this.reportName,
  }) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final ExportService _exportService = ExportService();
  
  String _selectedFormat = 'csv';
  String _customFilename = '';
  bool _isExporting = false;
  bool _shareAfterExport = true;
  
  @override
  void initState() {
    super.initState();
    _customFilename = _generateDefaultFilename();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download, color: Colors.blue),
          SizedBox(width: 8),
          Text('Exporter le rapport'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du rapport
            _buildReportInfo(),
            const SizedBox(height: 24),
            
            // Sélection du format
            _buildFormatSelection(),
            const SizedBox(height: 20),
            
            // Nom du fichier
            _buildFilenameInput(),
            const SizedBox(height: 20),
            
            // Options d'export
            _buildExportOptions(),
            
            // Aperçu des données
            const SizedBox(height: 20),
            _buildDataPreview(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportReport,
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Exporter'),
        ),
      ],
    );
  }
  
  Widget _buildReportInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.reportName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Généré le ${_formatDate(widget.reportData.generatedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.data_usage, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${widget.reportData.totalRows} lignes de données',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormatSelection() {
    final formats = _exportService.getAvailableFormats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Format d\'export',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ...formats.map((format) => RadioListTile<String>(
          value: format.id,
          groupValue: _selectedFormat,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFormat = value;
                _customFilename = _generateDefaultFilename();
              });
            }
          },
          title: Text(format.name),
          subtitle: Text(format.description),
          secondary: Icon(_getFormatIcon(format.icon)),
        )),
      ],
    );
  }
  
  Widget _buildFilenameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nom du fichier',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _customFilename),
          decoration: const InputDecoration(
            hintText: 'Nom du fichier...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
          onChanged: (value) {
            _customFilename = value;
          },
        ),
      ],
    );
  }
  
  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Partager après l\'export'),
          subtitle: const Text('Ouvrir le menu de partage automatiquement'),
          value: _shareAfterExport,
          onChanged: (value) {
            setState(() {
              _shareAfterExport = value ?? true;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
  
  Widget _buildDataPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu des données',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildPreviewContent(),
        ),
      ],
    );
  }
  
  Widget _buildPreviewContent() {
    if (widget.reportData.rows.isEmpty) {
      return const Center(
        child: Text('Aucune donnée à exporter'),
      );
    }
    
    final previewRows = widget.reportData.rows.take(3).toList();
    final headers = previewRows.first.keys.toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-têtes
          Text(
            headers.join(' | '),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Divider(height: 8),
          
          // Données preview
          ...previewRows.map((row) {
            final values = headers.map((h) => row[h]?.toString() ?? '').toList();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                values.join(' | '),
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
          
          // Indicateur de plus de données
          if (widget.reportData.rows.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... et ${widget.reportData.rows.length - 3} autres lignes',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _exportReport() async {
    if (_customFilename.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un nom de fichier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isExporting = true;
    });
    
    try {
      final filePath = await _exportService.exportInFormat(
        widget.reportData,
        _selectedFormat,
        filename: _customFilename,
      );
      
      // Fermer le dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Afficher le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport exporté avec succès'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () {
                // TODO: Ouvrir le fichier
              },
            ),
          ),
        );
      }
      
      // Partager si demandé
      if (_shareAfterExport && mounted) {
        await _exportService.shareExportedFile(filePath, widget.reportName);
      }
      
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _generateDefaultFilename() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final sanitizedName = widget.reportName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    
    final format = _exportService.getAvailableFormats().firstWhere((f) => f.id == _selectedFormat);
    return '${sanitizedName}_$timestamp${format.extension}';
  }
  
  IconData _getFormatIcon(String iconName) {
    switch (iconName) {
      case 'table_chart':
        return Icons.table_chart;
      case 'code':
        return Icons.code;
      case 'web':
        return Icons.web;
      default:
        return Icons.file_download;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Fonction utilitaire pour afficher le dialog d'export
Future<void> showExportDialog(BuildContext context, ReportData reportData, String reportName) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ExportDialog(
      reportData: reportData,
      reportName: reportName,
    ),
  );
}