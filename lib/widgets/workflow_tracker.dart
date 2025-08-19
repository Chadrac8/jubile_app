import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';
import '../pages/workflow_form_page.dart';
import '../pages/workflow_detail_page.dart';
import '../pages/workflow_edit_page.dart';
import '../../compatibility/app_theme_bridge.dart';

class WorkflowTracker extends StatefulWidget {
  final PersonModel person;

  const WorkflowTracker({super.key, required this.person});

  @override
  State<WorkflowTracker> createState() => _WorkflowTrackerState();
}

class _WorkflowTrackerState extends State<WorkflowTracker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

  Future<void> _startNewWorkflow() async {
    try {
      final workflows = await FirebaseService.getWorkflowsStream().first;
      
      if (!mounted) return;

      // Afficher le menu de choix : workflow existant ou créer nouveau
      final choice = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  Icons.playlist_add_check,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Démarrer un suivi'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choisissez une option pour ${widget.person.fullName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xB3000000), // 70% opacity black
                  ),
                ),
                const SizedBox(height: 20),
                
                // Option : Utiliser un workflow existant
                if (workflows.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'existing'),
                      icon: const Icon(Icons.list_alt),
                      label: Text('Utiliser un workflow existant (${workflows.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                
                // Option : Créer un nouveau workflow
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'create'),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Créer un nouveau workflow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (choice == null) return;

      if (choice == 'create') {
        await _createNewWorkflow();
      } else if (choice == 'existing') {
        await _selectExistingWorkflow(workflows);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectExistingWorkflow(List<WorkflowModel> workflows) async {
    if (workflows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucun workflow disponible'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final selectedWorkflow = await showDialog<WorkflowModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Choisir un workflow'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sélectionnez un workflow pour ${widget.person.fullName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xB3000000), // 70% opacity black
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: workflows.length,
                  itemBuilder: (context, index) {
                    final workflow = workflows[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0x33000000), // 20% opacity black
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))).withAlpha(25), // 10% opacity
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconData(workflow.icon),
                            color: Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          workflow.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(workflow.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A388E3C), // 10% opacity of secondary (#388E3C)
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    workflow.category,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${workflow.steps.length} étape(s)',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0x99000000), // 60% opacity black
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => Navigator.pop(context, workflow),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (selectedWorkflow != null) {
      await FirebaseService.startWorkflowForPerson(widget.person.id, selectedWorkflow.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Workflow "${selectedWorkflow.name}" démarré'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _createNewWorkflow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowFormPage(
          personId: widget.person.id,
          personName: widget.person.fullName,
        ),
      ),
    );

    if (result == true) {
      // Workflow créé et assigné avec succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Nouveau workflow créé et assigné avec succès'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with action button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suivis en cours',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Processus de suivi et d\'accompagnement',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0x99000000), // 60% opacity black
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _startNewWorkflow,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau suivi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Workflows list
            Expanded(
              child: StreamBuilder<List<PersonWorkflowModel>>(
                stream: _getPersonWorkflows(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final personWorkflows = snapshot.data ?? [];

                  if (personWorkflows.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: personWorkflows.length,
                    itemBuilder: (context, index) {
                      final personWorkflow = personWorkflows[index];
                      return _buildWorkflowCard(personWorkflow);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0x1A388E3C), // 10% opacity of secondary (#388E3C)
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.playlist_add_check,
              size: 80,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun suivi en cours',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez un nouveau suivi pour accompagner cette personne',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0x99000000), // 60% opacity black
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _startNewWorkflow,
                icon: const Icon(Icons.add),
                label: const Text('Démarrer un suivi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _createNewWorkflow(),
                icon: const Icon(Icons.add_task),
                label: const Text('Créer workflow'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(PersonWorkflowModel personWorkflow) {
    return FutureBuilder<WorkflowModel?>(
      future: _getWorkflowDetails(personWorkflow.workflowId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Chargement...'),
            ),
          );
        }

        final workflow = snapshot.data!;
        final progress = workflow.steps.isNotEmpty 
            ? (personWorkflow.completedSteps.length / workflow.steps.length)
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x33000000), // 20% opacity black
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D000000), // 5% opacity black
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))).withAlpha(25), // 10% opacity
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconData(workflow.icon),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workflow.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x1A1976D2), // 10% opacity of primary (#1976D2)
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  workflow.category,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(personWorkflow.status).withAlpha(25), // 10% opacity
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(personWorkflow.status),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _getStatusColor(personWorkflow.status),
                                    fontWeight: FontWeight.w500,
                                  ),
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
              
              // Progress and details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progrès',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${personWorkflow.completedSteps.length}/${workflow.steps.length} étapes',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(0x33000000), // 20% opacity black
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dates and actions
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commencé le',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0x99000000), // 60% opacity black
                                ),
                              ),
                              Text(
                                _formatDate(personWorkflow.startDate),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _editWorkflow(personWorkflow, workflow),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Modifier'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openWorkflowDetails(personWorkflow, workflow),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('Voir détails'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _openWorkflowDetails(PersonWorkflowModel personWorkflow, WorkflowModel workflow) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowDetailPage(
          personWorkflow: personWorkflow,
          workflow: workflow,
          person: widget.person,
        ),
      ),
    );
  }

  Future<void> _editWorkflow(PersonWorkflowModel personWorkflow, WorkflowModel workflow) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowEditPage(
          personWorkflow: personWorkflow,
          workflow: workflow,
          person: widget.person,
        ),
      ),
    );

    // Si des modifications ont été apportées, rafraîchir l'affichage
    if (result == true) {
      setState(() {
        // Le StreamBuilder se rechargera automatiquement
      });
    }
  }

  Stream<List<PersonWorkflowModel>> _getPersonWorkflows() {
    return FirebaseService.getPersonWorkflowsStream(widget.person.id);
  }

  Future<WorkflowModel?> _getWorkflowDetails(String workflowId) async {
    return await FirebaseService.getWorkflow(workflowId);
  }
}