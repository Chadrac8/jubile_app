import 'package:flutter/material.dart';
import '../../models/dashboard_widget_model.dart';
import '../../services/dashboard_firebase_service.dart';

class DashboardConfigurationPage extends StatefulWidget {
  const DashboardConfigurationPage({Key? key}) : super(key: key);

  @override
  State<DashboardConfigurationPage> createState() => _DashboardConfigurationPageState();
}

class _DashboardConfigurationPageState extends State<DashboardConfigurationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  List<DashboardWidgetModel> _allWidgets = [];
  Map<String, dynamic> _preferences = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfiguration();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    try {
      setState(() => _isLoading = true);

      final futures = await Future.wait([
        DashboardFirebaseService.getAllDashboardWidgetsStream().first,
        DashboardFirebaseService.getDashboardPreferences(),
      ]);

      _allWidgets = futures[0] as List<DashboardWidgetModel>;
      _preferences = futures[1] as Map<String, dynamic>;

      setState(() => _isLoading = false);
    } catch (e) {
      print('Erreur lors du chargement de la configuration: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.widgets), text: 'Widgets'),
            Tab(icon: Icon(Icons.settings), text: 'Préférences'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            onPressed: _resetToDefault,
            icon: const Icon(Icons.restore),
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWidgetsTab(),
                _buildPreferencesTab(),
              ],
            ),
    );
  }

  Widget _buildWidgetsTab() {
    final categories = _groupWidgetsByCategory();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // En-tête avec actions globales
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Widgets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionnez les widgets à afficher sur votre dashboard. '
                  'Vous pouvez réorganiser l\'ordre en glissant-déposant.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectAllWidgets,
                      icon: const Icon(Icons.select_all),
                      label: const Text('Tout sélectionner'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _deselectAllWidgets,
                      icon: const Icon(Icons.deselect),
                      label: const Text('Tout désélectionner'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Widgets groupés par catégorie
        ...categories.entries.map((entry) {
          return _buildCategorySection(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<DashboardWidgetModel> widgets) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          _getCategoryDisplayName(category),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${widgets.length} widgets'),
        leading: Icon(_getCategoryIcon(category)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: widgets.map((widget) => _buildWidgetTile(widget)).toList(),
              onReorder: (oldIndex, newIndex) => _reorderWidgets(widgets, oldIndex, newIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetTile(DashboardWidgetModel widget) {
    return ListTile(
      key: ValueKey(widget.id),
      leading: Icon(
        _getWidgetIcon(widget),
        color: _parseColor(widget.config['color']),
      ),
      title: Text(widget.title),
      subtitle: Text(_getWidgetTypeDisplayName(widget.type)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: widget.isVisible,
            onChanged: (value) => _toggleWidgetVisibility(widget, value),
          ),
          const Icon(Icons.drag_handle),
        ],
      ),
      onTap: () => _showWidgetDetails(widget),
    );
  }

  Widget _buildPreferencesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Préférences d\'Affichage',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Vue compacte
                SwitchListTile(
                  title: const Text('Vue compacte'),
                  subtitle: const Text('Affichage plus dense des widgets'),
                  value: _preferences['compactView'] ?? false,
                  onChanged: (value) => _updatePreference('compactView', value),
                ),
                
                // Afficher les tendances
                SwitchListTile(
                  title: const Text('Afficher les tendances'),
                  subtitle: const Text('Indicateurs d\'évolution des statistiques'),
                  value: _preferences['showTrends'] ?? true,
                  onChanged: (value) => _updatePreference('showTrends', value),
                ),
                
                // Actualisation automatique
                SwitchListTile(
                  title: const Text('Actualisation automatique'),
                  subtitle: const Text('Mise à jour périodique des données'),
                  value: _preferences['autoRefresh'] ?? true,
                  onChanged: (value) => _updatePreference('autoRefresh', value),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paramètres Avancés',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Intervalle d'actualisation
                ListTile(
                  title: const Text('Intervalle d\'actualisation'),
                  subtitle: Text('${(_preferences['refreshInterval'] ?? 300) ~/ 60} minutes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showRefreshIntervalDialog,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Bouton de sauvegarde
        ElevatedButton(
          onPressed: _isSaving ? null : _savePreferences,
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Sauvegarde...'),
                  ],
                )
              : const Text('Sauvegarder les Préférences'),
        ),
      ],
    );
  }

  // MÉTHODES UTILITAIRES

  Map<String, List<DashboardWidgetModel>> _groupWidgetsByCategory() {
    final Map<String, List<DashboardWidgetModel>> categories = {};
    
    for (final widget in _allWidgets) {
      if (!categories.containsKey(widget.category)) {
        categories[widget.category] = [];
      }
      categories[widget.category]!.add(widget);
    }
    
    // Trier chaque catégorie par ordre
    for (final widgets in categories.values) {
      widgets.sort((a, b) => a.order.compareTo(b.order));
    }
    
    return categories;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'persons': return 'Membres';
      case 'groups': return 'Groupes';
      case 'events': return 'Événements';
      case 'services': return 'Services';
      case 'tasks': return 'Tâches';
      case 'appointments': return 'Rendez-vous';
      default: return category.toUpperCase();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'persons': return Icons.people;
      case 'groups': return Icons.groups;
      case 'events': return Icons.event;
      case 'services': return Icons.church;
      case 'tasks': return Icons.task;
      case 'appointments': return Icons.schedule;
      default: return Icons.category;
    }
  }

  String _getWidgetTypeDisplayName(String type) {
    switch (type) {
      case 'stat': return 'Statistique';
      case 'chart': return 'Graphique';
      case 'list': return 'Liste';
      case 'card': return 'Carte';
      default: return type.toUpperCase();
    }
  }

  IconData _getWidgetIcon(DashboardWidgetModel widget) {
    final iconName = widget.config['icon'] as String?;
    if (iconName != null) {
      switch (iconName) {
        case 'people': return Icons.people;
        case 'person_check': return Icons.person_add_alt_1;
        case 'person_add': return Icons.person_add;
        case 'groups': return Icons.groups;
        case 'group_work': return Icons.group_work;
        case 'event': return Icons.event;
        case 'event_available': return Icons.event_available;
        case 'church': return Icons.church;
        case 'task': return Icons.task;
        case 'schedule': return Icons.schedule;
      }
    }
    
    switch (widget.type) {
      case 'stat': return Icons.analytics;
      case 'chart': return Icons.bar_chart;
      case 'list': return Icons.list;
      default: return Icons.widgets;
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        colorString = 'FF' + colorString;
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  // ACTIONS

  Future<void> _toggleWidgetVisibility(DashboardWidgetModel widget, bool isVisible) async {
    try {
      await DashboardFirebaseService.updateWidgetVisibility(widget.id, isVisible);
      
      // Mettre à jour localement
      setState(() {
        final index = _allWidgets.indexWhere((w) => w.id == widget.id);
        if (index != -1) {
          _allWidgets[index] = widget.copyWith(isVisible: isVisible);
        }
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la visibilité: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reorderWidgets(List<DashboardWidgetModel> widgets, int oldIndex, int newIndex) {
    // Ajuster newIndex si nécessaire
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Réorganiser la liste locale
    final widget = widgets.removeAt(oldIndex);
    widgets.insert(newIndex, widget);
    
    // Mettre à jour les ordres
    for (int i = 0; i < widgets.length; i++) {
      widgets[i] = widgets[i].copyWith(order: i);
    }
    
    // Sauvegarder l'ordre
    DashboardFirebaseService.updateWidgetsOrder(_allWidgets);
    
    setState(() {});
  }

  void _selectAllWidgets() {
    for (int i = 0; i < _allWidgets.length; i++) {
      if (!_allWidgets[i].isVisible) {
        DashboardFirebaseService.updateWidgetVisibility(_allWidgets[i].id, true);
        _allWidgets[i] = _allWidgets[i].copyWith(isVisible: true);
      }
    }
    setState(() {});
  }

  void _deselectAllWidgets() {
    for (int i = 0; i < _allWidgets.length; i++) {
      if (_allWidgets[i].isVisible) {
        DashboardFirebaseService.updateWidgetVisibility(_allWidgets[i].id, false);
        _allWidgets[i] = _allWidgets[i].copyWith(isVisible: false);
      }
    }
    setState(() {});
  }

  void _updatePreference(String key, dynamic value) {
    setState(() {
      _preferences[key] = value;
    });
  }

  Future<void> _savePreferences() async {
    try {
      setState(() => _isSaving = true);
      
      await DashboardFirebaseService.saveDashboardPreferences(_preferences);
      
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préférences sauvegardées'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le Dashboard'),
        content: const Text(
          'Voulez-vous vraiment réinitialiser le dashboard aux paramètres par défaut ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      try {
        await DashboardFirebaseService.resetToDefaultWidgets();
        await _loadConfiguration();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard réinitialisé'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réinitialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWidgetDetails(DashboardWidgetModel widget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getWidgetTypeDisplayName(widget.type)}'),
            Text('Catégorie: ${_getCategoryDisplayName(widget.category)}'),
            Text('Visible: ${widget.isVisible ? "Oui" : "Non"}'),
            Text('Ordre: ${widget.order}'),
            if (widget.config.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Configuration:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.config.entries.map((entry) => 
                Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRefreshIntervalDialog() {
    final currentInterval = (_preferences['refreshInterval'] ?? 300) ~/ 60;
    int selectedInterval = currentInterval;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Intervalle d\'actualisation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sélectionnez l\'intervalle d\'actualisation automatique:'),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: selectedInterval,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 minute')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 heure')),
                ],
                onChanged: (value) => setState(() => selectedInterval = value ?? 5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _updatePreference('refreshInterval', selectedInterval * 60);
                Navigator.of(context).pop();
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }
}