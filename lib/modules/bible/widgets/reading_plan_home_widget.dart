import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reading_plan.dart';
import '../../services/reading_plan_service.dart';
import '../views/reading_plans_home_page.dart';

class ReadingPlanHomeWidget extends StatefulWidget {
  const ReadingPlanHomeWidget({Key? key}) : super(key: key);

  @override
  State<ReadingPlanHomeWidget> createState() => _ReadingPlanHomeWidgetState();
}

class _ReadingPlanHomeWidgetState extends State<ReadingPlanHomeWidget> {
  ReadingPlan? _activePlan;
  UserReadingProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivePlan();
  }

  Future<void> _loadActivePlan() async {
    setState(() => _isLoading = true);
    
    try {
      final activePlan = await ReadingPlanService.getActivePlan();
      UserReadingProgress? progress;
      
      if (activePlan != null) {
        progress = await ReadingPlanService.getPlanProgress(activePlan.id);
      }
      
      setState(() {
        _activePlan = activePlan;
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return _buildLoadingWidget(theme);
    }
    
    if (_activePlan == null) {
      return _buildNoActivePlanWidget(theme);
    }
    
    return _buildActivePlanWidget(theme);
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.13),
                borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.all(12),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2))),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6))),
                ])),
          ])));
  }

  Widget _buildNoActivePlanWidget(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReadingPlansHomePage())).then((_) => _loadActivePlan());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.flag, color: theme.colorScheme.primary, size: 32)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plans de lecture',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      'Découvre des plans pour lire la Bible chaque jour.',
                      style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.secondary)),
                  ])),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.chevron_right, size: 24)),
            ]))));
  }

  Widget _buildActivePlanWidget(ThemeData theme) {
    final progressPercentage = _progress!.completedDays.length / _activePlan!.totalDays;
    final currentDay = _progress!.currentDay;
    final isUpToDate = _progress!.completedDays.contains(currentDay);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReadingPlansHomePage())).then((_) => _loadActivePlan());
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône et titre
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.2),
                          theme.colorScheme.secondary.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.menu_book,
                      color: theme.colorScheme.primary,
                      size: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activePlan!.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Jour $currentDay/${_activePlan!.totalDays}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            if (isUpToDate)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.successColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '✓',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.successColor,
                                    fontWeight: FontWeight.bold))),
                          ]),
                      ])),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.chevron_right, size: 24)),
                ]),
              
              const SizedBox(height: 16),
              
              // Barre de progression
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3)),
                      child: FractionallySizedBox(
                        widthFactor: progressPercentage,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ]),
                            borderRadius: BorderRadius.circular(3)))))),
                  const SizedBox(width: 12),
                  Text(
                    '${(progressPercentage * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
                ]),
              
              const SizedBox(height: 12),
              
              // Lecture du jour
              if (_activePlan!.days.isNotEmpty && currentDay <= _activePlan!.days.length)
                _buildTodayReading(theme, currentDay),
            ]))));
  }

  Widget _buildTodayReading(ThemeData theme, int currentDay) {
    final todayReading = _activePlan!.days.firstWhere(
      (day) => day.day == currentDay,
      orElse: () => _activePlan!.days.first);
    
    final isCompleted = _progress!.completedDays.contains(currentDay);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted 
            ? Theme.of(context).colorScheme.successColor.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Theme.of(context).colorScheme.successColor.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.today,
                size: 16,
                color: isCompleted 
                    ? Theme.of(context).colorScheme.successColor 
                    : theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                isCompleted ? 'Lecture terminée' : 'Lecture du jour',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCompleted 
                      ? Theme.of(context).colorScheme.successColor
                      : theme.colorScheme.primary)),
            ]),
          const SizedBox(height: 6),
          Text(
            todayReading.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            todayReading.readings.map((r) => r.displayText).join(' • '),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        ]));
  }
}
