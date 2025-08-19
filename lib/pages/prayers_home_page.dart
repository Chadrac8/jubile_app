import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../services/prayers_firebase_service.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_search_filter_bar.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'prayer_form_page.dart';
import 'prayer_detail_page.dart';

class PrayersHomePage extends StatefulWidget {
  const PrayersHomePage({super.key});

  @override
  State<PrayersHomePage> createState() => _PrayersHomePageState();
}

class _PrayersHomePageState extends State<PrayersHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  PrayerType? _selectedType;
  String? _selectedCategory;
  bool _showApprovedOnly = false; // Admin peut voir toutes les prières
  bool _showActiveOnly = true;
  bool _isGridView = false;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  List<PrayerModel> _selectedPrayers = [];
  bool _isSelectionMode = false;
  List<String> _availableCategories = [];
  PrayerStats? _stats;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
    _loadCategories();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await PrayersFirebaseService.getUsedCategories();
    setState(() {
      _availableCategories = categories;
    });
  }

  Future<void> _loadStats() async {
    final stats = await PrayersFirebaseService.getPrayerStats();
    setState(() {
      _stats = stats;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedCategory = null;
      _showApprovedOnly = false;
      _showActiveOnly = true;
    });
    _searchController.clear();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPrayers.clear();
    });
  }

  void _selectPrayer(PrayerModel prayer, bool selected) {
    setState(() {
      if (selected) {
        _selectedPrayers.add(prayer);
      } else {
        _selectedPrayers.removeWhere((p) => p.id == prayer.id);
      }
    });
  }

  Future<void> _bulkApprove() async {
    try {
      for (final prayer in _selectedPrayers) {
        await PrayersFirebaseService.approvePrayer(prayer.id);
      }
      setState(() {
        _selectedPrayers.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prières approuvées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkReject() async {
    try {
      for (final prayer in _selectedPrayers) {
        await PrayersFirebaseService.rejectPrayer(prayer.id);
      }
      setState(() {
        _selectedPrayers.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prières rejetées'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${_selectedPrayers.length} prière(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final prayer in _selectedPrayers) {
          await PrayersFirebaseService.deletePrayer(prayer.id);
        }
        setState(() {
          _selectedPrayers.clear();
          _isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prières supprimées avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToPrayerForm([PrayerModel? prayer]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrayerFormPage(prayer: prayer),
      ),
    ).then((_) {
      _loadStats();
      _loadCategories();
    });
  }

  void _navigateToPrayerDetail(PrayerModel prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrayerDetailPage(prayer: prayer),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques du Mur de Prière',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    '${_stats!.totalPrayers}',
                    Icons.pan_tool,
                    Theme.of(context).colorScheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Aujourd\'hui',
                    '${_stats!.todayPrayers}',
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Cette semaine',
                    '${_stats!.weekPrayers}',
                    Icons.date_range,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'En attente',
                    '${_stats!.pendingApproval}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedPrayers.length} sélectionnée(s)')
            : const Text('Mur de Prière - Administration'),
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _selectedPrayers.isNotEmpty ? _bulkApprove : null,
              tooltip: 'Approuver',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _selectedPrayers.isNotEmpty ? _bulkReject : null,
              tooltip: 'Rejeter',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedPrayers.isNotEmpty ? _bulkDelete : null,
              tooltip: 'Supprimer',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _toggleSelectionMode,
              tooltip: 'Annuler',
            ),
          ] else ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'Vue liste' : 'Vue grille',
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Sélection multiple',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Statistiques
          _buildStatsHeader(),

          // Barre de recherche et filtres
          PrayerSearchFilterBar(
            searchController: _searchController,
            searchQuery: _searchQuery,
            selectedType: _selectedType,
            selectedCategory: _selectedCategory,
            availableCategories: _availableCategories,
            showApprovedOnly: _showApprovedOnly,
            showActiveOnly: _showActiveOnly,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onTypeChanged: (type) => setState(() => _selectedType = type),
            onCategoryChanged: (category) => setState(() => _selectedCategory = category),
            onApprovedOnlyChanged: (value) => setState(() => _showApprovedOnly = value),
            onActiveOnlyChanged: (value) => setState(() => _showActiveOnly = value),
            onClearFilters: _clearFilters,
          ),

          // Liste des prières
          Expanded(
            child: StreamBuilder<List<PrayerModel>>(
              stream: PrayersFirebaseService.getPrayersStream(
                type: _selectedType,
                category: _selectedCategory,
                approvedOnly: _showApprovedOnly,
                activeOnly: _showActiveOnly,
                searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                limit: 100,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                final prayers = snapshot.data ?? [];

                if (prayers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pan_tool,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucune prière trouvée pour "${_searchQuery}"'
                              : 'Aucune prière pour le moment',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Les nouvelles prières apparaîtront ici',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: prayers.length,
                  itemBuilder: (context, index) {
                    final prayer = prayers[index];
                    final isSelected = _selectedPrayers.any((p) => p.id == prayer.id);

                    return Container(
                      decoration: _isSelectionMode && isSelected
                          ? BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primaryColor,
                                width: 2,
                              ),
                            )
                          : null,
                      child: PrayerCard(
                        prayer: prayer,
                        isAdminView: true,
                        onTap: _isSelectionMode
                            ? () => _selectPrayer(prayer, !isSelected)
                            : () => _navigateToPrayerDetail(prayer),
                        onEdit: () => _navigateToPrayerForm(prayer),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: const Text('Êtes-vous sûr de vouloir supprimer cette prière ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await PrayersFirebaseService.deletePrayer(prayer.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Prière supprimée avec succès'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: () => _navigateToPrayerForm(),
                tooltip: 'Ajouter une prière',
                child: const Icon(Icons.add),
              ),
            ),
    );
  }
}