import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reading_plan.dart';
import '../services/reading_plan_service.dart';
import 'daily_reading_view.dart';

class ActiveReadingPlanView extends StatefulWidget {
  final ReadingPlan plan;
  final UserReadingProgress? progress;
  final VoidCallback? onProgressUpdated;

  const ActiveReadingPlanView({
    Key? key,
    required this.plan,
    this.progress,
    this.onProgressUpdated,
  }) : super(key: key);

  @override
  State<ActiveReadingPlanView> createState() => _ActiveReadingPlanViewState();
}

class _ActiveReadingPlanViewState extends State<ActiveReadingPlanView> {
  UserReadingProgress? _progress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
  }

  @override
  void didUpdateWidget(ActiveReadingPlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progress = widget.progress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_progress == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentDay = _progress!.currentDay;
    final completedDays = _progress!.completedDays;
    final progressPercentage = completedDays.length / widget.plan.totalDays;
    final todayTask = widget.plan.days.firstWhere(
      (day) => day.day == currentDay,
      orElse: () => widget.plan.days.first);

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshProgress();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec progrès
            _buildProgressHeader(theme, progressPercentage),
            
            const SizedBox(height: 24),
            
            // Lecture du jour
            _buildTodayReading(theme, todayTask),
            
            const SizedBox(height: 24),
            
            // Actions rapides
            _buildQuickActions(theme),
            
            const SizedBox(height: 24),
            
            // Historique récent
            _buildRecentHistory(theme),
            
            const SizedBox(height: 24),
            
            // Statistiques
            _buildStatistics(theme),
          ])));
  }

  Widget _buildProgressHeader(ThemeData theme, double progressPercentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: theme.colorScheme.primary,
                size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                    Text(
                      'Jour ${_progress!.currentDay} sur ${widget.plan.totalDays}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  ])),
              CircularProgressIndicator(
                value: progressPercentage,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
            ]),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_progress!.completedDays.length} jours terminés',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7))),
              Text(
                '${(progressPercentage * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
            ]),
        ]));
  }

  Widget _buildTodayReading(ThemeData theme, ReadingPlanDay todayTask) {
    final isCompleted = _progress!.completedDays.contains(todayTask.day);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppTheme.successColor.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.today,
                  color: isCompleted ? AppTheme.successColor : theme.colorScheme.primary,
                  size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Lecture terminée !' : 'Lecture du jour',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppTheme.successColor : null)),
                    Text(
                      todayTask.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  ])),
            ]),
          const SizedBox(height: 16),
          
          // Lectures du jour
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lectures',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  todayTask.readings.map((r) => r.displayText).join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500)),
              ])),
          
          if (todayTask.reflection != null) ...[
            const SizedBox(height: 12),
            Text(
              'Réflexion',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              todayTask.reflection!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.4)),
          ],
          
          const SizedBox(height: 16),
          
          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted 
                    ? AppTheme.successColor 
                    : theme.colorScheme.primary,
                foregroundColor: AppTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
              onPressed: _isLoading ? null : () => _openDailyReading(todayTask),
              child: Text(
                isCompleted ? 'Relire' : 'Commencer la lecture',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)))),
        ]));
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                theme: theme,
                icon: Icons.history,
                title: 'Historique',
                subtitle: 'Voir toutes les lectures',
                onTap: () => _showHistoryDialog())),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                theme: theme,
                icon: Icons.note_add,
                title: 'Mes notes',
                subtitle: 'Voir mes réflexions',
                onTap: () => _showNotesDialog())),
          ]),
      ]);
  }

  Widget _buildActionCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2))),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center),
          ])));
  }

  Widget _buildRecentHistory(ThemeData theme) {
    final recentDays = _progress!.completedDays.toList()
      ..sort((a, b) => b.compareTo(a));
    final displayDays = recentDays.take(3).toList();
    
    if (displayDays.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lectures récentes',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...displayDays.map((dayNumber) {
          final day = widget.plan.days.firstWhere(
            (d) => d.day == dayNumber,
            orElse: () => widget.plan.days.first);
          return _buildHistoryItem(theme, day, true);
        }),
      ]);
  }

  Widget _buildHistoryItem(ThemeData theme, ReadingPlanDay day, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppTheme.successColor.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                '${day.day}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? AppTheme.successColor : theme.colorScheme.primary,
                  fontSize: 12)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
                Text(
                  day.readings.map((r) => r.displayText).join(', '),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ])),
          if (isCompleted)
            Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 20),
        ]));
  }

  Widget _buildStatistics(ThemeData theme) {
    final totalDays = widget.plan.totalDays;
    final completedDays = _progress!.completedDays.length;
    final remainingDays = totalDays - completedDays;
    final streak = _calculateStreak();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  value: '$completedDays',
                  label: 'Jours terminés',
                  color: AppTheme.successColor)),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  value: '$remainingDays',
                  label: 'Jours restants',
                  color: theme.colorScheme.primary)),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  value: '$streak',
                  label: 'Série actuelle',
                  color: AppTheme.warningColor)),
            ]),
        ]));
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color)),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6)),
          textAlign: TextAlign.center),
      ]);
  }

  int _calculateStreak() {
    if (_progress!.completedDays.isEmpty) return 0;
    
    final sortedDays = _progress!.completedDays.toList()..sort();
    int streak = 1;
    int maxStreak = 1;
    
    for (int i = 1; i < sortedDays.length; i++) {
      if (sortedDays[i] == sortedDays[i - 1] + 1) {
        streak++;
        maxStreak = maxStreak > streak ? maxStreak : streak;
      } else {
        streak = 1;
      }
    }
    
    return maxStreak;
  }

  Future<void> _refreshProgress() async {
    final progress = await ReadingPlanService.getPlanProgress(widget.plan.id);
    setState(() {
      _progress = progress;
    });
    widget.onProgressUpdated?.call();
  }

  void _openDailyReading(ReadingPlanDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyReadingView(
          plan: widget.plan,
          day: day,
          progress: _progress!,
          onCompleted: (note) async {
            await ReadingPlanService.completeDayReading(
              widget.plan.id,
              day.day,
              note: note);
            await _refreshProgress();
          })));
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historique des lectures'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.plan.days.where((day) => 
              _progress!.completedDays.contains(day.day)
            ).map((day) => _buildHistoryItem(Theme.of(context), day, true)).toList())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer')),
        ]));
  }

  void _showNotesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mes notes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _progress!.dayNotes.entries.map((entry) {
              final day = widget.plan.days.firstWhere(
                (d) => d.day == entry.key,
                orElse: () => widget.plan.days.first);
              return ListTile(
                title: Text('Jour ${entry.key}: ${day.title}'),
                subtitle: Text(entry.value));
            }).toList())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer')),
        ]));
  }
}
