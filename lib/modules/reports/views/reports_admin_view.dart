import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../services/reports_service.dart';
import '../models/report.dart';

class ReportsAdminView extends StatefulWidget {
  const ReportsAdminView({Key? key}) : super(key: key);

  @override
  State<ReportsAdminView> createState() => _ReportsAdminViewState();
}

class _ReportsAdminViewState extends State<ReportsAdminView> with TickerProviderStateMixin {
  final ReportsService _service = ReportsService();
  late TabController _tabController;
  
  // Données des onglets
  List<Report> _allReports = [];
  Map<String, dynamic> _statistics = {};
  List<ReportTemplate> _templates = [];
  bool _isLoading = true;

  // Contrôles de recherche et filtrage
  String _searchQuery = '';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _service.getAll();
      final stats = await _service.getReportsStatistics();
      final templates = ReportTemplate.builtInTemplates;

      setState(() {
        _allReports = reports;
        _statistics = stats;
        _templates = templates;
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
      title: '📊 Administration des Rapports',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _createNewReport(),
          tooltip: 'Nouveau rapport',
        ),
        PopupMenuButton<String>(
          onSelected: _handleGlobalAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'templates',
              child: ListTile(
                leading: Icon(Icons.description),
                title: Text('Voir les templates'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'cleanup',
              child: ListTile(
                leading: Icon(Icons.cleaning_services),
                title: Text('Nettoyer les anciennes données'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'regenerate_all',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Régénérer tous'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          // Onglets
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Rapports'),
              Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
              Tab(icon: Icon(Icons.description), text: 'Templates'),
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
                      _buildReportsTab(),
                      _buildStatisticsTab(),
                      _buildTemplatesTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final filteredReports = _allReports.where((report) {
      final matchesType = _selectedType == 'all' || report.type == _selectedType;
      final matchesSearch = _searchQuery.isEmpty ||
          report.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (report.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesType && matchesSearch;
    }).toList();

    return Column(
      children: [
        // Barre de recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: '🔍 Rechercher un rapport...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'all',
                    'attendance',
                    'financial',
                    'membership',
                    'event',
                    'custom'
                  ].map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getTypeLabel(type)),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        // Liste des rapports
        Expanded(
          child: filteredReports.isEmpty
              ? const Center(
                  child: Text('Aucun rapport trouvé'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _buildReportCard(report);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques générales
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total des rapports',
                  '${_statistics['total_reports'] ?? 0}',
                  Icons.assessment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Rapports actifs',
                  '${_statistics['active_reports'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total générations',
                  '${_statistics['total_generations'] ?? 0}',
                  Icons.refresh,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'À régénérer',
                  '${_statistics['reports_needing_regeneration'] ?? 0}',
                  Icons.schedule,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Répartition par type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Répartition par type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._buildTypeBreakdown(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Répartition par fréquence
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Répartition par fréquence',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._buildFrequencyBreakdown(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final categories = ReportTemplate.getCategories();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final templates = ReportTemplate.getTemplatesByCategory(category);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${templates.length} templates disponibles'),
            children: templates.map((template) => _buildTemplateCard(template)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<ReportData>>(
      future: _loadRecentReportData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }
        
        final reportDataList = snapshot.data ?? [];
        
        if (reportDataList.isEmpty) {
          return const Center(
            child: Text('Aucune génération récente'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportDataList.length,
          itemBuilder: (context, index) {
            final reportData = reportDataList[index];
            return _buildHistoryCard(reportData);
          },
        );
      },
    );
  }

  Widget _buildReportCard(Report report) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(report.type).withOpacity(0.1),
          child: Icon(
            _getTypeIcon(report.type),
            color: _getTypeColor(report.type),
          ),
        ),
        title: Text(report.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.description != null) Text(report.description!),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(_getTypeLabel(report.type)),
                  backgroundColor: _getTypeColor(report.type).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getTypeColor(report.type)),
                ),
                const SizedBox(width: 8),
                if (!report.isActive)
                  const Chip(
                    label: Text('Inactif'),
                    backgroundColor: Colors.grey,
                  ),
                if (report.shouldRegenerate())
                  const Chip(
                    label: Text('À régénérer'),
                    backgroundColor: Colors.orange,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleReportAction(value, report),
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
              value: 'generate',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Générer'),
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
            PopupMenuItem(
              value: report.isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(report.isActive ? Icons.pause : Icons.play_arrow),
                title: Text(report.isActive ? 'Désactiver' : 'Activer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _viewReport(report),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeBreakdown() {
    final typeCount = Map<String, int>.from(_statistics['reports_by_type'] ?? {});
    final total = typeCount.values.fold(0, (sum, count) => sum + count);
    
    return typeCount.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(_getTypeLabel(entry.key)),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: total > 0 ? entry.value / total : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(_getTypeColor(entry.key)),
              ),
            ),
            const SizedBox(width: 8),
            Text('${entry.value} ($percentage%)'),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildFrequencyBreakdown() {
    final frequencyCount = Map<String, int>.from(_statistics['reports_by_frequency'] ?? {});
    final total = frequencyCount.values.fold(0, (sum, count) => sum + count);
    
    return frequencyCount.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total * 100).round() : 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(_getFrequencyLabel(entry.key)),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: total > 0 ? entry.value / total : 0,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 8),
            Text('${entry.value} ($percentage%)'),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTemplateCard(ReportTemplate template) {
    return ListTile(
      leading: Icon(_getTypeIcon(template.type)),
      title: Text(template.name),
      subtitle: Text(template.description),
      trailing: ElevatedButton.icon(
        onPressed: () => _createFromTemplate(template),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Utiliser'),
      ),
    );
  }

  Widget _buildHistoryCard(ReportData reportData) {
    final report = _allReports.firstWhere(
      (r) => r.id == reportData.reportId,
      orElse: () => Report(
        id: reportData.reportId,
        name: 'Rapport supprimé',
        type: 'unknown',
        createdAt: DateTime.now(),
        createdBy: 'unknown',
      ),
    );
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getTypeIcon(report.type)),
        title: Text(report.name),
        subtitle: Text('Généré le ${_formatDateTime(reportData.generatedAt)}'),
        trailing: Text('${reportData.totalRows} lignes'),
        onTap: () => _viewReportData(reportData),
      ),
    );
  }

  Future<List<ReportData>> _loadRecentReportData() async {
    // Simuler le chargement des données récentes
    // En réalité, on ferait une requête Firestore
    return [];
  }

  void _createNewReport() {
    Navigator.of(context).pushNamed('/reports/form');
  }

  void _createFromTemplate(ReportTemplate template) {
    Navigator.of(context).pushNamed(
      '/reports/form',
      arguments: {'template': template},
    );
  }

  void _viewReport(Report report) {
    Navigator.of(context).pushNamed(
      '/reports/detail',
      arguments: report,
    );
  }

  void _viewReportData(ReportData reportData) {
    // TODO: Implémenter la vue des données du rapport
  }

  void _handleGlobalAction(String action) {
    switch (action) {
      case 'templates':
        _tabController.animateTo(2);
        break;
      case 'cleanup':
        _showCleanupDialog();
        break;
      case 'regenerate_all':
        _regenerateAllReports();
        break;
    }
  }

  void _handleReportAction(String action, Report report) {
    switch (action) {
      case 'view':
        _viewReport(report);
        break;
      case 'edit':
        Navigator.of(context).pushNamed('/reports/edit', arguments: report);
        break;
      case 'duplicate':
        _duplicateReport(report);
        break;
      case 'generate':
        _generateReport(report);
        break;
      case 'share':
        _shareReport(report);
        break;
      case 'activate':
      case 'deactivate':
        _toggleReportStatus(report);
        break;
      case 'delete':
        _deleteReport(report);
        break;
    }
  }

  Future<void> _duplicateReport(Report report) async {
    final name = '${report.name} (Copie)';
    try {
      await _service.duplicateReport(report.id, name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapport dupliqué avec succès')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  // TODO: Implémenter les autres méthodes d'action...

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer les anciennes données'),
        content: const Text(
          'Cette action supprimera les anciennes générations de rapports '
          'pour libérer de l\'espace. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performCleanup();
            },
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCleanup() async {
    // TODO: Implémenter le nettoyage
  }

  Future<void> _regenerateAllReports() async {
    // TODO: Implémenter la régénération de tous les rapports
  }

  Future<void> _generateReport(Report report) async {
    // TODO: Implémenter la génération individuelle
  }

  void _shareReport(Report report) {
    // TODO: Implémenter le partage de rapport
  }

  Future<void> _toggleReportStatus(Report report) async {
    // TODO: Implémenter l'activation/désactivation
  }

  void _deleteReport(Report report) {
    // TODO: Implémenter la suppression
  }

  // Méthodes utilitaires
  IconData _getTypeIcon(String type) {
    switch (type) {
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

  Color _getTypeColor(String type) {
    switch (type) {
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'Tous';
      case 'attendance':
        return 'Présence';
      case 'financial':
        return 'Financier';
      case 'membership':
        return 'Membres';
      case 'event':
        return 'Événement';
      case 'custom':
        return 'Personnalisé';
      default:
        return type;
    }
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      default:
        return frequency;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}