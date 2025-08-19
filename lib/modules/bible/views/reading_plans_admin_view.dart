import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reading_plan.dart';
import '../../services/reading_plan_service.dart';
import 'reading_plan_form_view.dart';
import 'reading_plan_detail_view.dart';

class ReadingPlansAdminView extends StatefulWidget {
  const ReadingPlansAdminView({Key? key}) : super(key: key);

  @override
  State<ReadingPlansAdminView> createState() => _ReadingPlansAdminViewState();
}

class _ReadingPlansAdminViewState extends State<ReadingPlansAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReadingPlan> _allPlans = [];
  List<ReadingPlan> _filteredPlans = [];
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  bool _isLoading = true;
  Set<String> _selectedPlans = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    
    try {
      final plans = await ReadingPlanService.getAvailablePlans();
      setState(() {
        _allPlans = plans;
        _filteredPlans = plans;
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
        final matchesCategory = _selectedCategory == 'Tous' || 
            plan.category == _selectedCategory;
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
          'Administration - Plans de lecture',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Tout sélectionner'),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Annuler la sélection'),
            if (_selectedPlans.isNotEmpty)
              PopupMenuButton<String>(
                onSelected: _handleBulkAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Theme.of(context).colorScheme.errorColor),
                        const SizedBox(width: 8),
                        const Text('Supprimer'),
                      ])),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Dupliquer'),
                      ])),
                ]),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(),
              tooltip: 'Rechercher'),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(),
              tooltip: 'Filtrer'),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPlans,
              tooltip: 'Actualiser'),
          ],
        ],
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
                Tab(text: 'Gestion'),
                Tab(text: 'Statistiques'),
              ])))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildManagementTab(),
                _buildStatsTab(),
              ]),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _createNewPlan,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.surfaceColor,
              icon: const Icon(Icons.add),
              label: Text(
                'Nouveau plan',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)))
          : null);
  }

  Widget _buildManagementTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Barre d'information
        if (_selectedPlans.isNotEmpty)
          Container(
            width: double.infinity,
            color: theme.colorScheme.primary.withOpacity(0.1),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${_selectedPlans.length} plan(s) sélectionné(s)',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(color: theme.colorScheme.primary))),
              ])),
        
        // Liste des plans
        Expanded(
          child: _filteredPlans.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredPlans.length,
                  itemBuilder: (context, index) {
                    return _buildPlanCard(_filteredPlans[index]);
                  })),
      ]);
  }

  Widget _buildStatsTab() {
    final theme = Theme.of(context);
    final totalPlans = _allPlans.length;
    final categoriesCount = _allPlans.map((p) => p.category).toSet().length;
    final popularPlans = _allPlans.where((p) => p.isPopular).length;
    final avgDuration = _allPlans.isEmpty ? 0 : 
        _allPlans.map((p) => p.totalDays).reduce((a, b) => a + b) / _allPlans.length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques générales',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Cartes de statistiques
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                title: 'Total des plans',
                value: '$totalPlans',
                icon: Icons.library_books,
                color: theme.colorScheme.primary),
              _buildStatCard(
                title: 'Catégories',
                value: '$categoriesCount',
                icon: Icons.category,
                color: Colors.blue),
              _buildStatCard(
                title: 'Plans populaires',
                value: '$popularPlans',
                icon: Icons.star,
                color: Theme.of(context).colorScheme.warningColor),
              _buildStatCard(
                title: 'Durée moyenne',
                value: '${avgDuration.round()} jours',
                icon: Icons.calendar_today,
                color: Theme.of(context).colorScheme.successColor),
            ]),
          
          const SizedBox(height: 32),
          
          // Répartition par catégorie
          Text(
            'Répartition par catégorie',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          ..._buildCategoryStats(),
        ]));
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color)),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color),
            textAlign: TextAlign.center),
        ]));
  }

  List<Widget> _buildCategoryStats() {
    final categories = <String, int>{};
    for (final plan in _allPlans) {
      categories[plan.category] = (categories[plan.category] ?? 0) + 1;
    }
    
    return categories.entries.map((entry) {
      final percentage = _allPlans.isEmpty ? 0.0 : entry.value / _allPlans.length;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                Text(
                  '${entry.value} (${(percentage * 100).toInt()}%)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              ]),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)),
          ]));
    }).toList();
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucun plan de lecture',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier plan de lecture',
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewPlan,
            icon: const Icon(Icons.add),
            label: const Text('Créer un plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.surfaceColor)),
        ]));
  }

  Widget _buildPlanCard(ReadingPlan plan) {
    final theme = Theme.of(context);
    final isSelected = _selectedPlans.contains(plan.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _isSelectionMode ? _toggleSelection(plan.id) : _viewPlanDetail(plan),
        onLongPress: () => _toggleSelectionMode(plan.id),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(plan.id)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        _getCategoryIcon(plan.category),
                        color: theme.colorScheme.primary)),
                    const SizedBox(width: 12),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold))),
                              if (plan.isPopular)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.warningColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    'Populaire',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.warningColor))),
                            ]),
                          Text(
                            plan.category,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500)),
                        ])),
                    PopupMenuButton<String>(
                      onSelected: (action) => _handlePlanAction(action, plan),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('Voir'),
                            ])),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ])),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy),
                              SizedBox(width: 8),
                              Text('Dupliquer'),
                            ])),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Theme.of(context).colorScheme.errorColor),
                              const SizedBox(width: 8),
                              const Text('Supprimer'),
                            ])),
                      ]),
                  ]),
                const SizedBox(height: 12),
                Text(
                  plan.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: '${plan.totalDays} jours'),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.access_time,
                      label: '${plan.estimatedReadingTime}min'),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.signal_cellular_alt,
                      label: _getDifficultyLabel(plan.difficulty)),
                  ]),
              ])))));
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
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

  void _toggleSelectionMode(String planId) {
    setState(() {
      _isSelectionMode = true;
      _selectedPlans = {planId};
    });
  }

  void _toggleSelection(String planId) {
    setState(() {
      if (_selectedPlans.contains(planId)) {
        _selectedPlans.remove(planId);
        if (_selectedPlans.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPlans.add(planId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPlans = _filteredPlans.map((p) => p.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPlans.clear();
      _isSelectionMode = false;
    });
  }

  void _handleBulkAction(String action) {
    switch (action) {
      case 'delete':
        _confirmBulkDelete();
        break;
      case 'duplicate':
        _bulkDuplicate();
        break;
    }
  }

  void _handlePlanAction(String action, ReadingPlan plan) {
    switch (action) {
      case 'view':
        _viewPlanDetail(plan);
        break;
      case 'edit':
        _editPlan(plan);
        break;
      case 'duplicate':
        _duplicatePlan(plan);
        break;
      case 'delete':
        _confirmDeletePlan(plan);
        break;
    }
  }

  void _createNewPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingPlanFormView(
          onSaved: _loadPlans)));
  }

  void _editPlan(ReadingPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingPlanFormView(
          plan: plan,
          onSaved: _loadPlans)));
  }

  void _viewPlanDetail(ReadingPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingPlanDetailView(plan: plan)));
  }

  void _duplicatePlan(ReadingPlan plan) {
    // TODO: Implémenter la duplication
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplication en cours de développement')));
  }

  void _bulkDuplicate() {
    // TODO: Implémenter la duplication en lot
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplication en lot en cours de développement')));
  }

  void _confirmDeletePlan(ReadingPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le plan "${plan.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlan(plan);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.errorColor),
            child: const Text('Supprimer')),
        ]));
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedPlans.length} plan(s) ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bulkDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.errorColor),
            child: const Text('Supprimer')),
        ]));
  }

  void _deletePlan(ReadingPlan plan) {
    // TODO: Implémenter la suppression
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan "${plan.name}" supprimé')));
    _loadPlans();
  }

  void _bulkDelete() {
    // TODO: Implémenter la suppression en lot
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedPlans.length} plan(s) supprimé(s)')));
    _clearSelection();
    _loadPlans();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom ou description...',
            border: OutlineInputBorder()),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _filterPlans();
          }),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              _filterPlans();
              Navigator.pop(context);
            },
            child: const Text('Effacer')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
        ]));
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Tous',
            'Classique',
            'Nouveau Testament',
            'Psaumes',
            'Évangiles',
            'Sagesse',
          ].map((category) {
            return RadioListTile<String>(
              title: Text(category),
              value: category,
              groupValue: _selectedCategory,
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
                _filterPlans();
                Navigator.pop(context);
              });
          }).toList())));
  }
}
