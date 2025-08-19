import 'package:flutter/material.dart';
import '../../models/dashboard_widget_model.dart';

class DashboardStatWidget extends StatelessWidget {
  final DashboardStatModel stat;
  final bool compactView;

  const DashboardStatWidget({
    Key? key,
    required this.stat,
    this.compactView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = stat.color != null ? _parseColor(stat.color!) : Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(compactView ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (stat.icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(stat.icon!),
                      color: color,
                      size: compactView ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    stat.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: compactView ? 12 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    stat.value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: compactView ? 24 : 32,
                    ),
                  ),
                ),
                if (stat.trend != null && !compactView) ...[
                  const SizedBox(width: 8),
                  _buildTrendIndicator(context, color),
                ],
              ],
            ),
            if (stat.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                stat.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: compactView ? 10 : 12,
                ),
              ),
            ],
            if (stat.trendValue != null && !compactView) ...[
              const SizedBox(height: 4),
              Text(
                stat.trendValue!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getTrendColor(stat.trend),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, Color baseColor) {
    if (stat.trend == null) return const SizedBox.shrink();

    IconData iconData;
    Color trendColor;

    switch (stat.trend!) {
      case 'up':
        iconData = Icons.trending_up;
        trendColor = Colors.green;
        break;
      case 'down':
        iconData = Icons.trending_down;
        trendColor = Colors.red;
        break;
      case 'stable':
        iconData = Icons.trending_flat;
        trendColor = Colors.orange;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: trendColor,
        size: 16,
      ),
    );
  }

  Color _getTrendColor(String? trend) {
    switch (trend) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      case 'stable':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'people':
        return Icons.people;
      case 'person_check':
        return Icons.person_add_alt_1;
      case 'person_add':
        return Icons.person_add;
      case 'groups':
        return Icons.groups;
      case 'group_work':
        return Icons.group_work;
      case 'event':
        return Icons.event;
      case 'event_available':
        return Icons.event_available;
      case 'church':
        return Icons.church;
      case 'task':
        return Icons.task;
      case 'schedule':
        return Icons.schedule;
      default:
        return Icons.bar_chart;
    }
  }
}