import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/group_model.dart';
import '../../compatibility/app_theme_bridge.dart';

class GroupMemberAttendanceStats extends StatefulWidget {
  final Map<String, PersonAttendanceStats> memberAttendance;
  final bool isExpanded;

  const GroupMemberAttendanceStats({
    super.key,
    required this.memberAttendance,
    this.isExpanded = false,
  });

  @override
  State<GroupMemberAttendanceStats> createState() => _GroupMemberAttendanceStatsState();
}

class _GroupMemberAttendanceStatsState extends State<GroupMemberAttendanceStats>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _sortBy = 'attendanceRate'; // attendanceRate, name, consecutiveAbsences
  bool _sortDescending = true;
  String _filterBy = 'all'; // all, excellent, good, average, poor

  final Map<String, String> _sortOptions = {
    'attendanceRate': 'Taux de présence',
    'name': 'Nom',
    'consecutiveAbsences': 'Absences consécutives',
    'lastAttendance': 'Dernière présence',
  };

  final Map<String, String> _filterOptions = {
    'all': 'Tous les membres',
    'excellent': 'Excellente assiduité (≥90%)',
    'good': 'Bonne assiduité (≥70%)',
    'average': 'Assiduité moyenne (≥50%)',
    'poor': 'Faible assiduité (<50%)',
    'absent': 'Absences consécutives (≥3)',
  };

  @override
  void initState() {
    super.initState();
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<PersonAttendanceStats> get _filteredAndSortedMembers {
    List<PersonAttendanceStats> members = widget.memberAttendance.values.toList();
    
    // Filter
    switch (_filterBy) {
      case 'excellent':
        members = members.where((m) => m.attendanceRate >= 0.9).toList();
        break;
      case 'good':
        members = members.where((m) => m.attendanceRate >= 0.7 && m.attendanceRate < 0.9).toList();
        break;
      case 'average':
        members = members.where((m) => m.attendanceRate >= 0.5 && m.attendanceRate < 0.7).toList();
        break;
      case 'poor':
        members = members.where((m) => m.attendanceRate < 0.5).toList();
        break;
      case 'absent':
        members = members.where((m) => m.consecutiveAbsences >= 3).toList();
        break;
    }
    
    // Sort
    members.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'attendanceRate':
          comparison = a.attendanceRate.compareTo(b.attendanceRate);
          break;
        case 'name':
          comparison = a.personName.toLowerCase().compareTo(b.personName.toLowerCase());
          break;
        case 'consecutiveAbsences':
          comparison = a.consecutiveAbsences.compareTo(b.consecutiveAbsences);
          break;
        case 'lastAttendance':
          if (a.lastAttendance == null && b.lastAttendance == null) {
            comparison = 0;
          } else if (a.lastAttendance == null) {
            comparison = 1;
          } else if (b.lastAttendance == null) {
            comparison = -1;
          } else {
            comparison = a.lastAttendance!.compareTo(b.lastAttendance!);
          }
          break;
        default:
          comparison = 0;
      }
      return _sortDescending ? -comparison : comparison;
    });
    
    return members;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.memberAttendance.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildControls(),
            _buildMembersList(),
            if (widget.isExpanded) _buildAttendanceChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_alt,
            color: Theme.of(context).colorScheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assiduité des membres',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.memberAttendance.length} membres',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Trier par',
                    prefixIcon: Icon(Icons.sort),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _sortOptions.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortDescending = !_sortDescending;
                  });
                },
                icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
                tooltip: _sortDescending ? 'Décroissant' : 'Croissant',
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _filterBy,
            decoration: const InputDecoration(
              labelText: 'Filtrer par',
              prefixIcon: Icon(Icons.filter_list),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _filterOptions.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filterBy = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    final members = _filteredAndSortedMembers;
    
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.textTertiaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun membre trouvé',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier les filtres',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: members.map((member) => _buildMemberCard(member)).toList(),
    );
  }

  Widget _buildMemberCard(PersonAttendanceStats member) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.backgroundColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: member.attendanceColor.withOpacity(0.2),
          child: Text(
            member.personName.isNotEmpty 
                ? member.personName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                : '?',
            style: TextStyle(
              color: member.attendanceColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          member.personName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: member.attendanceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(member.attendanceRate * 100).toInt()}% - ${member.attendanceLabel}',
                    style: TextStyle(
                      color: member.attendanceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (member.consecutiveAbsences >= 3) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${member.consecutiveAbsences} absences',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${member.presentCount}/${member.totalMeetings} présences',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Réunions totales',
                  member.totalMeetings.toString(),
                  Icons.event,
                ),
                _buildDetailRow(
                  'Présences',
                  member.presentCount.toString(),
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.successColor,
                ),
                _buildDetailRow(
                  'Absences',
                  member.absentCount.toString(),
                  Icons.cancel,
                  color: Theme.of(context).colorScheme.errorColor,
                ),
                if (member.consecutiveAbsences > 0)
                  _buildDetailRow(
                    'Absences consécutives',
                    member.consecutiveAbsences.toString(),
                    Icons.warning,
                    color: Theme.of(context).colorScheme.warningColor,
                  ),
                if (member.lastAttendance != null)
                  _buildDetailRow(
                    'Dernière présence',
                    _formatDate(member.lastAttendance!),
                    Icons.access_time,
                  ),
                const SizedBox(height: 16),
                _buildProgressBar(member),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.textSecondaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(PersonAttendanceStats member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taux de présence',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: member.attendanceRate,
          backgroundColor: Theme.of(context).colorScheme.backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(member.attendanceColor),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${(member.attendanceRate * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: member.attendanceColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    if (widget.memberAttendance.isEmpty) return const SizedBox.shrink();

    final attendanceRanges = <String, int>{
      'Excellente (≥90%)': 0,
      'Bonne (70-89%)': 0,
      'Moyenne (50-69%)': 0,
      'Faible (<50%)': 0,
    };

    for (final member in widget.memberAttendance.values) {
      if (member.attendanceRate >= 0.9) {
        attendanceRanges['Excellente (≥90%)'] = attendanceRanges['Excellente (≥90%)']! + 1;
      } else if (member.attendanceRate >= 0.7) {
        attendanceRanges['Bonne (70-89%)'] = attendanceRanges['Bonne (70-89%)']! + 1;
      } else if (member.attendanceRate >= 0.5) {
        attendanceRanges['Moyenne (50-69%)'] = attendanceRanges['Moyenne (50-69%)']! + 1;
      } else {
        attendanceRanges['Faible (<50%)'] = attendanceRanges['Faible (<50%)']! + 1;
      }
    }

    return Container(
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
                    Theme.of(context).colorScheme.successColor,
                    Theme.of(context).colorScheme.warningColor,
                    Theme.of(context).colorScheme.tertiaryColor,
                    Theme.of(context).colorScheme.errorColor,
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
                Theme.of(context).colorScheme.successColor,
                Theme.of(context).colorScheme.warningColor,
                Theme.of(context).colorScheme.tertiaryColor,
                Theme.of(context).colorScheme.errorColor,
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
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}