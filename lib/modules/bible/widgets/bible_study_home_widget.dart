import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_study.dart';
import '../services/bible_study_service.dart';
import '../views/bible_study_detail_view.dart';
import '../views/bible_studies_list_view.dart';

class BibleStudyHomeWidget extends StatefulWidget {
  const BibleStudyHomeWidget({Key? key}) : super(key: key);

  @override
  State<BibleStudyHomeWidget> createState() => _BibleStudyHomeWidgetState();
}

class _BibleStudyHomeWidgetState extends State<BibleStudyHomeWidget> {
  List<BibleStudy> _popularStudies = [];
  List<BibleStudy> _activeStudies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudies();
  }

  Future<void> _loadStudies() async {
    try {
      final popular = await BibleStudyService.getPopularStudies(limit: 3);
      final active = await BibleStudyService.getActiveStudies();
      
      setState(() {
        _popularStudies = popular;
        _activeStudies = active;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  Icons.school_outlined,
                  color: theme.colorScheme.primary,
                  size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Études bibliques',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                    Text(
                      'Approfondissez votre foi',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ])),
              TextButton(
                onPressed: () => _openStudiesPage(),
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary))),
            ]),
          
          const SizedBox(height: 16),
          
          if (_isLoading)
            _buildLoadingState()
          else if (_activeStudies.isNotEmpty)
            _buildActiveStudiesSection()
          else
            _buildPopularStudiesSection(),
        ]));
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => _buildLoadingCard()));
  }

  Widget _buildLoadingCard() {
    final theme = Theme.of(context);
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6))),
                  ])),
            ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 4),
          Container(
            width: 150,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6))),
        ]));
  }

  Widget _buildActiveStudiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Études en cours',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _activeStudies.length,
            itemBuilder: (context, index) {
              return _buildActiveStudyCard(_activeStudies[index]);
            })),
        if (_popularStudies.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Études populaires',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _popularStudies.length,
              itemBuilder: (context, index) {
                return _buildStudyCard(_popularStudies[index]);
              })),
        ],
      ]);
  }

  Widget _buildPopularStudiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Études populaires',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _popularStudies.length,
            itemBuilder: (context, index) {
              return _buildStudyCard(_popularStudies[index]);
            })),
      ]);
  }

  Widget _buildActiveStudyCard(BibleStudy study) {
    final theme = Theme.of(context);
    
    return FutureBuilder<UserStudyProgress?>(
      future: BibleStudyService.getStudyProgress(study.id),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openStudyDetail(study),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: Icon(
                            Icons.school_outlined,
                            color: theme.colorScheme.primary,
                            size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                study.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                              Text(
                                study.author,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
                            ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'EN COURS',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.surfaceColor))),
                      ]),
                    const SizedBox(height: 12),
                    Text(
                      study.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress.progressPercentage / 100,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary))),
                          const SizedBox(width: 8),
                          Text(
                            '${progress.progressPercentage.round()}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary)),
                        ]),
                    ],
                  ])))));
      });
  }

  Widget _buildStudyCard(BibleStudy study) {
    final theme = Theme.of(context);
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openStudyDetail(study),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(study.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        _getCategoryIcon(study.category),
                        color: _getCategoryColor(study.category),
                        size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            study.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                          Text(
                            study.author,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ])),
                    if (study.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'POPULAIRE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningColor))),
                  ]),
                const SizedBox(height: 12),
                Text(
                  study.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      study.formattedDuration,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      study.displayDifficulty,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ]),
              ])))));
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
      default:
        return Icons.book;
    }
  }

  void _openStudiesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BibleStudiesListView()));
  }

  void _openStudyDetail(BibleStudy study) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyDetailView(study: study)));
  }
}
