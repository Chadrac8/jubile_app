import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/appointment_model.dart';
import '../services/appointments_firebase_service.dart';
// Removed unused import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class AppointmentStatisticsWidget extends StatefulWidget {
  final String? responsableId;

  const AppointmentStatisticsWidget({
    super.key,
    this.responsableId,
  });

  @override
  State<AppointmentStatisticsWidget> createState() => _AppointmentStatisticsWidgetState();
}

class _AppointmentStatisticsWidgetState extends State<AppointmentStatisticsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  AppointmentStatisticsModel? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    try {
      final statistics = await AppointmentsFirebaseService.getAppointmentStatistics(
        responsableId: widget.responsableId,
      );
      
      if (mounted) {
        setState(() {
          _statistics = statistics;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_statistics == null) {
      return const Center(
        child: Text('Impossible de charger les statistiques'),
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
            _buildMonthlyChart(),
            const SizedBox(height: 24),
            _buildStatusDistribution(),
            const SizedBox(height: 24),
            _buildLocationDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // 5% opacity black
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Theme.of(context).colorScheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Vue d\'ensemble',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.textPrimaryColor,
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
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total',
                _statistics!.totalAppointments.toString(),
                Icons.event_available,
                Theme.of(context).colorScheme.primaryColor,
              ),
              _buildStatCard(
                'En attente',
                _statistics!.pendingAppointments.toString(),
                Icons.schedule,
                Theme.of(context).colorScheme.warningColor,
              ),
              _buildStatCard(
                'Confirmés',
                _statistics!.confirmedAppointments.toString(),
                Icons.check_circle,
                Theme.of(context).colorScheme.successColor,
              ),
              _buildStatCard(
                'Terminés',
                _statistics!.completedAppointments.toString(),
                Icons.done_all,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRateIndicator(
            'Taux de confirmation',
            _statistics!.confirmationRate,
            Theme.of(context).colorScheme.successColor,
          ),
          const SizedBox(height: 8),
          _buildRateIndicator(
            'Taux de finalisation',
            _statistics!.completionRate,
            Theme.of(context).colorScheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25), // 0.1 * 255 ≈ 25
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)), // 0.2 * 255 ≈ 51
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRateIndicator(String label, double rate, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.textPrimaryColor,
              ),
            ),
            Text(
              '${(rate * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: rate,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Rendez-vous par mois',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: _getBarGroups(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _getMonthName(value.toInt()),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return _statistics!.appointmentsByMonth.entries.map((entry) {
      final month = int.tryParse(entry.key) ?? 0;
      final count = entry.value.toDouble();
      
      return BarChartGroupData(
        x: month,
        barRods: [
          BarChartRodData(
            toY: count,
            color: Theme.of(context).colorScheme.primaryColor,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  String _getMonthName(int month) {
    const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return month > 0 && month <= 12 ? months[month] : '';
  }

  Widget _buildStatusDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Répartition par statut',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieChartSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('En attente', Theme.of(context).colorScheme.warningColor, _statistics!.pendingAppointments),
                    _buildLegendItem('Confirmés', Theme.of(context).colorScheme.successColor, _statistics!.confirmedAppointments),
                    _buildLegendItem('Terminés', Colors.green, _statistics!.completedAppointments),
                    _buildLegendItem('Annulés', Theme.of(context).colorScheme.errorColor, _statistics!.cancelledAppointments),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    final total = _statistics!.totalAppointments;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Theme.of(context).colorScheme.warningColor,
        value: _statistics!.pendingAppointments.toDouble(),
        title: '${((_statistics!.pendingAppointments / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Theme.of(context).colorScheme.successColor,
        value: _statistics!.confirmedAppointments.toDouble(),
        title: '${((_statistics!.confirmedAppointments / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: _statistics!.completedAppointments.toDouble(),
        title: '${((_statistics!.completedAppointments / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Theme.of(context).colorScheme.errorColor,
        value: _statistics!.cancelledAppointments.toDouble(),
        title: '${((_statistics!.cancelledAppointments / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.textPrimaryColor,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Theme.of(context).colorScheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Répartition par lieu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._statistics!.appointmentsByLieu.entries.map((entry) {
            return _buildLocationItem(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String lieu, int count) {
    final total = _statistics!.totalAppointments;
    final percentage = total > 0 ? (count / total) : 0.0;
    
    IconData icon;
    Color color;
    String label;
    
    switch (lieu) {
      case 'en_personne':
        icon = Icons.place;
        color = Theme.of(context).colorScheme.primaryColor;
        label = 'En personne';
        break;
      case 'appel_video':
        icon = Icons.videocam;
        color = Theme.of(context).colorScheme.secondaryColor;
        label = 'Appel vidéo';
        break;
      case 'telephone':
        icon = Icons.phone;
        color = Theme.of(context).colorScheme.tertiaryColor;
        label = 'Téléphone';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        label = lieu;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.textPrimaryColor,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${(percentage * 100).toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}