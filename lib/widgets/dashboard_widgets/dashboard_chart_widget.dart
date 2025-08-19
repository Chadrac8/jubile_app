import 'package:flutter/material.dart';
import '../../models/dashboard_widget_model.dart';

class DashboardChartWidget extends StatelessWidget {
  final DashboardChartModel chart;
  final bool compactView;

  const DashboardChartWidget({
    Key? key,
    required this.chart,
    this.compactView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(compactView ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chart.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: compactView ? 14 : 16,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: chart.data.isNotEmpty
                  ? _buildChart(context)
                  : _buildEmptyState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    switch (chart.type) {
      case 'pie':
        return _buildPieChart(context);
      case 'bar':
        return _buildBarChart(context);
      case 'line':
        return _buildLineChart(context);
      default:
        return _buildPieChart(context);
    }
  }

  Widget _buildPieChart(BuildContext context) {
    final total = chart.data.fold(0.0, (sum, item) => sum + item.value);
    
    return Row(
      children: [
        // Graphique circulaire simple avec des segments colorés
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: PieChartPainter(chart.data, total),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Légende
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: chart.data.map((item) {
              final percentage = total > 0 ? (item.value / total * 100).toStringAsFixed(1) : '0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(item.color ?? '#2196F3'),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final maxValue = chart.data.isNotEmpty 
        ? chart.data.map((item) => item.value).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chart.data.map((item) {
              final height = item.value / maxValue;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Valeur au-dessus de la barre
                      Text(
                        item.value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: compactView ? 10 : 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Barre
                      Container(
                        height: height * (compactView ? 80 : 120),
                        decoration: BoxDecoration(
                          color: _parseColor(item.color ?? '#2196F3'),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Labels des barres
        Row(
          children: chart.data.map((item) {
            return Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: compactView ? 8 : 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context) {
    // Implémentation simplifiée du graphique linéaire
    final maxValue = chart.data.isNotEmpty 
        ? chart.data.map((item) => item.value).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: LineChartPainter(chart.data, maxValue),
            child: Container(),
          ),
        ),
        const SizedBox(height: 8),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: chart.data.map((item) {
            return Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: compactView ? 8 : 10,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: compactView ? 32 : 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune donnée disponible',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        colorString = 'FF' + colorString;
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}

// Painter pour le graphique circulaire
class PieChartPainter extends CustomPainter {
  final List<DashboardChartDataPoint> data;
  final double total;

  PieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 - 4 : size.height / 2 - 4;
    
    double startAngle = -90 * (3.14159 / 180); // Commencer en haut

    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = _parseColor(item.color ?? '#2196F3')
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        colorString = 'FF' + colorString;
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}

// Painter pour le graphique linéaire
class LineChartPainter extends CustomPainter {
  final List<DashboardChartDataPoint> data;
  final double maxValue;

  LineChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - (data[i].value / maxValue) * size.height;
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Dessiner la ligne
    canvas.drawPath(path, paint);

    // Dessiner les points
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}