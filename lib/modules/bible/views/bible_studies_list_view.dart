import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_study.dart';
import '../services/bible_study_service.dart';
import 'bible_study_detail_view.dart';

class BibleStudiesListView extends StatefulWidget {
  final String? initialCategory;

  const BibleStudiesListView({
    Key? key,
    this.initialCategory,
  }) : super(key: key);

  @override
  State<BibleStudiesListView> createState() => _BibleStudiesListViewState();
}

class _BibleStudiesListViewState extends State<BibleStudiesListView> {
  List<BibleStudy> _studies = [];
  List<BibleStudy> _filteredStudies = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  
  final List<String> _categories = [
    'Tous',
    'Nouveau Testament',
    'Ancien Testament',
    'Spiritualité',
    'Théologie',
    'Vie chrétienne',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Tous';
    _loadStudies();
  }

  Future<void> _loadStudies() async {
    setState(() => _isLoading = true);
    try {
      final studies = await BibleStudyService.getAvailableStudies();
      setState(() {
        _studies = studies;
        _applyFilters();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<BibleStudy> filtered = _studies;

    // Filtrer par catégorie
    if (_selectedCategory != 'Tous') {
      filtered = filtered.where((study) => study.category == _selectedCategory).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((study) =>
        study.title.toLowerCase().contains(query) ||
        study.description.toLowerCase().contains(query) ||
        study.author.toLowerCase().contains(query) ||
        study.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }

    setState(() {
      _filteredStudies = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Études bibliques',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1),
      body: Column(
        children: [
          _buildSearchAndFilters(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStudiesList(theme)),
        ]));
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une étude...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary)),
              filled: true,
              fillColor: theme.colorScheme.surface),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            }),
          const SizedBox(height: 16),
          
          // Filtres par catégorie
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: EdgeInsets.only(right: index < _categories.length - 1 ? 8 : 0),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected 
                            ? AppTheme.surfaceColor 
                            : theme.colorScheme.onSurface)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _applyFilters();
                      });
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: AppTheme.surfaceColor,
                    side: BorderSide(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.outline.withOpacity(0.3))));
              })),
        ]));
  }

  Widget _buildStudiesList(ThemeData theme) {
    if (_filteredStudies.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadStudies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStudies.length,
        itemBuilder: (context, index) {
          final study = _filteredStudies[index];
          return _buildStudyCard(study, theme);
        }));
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Aucune étude trouvée',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères de recherche',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5)),
            textAlign: TextAlign.center),
        ]));
  }

  Widget _buildStudyCard(BibleStudy study, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4)),
        ]),
      child: InkWell(
        onTap: () => _navigateToStudyDetail(study),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image de l'étude
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primary.withOpacity(0.1)),
                    child: study.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              study.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildDefaultImage(theme)))
                        : _buildDefaultImage(theme)),
                  const SizedBox(width: 16),
                  
                  // Contenu
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
                                  color: theme.colorScheme.onSurface),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis)),
                            if (study.isPopular)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  'Populaire',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warningColor))),
                          ]),
                        const SizedBox(height: 4),
                        Text(
                          'Par ${study.author}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        const SizedBox(height: 8),
                        Text(
                          study.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      ])),
                ]),
              const SizedBox(height: 16),
              
              // Métadonnées
              Row(
                children: [
                  _buildMetaChip(
                    icon: Icons.category_outlined,
                    label: study.category,
                    theme: theme),
                  const SizedBox(width: 8),
                  _buildMetaChip(
                    icon: Icons.signal_cellular_alt,
                    label: study.displayDifficulty,
                    theme: theme),
                  const SizedBox(width: 8),
                  _buildMetaChip(
                    icon: Icons.access_time,
                    label: study.formattedDuration,
                    theme: theme),
                  const Spacer(),
                  Text(
                    '${study.lessons.length} leçon${study.lessons.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary)),
                ]),
              
              // Tags
              if (study.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: study.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary)))).toList()),
              ],
            ]))));
  }

  Widget _buildDefaultImage(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primary.withOpacity(0.1)),
      child: Icon(
        Icons.menu_book,
        size: 32,
        color: theme.colorScheme.primary.withOpacity(0.6)));
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
        ]));
  }

  void _navigateToStudyDetail(BibleStudy study) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyDetailView(study: study)));
  }
}
