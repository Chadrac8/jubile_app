import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../auth/auth_service.dart';
import '../widgets/task_card.dart';
import '../widgets/task_calendar_view.dart';
import 'task_detail_page.dart';
import '../../compatibility/app_theme_bridge.dart';

class MemberTasksPage extends StatefulWidget {
  const MemberTasksPage({super.key});

  @override
  State<MemberTasksPage> createState() => _MemberTasksPageState();
}

class _MemberTasksPageState extends State<MemberTasksPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedView = 'list'; // 'list', 'calendar'
  String _selectedFilter = 'active'; // 'all', 'active', 'completed', 'overdue', 'due_soon'
  String _selectedPriority = 'all'; // 'all', 'high', 'medium', 'low'
  bool _isLoading = true;
  
  List<TaskModel> _tasks = [];
  List<TaskReminderModel> _reminders = [];

  final Map<String, String> _filterLabels = {
    'all': 'Toutes',
    'active': 'Actives',
    'completed': 'Terminées',
    'overdue': 'En retard',
    'due_soon': 'Échéance proche',
  };

  final Map<String, String> _priorityLabels = {
    'all': 'Toutes priorités',
    'high': 'Haute priorité',
    'medium': 'Priorité moyenne',
    'low': 'Basse priorité',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) return;
      
      // Load user's reminders
      TasksFirebaseService.getUserRemindersStream(userId).listen((reminders) {
        if (mounted) {
          setState(() => _reminders = reminders);
        }
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _getStatusFilters() {
    switch (_selectedFilter) {
      case 'active':
        return ['todo', 'in_progress'];
      case 'completed':
        return ['completed'];
      case 'overdue':
      case 'due_soon':
        return ['todo', 'in_progress'];
      default:
        return [];
    }
  }

  List<String> _getPriorityFilters() {
    if (_selectedPriority == 'all') return [];
    return [_selectedPriority];
  }

  Future<void> _updateTaskStatus(TaskModel task, String newStatus) async {
    try {
      await TasksFirebaseService.updateTaskStatus(
        task.id, 
        newStatus, 
        userId: AuthService.currentUser?.uid,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tâche marquée comme ${task.statusLabel.toLowerCase()}'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    }
  }

  void _onTaskTap(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vous devez être connecté pour voir vos tâches'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tâches'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_selectedView == 'list' ? Icons.calendar_today : Icons.list),
            onPressed: () {
              setState(() {
                _selectedView = _selectedView == 'list' ? 'calendar' : 'list';
              });
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem(
                enabled: false,
                child: Text('Filtrer par statut', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ..._filterLabels.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: 'filter_${entry.key}',
                  child: Row(
                    children: [
                      Icon(
                        _selectedFilter == entry.key ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Filtrer par priorité', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ..._priorityLabels.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: 'priority_${entry.key}',
                  child: Row(
                    children: [
                      Icon(
                        _selectedPriority == entry.key ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }),
            ],
            onSelected: (value) {
              final parts = value.toString().split('_');
              if (parts[0] == 'filter') {
                setState(() => _selectedFilter = parts[1]);
              } else if (parts[0] == 'priority') {
                setState(() => _selectedPriority = parts[1]);
              }
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildHeader(),
                _buildRemindersSection(),
                Expanded(
                  child: _selectedView == 'list' ? _buildTasksList() : _buildCalendarView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Filtres actifs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(_filterLabels[_selectedFilter]!),
                backgroundColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
              ),
              if (_selectedPriority != 'all')
                Chip(
                  label: Text(_priorityLabels[_selectedPriority]!),
                  backgroundColor: Theme.of(context).colorScheme.secondaryColor.withOpacity(0.1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    if (_reminders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Rappels (${_reminders.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
          ...(_reminders.take(3).map((reminder) {
            return ListTile(
              dense: true,
              leading: Icon(
                _getReminderIcon(reminder.type),
                color: Theme.of(context).colorScheme.warningColor,
                size: 20,
              ),
              title: Text(_getReminderTitle(reminder.type)),
              subtitle: Text(_formatReminderDate(reminder.reminderDate)),
              onTap: () async {
                await TasksFirebaseService.markReminderAsRead(reminder.id);
                // Navigate to related task
              },
            );
          }).toList()),
          if (_reminders.length > 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  // Navigate to full reminders list
                },
                child: Text('Voir tous les rappels (${_reminders.length})'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        assigneeIds: [AuthService.currentUser!.uid],
        statusFilters: _getStatusFilters(),
        priorityFilters: _getPriorityFilters(),
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
                Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.errorColor),
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

        var tasks = snapshot.data ?? [];

        // Apply special filters
        if (_selectedFilter == 'overdue') {
          tasks = tasks.where((task) => task.isOverdue).toList();
        } else if (_selectedFilter == 'due_soon') {
          tasks = tasks.where((task) => task.isDueSoon).toList();
        }

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyStateIcon(),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyStateTitle(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateSubtitle(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            // Vérification de sécurité pour éviter les erreurs d'index
            if (index >= tasks.length) {
              return const SizedBox.shrink();
            }
            
            final task = tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(
                task: task,
                onTap: () => _onTaskTap(task),
                onLongPress: () {},
                isSelectionMode: false,
                isSelected: false,
                onSelectionChanged: (_) {},
                showActions: true,
                onStatusChanged: (newStatus) => _updateTaskStatus(task, newStatus),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarView() {
    return TaskCalendarView(
      assigneeIds: [AuthService.currentUser!.uid],
      statusFilters: _getStatusFilters(),
      priorityFilters: _getPriorityFilters(),
      onTaskTap: _onTaskTap,
    );
  }

  IconData _getReminderIcon(String type) {
    switch (type) {
      case 'due_soon':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning;
      case 'assigned':
        return Icons.assignment_ind;
      case 'comment_added':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  String _getReminderTitle(String type) {
    switch (type) {
      case 'due_soon':
        return 'Échéance proche';
      case 'overdue':
        return 'Tâche en retard';
      case 'assigned':
        return 'Nouvelle assignation';
      case 'comment_added':
        return 'Nouveau commentaire';
      default:
        return 'Rappel';
    }
  }

  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedFilter) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'overdue':
        return Icons.warning_amber;
      case 'due_soon':
        return Icons.schedule;
      default:
        return Icons.task_alt;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'completed':
        return 'Aucune tâche terminée';
      case 'overdue':
        return 'Aucune tâche en retard';
      case 'due_soon':
        return 'Aucune échéance proche';
      case 'active':
        return 'Aucune tâche active';
      default:
        return 'Aucune tâche';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'completed':
        return 'Terminez vos tâches pour les voir apparaître ici';
      case 'overdue':
        return 'Bravo ! Toutes vos tâches sont à jour';
      case 'due_soon':
        return 'Aucune tâche n\'arrive à échéance prochainement';
      case 'active':
        return 'Vous n\'avez pas de tâches en cours';
      default:
        return 'Vous n\'avez aucune tâche assignée';
    }
  }
}