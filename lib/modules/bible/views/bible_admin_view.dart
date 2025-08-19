import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/reading_plan.dart';
import '../../models/bible_study.dart';
import '../../services/reading_plan_service.dart';
import '../../services/bible_study_service.dart';
import 'reading_plan_form_view.dart';
import 'bible_study_form_view.dart';

class BibleAdminView extends StatefulWidget {
  const BibleAdminView({Key? key}) : super(key: key);

  @override
  State<BibleAdminView> createState() => _BibleAdminViewState();
}

class _BibleAdminViewState extends State<BibleAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Plans de lecture
  List<ReadingPlan> _allPlans = [];
  List<ReadingPlan> _filteredPlans = [];
  String _plansSearchQuery = '';
  Set<String> _selectedPlans = {};
  
  // Études bibliques
  List<BibleStudy> _allStudies = [];
  List<BibleStudy> _filteredStudies = [];
  String _studiesSearchQuery = '';
  Set<String> _selectedStudies = {};
  
  bool _isLoading = true;
  
  // Paramètres Bible
  double _fontSize = 16.0;
  bool _isDarkMode = false;
  double _lineHeight = 1.5;
  String _fontFamily = '';
  Color? _customBgColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _loadPrefs();
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
      final studies = await BibleStudyService.getAvailableStudies();
      
      setState(() {
        _allPlans = plans;
        _filteredPlans = plans;
        _allStudies = studies;
        _filteredStudies = studies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPlans() {
    setState(() {
      _filteredPlans = _allPlans.where((plan) {
        return _plansSearchQuery.isEmpty ||
            plan.name.toLowerCase().contains(_plansSearchQuery.toLowerCase()) ||
            plan.description.toLowerCase().contains(_plansSearchQuery.toLowerCase());
      }).toList();
    });
  }

  void _filterStudies() {
    setState(() {
      _filteredStudies = _allStudies.where((study) {
        return _studiesSearchQuery.isEmpty ||
            study.title.toLowerCase().contains(_studiesSearchQuery.toLowerCase()) ||
            study.description.toLowerCase().contains(_studiesSearchQuery.toLowerCase()) ||
            study.author.toLowerCase().contains(_studiesSearchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('bible_font_size') ?? 16.0;
      _isDarkMode = prefs.getBool('bible_dark_mode') ?? false;
      _lineHeight = prefs.getDouble('bible_line_height') ?? 1.5;
      _fontFamily = prefs.getString('bible_font_family') ?? '';
      final colorValue = prefs.getInt('bible_custom_bg_color');
      _customBgColor = colorValue != null ? Color(colorValue) : null;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bible_font_size', _fontSize);
    await prefs.setBool('bible_dark_mode', _isDarkMode);
    await prefs.setString('bible_font_family', _fontFamily);
    await prefs.setDouble('bible_line_height', _lineHeight);
    if (_customBgColor != null) {
      await prefs.setInt('bible_custom_bg_color', _customBgColor!.toARGB32());
    }
  }

  void _changeFontSize(double value) {
    setState(() {
      _fontSize = value;
    });
    _savePrefs();
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _savePrefs();
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Options de lecture Bible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Taille du texte'),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12,
                      max: 28,
                      divisions: 8,
                      label: _fontSize.toStringAsFixed(0),
                      onChanged: _changeFontSize)),
                  Text('${_fontSize.toStringAsFixed(0)}'),
                ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Interlignage'),
                  Expanded(
                    child: Slider(
                      value: _lineHeight,
                      min: 1.0,
                      max: 2.2,
                      divisions: 12,
                      label: _lineHeight.toStringAsFixed(2),
                      onChanged: (v) {
                        setState(() {
                          _lineHeight = v;
                        });
                        _savePrefs();
                      })),
                  Text(_lineHeight.toStringAsFixed(2)),
                ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Police'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _fontFamily.isEmpty ? null : _fontFamily,
                    hint: const Text('Défaut'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Défaut')),
                      DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                      DropdownMenuItem(value: 'Arial', child: Text('Arial')),
                      DropdownMenuItem(value: 'Times New Roman', child: Text('Times New Roman')),
                      DropdownMenuItem(value: 'Montserrat', child: Text('Montserrat')),
                      DropdownMenuItem(value: 'Lato', child: Text('Lato')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _fontFamily = v ?? '';
                      });
                      _savePrefs();
                    }),
                ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Thème'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _customBgColor == null ? (_isDarkMode ? 'dark' : 'light') : 'custom',
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text('Clair')),
                      DropdownMenuItem(value: 'dark', child: Text('Sombre')),
                      DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
                    ],
                    onChanged: (v) async {
                      if (v == 'light') {
                        setState(() {
                          _isDarkMode = false;
                          _customBgColor = null;
                        });
                        await _savePrefs();
                      } else if (v == 'dark') {
                        setState(() {
                          _isDarkMode = true;
                          _customBgColor = null;
                        });
                        await _savePrefs();
                      } else if (v == 'custom') {
                        // Ouvre le color picker
                        Color picked = _customBgColor ?? Colors.amber[50]!;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Choisir une couleur de fond'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: picked,
                                onColorChanged: (c) {
                                  picked = c;
                                })),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _customBgColor = picked;
                                    _isDarkMode = false;
                                  });
                                  _savePrefs();
                                  Navigator.pop(context);
                                },
                                child: const Text('OK')),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler')),
                            ]));
                      }
                    }),
                ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Mode nuit'),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode),
                ]),
            ]))));
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
          'Administration Bible',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
            tooltip: 'Mode nuit',
            onPressed: () => _toggleDarkMode(!_isDarkMode)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _showSettings(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Options Bible'),
                  contentPadding: EdgeInsets.zero)),
            ]),
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
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Plans de lecture'),
                Tab(text: 'Études bibliques'),
                Tab(text: 'Statistiques'),
              ])))),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlansTab(),
          _buildStudiesTab(),
          _buildStatisticsTab(),
        ]));
  }

  Widget _buildPlansTab() {
    return Column(
      children: [
        // En-tête avec recherche et actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un plan...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface),
                      onChanged: (value) {
                        _plansSearchQuery = value;
                        _filterPlans();
                      })),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _createNewPlan(),
                    icon: const Icon(Icons.add),
                    tooltip: 'Nouveau plan'),
                ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_filteredPlans.length} plan(s)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  const Spacer(),
                  if (_selectedPlans.isNotEmpty) ...[
                    Text(
                      '${_selectedPlans.length} sélectionné(s)',
                      style: GoogleFonts.inter(fontSize: 12)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _deleteSelectedPlans,
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.errorColor),
                      iconSize: 20),
                  ],
                ]),
            ])),
        
        // Liste des plans
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPlans.isEmpty
                  ? _buildEmptyPlansState()
                  : _buildPlansList()),
      ]);
  }

  Widget _buildStudiesTab() {
    return Column(
      children: [
        // En-tête avec recherche et actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher une étude...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface),
                      onChanged: (value) {
                        _studiesSearchQuery = value;
                        _filterStudies();
                      })),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _createNewStudy(),
                    icon: const Icon(Icons.add),
                    tooltip: 'Nouvelle étude'),
                ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_filteredStudies.length} étude(s)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  const Spacer(),
                  if (_selectedStudies.isNotEmpty) ...[
                    Text(
                      '${_selectedStudies.length} sélectionnée(s)',
                      style: GoogleFonts.inter(fontSize: 12)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _deleteSelectedStudies,
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.errorColor),
                      iconSize: 20),
                  ],
                ]),
            ])),
        
        // Liste des études
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredStudies.isEmpty
                  ? _buildEmptyStudiesState()
                  : _buildStudiesList()),
      ]);
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data ?? {};
        final theme = Theme.of(context);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques générales',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Cartes de statistiques
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    title: 'Plans de lecture',
                    value: '${stats['totalPlans'] ?? 0}',
                    icon: Icons.schedule,
                    color: Colors.blue,
                    theme: theme),
                  _buildStatCard(
                    title: 'Études bibliques',
                    value: '${stats['totalStudies'] ?? 0}',
                    icon: Icons.school,
                    color: Theme.of(context).colorScheme.successColor,
                    theme: theme),
                  _buildStatCard(
                    title: 'Plans actifs',
                    value: '${stats['activePlans'] ?? 0}',
                    icon: Icons.play_circle,
                    color: Theme.of(context).colorScheme.warningColor,
                    theme: theme),
                  _buildStatCard(
                    title: 'Études en cours',
                    value: '${stats['activeStudies'] ?? 0}',
                    icon: Icons.pending_actions,
                    color: Colors.purple,
                    theme: theme),
                ]),
              
              const SizedBox(height: 24),
              
              Text(
                'Contenu populaire',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Plans populaires
              _buildPopularContent(),
            ]));
      });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface)),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6))),
        ]));
  }

  Widget _buildEmptyPlansState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, color: Theme.of(context).colorScheme.textTertiaryColor),
          const SizedBox(height: 16),
          Text(
            'Aucun plan de lecture',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Créez votre premier plan de lecture'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createNewPlan,
            icon: const Icon(Icons.add),
            label: const Text('Nouveau plan')),
        ]));
  }

  Widget _buildEmptyStudiesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, color: Theme.of(context).colorScheme.textTertiaryColor),
          const SizedBox(height: 16),
          Text(
            'Aucune étude biblique',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Créez votre première étude biblique'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createNewStudy,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle étude')),
        ]));
  }

  Widget _buildPlansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPlans.length,
      itemBuilder: (context, index) {
        final plan = _filteredPlans[index];
        final isSelected = _selectedPlans.contains(plan.id);
        
        return _buildPlanCard(plan, isSelected);
      });
  }

  Widget _buildStudiesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudies.length,
      itemBuilder: (context, index) {
        final study = _filteredStudies[index];
        final isSelected = _selectedStudies.contains(study.id);
        
        return _buildStudyCard(study, isSelected);
      });
  }

  Widget _buildPlanCard(ReadingPlan plan, bool isSelected) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editPlan(plan),
          onLongPress: () => _togglePlanSelection(plan.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null),
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary)
                else
                  Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                      Text(
                        plan.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        '${plan.totalDays} jours • ${plan.category}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.primary)),
                    ])),
                PopupMenuButton<String>(
                  onSelected: (action) => _handlePlanAction(action, plan),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
                    PopupMenuItem(
                      value: 'toggle_popular',
                      child: Text(plan.isPopular ? 'Retirer des populaires' : 'Marquer populaire')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ]),
              ])))));
  }

  Widget _buildStudyCard(BibleStudy study, bool isSelected) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editStudy(study),
          onLongPress: () => _toggleStudySelection(study.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null),
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary)
                else
                  Icon(Icons.school, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        study.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                      Text(
                        'Par ${study.author}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      const SizedBox(height: 4),
                      Text(
                        study.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        '${study.lessons.length} leçons • ${study.category} • ${study.formattedDuration}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.primary)),
                    ])),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleStudyAction(action, study),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
                    PopupMenuItem(
                      value: 'toggle_popular',
                      child: Text(study.isPopular ? 'Retirer des populaires' : 'Marquer populaire')),
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Text(study.isActive ? 'Désactiver' : 'Activer')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ]),
              ])))));
  }

  Widget _buildPopularContent() {
    final popularPlans = _allPlans.where((plan) => plan.isPopular).toList();
    final popularStudies = _allStudies.where((study) => study.isPopular).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (popularPlans.isNotEmpty) ...[
          Text(
            'Plans de lecture populaires',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...popularPlans.map((plan) => ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(plan.name),
            subtitle: Text('${plan.totalDays} jours'),
            trailing: Icon(Icons.star, color: Theme.of(context).colorScheme.warningColor))),
          const SizedBox(height: 16),
        ],
        
        if (popularStudies.isNotEmpty) ...[
          Text(
            'Études bibliques populaires',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...popularStudies.map((study) => ListTile(
            leading: const Icon(Icons.school),
            title: Text(study.title),
            subtitle: Text('${study.lessons.length} leçons • ${study.author}'),
            trailing: Icon(Icons.star, color: Theme.of(context).colorScheme.warningColor))),
        ],
      ]);
  }

  Future<Map<String, dynamic>> _getStatistics() async {
    final planStats = await ReadingPlanService.getUsageStatistics();
    final studyStats = await BibleStudyService.getUsageStatistics();
    
    return {
      'totalPlans': _allPlans.length,
      'totalStudies': _allStudies.length,
      'activePlans': planStats['activePlans'] ?? 0,
      'activeStudies': studyStats['activeStudies'] ?? 0,
    };
  }

  void _createNewPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingPlanFormView(
          onSaved: () => _loadData())));
  }

  void _createNewStudy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyFormView(
          onSaved: () => _loadData())));
  }

  void _editPlan(ReadingPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingPlanFormView(
          plan: plan,
          onSaved: () => _loadData())));
  }

  void _editStudy(BibleStudy study) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleStudyFormView(
          study: study,
          onSaved: () => _loadData())));
  }

  void _togglePlanSelection(String planId) {
    setState(() {
      if (_selectedPlans.contains(planId)) {
        _selectedPlans.remove(planId);
      } else {
        _selectedPlans.add(planId);
      }
    });
  }

  void _toggleStudySelection(String studyId) {
    setState(() {
      if (_selectedStudies.contains(studyId)) {
        _selectedStudies.remove(studyId);
      } else {
        _selectedStudies.add(studyId);
      }
    });
  }

  void _handlePlanAction(String action, ReadingPlan plan) {
    switch (action) {
      case 'edit':
        _editPlan(plan);
        break;
      case 'duplicate':
        // TODO: Implémenter la duplication
        break;
      case 'toggle_popular':
        // TODO: Implémenter le basculement populaire
        break;
      case 'delete':
        _deletePlan(plan);
        break;
    }
  }

  void _handleStudyAction(String action, BibleStudy study) {
    switch (action) {
      case 'edit':
        _editStudy(study);
        break;
      case 'duplicate':
        // TODO: Implémenter la duplication
        break;
      case 'toggle_popular':
        // TODO: Implémenter le basculement populaire
        break;
      case 'toggle_active':
        // TODO: Implémenter le basculement actif
        break;
      case 'delete':
        _deleteStudy(study);
        break;
    }
  }

  void _deletePlan(ReadingPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le plan'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${plan.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la suppression
              _loadData();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ]));
  }

  void _deleteStudy(BibleStudy study) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'étude'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${study.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la suppression
              _loadData();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ]));
  }

  void _deleteSelectedPlans() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les plans'),
        content: Text('Supprimer ${_selectedPlans.length} plan(s) sélectionné(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPlans.clear();
              });
              _loadData();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ]));
  }

  void _deleteSelectedStudies() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les études'),
        content: Text('Supprimer ${_selectedStudies.length} étude(s) sélectionnée(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedStudies.clear();
              });
              _loadData();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ]));
  }
}
