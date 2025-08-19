import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reading_plan.dart';
import '../../services/reading_plan_service.dart';
import 'reading_plan_detail_view.dart';
import 'active_reading_plan_view.dart';

class ReadingPlansHomePage extends StatefulWidget {
  const ReadingPlansHomePage({Key? key}) : super(key: key);

  @override
  State<ReadingPlansHomePage> createState() => _ReadingPlansHomePageState();
}

class _ReadingPlansHomePageState extends State<ReadingPlansHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReadingPlan> _allPlans = [];
  List<ReadingPlan> _filteredPlans = [];
  List<String> _categories = [];
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoading = true;
  ReadingPlan? _activePlan;
  UserReadingProgress? _activeProgress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final plans = await ReadingPlanService.getAvailablePlans();
      final categories = await ReadingPlanService.getCategories();
      final activePlan = await ReadingPlanService.getActivePlan();
      UserReadingProgress? activeProgress;
      
      if (activePlan != null) {
        activeProgress = await ReadingPlanService.getPlanProgress(activePlan.id);
      }

      setState(() {
        _allPlans = plans;
        _filteredPlans = plans;
        _categories = categories;
        _activePlan = activePlan;
        _activeProgress = activeProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')));
      }
    }
  }

  void _filterPlans() {
    setState(() {
      _filteredPlans = _allPlans.where((plan) {
        final matchesCategory = _selectedCategory == 'Tous' || plan.category == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
            plan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            plan.description.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
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
          'Plans de lecture',
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
              labelColor: Theme.of(context).colorScheme.surfaceColor,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Actuel'),
                Tab(text: 'Découvrir'),
                Tab(text: 'Populaires'),
              ])))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildDiscoverTab(),
                _buildPopularTab(),
              ]));
  }

  Widget _buildActiveTab() {
    if (_activePlan == null) {
      return _buildNoActivePlanView();
    }

    return ActiveReadingPlanView(
      plan: _activePlan!,
      progress: _activeProgress,
      onProgressUpdated: _loadData);
  }

  Widget _buildNoActivePlanView() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
              child: Icon(
                Icons.menu_book,
                size: 64,
                color: theme.colorScheme.primary)),
            const SizedBox(height: 24),
            Text(
              'Aucun plan actif',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Text(
              'Choisissez un plan de lecture pour commencer votre parcours spirituel',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
              onPressed: () => _tabController.animateTo(1),
              child: Text(
                'Découvrir les plans',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ])));
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Barre de recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un plan...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _filterPlans();
                }),
              const SizedBox(height: 12),
              // Filtres par catégorie
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                          _filterPlans();
                        },
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2)));
                  }).toList())),
            ])),
        // Liste des plans
        Expanded(
          child: _filteredPlans.isEmpty
              ? const Center(child: Text('Aucun plan trouvé'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredPlans.length,
                  itemBuilder: (context, index) {
                    return _buildPlanCard(_filteredPlans[index]);
                  })),
      ]);
  }

  Widget _buildPopularTab() {
    final popularPlans = _allPlans.where((plan) => plan.isPopular).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: popularPlans.length,
      itemBuilder: (context, index) {
        return _buildPlanCard(popularPlans[index], showPopularBadge: true);
      });
  }

  Widget _buildPlanCard(ReadingPlan plan, {bool showPopularBadge = false}) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToPlanDetail(plan),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      _getCategoryIcon(plan.category),
                      color: theme.colorScheme.primary,
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
                                plan.name,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold))),
                            if (showPopularBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.warningColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  'Populaire',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.warningColor))),
                          ]),
                        const SizedBox(height: 4),
                        Text(
                          plan.category,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500)),
                      ])),
                ]),
              const SizedBox(height: 16),
              Text(
                plan.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: '${plan.totalDays} jours',
                    theme: theme),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: '${plan.estimatedReadingTime}min/jour',
                    theme: theme),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.signal_cellular_alt,
                    label: _getDifficultyLabel(plan.difficulty),
                    theme: theme),
                ]),
            ]))));
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.8))),
        ]));
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

  void _navigateToPlanDetail(ReadingPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingPlanDetailView(
          plan: plan,
          onStartPlan: () {
            _startPlan(plan);
          })));
  }

  Future<void> _startPlan(ReadingPlan plan) async {
    try {
      await ReadingPlanService.startReadingPlan(plan.id);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan "${plan.name}" commencé !'),
            backgroundColor: Theme.of(context).colorScheme.successColor));
        _tabController.animateTo(0); // Aller à l'onglet "Actuel"
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
