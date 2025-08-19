import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../widgets/task_card.dart';
import '../widgets/task_list_card.dart';
import '../widgets/task_kanban_view.dart';
import '../widgets/task_calendar_view.dart';
import '../widgets/task_search_filter_bar.dart';
import 'task_form_page.dart';
import 'task_list_form_page.dart';
import 'task_detail_page.dart';
import '../theme.dart';

class TasksHomePage extends StatefulWidget {
  const TasksHomePage({super.key});

  @override
  State<TasksHomePage> createState() => _TasksHomePageState();
}

class _TasksHomePageState extends State<TasksHomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  List<String> _selectedStatusFilters = ['todo', 'in_progress'];
  List<String> _selectedPriorityFilters = [];
  DateTime? _dueBefore;
  DateTime? _dueAfter;
  String _currentView = 'lists'; // 'lists', 'tasks', 'kanban', 'calendar'
  
  List<TaskModel> _selectedTasks = [];
  List<TaskListModel> _selectedTaskLists = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onFiltersChanged(
    List<String> statusFilters,
    List<String> priorityFilters,
    DateTime? dueBefore,
    DateTime? dueAfter,
  ) {
    setState(() {
      _selectedStatusFilters = statusFilters;
      _selectedPriorityFilters = priorityFilters;
      _dueBefore = dueBefore;
      _dueAfter = dueAfter;
    });
  }

  void _changeView(String view) {
    setState(() {
      _currentView = view;
      _isSelectionMode = false;
      _selectedTasks.clear();
      _selectedTaskLists.clear();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTasks.clear();
        _selectedTaskLists.clear();
      }
    });
  }

  void _onTaskSelected(TaskModel task, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTasks.add(task);
      } else {
        _selectedTasks.remove(task);
      }
    });
  }

  void _onTaskListSelected(TaskListModel taskList, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTaskLists.add(taskList);
      } else {
        _selectedTaskLists.remove(taskList);
      }
    });
  }

  Future<void> _createNewTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskFormPage()),
    );
    if (result == true) {
      // Refresh handled by streams
    }
  }

  Future<void> _createNewTaskList() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskListFormPage()),
    );
    if (result == true) {
      // Refresh handled by streams
    }
  }

  Future<void> _createFromTemplate() async {
    await _showTemplateDialog();
  }

  Future<void> _performBulkAction(String action) async {
    try {
      switch (action) {
        case 'complete':
          await _completeSelectedTasks();
          break;
        case 'delete':
          await _showDeleteConfirmation();
          break;
        case 'assign':
          await _showAssignmentDialog();
          break;
        case 'move':
          await _showMoveToListDialog();
          break;
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

  Future<void> _completeSelectedTasks() async {
    for (final task in _selectedTasks) {
      await TasksFirebaseService.updateTaskStatus(task.id, 'completed');
    }
    _toggleSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tâches marquées comme terminées'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          _selectedTasks.isNotEmpty
              ? 'Voulez-vous vraiment supprimer ${_selectedTasks.length} tâche(s) ?'
              : 'Voulez-vous vraiment supprimer ${_selectedTaskLists.length} liste(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final task in _selectedTasks) {
        await TasksFirebaseService.deleteTask(task.id);
      }
      for (final taskList in _selectedTaskLists) {
        await TasksFirebaseService.deleteTaskList(taskList.id);
      }
      _toggleSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Éléments supprimés'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  Future<void> _showAssignmentDialog() async {
    // Implementation would show user selection dialog
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité d\'assignation à implémenter')),
    );
  }

  Future<void> _showMoveToListDialog() async {
    // Implementation would show task list selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de déplacement à implémenter')),
    );
  }

  Future<void> _showTemplateDialog() async {
    final templates = await TasksFirebaseService.getTaskTemplates();
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => _TemplateSelectionDialog(templates: templates),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tâches'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_currentView == 'lists' ? Icons.view_list : 
                      _currentView == 'tasks' ? Icons.view_agenda :
                      _currentView == 'kanban' ? Icons.view_kanban :
                      Icons.calendar_today),
            onPressed: _showViewSelector,
          ),
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showBulkActionsMenu,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Toggle search bar
              },
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'template',
                  child: ListTile(
                    leading: Icon(Icons.library_add),
                    title: Text('Créer depuis modèle'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'statistics',
                  child: ListTile(
                    leading: Icon(Icons.analytics),
                    title: Text('Statistiques'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Paramètres'),
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'template':
                    _createFromTemplate();
                    break;
                  case 'statistics':
                    _showStatistics();
                    break;
                  case 'settings':
                    _showSettings();
                    break;
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          TaskSearchFilterBar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onFiltersChanged: _onFiltersChanged,
            selectedStatusFilters: _selectedStatusFilters,
            selectedPriorityFilters: _selectedPriorityFilters,
            dueBefore: _dueBefore,
            dueAfter: _dueAfter,
          ),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: _isSelectionMode
                ? FloatingActionButton(
                    onPressed: _toggleSelectionMode,
                    backgroundColor: AppTheme.errorColor,
                    child: const Icon(Icons.close),
                  )
                : FloatingActionButton.extended(
                    onPressed: _showCreateMenu,
                    label: const Text('Créer'),
                    icon: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'lists':
        return _buildListsView();
      case 'tasks':
        return _buildTasksView();
      case 'kanban':
        return _buildKanbanView();
      case 'calendar':
        return _buildCalendarView();
      default:
        return _buildListsView();
    }
  }

  Widget _buildListsView() {
    return StreamBuilder<List<TaskListModel>>(
      stream: TasksFirebaseService.getTaskListsStream(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilters: ['active'],
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

        final taskLists = snapshot.data ?? [];

        if (taskLists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune liste de tâches',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre première liste pour organiser vos tâches',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createNewTaskList,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une liste'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: taskLists.length,
          itemBuilder: (context, index) {
            // Vérification de sécurité pour éviter les erreurs d'index
            if (index >= taskLists.length) {
              return const SizedBox.shrink();
            }
            
            final taskList = taskLists[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TaskListCard(
                taskList: taskList,
                onTap: () => _onTaskListTap(taskList),
                onLongPress: () => _onTaskListLongPress(taskList),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedTaskLists.contains(taskList),
                onSelectionChanged: (isSelected) => _onTaskListSelected(taskList, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTasksView() {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilters: _selectedStatusFilters.isNotEmpty ? _selectedStatusFilters : null,
        priorityFilters: _selectedPriorityFilters.isNotEmpty ? _selectedPriorityFilters : null,
        dueBefore: _dueBefore,
        dueAfter: _dueAfter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Aucune tâche trouvée'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createNewTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une tâche'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
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
                onLongPress: () => _onTaskLongPress(task),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedTasks.contains(task),
                onSelectionChanged: (isSelected) => _onTaskSelected(task, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKanbanView() {
    return TaskKanbanView(
      searchQuery: _searchQuery,
      statusFilters: _selectedStatusFilters,
      priorityFilters: _selectedPriorityFilters,
      dueBefore: _dueBefore,
      dueAfter: _dueAfter,
      onTaskTap: _onTaskTap,
    );
  }

  Widget _buildCalendarView() {
    return TaskCalendarView(
      searchQuery: _searchQuery,
      statusFilters: _selectedStatusFilters,
      priorityFilters: _selectedPriorityFilters,
      onTaskTap: _onTaskTap,
    );
  }

  void _onTaskTap(TaskModel task) {
    if (_isSelectionMode) {
      _onTaskSelected(task, !_selectedTasks.contains(task));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailPage(task: task),
        ),
      );
    }
  }

  void _onTaskLongPress(TaskModel task) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onTaskSelected(task, true);
    }
  }

  void _onTaskListTap(TaskListModel taskList) {
    if (_isSelectionMode) {
      _onTaskListSelected(taskList, !_selectedTaskLists.contains(taskList));
    } else {
      // Navigate to task list detail view
      setState(() {
        _currentView = 'tasks';
        // Filter tasks by this list
      });
    }
  }

  void _onTaskListLongPress(TaskListModel taskList) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onTaskListSelected(taskList, true);
    }
  }

  void _showViewSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.view_list, color: _currentView == 'lists' ? AppTheme.primaryColor : null),
              title: const Text('Listes'),
              onTap: () {
                Navigator.pop(context);
                _changeView('lists');
              },
            ),
            ListTile(
              leading: Icon(Icons.view_agenda, color: _currentView == 'tasks' ? AppTheme.primaryColor : null),
              title: const Text('Tâches'),
              onTap: () {
                Navigator.pop(context);
                _changeView('tasks');
              },
            ),
            ListTile(
              leading: Icon(Icons.view_kanban, color: _currentView == 'kanban' ? AppTheme.primaryColor : null),
              title: const Text('Kanban'),
              onTap: () {
                Navigator.pop(context);
                _changeView('kanban');
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: _currentView == 'calendar' ? AppTheme.primaryColor : null),
              title: const Text('Calendrier'),
              onTap: () {
                Navigator.pop(context);
                _changeView('calendar');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Nouvelle tâche'),
              subtitle: const Text('Créer une tâche individuelle'),
              onTap: () {
                Navigator.pop(context);
                _createNewTask();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Nouvelle liste'),
              subtitle: const Text('Créer une liste de tâches'),
              onTap: () {
                Navigator.pop(context);
                _createNewTaskList();
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_add),
              title: const Text('Depuis un modèle'),
              subtitle: const Text('Utiliser un modèle prédéfini'),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedTasks.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: AppTheme.successColor),
                title: const Text('Marquer comme terminé'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('complete');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Assigner'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('assign');
                },
              ),
              ListTile(
                leading: const Icon(Icons.move_to_inbox),
                title: const Text('Déplacer vers une liste'),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkAction('move');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('delete');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics() {
    // Implementation for statistics view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Statistiques à implémenter')),
    );
  }

  void _showSettings() {
    // Implementation for settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres à implémenter')),
    );
  }
}

class _TemplateSelectionDialog extends StatelessWidget {
  final List<TaskTemplateModel> templates;

  const _TemplateSelectionDialog({required this.templates});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un modèle'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return ListTile(
              leading: Icon(
                template.type == 'task' ? Icons.task_alt : Icons.list_alt,
                color: AppTheme.primaryColor,
              ),
              title: Text(template.name),
              subtitle: Text(template.description),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate(context, template);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  void _createFromTemplate(BuildContext context, TaskTemplateModel template) async {
    try {
      await TasksFirebaseService.createFromTemplate(template.id, {});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${template.name} créé avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}