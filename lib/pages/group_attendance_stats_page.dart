import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/group_model.dart';
import '../services/groups_firebase_service.dart';
import '../widgets/group_member_attendance_stats.dart';
import '../theme.dart';

class GroupAttendanceStatsPage extends StatefulWidget {
  final GroupModel group;

  const GroupAttendanceStatsPage({
    super.key,
    required this.group,
  });

  @override
  State<GroupAttendanceStatsPage> createState() => _GroupAttendanceStatsPageState();
}

class _GroupAttendanceStatsPageState extends State<GroupAttendanceStatsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  GroupStatisticsModel? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stats = await GroupsFirebaseService.getGroupStatistics(widget.group.id);
      
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color get _groupColor => Color(int.parse(widget.group.color.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques d\'assiduité',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.group.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: _groupColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              icon: Icon(Icons.bar_chart),
              text: 'Vue d\'ensemble',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Par membre',
            ),
            Tab(
              icon: Icon(Icons.timeline),
              text: 'Évolution',
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_statistics == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMembersTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _statistics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Membres actifs',
                  stats.activeMembers.toString(),
                  Icons.group,
                  _groupColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Réunions',
                  stats.totalMeetings.toString(),
                  Icons.event,
                  AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Taux moyen',
                  '${(stats.averageAttendance * 100).round()}%',
                  Icons.how_to_reg,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total membres',
                  stats.totalMembers.toString(),
                  Icons.people,
                  AppTheme.tertiaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Attendance distribution chart
          _buildAttendanceDistributionChart(),
          
          const SizedBox(height: 32),
          
          // Monthly trends
          _buildMonthlyTrendsChart(),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return SingleChildScrollView(
      child: GroupMemberAttendanceStats(
        memberAttendance: _statistics!.memberAttendance,
        isExpanded: false,
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution mensuelle',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMonthlyTrendsChart(detailed: true),
          
          const SizedBox(height: 32),
          
          Text(
            'Analyse des tendances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendsAnalysis(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
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
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDistributionChart() {
    final stats = _statistics!;
    
    if (stats.memberAttendance.isEmpty) {
      return const SizedBox.shrink();
    }

    final attendanceRanges = <String, int>{
      'Excellente': 0,
      'Bonne': 0,
      'Moyenne': 0,
      'Faible': 0,
    };

    for (final member in stats.memberAttendance.values) {
      if (member.attendanceRate >= 0.9) {
        attendanceRanges['Excellente'] = attendanceRanges['Excellente']! + 1;
      } else if (member.attendanceRate >= 0.7) {
        attendanceRanges['Bonne'] = attendanceRanges['Bonne']! + 1;
      } else if (member.attendanceRate >= 0.5) {
        attendanceRanges['Moyenne'] = attendanceRanges['Moyenne']! + 1;
      } else {
        attendanceRanges['Faible'] = attendanceRanges['Faible']! + 1;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition de l\'assiduité',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: attendanceRanges.entries.map((entry) {
                    final index = attendanceRanges.keys.toList().indexOf(entry.key);
                    final colors = [
                      AppTheme.successColor,
                      AppTheme.warningColor,
                      AppTheme.tertiaryColor,
                      AppTheme.errorColor,
                    ];
                    
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      color: colors[index],
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: attendanceRanges.entries.map((entry) {
                final index = attendanceRanges.keys.toList().indexOf(entry.key);
                final colors = [
                  AppTheme.successColor,
                  AppTheme.warningColor,
                  AppTheme.tertiaryColor,
                  AppTheme.errorColor,
                ];
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendsChart({bool detailed = false}) {
    final stats = _statistics!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detailed ? 'Évolution détaillée' : 'Tendance sur 6 mois',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: detailed ? 300 : 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value * 100).toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final months = stats.monthlyAttendance.keys.toList()..sort();
                          if (value.toInt() < months.length) {
                            final month = months[value.toInt()];
                            return Text(month.substring(5)); // Show only MM
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getMonthlySpots(),
                      isCurved: true,
                      color: _groupColor,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: _groupColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _groupColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getMonthlySpots() {
    final stats = _statistics!;
    final months = stats.monthlyAttendance.keys.toList()..sort();
    
    return months.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;
      final attendance = stats.monthlyAttendance[month] ?? 0.0;
      return FlSpot(index.toDouble(), attendance);
    }).toList();
  }

  Widget _buildTrendsAnalysis() {
    final stats = _statistics!;
    final memberAttendance = stats.memberAttendance.values.toList();
    
    // Calculate insights
    final excellentCount = memberAttendance.where((m) => m.attendanceRate >= 0.9).length;
    final poorCount = memberAttendance.where((m) => m.attendanceRate < 0.5).length;
    final absenceCount = memberAttendance.where((m) => m.consecutiveAbsences >= 3).length;
    
    final insights = <Map<String, dynamic>>[];
    
    if (excellentCount > 0) {
      insights.add({
        'icon': Icons.star,
        'color': AppTheme.successColor,
        'title': 'Excellente assiduité',
        'description': '$excellentCount membre${excellentCount > 1 ? 's ont' : ' a'} une assiduité excellente (≥90%)',
      });
    }
    
    if (absenceCount > 0) {
      insights.add({
        'icon': Icons.warning,
        'color': AppTheme.errorColor,
        'title': 'Attention requise',
        'description': '$absenceCount membre${absenceCount > 1 ? 's ont' : ' a'} 3+ absences consécutives',
      });
    }
    
    if (poorCount > 0) {
      insights.add({
        'icon': Icons.trending_down,
        'color': AppTheme.warningColor,
        'title': 'Assiduité faible',
        'description': '$poorCount membre${poorCount > 1 ? 's ont' : ' a'} une assiduité faible (<50%)',
      });
    }
    
    if (stats.averageAttendance >= 0.8) {
      insights.add({
        'icon': Icons.thumb_up,
        'color': AppTheme.successColor,
        'title': 'Groupe dynamique',
        'description': 'Le taux de présence moyen est excellent (${(stats.averageAttendance * 100).round()}%)',
      });
    }

    return Column(
      children: insights.map((insight) => _buildInsightCard(insight)).toList(),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (insight['color'] as Color).withOpacity(0.2),
          child: Icon(
            insight['icon'] as IconData,
            color: insight['color'] as Color,
          ),
        ),
        title: Text(
          insight['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(insight['description'] as String),
      ),
    );
  }
}