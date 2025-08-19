import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../widgets/task_comments_widget.dart';
import 'task_form_page.dart';
import '../theme.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskModel task;

  const TaskDetailPage({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  TaskModel? _currentTask;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();
    _refreshTaskData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshTaskData() async {
    try {
      final task = await TasksFirebaseService.getTask(widget.task.id);
      if (task != null && mounted) {
        setState(() => _currentTask = task);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rafraîchissement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormPage(task: _currentTask),
      ),
    );
    
    if (result == true) {
      await _refreshTaskData();
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    try {
      setState(() => _isLoading = true);
      
      await TasksFirebaseService.updateTaskStatus(_currentTask!.id, newStatus);
      await _refreshTaskData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusLabel(newStatus)}'),
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _duplicateTask() async {
    try {
      setState(() => _isLoading = true);
      
      await TasksFirebaseService.duplicateTask(_currentTask!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tâche dupliquée avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la duplication: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color get _priorityColor {
    switch (_currentTask?.priority) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.warningColor;
    }
  }

  Color get _statusColor {
    switch (_currentTask?.status) {
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTask == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tâche')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _currentTask!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _priorityColor,
                        _priorityColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60), // Space for app bar
                        
                        // Priority and status badges
                        Row(
                          children: [
                            _buildBadge(
                              _currentTask!.priorityLabel,
                              _priorityColor,
                              Icons.flag,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              _currentTask!.statusLabel,
                              _statusColor,
                              Icons.circle,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Due date if present
                        if (_currentTask!.dueDate != null)
                          Row(
                            children: [
                              Icon(
                                _currentTask!.isOverdue 
                                    ? Icons.warning 
                                    : Icons.schedule,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(_currentTask!.dueDate!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Dupliquer'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editTask();
                        break;
                      case 'duplicate':
                        _duplicateTask();
                        break;
                      case 'delete':
                        _showDeleteConfirmation();
                        break;
                    }
                  },
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Détails'),
                    Tab(text: 'Commentaires'),
                    Tab(text: 'Activité'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(),
            _buildCommentsTab(),
            _buildActivityTab(),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: _buildStatusFAB(),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        if (_currentTask!.description.isNotEmpty) ...[
          _buildInfoCard(
            title: 'Description',
            icon: Icons.description,
            children: [
              Text(
                _currentTask!.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Details
        _buildInfoCard(
          title: 'Informations',
          icon: Icons.info,
          children: [
            _buildInfoRow(
              icon: Icons.person,
              label: 'Créé par',
              value: _currentTask!.createdBy,
            ),
            if (_currentTask!.assigneeIds.isNotEmpty)
              _buildInfoRow(
                icon: Icons.people,
                label: 'Assigné à',
                value: '${_currentTask!.assigneeIds.length} personne(s)',
              ),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Créé le',
              value: _formatDate(_currentTask!.createdAt),
            ),
            if (_currentTask!.updatedAt != _currentTask!.createdAt)
              _buildInfoRow(
                icon: Icons.update,
                label: 'Modifié le',
                value: _formatDate(_currentTask!.updatedAt),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Tags
        if (_currentTask!.tags.isNotEmpty) ...[
          _buildInfoCard(
            title: 'Tags',
            icon: Icons.label,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentTask!.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Attachments
        if (_currentTask!.attachmentUrls.isNotEmpty) ...[
          _buildInfoCard(
            title: 'Pièces jointes',
            icon: Icons.attach_file,
            children: [
              ...(_currentTask!.attachmentUrls.map((url) {
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text('Fichier joint'),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    // TODO: Download or view attachment
                  },
                );
              }).toList()),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Linked items
        if (_currentTask!.linkedToType != null) ...[
          _buildInfoCard(
            title: 'Lié à',
            icon: Icons.link,
            children: [
              _buildInfoRow(
                icon: Icons.link,
                label: 'Type',
                value: _currentTask!.linkedToType!,
              ),
              _buildInfoRow(
                icon: Icons.tag,
                label: 'ID',
                value: _currentTask!.linkedToId ?? '',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCommentsTab() {
    return TaskCommentsWidget(task: _currentTask!);
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Text('Historique des activités à implémenter'),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFAB() {
    if (_currentTask!.isCompleted) {
      return FloatingActionButton.extended(
        onPressed: () => _updateTaskStatus('todo'),
        icon: const Icon(Icons.undo),
        label: const Text('Rouvrir'),
        backgroundColor: AppTheme.warningColor,
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: () => _updateTaskStatus('completed'),
        icon: const Icon(Icons.check),
        label: const Text('Terminer'),
        backgroundColor: AppTheme.successColor,
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette tâche ?'),
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
      try {
        await TasksFirebaseService.deleteTask(_currentTask!.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche supprimée'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}