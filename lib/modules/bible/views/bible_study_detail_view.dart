import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_study.dart';
import '../services/bible_study_service.dart';
import 'bible_study_lesson_view.dart';

class BibleStudyDetailView extends StatefulWidget {
  final BibleStudy study;

  const BibleStudyDetailView({
    Key? key,
    required this.study,
  }) : super(key: key);

  @override
  State<BibleStudyDetailView> createState() => _BibleStudyDetailViewState();
}

class _BibleStudyDetailViewState extends State<BibleStudyDetailView> {
  UserStudyProgress? _progress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await BibleStudyService.getStudyProgress(widget.study.id);
    setState(() {
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: _buildContent(theme)),
        ]),
      bottomNavigationBar: _buildBottomBar(theme));
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getCategoryColor(widget.study.category).withOpacity(0.8),
                _getCategoryColor(widget.study.category).withOpacity(0.3),
              ])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16)),
                        child: Icon(
                          _getCategoryIcon(widget.study.category),
                          color: _getCategoryColor(widget.study.category),
                          size: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.study.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  'POPULAIRE',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.surfaceColor))),
                            Text(
                              widget.study.title,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.surfaceColor,
                                height: 1.2)),
                            const SizedBox(height: 4),
                            Text(
                              'Par ${widget.study.author}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.surfaceColor.withOpacity(0.9))),
                          ])),
                    ]),
                ]))))));
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations sur l'étude
          _buildStudyInfo(theme),
          
          const SizedBox(height: 24),
          
          // Progrès (si commencée)
          if (_progress != null) ...[
            _buildProgressSection(theme),
            const SizedBox(height: 24),
          ],
          
          // Description
          _buildDescriptionSection(theme),
          
          const SizedBox(height: 24),
          
          // Leçons
          _buildLessonsSection(theme),
          
          const SizedBox(height: 100), // Espace pour le bottom bar
        ]));
  }

  Widget _buildStudyInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoItem(
                icon: Icons.access_time,
                label: 'Durée',
                value: widget.study.formattedDuration,
                theme: theme),
              const SizedBox(width: 24),
              _buildInfoItem(
                icon: Icons.signal_cellular_alt,
                label: 'Niveau',
                value: widget.study.displayDifficulty,
                theme: theme),
            ]),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(
                icon: Icons.book,
                label: 'Leçons',
                value: '${widget.study.lessons.length}',
                theme: theme),
              const SizedBox(width: 24),
              _buildInfoItem(
                icon: Icons.category,
                label: 'Catégorie',
                value: widget.study.category,
                theme: theme),
            ]),
        ]));
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface)),
        ]));
  }

  Widget _buildProgressSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: theme.colorScheme.primary,
                size: 20),
              const SizedBox(width: 8),
              Text(
                'Votre progression',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
              const Spacer(),
              Text(
                '${_progress!.progressPercentage.round()}%',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary)),
            ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress!.progressPercentage / 100,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
          const SizedBox(height: 12),
          Text(
            '${_progress!.completedLessons.length} leçon(s) sur ${widget.study.lessons.length} terminée(s)',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
        ]));
  }

  Widget _buildDescriptionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos de cette étude',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        Text(
          widget.study.description,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: theme.colorScheme.onSurface.withOpacity(0.8))),
        if (widget.study.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.study.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
                child: Text(
                  '#$tag',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary)));
            }).toList()),
        ],
      ]);
  }

  Widget _buildLessonsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leçons (${widget.study.lessons.length})',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        ...widget.study.lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          final isCompleted = _progress?.completedLessons.contains(lesson.id) ?? false;
          final isCurrent = _progress?.currentLessonIndex == index;
          final isAccessible = index == 0 || 
              (_progress?.completedLessons.contains(widget.study.lessons[index - 1].id) ?? false);
          
          return _buildLessonCard(lesson, index + 1, isCompleted, isCurrent, isAccessible, theme);
        }),
      ]);
  }

  Widget _buildLessonCard(
    BibleStudyLesson lesson, 
    int number, 
    bool isCompleted, 
    bool isCurrent, 
    bool isAccessible,
    ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAccessible ? () => _openLesson(lesson) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isCurrent
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : Border.all(color: theme.colorScheme.outline.withOpacity(0.2))),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.successColor
                        : isCurrent
                            ? theme.colorScheme.primary
                            : isAccessible
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : isCurrent
                            ? Icons.play_arrow
                            : isAccessible
                                ? Icons.book_outlined
                                : Icons.lock_outline,
                    color: isCompleted || isCurrent
                        ? AppTheme.surfaceColor
                        : isAccessible
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leçon $number: ${lesson.title}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isAccessible
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.4))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.estimatedDuration}min',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.menu_book,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.references.length} passage(s)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ]),
                      if (lesson.references.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          lesson.references.map((ref) => ref.displayText).join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.primary.withOpacity(0.8),
                            fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      ],
                    ])),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'TERMINÉE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor)))
                else if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'EN COURS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary))),
              ])))));
  }

  Widget _buildBottomBar(ThemeData theme) {
    final hasStarted = _progress != null;
    final isCompleted = _progress?.isCompleted ?? false;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2)),
        ]),
      child: Row(
        children: [
          if (hasStarted && !isCompleted) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _continueStudy(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: Text(
                  'Continuer',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600)))),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _startOrRestart(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(
                      isCompleted
                          ? 'Recommencer'
                          : hasStarted
                              ? 'Reprendre'
                              : 'Commencer',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600)))),
        ]));
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Nouveau Testament':
        return Colors.blue;
      case 'Ancien Testament':
        return AppTheme.successColor;
      case 'Spiritualité':
        return Colors.purple;
      case 'Théologie':
        return AppTheme.warningColor;
      case 'Paraboles':
        return Colors.teal;
      default:
        return AppTheme.textTertiaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Nouveau Testament':
        return Icons.auto_stories;
      case 'Ancien Testament':
        return Icons.history_edu;
      case 'Spiritualité':
        return Icons.self_improvement;
      case 'Théologie':
        return Icons.psychology;
      case 'Paraboles':
        return Icons.format_quote;
      default:
        return Icons.book;
    }
  }

  Future<void> _startOrRestart() async {
    setState(() => _isLoading = true);
    
    try {
      await BibleStudyService.startStudy(widget.study.id);
      await _loadProgress();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _progress?.isCompleted == true 
                  ? 'Étude redémarrée !' 
                  : 'Étude commencée !'),
            backgroundColor: AppTheme.successColor));
        _continueStudy();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continueStudy() {
    if (_progress == null) return;
    
    final currentLessonIndex = _progress!.currentLessonIndex;
    if (currentLessonIndex < widget.study.lessons.length) {
      final lesson = widget.study.lessons[currentLessonIndex];
      _openLesson(lesson);
    }
  }

  void _openLesson(BibleStudyLesson lesson) {
    final lessonIndex = widget.study.lessons.indexOf(lesson);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyLessonView(
          study: widget.study,
          lesson: lesson,
          lessonIndex: lessonIndex))).then((_) {
      // Recharger le progrès quand on revient de la leçon
      _loadProgress();
    });
  }
}
