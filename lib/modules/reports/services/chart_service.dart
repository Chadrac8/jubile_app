import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report.dart';

/// Service pour générer des graphiques à partir des données de rapport
class ChartService {
  
  /// Générer un graphique à barres
  Widget generateBarChart(ReportData reportData, {
    String? xAxisLabel,
    String? yAxisLabel,
    Color? primaryColor,
  }) {
    final chartData = List<Map<String, dynamic>>.from(reportData.data['chart_data'] ?? []);
    
    if (chartData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible pour le graphique'),
      );
    }
    
    final spots = chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = _parseNumericValue(data['value']);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: primaryColor ?? Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              color: Colors.grey.withOpacity(0.1),
              toY: _getMaxValue(chartData) * 1.1,
            ),
          ),
        ],
      );
    }).toList();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          maxY: _getMaxValue(chartData) * 1.2,
          barGroups: spots,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: xAxisLabel != null ? Text(xAxisLabel) : null,
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    final label = chartData[index]['label']?.toString() ?? '';
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        _truncateLabel(label),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: yAxisLabel != null ? Text(yAxisLabel) : null,
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatValue(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: _getMaxValue(chartData) / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
        ),
      ),
    );
  }
  
  /// Générer un graphique linéaire
  Widget generateLineChart(ReportData reportData, {
    String? xAxisLabel,
    String? yAxisLabel,
    Color? primaryColor,
  }) {
    final chartData = List<Map<String, dynamic>>.from(reportData.data['chart_data'] ?? []);
    
    if (chartData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible pour le graphique'),
      );
    }
    
    final spots = chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = _parseNumericValue(data['value']);
      return FlSpot(index.toDouble(), value);
    }).toList();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: _getMaxValue(chartData) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: primaryColor ?? Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: primaryColor ?? Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: (primaryColor ?? Colors.blue).withOpacity(0.1),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: xAxisLabel != null ? Text(xAxisLabel) : null,
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    final label = chartData[index]['label']?.toString() ?? '';
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        _truncateLabel(label),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: yAxisLabel != null ? Text(yAxisLabel) : null,
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatValue(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: _getMaxValue(chartData) / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Générer un graphique en secteurs (pie chart)
  Widget generatePieChart(ReportData reportData, {
    bool showLabels = true,
    bool showPercentage = true,
  }) {
    final chartData = List<Map<String, dynamic>>.from(reportData.data['chart_data'] ?? []);
    
    if (chartData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible pour le graphique'),
      );
    }
    
    final total = chartData.fold<double>(0, (sum, item) => sum + _parseNumericValue(item['value']));
    final colors = _generateColors(chartData.length);
    
    final sections = chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = _parseNumericValue(data['value']);
      final percentage = (value / total * 100);
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: showPercentage ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          if (showLabels) ...[
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final value = _parseNumericValue(data['value']);
                  final percentage = (value / total * 100);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: colors[index % colors.length],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${data['label']} (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Générer un tableau de données
  Widget generateDataTable(ReportData reportData, {
    bool showIndex = false,
    int maxRows = 100,
  }) {
    if (reportData.rows.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }
    
    final headers = reportData.rows.first.keys.toList();
    final displayRows = reportData.rows.take(maxRows).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reportData.rows.length > maxRows)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Affichage des ${maxRows} premiers éléments sur ${reportData.rows.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                if (showIndex)
                  const DataColumn(
                    label: Text(
                      '#',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ...headers.map((header) => DataColumn(
                  label: Text(
                    header,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
              ],
              rows: displayRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                
                return DataRow(
                  cells: [
                    if (showIndex)
                      DataCell(Text('${index + 1}')),
                    ...headers.map((header) => DataCell(
                      Text(row[header]?.toString() ?? ''),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Générer le widget approprié selon le type de graphique
  Widget generateChart(ReportData reportData, String chartType, {
    String? xAxisLabel,
    String? yAxisLabel,
    Color? primaryColor,
    Map<String, dynamic>? options,
  }) {
    switch (chartType.toLowerCase()) {
      case 'bar':
        return generateBarChart(
          reportData,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          primaryColor: primaryColor,
        );
      case 'line':
        return generateLineChart(
          reportData,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          primaryColor: primaryColor,
        );
      case 'pie':
        return generatePieChart(
          reportData,
          showLabels: options?['showLabels'] ?? true,
          showPercentage: options?['showPercentage'] ?? true,
        );
      case 'table':
        return generateDataTable(
          reportData,
          showIndex: options?['showIndex'] ?? false,
          maxRows: options?['maxRows'] ?? 100,
        );
      default:
        return generateBarChart(reportData, primaryColor: primaryColor);
    }
  }
  
  // Méthodes utilitaires privées
  
  double _parseNumericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }
    return 0.0;
  }
  
  double _getMaxValue(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return 100.0;
    
    return chartData.fold<double>(0, (max, item) {
      final value = _parseNumericValue(item['value']);
      return value > max ? value : max;
    });
  }
  
  String _truncateLabel(String label, {int maxLength = 10}) {
    if (label.length <= maxLength) return label;
    return '${label.substring(0, maxLength)}...';
  }
  
  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }
  
  List<Color> _generateColors(int count) {
    final baseColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];
    
    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    
    return colors;
  }
}