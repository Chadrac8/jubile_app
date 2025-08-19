import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/chart_service.dart';

/// Widget pour afficher des graphiques de rapport
class ReportChartWidget extends StatefulWidget {
  final ReportData reportData;
  final String chartType;
  final String? title;
  final Color? primaryColor;
  final Map<String, dynamic>? chartOptions;
  final bool showControls;
  final Function(String)? onChartTypeChanged;
  
  const ReportChartWidget({
    Key? key,
    required this.reportData,
    required this.chartType,
    this.title,
    this.primaryColor,
    this.chartOptions,
    this.showControls = false,
    this.onChartTypeChanged,
  }) : super(key: key);

  @override
  State<ReportChartWidget> createState() => _ReportChartWidgetState();
}

class _ReportChartWidgetState extends State<ReportChartWidget> {
  final ChartService _chartService = ChartService();
  late String _currentChartType;
  bool _isFullscreen = false;
  
  @override
  void initState() {
    super.initState();
    _currentChartType = widget.chartType;
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et contrôles
          if (widget.title != null || widget.showControls)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (widget.showControls) ...[
                    // Sélecteur de type de graphique
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.bar_chart),
                      onSelected: (value) {
                        setState(() {
                          _currentChartType = value;
                        });
                        widget.onChartTypeChanged?.call(value);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'bar',
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart),
                              SizedBox(width: 8),
                              Text('Barres'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'line',
                          child: Row(
                            children: [
                              Icon(Icons.show_chart),
                              SizedBox(width: 8),
                              Text('Lignes'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'pie',
                          child: Row(
                            children: [
                              Icon(Icons.pie_chart),
                              SizedBox(width: 8),
                              Text('Secteurs'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'table',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart),
                              SizedBox(width: 8),
                              Text('Tableau'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Bouton plein écran
                    IconButton(
                      icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                      onPressed: () {
                        if (_isFullscreen) {
                          Navigator.of(context).pop();
                        } else {
                          _showFullscreenChart();
                        }
                      },
                      tooltip: _isFullscreen ? 'Quitter le plein écran' : 'Plein écran',
                    ),
                  ],
                ],
              ),
            ),
          
          // Graphique
          _buildChart(),
          
          // Métadonnées
          if (widget.reportData.metadata.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildMetadata(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildChart() {
    return _chartService.generateChart(
      widget.reportData,
      _currentChartType,
      primaryColor: widget.primaryColor,
      options: widget.chartOptions,
    );
  }
  
  Widget _buildMetadata() {
    final metadata = widget.reportData.metadata;
    final relevantMetadata = <String, dynamic>{};
    
    // Filtrer les métadonnées pertinentes à afficher
    for (final entry in metadata.entries) {
      if (entry.key != 'parameters' && entry.key != 'report_name') {
        relevantMetadata[entry.key] = entry.value;
      }
    }
    
    if (relevantMetadata.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: relevantMetadata.entries.map((entry) {
            return _buildMetadataChip(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildMetadataChip(String key, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$key: $value',
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
  
  void _showFullscreenChart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(widget.title ?? 'Graphique'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareChart(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Graphique en plein écran
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _chartService.generateChart(
                      widget.reportData,
                      _currentChartType,
                      primaryColor: widget.primaryColor,
                      options: widget.chartOptions,
                    ),
                  ),
                  
                  // Résumé
                  if (widget.reportData.summary.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSummarySection(),
                  ],
                  
                  // Contrôles de type de graphique
                  const SizedBox(height: 24),
                  _buildChartTypeSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: widget.reportData.summary.entries.map((entry) {
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
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type de graphique',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChartTypeButton('bar', Icons.bar_chart, 'Barres'),
                _buildChartTypeButton('line', Icons.show_chart, 'Lignes'),
                _buildChartTypeButton('pie', Icons.pie_chart, 'Secteurs'),
                _buildChartTypeButton('table', Icons.table_chart, 'Tableau'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartTypeButton(String type, IconData icon, String label) {
    final isSelected = _currentChartType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentChartType = type;
        });
        widget.onChartTypeChanged?.call(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _shareChart() {
    // TODO: Implémenter le partage du graphique
    // Pourrait inclure l'export en image ou PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à venir'),
      ),
    );
  }
}