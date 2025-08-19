import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import 'task_card.dart';
import '../theme.dart';

class TaskKanbanView extends StatefulWidget {
  final String? searchQuery;
  final List<String> statusFilters;
  final List<String> priorityFilters;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final Function(TaskModel) onTaskTap;

  const TaskKanbanView({
    super.key,
    this.searchQuery,
    required this.statusFilters,
    required this.priorityFilters,
    this.dueBefore,
    this.dueAfter,
    required this.onTaskTap,
  });

  @override
  State<TaskKanbanView> createState() => _TaskKanbanViewState();
}

class _TaskKanbanViewState extends State<TaskKanbanView> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _columns = ['todo', 'in_progress', 'completed'];
  
  final Map<String, String> _columnTitles = {
    'todo': 'À faire',
    'in_progress': 'En cours',
    'completed': 'Terminé',
  };
  
  final Map<String, Color> _columnColors = {
    'todo': AppTheme.primaryColor,
    'in_progress': AppTheme.warningColor,
    'completed': AppTheme.successColor,
  };

  final Map<String, IconData> _columnIcons = {
    'todo': Icons.radio_button_unchecked,
    'in_progress': Icons.play_circle,
    'completed': Icons.check_circle,
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _moveTask(TaskModel task, String newStatus) async {
    try {
      await TasksFirebaseService.updateTaskStatus(task.id, newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tâche déplacée vers ${_columnTitles[newStatus]}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        searchQuery: widget.searchQuery,
        statusFilters: widget.statusFilters.isNotEmpty ? widget.statusFilters : null,
        priorityFilters: widget.priorityFilters.isNotEmpty ? widget.priorityFilters : null,
        dueBefore: widget.dueBefore,
        dueAfter: widget.dueAfter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final allTasks = snapshot.data ?? [];
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columns.map((status) {
              final columnTasks = allTasks.where((task) => task.status == status).toList();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildColumn(status, columnTasks),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildColumn(String status, List<TaskModel> tasks) {
    final color = _columnColors[status]!;
    final title = _columnTitles[status]!;
    final icon = _columnIcons[status]!;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tasks list
          Expanded(
            child: DragTarget<TaskModel>(
              onWillAccept: (task) => task != null && task.status != status,
              onAccept: (task) => _moveTask(task, status),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? color.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: tasks.isEmpty
                      ? _buildEmptyColumn(status)
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            // Vérification de sécurité pour éviter les erreurs d'index
                            if (index >= tasks.length) {
                              return const SizedBox.shrink();
                            }
                            
                            final task = tasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildDraggableTask(task),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTask(TaskModel task) {
    return Draggable<TaskModel>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          child: TaskCard(
            task: task,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (_) {},
            isSelectionMode: false,
            isSelected: false,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: TaskCard(
          task: task,
          onTap: () => widget.onTaskTap(task),
          onLongPress: () {},
          onSelectionChanged: (_) {},
          isSelectionMode: false,
          isSelected: false,
        ),
      ),
      child: TaskCard(
        task: task,
        onTap: () => widget.onTaskTap(task),
        onLongPress: () {},
        onSelectionChanged: (_) {},
        isSelectionMode: false,
        isSelected: false,
      ),
    );
  }

  Widget _buildEmptyColumn(String status) {
    final color = _columnColors[status]!;
    final title = _columnTitles[status]!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _columnIcons[status],
              size: 48,
              color: color.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune tâche\n$title',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Glissez une tâche ici\npour changer son statut',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}