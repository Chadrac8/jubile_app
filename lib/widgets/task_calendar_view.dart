import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../theme.dart';

class TaskCalendarView extends StatefulWidget {
  final String? searchQuery;
  final List<String>? assigneeIds;
  final List<String> statusFilters;
  final List<String> priorityFilters;
  final Function(TaskModel) onTaskTap;

  const TaskCalendarView({
    super.key,
    this.searchQuery,
    this.assigneeIds,
    required this.statusFilters,
    required this.priorityFilters,
    required this.onTaskTap,
  });

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
  late DateTime _currentMonth;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    });
  }

  List<TaskModel> _getTasksForDate(DateTime date, List<TaskModel> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == date.year &&
             task.dueDate!.month == date.month &&
             task.dueDate!.day == date.day;
    }).toList();
  }

  Color _getTaskColor(TaskModel task) {
    if (task.isOverdue) return AppTheme.errorColor;
    if (task.isDueSoon) return AppTheme.warningColor;
    
    switch (task.priority) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        searchQuery: widget.searchQuery,
        assigneeIds: widget.assigneeIds,
        statusFilters: widget.statusFilters.isNotEmpty ? widget.statusFilters : null,
        priorityFilters: widget.priorityFilters.isNotEmpty ? widget.priorityFilters : null,
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
              ],
            ),
          );
        }

        final allTasks = snapshot.data ?? [];
        
        return Column(
          children: [
            // Calendar header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _getMonthYear(_currentMonth),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _goToToday,
                    child: const Text('Aujourd\'hui'),
                  ),
                ],
              ),
            ),
            
            // Weekday headers
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppTheme.backgroundColor,
              child: Row(
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Calendar grid
            Expanded(
              child: _buildCalendarGrid(allTasks),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarGrid(List<TaskModel> allTasks) {
    final firstDayOfMonth = _currentMonth;
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    final endDate = lastDayOfMonth.add(Duration(days: 7 - lastDayOfMonth.weekday));
    
    final weeks = <List<DateTime>>[];
    DateTime currentWeekStart = startDate;
    
    while (currentWeekStart.isBefore(endDate)) {
      final week = List.generate(7, (index) => currentWeekStart.add(Duration(days: index)));
      weeks.add(week);
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    }

    return ListView.builder(
      itemCount: weeks.length,
      itemBuilder: (context, weekIndex) {
        // Vérification de sécurité pour éviter les erreurs d'index
        if (weekIndex >= weeks.length) {
          return const SizedBox.shrink();
        }
        
        final week = weeks[weekIndex];
        return Container(
          height: 120,
          child: Row(
            children: week.map((date) {
              final isCurrentMonth = date.month == _currentMonth.month;
              final isToday = _isToday(date);
              final tasksForDate = _getTasksForDate(date, allTasks);
              
              return Expanded(
                child: _buildCalendarCell(date, isCurrentMonth, isToday, tasksForDate),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCalendarCell(DateTime date, bool isCurrentMonth, bool isToday, List<TaskModel> tasks) {
    return GestureDetector(
      onTap: () => _showDayTasks(date, tasks),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isToday 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : isCurrentMonth 
                  ? Colors.white 
                  : AppTheme.backgroundColor,
          border: Border.all(
            color: isToday 
                ? AppTheme.primaryColor 
                : Colors.grey[200]!,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Date number
            Container(
              height: 32,
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentMonth 
                      ? (isToday ? AppTheme.primaryColor : AppTheme.textPrimaryColor)
                      : AppTheme.textTertiaryColor,
                ),
              ),
            ),
            
            // Task indicators
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    ...tasks.take(3).map((task) {
                      return Container(
                        width: double.infinity,
                        height: 16,
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _getTaskColor(task),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    
                    // More tasks indicator
                    if (tasks.length > 3)
                      Container(
                        width: double.infinity,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${tasks.length - 3}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayTasks(DateTime date, List<TaskModel> tasks) {
    if (tasks.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Header
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${tasks.length} tâche${tasks.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Tasks list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    // Vérification de sécurité pour éviter les erreurs d'index
                    if (index >= tasks.length) {
                      return const SizedBox.shrink();
                    }
                    
                    final task = tasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildDayTaskItem(task),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayTaskItem(TaskModel task) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _getTaskColor(task),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildTaskBadge(task.priorityLabel, _getTaskColor(task)),
                const SizedBox(width: 8),
                _buildTaskBadge(task.statusLabel, _getStatusColor(task)),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(task.dueDate!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: task.isOverdue || task.isDueSoon
            ? Icon(
                task.isOverdue ? Icons.warning : Icons.schedule,
                color: task.isOverdue ? AppTheme.errorColor : AppTheme.warningColor,
                size: 20,
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          widget.onTaskTap(task);
        },
      ),
    );
  }

  Widget _buildTaskBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(TaskModel task) {
    switch (task.status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.warningColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    const weekdays = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    
    return '${weekdays[date.weekday - 1].capitalize()} ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}