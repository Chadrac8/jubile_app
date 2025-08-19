import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../models/person_model.dart';
import 'workflow_detail_page.dart';

class WorkflowFollowupsManagementPage extends StatelessWidget {
  const WorkflowFollowupsManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des suivis de workflow'),
      ),
      body: StreamBuilder<List<WorkflowModel>>(
        stream: FirebaseService.getWorkflowsStream(),
        builder: (context, workflowSnapshot) {
          if (workflowSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!workflowSnapshot.hasData || workflowSnapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun workflow trouvé.'));
          }
          final workflows = workflowSnapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workflows.length,
            separatorBuilder: (context, i) => const SizedBox(height: 24),
            itemBuilder: (context, i) {
              final workflow = workflows[i];
              return _WorkflowCard(workflow: workflow);
            },
          );
        },
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  final WorkflowModel workflow;
  const _WorkflowCard({required this.workflow});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(workflow.color.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getIconData(workflow.icon), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        workflow.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x1A388E3C),
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
              ],
            ),
            const SizedBox(height: 16),
            Text('Étapes : ${workflow.steps.length}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            _WorkflowPersonsList(workflowId: workflow.id, steps: workflow.steps),
          ],
        ),
      ),
    );
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
}

class _WorkflowPersonsList extends StatelessWidget {
  final String workflowId;
  final List<WorkflowStep> steps;
  const _WorkflowPersonsList({required this.workflowId, required this.steps});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PersonWorkflowModel>>(
      stream: FirebaseService.getPersonWorkflowsByWorkflowId(workflowId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final personWorkflows = snapshot.data ?? [];
        if (personWorkflows.isEmpty) {
          return const Text('Aucune personne en suivi.', style: TextStyle(color: Colors.grey));
        }
        return Column(
          children: personWorkflows.map((pw) => _WorkflowPersonTile(personWorkflow: pw, steps: steps)).toList(),
        );
      },
    );
  }
}

class _WorkflowPersonTile extends StatelessWidget {
  final PersonWorkflowModel personWorkflow;
  final List<WorkflowStep> steps;
  const _WorkflowPersonTile({required this.personWorkflow, required this.steps});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersonModel?>(
      future: FirebaseService.getPerson(personWorkflow.personId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(title: Text('Chargement...'));
        }
        final person = snapshot.data!;
        final progress = steps.isNotEmpty ? (personWorkflow.completedSteps.length / steps.length) : 0.0;
        return ListTile(
          leading: CircleAvatar(child: Text(person.displayInitials)),
          title: Text(person.fullName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${personWorkflow.completedSteps.length}/${steps.length} étapes complétées'),
              LinearProgressIndicator(value: progress, minHeight: 6),
              Text('Statut: ${personWorkflow.status}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () async {
              // Récupérer le workflow complet (pour les étapes, couleurs, etc.)
              final workflow = await FirebaseService.getWorkflow(personWorkflow.workflowId);
              if (workflow == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workflow introuvable')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkflowDetailPage(
                    personWorkflow: personWorkflow,
                    workflow: workflow,
                    person: person,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
