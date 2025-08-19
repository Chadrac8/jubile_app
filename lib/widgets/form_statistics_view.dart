import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class FormStatisticsView extends StatefulWidget {
  final FormModel form;

  const FormStatisticsView({super.key, required this.form});

  @override
  State<FormStatisticsView> createState() => _FormStatisticsViewState();
}

class _FormStatisticsViewState extends State<FormStatisticsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  FormStatisticsModel? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final statistics = await FormsFirebaseService.getFormStatistics(widget.form.id);
      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des statistiques: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primaryColor),
        ),
      );
    }

    if (_statistics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les statistiques',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 24),
            _buildSubmissionsChart(),
            const SizedBox(height: 24),
            _buildStatusDistribution(),
            const SizedBox(height: 24),
            _buildFieldResponsesAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Vue d\'ensemble',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(
                  'Total soumissions',
                  _statistics!.realSubmissions.toString(),
                  Icons.inbox,
                  Theme.of(context).colorScheme.primaryColor,
                ),
                _buildStatCard(
                  'Soumissions traitées',
                  _statistics!.processedSubmissions.toString(),
                  Icons.check_circle,
                  Theme.of(context).colorScheme.successColor,
                ),
                _buildStatCard(
                  'Taux de traitement',
                  '${(_statistics!.processedRate * 100).toInt()}%',
                  Icons.trending_up,
                  Theme.of(context).colorScheme.secondaryColor,
                ),
                _buildStatCard(
                  'Soumissions de test',
                  _statistics!.testSubmissions.toString(),
                  Icons.science,
                  Theme.of(context).colorScheme.warningColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsChart() {
    if (_statistics!.submissionsByDate.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: Theme.of(context).colorScheme.secondaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Évolution des soumissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final dates = _statistics!.submissionsByDate.keys.toList()..sort();
                          if (value.toInt() >= 0 && value.toInt() < dates.length) {
                            final date = DateTime.parse(dates[value.toInt()]);
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: Theme.of(context).colorScheme.textTertiaryColor,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Theme.of(context).colorScheme.textTertiaryColor,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: (_statistics!.submissionsByDate.length - 1).toDouble(),
                  minY: 0,
                  maxY: _statistics!.submissionsByDate.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryColor,
                          Theme.of(context).colorScheme.secondaryColor,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
                            Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots() {
    final dates = _statistics!.submissionsByDate.keys.toList()..sort();
    return dates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final count = _statistics!.submissionsByDate[date] ?? 0;
      return FlSpot(index.toDouble(), count.toDouble());
    }).toList();
  }

  Widget _buildStatusDistribution() {
    final total = _statistics!.totalSubmissions;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).colorScheme.warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Répartition par statut',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Theme.of(context).colorScheme.warningColor,
                            value: (_statistics!.totalSubmissions - _statistics!.processedSubmissions - _statistics!.archivedSubmissions).toDouble(),
                            title: 'Soumis',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Theme.of(context).colorScheme.successColor,
                            value: _statistics!.processedSubmissions.toDouble(),
                            title: 'Traités',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Theme.of(context).colorScheme.textTertiaryColor,
                            value: _statistics!.archivedSubmissions.toDouble(),
                            title: 'Archivés',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildLegendItem(
                        'Soumis',
                        Theme.of(context).colorScheme.warningColor,
                        _statistics!.totalSubmissions - _statistics!.processedSubmissions - _statistics!.archivedSubmissions,
                      ),
                      _buildLegendItem(
                        'Traités',
                        Theme.of(context).colorScheme.successColor,
                        _statistics!.processedSubmissions,
                      ),
                      _buildLegendItem(
                        'Archivés',
                        Theme.of(context).colorScheme.textTertiaryColor,
                        _statistics!.archivedSubmissions,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldResponsesAnalysis() {
    if (_statistics!.fieldResponses.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Theme.of(context).colorScheme.tertiaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analyse des réponses par champ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...List.generate(_statistics!.fieldResponses.length, (index) {
              final entry = _statistics!.fieldResponses.entries.elementAt(index);
              final fieldId = entry.key;
              final responses = entry.value;
              
              final field = widget.form.fields.firstWhere(
                (f) => f.id == fieldId,
                orElse: () => CustomFormField(id: fieldId, type: 'text', label: 'Champ inconnu', order: 0),
              );
              
              return _buildFieldAnalysis(field, responses);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldAnalysis(CustomFormField field, Map<String, int> responses) {
    final totalResponses = responses.values.fold(0, (sum, count) => sum + count);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFieldIcon(field.type),
                size: 18,
                color: Theme.of(context).colorScheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  field.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$totalResponses réponses',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(responses.entries.length.clamp(0, 5), (index) {
            final responseEntry = responses.entries.elementAt(index);
            final response = responseEntry.key;
            final count = responseEntry.value;
            final percentage = (count / totalResponses * 100).round();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          response.length > 50 ? '${response.substring(0, 50)}...' : response,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '$count ($percentage%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: count / totalResponses,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primaryColor),
                  ),
                ],
              ),
            );
          }),
          if (responses.length > 5)
            Text(
              '+${responses.length - 5} autres réponses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.textTertiaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String type) {
    switch (type) {
      case 'text': return Icons.text_fields;
      case 'textarea': return Icons.subject;
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'checkbox': return Icons.check_box;
      case 'radio': return Icons.radio_button_checked;
      case 'select': return Icons.arrow_drop_down;
      case 'date': return Icons.calendar_today;
      case 'time': return Icons.access_time;
      case 'file': return Icons.attach_file;
      case 'signature': return Icons.edit;
      default: return Icons.help_outline;
    }
  }
}