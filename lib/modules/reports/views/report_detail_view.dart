import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../models/report.dart';
import '../services/reports_service.dart';
import '../services/scheduler_service.dart';
import '../widgets/report_chart_widget.dart';
import '../widgets/export_dialog.dart';
import '../widgets/schedule_dialog.dart';

class ReportDetailView extends StatefulWidget {
  final Report report;

  const ReportDetailView({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  State<ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends State<ReportDetailView> with TickerProviderStateMixin {
  final ReportsService _service = ReportsService();
  final SchedulerService _schedulerService = SchedulerService();
  late TabController _tabController;
  
  ReportData? _latestData;
  List<ReportData> _historyData = [];
  List<ScheduledTask> _scheduledTasks = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedChartType = 'bar';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedChartType = widget.report.chartType ?? 'bar';
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final latestData = await _service.getLatestReportData(widget.report.id);
      final historyData = await _service.getReportData(widget.report.id, limit: 10);
      final scheduledTasks = await _schedulerService.getSchedulesForReport(widget.report.id);
      
      setState(() {
        _latestData = latestData;
        _historyData = historyData;
        _scheduledTasks = scheduledTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: widget.report.name,
      actions: [
        if (_latestData != null)
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(),
            tooltip: 'Exporter',
          ),
        IconButton(
          icon: Icon(_isGenerating ? Icons.hourglass_empty : Icons.refresh),
          onPressed: _isGenerating ? null : _generateReport,
          tooltip: 'Générer',
        ),
        PopupMenuButton<String>(
          onSelected: _handleAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Dupliquer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'schedule',
              child: ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Planifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Partager'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          // En-tête avec informations du rapport
          _buildReportHeader(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Graphiques'),
              Tab(icon: Icon(Icons.table_chart), text: 'Données'),
              Tab(icon: Icon(Icons.history), text: 'Historique'),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildChartsTab(),
                      _buildDataTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return CustomCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getTypeColor().withOpacity(0.1),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.report.description != null)
                        Text(
                          widget.report.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isGenerating) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistiques rapides
            Row(
              children: [
                _buildStatChip(
                  'Type',
                  _getTypeLabel(),
                  _getTypeColor(),
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Fréquence',
                  _getFrequencyLabel(widget.report.frequency),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                if (widget.report.lastGenerated != null)
                  _buildStatChip(
                    'Dernière génération',
                    _formatDate(widget.report.lastGenerated!),
                    Colors.green,
                  ),
              ],
            ),
            
            // Actions rapides
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateReport,
                    icon: Icon(_isGenerating ? Icons.hourglass_empty : Icons.refresh),
                    label: Text(_isGenerating ? 'Génération...' : 'Générer maintenant'),
                  ),
                ),
                const SizedBox(width: 8),
                if (_latestData != null)
                  ElevatedButton.icon(
                    onPressed: _showExportDialog,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Exporter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé des données
          if (_latestData?.summary.isNotEmpty ?? false) ...[
            _buildSummarySection(),
            const SizedBox(height: 20),
          ],
          
          // Aperçu graphique
          if (_latestData != null) ...[
            _buildQuickChart(),
            const SizedBox(height: 20),
          ],
          
          // Planifications
          if (_scheduledTasks.isNotEmpty) ...[
            _buildSchedulesSection(),
            const SizedBox(height: 20),
          ],
          
          // Informations détaillées
          _buildDetailsSection(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_latestData?.summary.isEmpty ?? true) return const SizedBox.shrink();
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé des données',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _latestData!.summary.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChart() {
    if (_latestData == null) return const SizedBox.shrink();
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Aperçu graphique',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Voir plus'),
                ),
              ],
            ),
          ),
          ReportChartWidget(
            reportData: _latestData!,
            chartType: _selectedChartType,
            showControls: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Planifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showScheduleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_scheduledTasks.take(3).map((task) => _buildScheduleCard(task))),
            if (_scheduledTasks.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Afficher toutes les planifications
                },
                child: Text('Voir toutes (${_scheduledTasks.length})'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ScheduledTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: task.isActive ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.isActive ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.isActive ? Icons.schedule : Icons.pause,
            size: 16,
            color: task.isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFrequencyLabel(task.config.frequency.toString()),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Prochaine: ${_formatDateTime(task.nextExecution)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            task.lastStatus,
            style: TextStyle(
              fontSize: 12,
              color: task.lastStatus == 'Succès' ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations détaillées',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ID', widget.report.id),
            _buildDetailRow('Type', _getTypeLabel()),
            _buildDetailRow('Créé le', _formatDate(widget.report.createdAt)),
            _buildDetailRow('Créé par', widget.report.createdBy),
            _buildDetailRow('Fréquence', _getFrequencyLabel(widget.report.frequency)),
            _buildDetailRow('Générations', '${widget.report.generationCount}'),
            if (widget.report.lastGenerated != null)
              _buildDetailRow('Dernière génération', _formatDate(widget.report.lastGenerated!)),
            _buildDetailRow('Statut', widget.report.isActive ? 'Actif' : 'Inactif'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    if (_latestData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Générez le rapport pour voir les graphiques',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ReportChartWidget(
        reportData: _latestData!,
        chartType: _selectedChartType,
        title: 'Visualisation des données',
        showControls: true,
        onChartTypeChanged: (type) {
          setState(() {
            _selectedChartType = type;
          });
        },
      ),
    );
  }

  Widget _buildDataTab() {
    if (_latestData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Générez le rapport pour voir les données',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CustomCard(
        child: ReportChartWidget(
          reportData: _latestData!,
          chartType: 'table',
          title: 'Données tabulaires (${_latestData!.totalRows} lignes)',
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun historique disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyData.length,
      itemBuilder: (context, index) {
        final data = _historyData[index];
        return _buildHistoryCard(data);
      },
    );
  }

  Widget _buildHistoryCard(ReportData data) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.analytics, color: Colors.blue),
        ),
        title: Text('Génération du ${_formatDateTime(data.generatedAt)}'),
        subtitle: Text('${data.totalRows} lignes de données'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleHistoryAction(value, data),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Voir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Exporter'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Actions et méthodes utilitaires

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final reportData = await _service.generateReportData(widget.report);
      
      setState(() {
        _latestData = reportData;
        _historyData.insert(0, reportData);
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportDialog() {
    if (_latestData != null) {
      showExportDialog(context, _latestData!, widget.report.name);
    }
  }

  void _showScheduleDialog() {
    showScheduleDialog(context, widget.report.id, widget.report.name).then((result) {
      if (result == true) {
        _loadReportData(); // Recharger pour voir les nouvelles planifications
      }
    });
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.of(context).pushNamed('/reports/edit', arguments: widget.report);
        break;
      case 'duplicate':
        _duplicateReport();
        break;
      case 'schedule':
        _showScheduleDialog();
        break;
      case 'share':
        _shareReport();
        break;
    }
  }

  void _handleHistoryAction(String action, ReportData data) {
    switch (action) {
      case 'view':
        // TODO: Afficher les détails de cette génération
        break;
      case 'export':
        showExportDialog(context, data, widget.report.name);
        break;
    }
  }

  Future<void> _duplicateReport() async {
    try {
      final newReportId = await _service.duplicateReport(
        widget.report.id, 
        '${widget.report.name} (Copie)',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport dupliqué avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la duplication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareReport() {
    // TODO: Implémenter le partage du rapport
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à venir'),
      ),
    );
  }

  // Méthodes utilitaires

  IconData _getTypeIcon() {
    switch (widget.report.type) {
      case 'attendance':
        return Icons.people_outline;
      case 'financial':
        return Icons.account_balance_wallet;
      case 'membership':
        return Icons.group_add;
      case 'event':
        return Icons.event_note;
      case 'custom':
        return Icons.analytics;
      default:
        return Icons.assessment;
    }
  }

  Color _getTypeColor() {
    switch (widget.report.type) {
      case 'attendance':
        return Colors.blue;
      case 'financial':
        return Colors.green;
      case 'membership':
        return Colors.purple;
      case 'event':
        return Colors.orange;
      case 'custom':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel() {
    switch (widget.report.type) {
      case 'attendance':
        return 'Présence';
      case 'financial':
        return 'Financier';
      case 'membership':
        return 'Membres';
      case 'event':
        return 'Événements';
      case 'custom':
        return 'Personnalisé';
      default:
        return 'Autre';
    }
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'hourly':
        return 'Horaire';
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      case 'custom':
        return 'Personnalisé';
      default:
        return frequency;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}