import 'package:flutter/material.dart';
import '../models/automation.dart';
import '../models/automation_template.dart';
import '../services/automation_service.dart';
import '../../../theme.dart';
import '../../../widgets/custom_card.dart';

/// Vue de formulaire pour créer/modifier une automatisation
class AutomationFormView extends StatefulWidget {
  final Automation? automation;
  final bool isEdit;
  final AutomationTemplate? template;

  const AutomationFormView({
    Key? key,
    this.automation,
    this.isEdit = false,
    this.template,
  }) : super(key: key);

  @override
  State<AutomationFormView> createState() => _AutomationFormViewState();
}

class _AutomationFormViewState extends State<AutomationFormView> {
  final _formKey = GlobalKey<FormState>();
  final AutomationService _automationService = AutomationService();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  // Form data
  AutomationTrigger _selectedTrigger = AutomationTrigger.personAdded;
  AutomationStatus _selectedStatus = AutomationStatus.draft;
  List<AutomationCondition> _conditions = [];
  List<AutomationActionConfig> _actions = [];
  Map<String, dynamic> _triggerConfig = {};
  bool _isRecurring = false;
  String _scheduleExpression = '';

  @override
  void initState() {
    super.initState();
    
    if (widget.automation != null) {
      _loadAutomationData();
    } else if (widget.template != null) {
      _loadTemplateData();
    }
  }

  void _loadAutomationData() {
    final automation = widget.automation!;
    _nameController.text = automation.name;
    _descriptionController.text = automation.description;
    _tagsController.text = automation.tags.join(', ');
    _selectedTrigger = automation.trigger;
    _selectedStatus = automation.status;
    _conditions = List.from(automation.conditions);
    _actions = List.from(automation.actions);
    _triggerConfig = Map.from(automation.triggerConfig);
    _isRecurring = automation.isRecurring;
    _scheduleExpression = automation.schedule ?? '';
  }

  void _loadTemplateData() {
    final template = widget.template!;
    _nameController.text = template.name;
    _descriptionController.text = template.description;
    _selectedTrigger = template.trigger;
    _selectedStatus = AutomationStatus.draft;
    _conditions = List.from(template.conditions);
    _actions = List.from(template.actions);
    _triggerConfig = Map<String, dynamic>.from(template.triggerConfig);
    _isRecurring = false; // Par défaut
    _scheduleExpression = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Modifier l\'automatisation' : 'Nouvelle automatisation'),
        actions: [
          TextButton(
            onPressed: _saveAutomation,
            child: Text(widget.isEdit ? 'Modifier' : 'Créer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoCard(),
              const SizedBox(height: 20),
              _buildTriggerCard(),
              const SizedBox(height: 20),
              _buildConditionsCard(),
              const SizedBox(height: 20),
              _buildActionsCard(),
              const SizedBox(height: 20),
              _buildScheduleCard(),
              const SizedBox(height: 20),
              _buildTagsCard(),
              const SizedBox(height: 20),
              _buildStatusCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de base',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'automatisation',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir un nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Déclencheur',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AutomationTrigger>(
            value: _selectedTrigger,
            decoration: const InputDecoration(
              labelText: 'Type de déclencheur',
              border: OutlineInputBorder(),
            ),
            items: AutomationTrigger.values.map((trigger) {
              return DropdownMenuItem(
                value: trigger,
                child: Text(trigger.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTrigger = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Conditions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addCondition,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_conditions.isEmpty)
            const Text('Aucune condition définie')
          else
            ..._conditions.asMap().entries.map(
              (entry) => Card(
                child: ListTile(
                  title: Text('${entry.value.field} ${entry.value.operator} ${entry.value.value}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeCondition(entry.key),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addAction,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_actions.isEmpty)
            const Text('Aucune action définie')
          else
            ..._actions.asMap().entries.map(
              (entry) => Card(
                child: ListTile(
                  title: Text(entry.value.action.label),
                  subtitle: entry.value.delayMinutes != null 
                      ? Text('Délai: ${entry.value.delayMinutes} min')
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: entry.value.enabled,
                        onChanged: (value) => _toggleAction(entry.key, value),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeAction(entry.key),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planification',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Automatisation récurrente'),
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
              });
            },
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _scheduleExpression,
              decoration: const InputDecoration(
                labelText: 'Expression cron',
                border: OutlineInputBorder(),
                hintText: '0 9 * * 1-5',
              ),
              onChanged: (value) {
                _scheduleExpression = value;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (séparés par des virgules)',
              border: OutlineInputBorder(),
              hintText: 'urgent, communication, suivi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statut',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AutomationStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Statut de l\'automatisation',
              border: OutlineInputBorder(),
            ),
            items: AutomationStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  void _addCondition() {
    setState(() {
      _conditions.add(
        AutomationCondition(
          field: 'field',
          operator: 'equals',
          value: 'value',
        ),
      );
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  void _addAction() {
    setState(() {
      _actions.add(
        AutomationActionConfig(
          action: AutomationAction.sendNotification,
          enabled: true,
          parameters: {},
        ),
      );
    });
  }

  void _removeAction(int index) {
    setState(() {
      _actions.removeAt(index);
    });
  }

  void _toggleAction(int index, bool enabled) {
    setState(() {
      _actions[index] = _actions[index].copyWith(enabled: enabled);
    });
  }

  void _saveAutomation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final automation = Automation(
        id: widget.automation?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        trigger: _selectedTrigger,
        triggerConfig: _triggerConfig,
        conditions: _conditions,
        actions: _actions,
        status: _selectedStatus,
        isRecurring: _isRecurring,
        schedule: _scheduleExpression.isNotEmpty ? _scheduleExpression : null,
        tags: tags,
        createdAt: widget.automation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.automation?.createdBy ?? 'current_user',
        executionCount: widget.automation?.executionCount ?? 0,
        successCount: widget.automation?.successCount ?? 0,
        failureCount: widget.automation?.failureCount ?? 0,
        lastExecutedAt: widget.automation?.lastExecutedAt,
      );

      if (widget.isEdit) {
        await _automationService.updateAutomation(automation.id!, automation);
      } else {
        await _automationService.createAutomation(automation);
      }

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEdit 
              ? 'Automatisation modifiée avec succès' 
              : 'Automatisation créée avec succès'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}