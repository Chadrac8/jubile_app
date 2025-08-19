import 'package:flutter/material.dart';
import '../../models/dashboard_widget_model.dart';

class DashboardListWidget extends StatelessWidget {
  final DashboardListModel listData;
  final bool compactView;

  const DashboardListWidget({
    Key? key,
    required this.listData,
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
            // En-tête avec titre et action optionnelle
            Row(
              children: [
                Expanded(
                  child: Text(
                    listData.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: compactView ? 14 : 16,
                    ),
                  ),
                ),
                if (listData.actionLabel != null)
                  TextButton(
                    onPressed: listData.onAction,
                    child: Text(
                      listData.actionLabel!,
                      style: TextStyle(
                        fontSize: compactView ? 12 : 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Liste des éléments
            Expanded(
              child: listData.items.isNotEmpty
                  ? ListView.separated(
                      itemCount: listData.items.length,
                      separatorBuilder: (context, index) => Divider(
                        height: compactView ? 8 : 12,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final item = listData.items[index];
                        return _buildListItem(context, item);
                      },
                    )
                  : _buildEmptyState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DashboardListItem item) {
    final color = item.color != null ? _parseColor(item.color!) : Theme.of(context).primaryColor;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: compactView ? 6 : 8,
          horizontal: compactView ? 8 : 12,
        ),
        child: Row(
          children: [
            // Icône
            if (item.icon != null) ...[
              Container(
                width: compactView ? 32 : 40,
                height: compactView ? 32 : 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(item.icon!),
                  color: color,
                  size: compactView ? 16 : 20,
                ),
              ),
              SizedBox(width: compactView ? 8 : 12),
            ],
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: compactView ? 12 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: compactView ? 10 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Flèche de navigation
            if (item.onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: compactView ? 16 : 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: compactView ? 32 : 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun élément à afficher',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: compactView ? 12 : 14,
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'event':
        return Icons.event;
      case 'group':
        return Icons.group;
      case 'task':
        return Icons.task;
      case 'appointment':
        return Icons.schedule;
      case 'church':
        return Icons.church;
      case 'music':
        return Icons.music_note;
      case 'form':
        return Icons.description;
      default:
        return Icons.circle;
    }
  }
}