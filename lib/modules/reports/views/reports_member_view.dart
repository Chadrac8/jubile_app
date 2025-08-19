import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../services/reports_service.dart';
import '../models/report.dart';

class ReportsMemberView extends StatefulWidget {
  const ReportsMemberView({Key? key}) : super(key: key);

  @override
  State<ReportsMemberView> createState() => _ReportsMemberViewState();
}

class _ReportsMemberViewState extends State<ReportsMemberView> {
  final ReportsService _service = ReportsService();
  List<Report> _reports = [];
  List<Report> _filteredReports = [];
  bool _isLoading = true;
  String _selectedType = 'all';
  String _searchQuery = '';

  final List<String> _reportTypes = [
    'all',
    'attendance',
    'financial',
    'membership',
    'event',
    'custom',
  ];

  final Map<String, String> _typeLabels = {
    'all': '📊 Tous les rapports',
    'attendance': '👥 Présence',
    'financial': '💰 Financier',
    'membership': '👤 Membres',
    'event': '📅 Événements',
    'custom': '🔧 Personnalisé',
  };

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtenir les rapports publics et partagés
      final publicReports = await _service.getPublicReports();
      final sharedReports = await _service.getSharedWith('current_user_id'); // TODO: ID utilisateur réel
      
      final allReports = <Report>[];
      allReports.addAll(publicReports);
      
      // Éviter les doublons
      for (final shared in sharedReports) {
        if (!allReports.any((r) => r.id == shared.id)) {
          allReports.add(shared);
        }
      }
      
      allReports.sort((a, b) => a.name.compareTo(b.name));
      
      setState(() {
        _reports = allReports;
        _filteredReports = allReports;
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

  void _filterReports() {
    setState(() {
      _filteredReports = _reports.where((report) {
        final matchesType = _selectedType == 'all' || report.type == _selectedType;
        final matchesSearch = _searchQuery.isEmpty ||
            report.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (report.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        return matchesType && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: '📊 Rapports',
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
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
                    _filterReports();
                  },
                ),
                const SizedBox(height: 16),
                // Filtres par type
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _reportTypes.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_typeLabels[type] ?? type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                            _filterReports();
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = _filteredReports[index];
                            return _buildReportCard(report);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assessment_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun rapport trouvé pour "$_searchQuery"'
                : 'Aucun rapport disponible',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les rapports publics et partagés apparaîtront ici',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    final typeIcon = _getTypeIcon(report.type);
    final typeColor = _getTypeColor(report.type);
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewReport(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec type et actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 16, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          _getTypeLabel(report.type),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (report.isPublic)
                    const Icon(Icons.public, size: 16, color: Colors.green),
                  if (!report.isPublic)
                    const Icon(Icons.people, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value, report),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('Voir le rapport'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'generate',
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Générer maintenant'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Titre et description
              Text(
                report.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (report.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  report.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              
              // Méta-informations
              Row(
                children: [
                  _buildMetaChip(
                    Icons.schedule,
                    _getFrequencyLabel(report.frequency),
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  if (report.lastGenerated != null)
                    _buildMetaChip(
                      Icons.update,
                      _formatDate(report.lastGenerated!),
                      Colors.green,
                    ),
                  if (report.lastGenerated == null)
                    _buildMetaChip(
                      Icons.new_releases,
                      'Nouveau',
                      Colors.red,
                    ),
                  const Spacer(),
                  Text(
                    '${report.generationCount} générations',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _viewReport(Report report) {
    Navigator.of(context).pushNamed(
      '/reports/detail',
      arguments: report,
    );
  }

  void _handleAction(String action, Report report) {
    switch (action) {
      case 'view':
        _viewReport(report);
        break;
      case 'generate':
        _generateReport(report);
        break;
    }
  }

  Future<void> _generateReport(Report report) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Génération en cours...'),
          ],
        ),
      ),
    );

    try {
      await _service.generateReportData(report);
      Navigator.of(context).pop(); // Fermer le dialog de chargement
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport généré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      _viewReport(report);
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialog de chargement
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
        return 'Rapport';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      return 'Il y a ${(difference.inDays / 7).floor()} semaines';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}