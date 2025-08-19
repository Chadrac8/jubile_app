import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'workflow_edit_page.dart';

class WorkflowDetailPage extends StatefulWidget {
  final PersonWorkflowModel personWorkflow;
  final WorkflowModel workflow;
  final PersonModel person;

  const WorkflowDetailPage({
    super.key,
    required this.personWorkflow,
    required this.workflow,
    required this.person,
  });

  @override
  State<WorkflowDetailPage> createState() => _WorkflowDetailPageState();
}

class _WorkflowDetailPageState extends State<WorkflowDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PersonWorkflowModel? _currentWorkflow;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentWorkflow = widget.personWorkflow;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleStepCompletion(String stepId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isCompleted = _currentWorkflow!.completedSteps.contains(stepId);
      
      if (isCompleted) {
        await FirebaseService.markWorkflowStepAsIncomplete(
          widget.person.id,
          _currentWorkflow!.id,
          stepId,
        );
        _currentWorkflow!.completedSteps.remove(stepId);
      } else {
        await FirebaseService.markWorkflowStepAsComplete(
          widget.person.id,
          _currentWorkflow!.id,
          stepId,
        );
        _currentWorkflow!.completedSteps.add(stepId);
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isCompleted ? Icons.remove_circle : Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCompleted 
                    ? 'Étape marquée comme non terminée'
                    : 'Étape marquée comme terminée',
                ),
              ),
            ],
          ),
          backgroundColor: isCompleted 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeWorkflow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 8),
            const Text('Terminer le workflow'),
          ],
        ),
        content: Text(
          'Voulez-vous marquer ce workflow comme terminé pour ${widget.person.fullName} ?\\n\\nCette action marquera toutes les étapes restantes comme terminées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseService.completeWorkflowForPerson(
          widget.person.id,
          _currentWorkflow!.id,
        );

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Workflow terminé avec succès !')),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pauseWorkflow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.pause, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Mettre en pause'),
          ],
        ),
        content: Text(
          'Voulez-vous mettre en pause ce workflow pour ${widget.person.fullName} ?\\n\\nVous pourrez le reprendre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Mettre en pause'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.pauseWorkflowForPerson(
          widget.person.id,
          _currentWorkflow!.id,
        );

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.pause, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Workflow mis en pause')),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _editWorkflow() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowEditPage(
          personWorkflow: _currentWorkflow!,
          workflow: widget.workflow,
          person: widget.person,
        ),
      ),
    );

    // Si des modifications ont été apportées, recharger les données
    if (result == true) {
      // Recharger les données du workflow
      final updatedWorkflow = await FirebaseService.getPersonWorkflowsStream(widget.person.id)
          .firstWhere((workflows) => workflows.any((w) => w.id == widget.personWorkflow.id))
          .then((workflows) => workflows.firstWhere((w) => w.id == widget.personWorkflow.id));
      
      setState(() {
        _currentWorkflow = updatedWorkflow;
      });
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'track_changes':
        return Icons.track_changes;
      case 'person_add':
        return Icons.person_add;
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'healing':
        return Icons.healing;
      case 'church':
        return Icons.church;
      case 'groups':
        return Icons.groups;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'psychology':
        return Icons.psychology;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.track_changes;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'actif':
        return Colors.green;
      case 'completed':
      case 'terminé':
        return Colors.blue;
      case 'paused':
      case 'en pause':
        return Colors.orange;
      case 'cancelled':
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'paused':
        return 'En pause';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double get _progress {
    if (widget.workflow.steps.isEmpty) return 0.0;
    return _currentWorkflow!.completedSteps.length / widget.workflow.steps.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.workflow.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))),
                        Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconData(widget.workflow.icon),
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editWorkflow();
                        break;
                      case 'complete':
                        _completeWorkflow();
                        break;
                      case 'pause':
                        _pauseWorkflow();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Modifier le suivi'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Marquer comme terminé'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pause',
                      child: Row(
                        children: [
                          Icon(Icons.pause, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Mettre en pause'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Person and workflow info
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  
                  // Progress overview
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  
                  // Workflow steps
                  _buildStepsCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.person.profileImageUrl != null 
                    ? NetworkImage(widget.person.profileImageUrl!)
                    : null,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: widget.person.profileImageUrl == null
                    ? Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      )
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.person.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_currentWorkflow!.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(_currentWorkflow!.status),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(_currentWorkflow!.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Workflow details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconData(widget.workflow.icon),
                          color: Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.workflow.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.workflow.category,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.workflow.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commencé le',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              _formatDate(_currentWorkflow!.startDate),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_currentWorkflow!.completedDate != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terminé le',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                _formatDate(_currentWorkflow!.completedDate!),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress circle and stats
            Row(
              children: [
                // Progress circle
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 8,
                            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_progress * 100).round()}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                
                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow(
                        'Étapes terminées',
                        '${_currentWorkflow!.completedSteps.length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        'Étapes restantes',
                        '${widget.workflow.steps.length - _currentWorkflow!.completedSteps.length}',
                        Icons.pending,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        'Total d\'étapes',
                        '${widget.workflow.steps.length}',
                        Icons.list_alt,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Progress bar with labels
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression globale',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_currentWorkflow!.completedSteps.length}/${widget.workflow.steps.length} étapes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(int.parse(widget.workflow.color.replaceFirst('#', '0xFF'))),
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_list_numbered,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Étapes du workflow',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Steps list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.workflow.steps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final step = widget.workflow.steps[index];
                final isCompleted = _currentWorkflow!.completedSteps.contains(step.id);
                
                return _buildStepItem(step, isCompleted, index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(WorkflowStep step, bool isCompleted, int stepNumber) {
    return Container(
      decoration: BoxDecoration(
        color: isCompleted 
          ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: GestureDetector(
          onTap: _isLoading ? null : () => _toggleStepCompletion(step.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted 
                ? Theme.of(context).colorScheme.secondary
                : Colors.transparent,
              border: Border.all(
                color: isCompleted 
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Center(
                  child: Text(
                    stepNumber.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
          ),
        ),
        title: Text(
          step.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted 
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
              : null,
          ),
        ),
        subtitle: step.description.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                step.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            )
          : null,
        trailing: isCompleted
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.secondary,
            )
          : Icon(
              Icons.radio_button_unchecked,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
        onTap: _isLoading ? null : () => _toggleStepCompletion(step.id),
      ),
    );
  }
}