import 'package:flutter/material.dart';
import '../models/automation_execution.dart';
import '../services/automation_service.dart';
import '../../../theme.dart';
import '../../../widgets/custom_card.dart';

/// Vue détaillée d'une exécution d'automatisation
class AutomationExecutionDetailView extends StatefulWidget {
  final AutomationExecution? execution;

  const AutomationExecutionDetailView({Key? key, this.execution}) : super(key: key);

  @override
  State<AutomationExecutionDetailView> createState() => _AutomationExecutionDetailViewState();
}

class _AutomationExecutionDetailViewState extends State<AutomationExecutionDetailView> {
  final AutomationService _automationService = AutomationService();
  
  AutomationExecution? _execution;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _execution = widget.execution;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_execution?.id != null) {
      try {
        final execution = await _automationService.executionService.getById(_execution!.id!);
        if (execution != null) {
          setState(() {
            _execution = execution;
          });
        }
      } catch (e) {
        print('Erreur lors du chargement de l\'exécution: $e');
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_execution == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exécution non trouvée')),
        body: const Center(
          child: Text('Aucune exécution trouvée'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Exécution: ${_execution!.automationName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildGeneralInfoCard(),
          const SizedBox(height: 16),
          _buildTimingCard(),
          const SizedBox(height: 16),
          if (_execution!.triggerData.isNotEmpty) ...[
            _buildTriggerDataCard(),
            const SizedBox(height: 16),
          ],
          if (_execution!.executionData.isNotEmpty) ...[
            _buildExecutionDataCard(),
            const SizedBox(height: 16),
          ],
          if (_execution!.error != null) ...[
            _buildErrorCard(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(_execution!.status),
                color: _getStatusColor(_execution!.status),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _execution!.status.label,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _getStatusColor(_execution!.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _execution!.automationName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_execution!.status == ExecutionStatus.failed && _execution!.error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _execution!.error!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations générales',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID', _execution!.id ?? 'N/A'),
          _buildInfoRow('Automatisation', _execution!.automationName),
          _buildInfoRow('ID Automatisation', _execution!.automationId),
          _buildInfoRow('Déclencheur', _execution!.triggerType),
          if (_execution!.triggeredBy != null)
            _buildInfoRow('Déclenché par', _execution!.triggeredBy!),
        ],
      ),
    );
  }

  Widget _buildTimingCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timing',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Déclenchée le', _formatDateTime(_execution!.triggeredAt)),
          if (_execution!.startedAt != null)
            _buildInfoRow('Démarrée le', _formatDateTime(_execution!.startedAt!)),
          if (_execution!.completedAt != null)
            _buildInfoRow('Terminée le', _formatDateTime(_execution!.completedAt!)),
          if (_execution!.duration != null)
            _buildInfoRow('Durée', '${_execution!.duration!.inMilliseconds}ms'),
        ],
      ),
    );
  }

  Widget _buildTriggerDataCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données de déclenchement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._execution!.triggerData.entries.map(
            (entry) => _buildInfoRow(entry.key, entry.value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionDataCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données d\'exécution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._execution!.executionData.entries.map(
            (entry) => _buildInfoRow(entry.key, entry.value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return CustomCard(
      color: Colors.red[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Erreur',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              _execution!.error!,
              style: TextStyle(
                color: Colors.red[700],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.pending:
        return Icons.schedule;
      case ExecutionStatus.running:
        return Icons.play_arrow;
      case ExecutionStatus.completed:
        return Icons.check_circle;
      case ExecutionStatus.failed:
        return Icons.error;
      case ExecutionStatus.cancelled:
        return Icons.cancel;
      case ExecutionStatus.skipped:
        return Icons.skip_next;
    }
  }

  Color _getStatusColor(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.pending:
        return Colors.orange;
      case ExecutionStatus.running:
        return Colors.blue;
      case ExecutionStatus.completed:
        return Colors.green;
      case ExecutionStatus.failed:
        return Colors.red;
      case ExecutionStatus.cancelled:
        return Colors.grey;
      case ExecutionStatus.skipped:
        return Colors.orange;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}