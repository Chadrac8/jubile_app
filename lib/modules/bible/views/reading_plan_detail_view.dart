import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reading_plan.dart';
import '../services/reading_plan_service.dart';

class ReadingPlanDetailView extends StatefulWidget {
  final ReadingPlan plan;
  final VoidCallback? onStartPlan;

  const ReadingPlanDetailView({
    Key? key,
    required this.plan,
    this.onStartPlan,
  }) : super(key: key);

  @override
  State<ReadingPlanDetailView> createState() => _ReadingPlanDetailViewState();
}

class _ReadingPlanDetailViewState extends State<ReadingPlanDetailView> {
  UserReadingProgress? _progress;
  bool _isLoading = true;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await ReadingPlanService.getPlanProgress(widget.plan.id);
    setState(() {
      _progress = progress;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.plan.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.surfaceColor)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ])),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(widget.plan.category),
                    size: 80,
                    color: AppTheme.surfaceColor.withOpacity(0.3)))))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges informatifs
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoBadge(
                        icon: Icons.category,
                        label: widget.plan.category,
                        color: theme.colorScheme.primary),
                      _buildInfoBadge(
                        icon: Icons.calendar_today,
                        label: '${widget.plan.totalDays} jours',
                        color: Colors.blue),
                      _buildInfoBadge(
                        icon: Icons.access_time,
                        label: '${widget.plan.estimatedReadingTime}min/jour',
                        color: AppTheme.successColor),
                      _buildInfoBadge(
                        icon: Icons.signal_cellular_alt,
                        label: _getDifficultyLabel(widget.plan.difficulty),
                        color: _getDifficultyColor(widget.plan.difficulty)),
                    ]),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    widget.plan.description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withOpacity(0.8))),
                  
                  const SizedBox(height: 32),
                  
                  // Progrès si le plan est déjà commencé
                  if (_progress != null) ...[
                    _buildProgressSection(),
                    const SizedBox(height: 32),
                  ],
                  
                  // Aperçu des premiers jours
                  Text(
                    'Aperçu du plan',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Afficher les 5 premiers jours
                  ...widget.plan.days.take(5).map((day) => _buildDayPreview(day)),
                  
                  if (widget.plan.days.length > 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '... et ${widget.plan.days.length - 5} autres jours',
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic))),
                ]))),
        ]),
      bottomNavigationBar: _isLoading 
          ? null 
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5)),
                ]),
              child: SafeArea(
                child: _progress != null 
                    ? _buildContinueButton()
                    : _buildStartButton())));
  }

  Widget _buildProgressSection() {
    final theme = Theme.of(context);
    final progressPercentage = _progress!.completedDays.length / widget.plan.totalDays;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Votre progrès',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
              Text(
                '${_progress!.completedDays.length}/${widget.plan.totalDays}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
            ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text(
            '${(progressPercentage * 100).toInt()}% terminé',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
          if (_progress!.lastReadDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dernière lecture: ${_formatDate(_progress!.lastReadDate!)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ]));
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color)),
        ]));
  }

  Widget _buildDayPreview(ReadingPlanDay day) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  day.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16))),
            ]),
          const SizedBox(height: 12),
          Text(
            'Lectures: ${day.readings.map((r) => r.displayText).join(', ')}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
          if (day.reflection != null) ...[
            const SizedBox(height: 8),
            Text(
              day.reflection!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          ],
        ]));
  }

  Widget _buildStartButton() {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: AppTheme.surfaceColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16))),
        onPressed: _isStarting ? null : _startPlan,
        child: _isStarting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.surfaceColor,
                  strokeWidth: 2))
            : Text(
                'Commencer ce plan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600))));
  }

  Widget _buildContinueButton() {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: AppTheme.surfaceColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16))),
        onPressed: () {
          Navigator.pop(context);
          // TODO: Naviguer vers la vue de lecture active
        },
        child: Text(
          'Continuer la lecture',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600))));
  }

  Future<void> _startPlan() async {
    if (_isStarting) return;
    
    setState(() => _isStarting = true);
    
    try {
      await ReadingPlanService.startReadingPlan(widget.plan.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan "${widget.plan.name}" commencé !'),
            backgroundColor: AppTheme.successColor));
        
        widget.onStartPlan?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Classique':
        return Icons.menu_book;
      case 'Nouveau Testament':
        return Icons.auto_stories;
      case 'Psaumes':
        return Icons.music_note;
      case 'Évangiles':
        return Icons.star;
      case 'Sagesse':
        return Icons.lightbulb;
      default:
        return Icons.book;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      default:
        return 'Débutant';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return AppTheme.successColor;
      case 'intermediate':
        return AppTheme.warningColor;
      case 'advanced':
        return AppTheme.errorColor;
      default:
        return AppTheme.successColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
