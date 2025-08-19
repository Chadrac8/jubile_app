import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_study.dart';
import '../services/bible_study_service.dart';
import 'bible_study_detail_view.dart';

class BibleStudiesHomeView extends StatefulWidget {
  const BibleStudiesHomeView({Key? key}) : super(key: key);

  @override
  State<BibleStudiesHomeView> createState() => _BibleStudiesHomeViewState();
}

class _BibleStudiesHomeViewState extends State<BibleStudiesHomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BibleStudy> _allStudies = [];
  List<BibleStudy> _activeStudies = [];
  List<BibleStudy> _completedStudies = [];
  List<BibleStudy> _filteredStudies = [];
  
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  bool _isLoading = true;

  final List<String> _categories = [
    'Tous',
    'Nouveau Testament',
    'Ancien Testament',
    'Spiritualité',
    'Théologie',
    'Paraboles',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudies() async {
    setState(() => _isLoading = true);
    
    try {
      final allStudies = await BibleStudyService.getAvailableStudies();
      final activeStudies = await BibleStudyService.getActiveStudies();
      final completedStudies = await BibleStudyService.getCompletedStudies();
      
      setState(() {
        _allStudies = allStudies;
        _activeStudies = activeStudies;
        _completedStudies = completedStudies;
        _filteredStudies = allStudies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterStudies() {
    setState(() {
      _filteredStudies = _allStudies.where((study) {
        final matchesSearch = _searchQuery.isEmpty ||
            study.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            study.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            study.author.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'Tous' ||
            study.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Études bibliques',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
              ]),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary),
              labelColor: AppTheme.surfaceColor,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Découvrir'),
                Tab(text: 'En cours'),
                Tab(text: 'Terminées'),
              ])))),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildActiveTab(),
          _buildCompletedTab(),
        ]));
  }

  Widget _buildDiscoverTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Barre de recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une étude...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                  filled: true,
                  fillColor: theme.colorScheme.surface),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterStudies();
                }),
              
              const SizedBox(height: 12),
              
              // Filtres par catégorie
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _filterStudies();
                        },
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? AppTheme.surfaceColor 
                              : theme.colorScheme.onSurface),
                        backgroundColor: theme.colorScheme.surface,
                        selectedColor: theme.colorScheme.primary));
                  })),
            ])),
        
        // Liste des études
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _filteredStudies.isEmpty
                  ? _buildEmptyState()
                  : _buildStudiesList(_filteredStudies)),
      ]);
  }

  Widget _buildActiveTab() {
    if (_isLoading) return _buildLoadingState();
    
    if (_activeStudies.isEmpty) {
      return _buildEmptyActiveState();
    }
    
    return _buildStudiesList(_activeStudies, showProgress: true);
  }

  Widget _buildCompletedTab() {
    if (_isLoading) return _buildLoadingState();
    
    if (_completedStudies.isEmpty) {
      return _buildEmptyCompletedState();
    }
    
    return _buildStudiesList(_completedStudies, showCompleted: true);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildLoadingCard());
  }

  Widget _buildLoadingCard() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 16),
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
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7))),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6))),
              ])),
        ]));
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucune étude trouvée',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ]));
  }

  Widget _buildEmptyActiveState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucune étude en cours',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Commencez une étude pour la voir ici',
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text('Découvrir les études')),
        ]));
  }

  Widget _buildEmptyCompletedState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucune étude terminée',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Terminez vos études pour les voir ici',
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ]));
  }

  Widget _buildStudiesList(List<BibleStudy> studies, {bool showProgress = false, bool showCompleted = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: studies.length,
      itemBuilder: (context, index) {
        return _buildStudyCard(studies[index], showProgress: showProgress, showCompleted: showCompleted);
      });
  }

  Widget _buildStudyCard(BibleStudy study, {bool showProgress = false, bool showCompleted = false}) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(study.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    _getCategoryIcon(study.category),
                    color: _getCategoryColor(study.category),
                    size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              study.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface))),
                          if (study.isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      const SizedBox(height: 4),
                      Text(
                        study.author,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      const SizedBox(height: 8),
                      Text(
                        study.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
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
                          const SizedBox(width: 16),
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
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(study.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              study.category,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _getCategoryColor(study.category)))),
                        ]),
                      if (showProgress || showCompleted) ...[
                        const SizedBox(height: 12),
                        FutureBuilder<UserStudyProgress?>(
                          future: BibleStudyService.getStudyProgress(study.id),
                          builder: (context, snapshot) {
                            final progress = snapshot.data;
                            if (progress == null) return const SizedBox.shrink();
                            
                            return Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress.progressPercentage / 100,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      showCompleted ? AppTheme.successColor : theme.colorScheme.primary))),
                                const SizedBox(width: 12),
                                Text(
                                  showCompleted 
                                      ? 'TERMINÉE' 
                                      : '${progress.progressPercentage.round()}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: showCompleted 
                                        ? AppTheme.successColor 
                                        : theme.colorScheme.primary)),
                              ]);
                          }),
                      ],
                    ])),
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

  void _openStudyDetail(BibleStudy study) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyDetailView(study: study)));
  }
}
