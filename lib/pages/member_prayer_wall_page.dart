import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../services/prayers_firebase_service.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_search_filter_bar.dart';
import '../../compatibility/app_theme_bridge.dart';
import '../auth/auth_service.dart';
import 'prayer_form_page.dart';
import 'prayer_detail_page.dart';

class MemberPrayerWallPage extends StatefulWidget {
  const MemberPrayerWallPage({super.key});

  @override
  State<MemberPrayerWallPage> createState() => _MemberPrayerWallPageState();
}

class _MemberPrayerWallPageState extends State<MemberPrayerWallPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  PrayerType? _selectedType;
  String? _selectedCategory;
  bool _showApprovedOnly = true; // Membres voient seulement les prières approuvées
  bool _showActiveOnly = true;
  String _selectedTab = 'all';
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  
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

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    );
    _tabAnimationController.forward();

    _loadCategories();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _tabAnimationController.dispose();
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
      _showApprovedOnly = true;
      _showActiveOnly = true;
    });
    _searchController.clear();
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pan_tool,
                  color: Theme.of(context).colorScheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mur de Prière Communautaire',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Partagez vos demandes, témoignages et actions de grâce avec la communauté',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
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
                    'Intercessions',
                    '${_stats!.totalPrayerCount}',
                    Icons.favorite,
                    Colors.red,
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                'all',
                'Toutes',
                Icons.pan_tool,
                null,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                'my_prayers',
                'Mes prières',
                Icons.person,
                null,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                'my_intercessions',
                'Mes intercessions',
                Icons.favorite,
                null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon, Color? color) {
    final isSelected = _selectedTab == tabId;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tabId),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected 
                ? Border.all(color: Theme.of(context).colorScheme.primaryColor, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primaryColor 
                    : Colors.grey,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryColor 
                        : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<List<PrayerModel>> _getPrayersStream() {
    final user = AuthService.currentUser;
    
    switch (_selectedTab) {
      case 'my_prayers':
        return PrayersFirebaseService.getUserPrayersStream();
      case 'my_intercessions':
        if (user == null) return Stream.value([]);
        return PrayersFirebaseService.getPrayersStream(
          approvedOnly: _showApprovedOnly,
          activeOnly: _showActiveOnly,
          limit: 100,
        ).map((prayers) => prayers.where((prayer) => 
            prayer.prayedByUsers.contains(user.uid)).toList());
      default:
        return PrayersFirebaseService.getPrayersStream(
          type: _selectedType,
          category: _selectedCategory,
          approvedOnly: _showApprovedOnly,
          activeOnly: _showActiveOnly,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          limit: 100,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mur de Prière'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Statistiques
          _buildStatsHeader(),

          // Sélecteur d'onglets
          _buildTabSelector(),

          // Barre de recherche et filtres (seulement pour "Toutes")
          if (_selectedTab == 'all')
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
              stream: _getPrayersStream(),
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final prayers = snapshot.data ?? [];

                if (prayers.isEmpty) {
                  String emptyMessage;
                  String emptySubtitle;
                  IconData emptyIcon;

                  switch (_selectedTab) {
                    case 'my_prayers':
                      emptyMessage = 'Aucune prière personnelle';
                      emptySubtitle = 'Créez votre première prière pour commencer';
                      emptyIcon = Icons.person_outline;
                      break;
                    case 'my_intercessions':
                      emptyMessage = 'Aucune intercession';
                      emptySubtitle = 'Les prières pour lesquelles vous intercédez apparaîtront ici';
                      emptyIcon = Icons.favorite_outline;
                      break;
                    default:
                      emptyMessage = _searchQuery.isNotEmpty
                          ? 'Aucune prière trouvée pour "${_searchQuery}"'
                          : 'Aucune prière pour le moment';
                      emptySubtitle = _searchQuery.isNotEmpty
                          ? 'Essayez d\'ajuster vos critères de recherche'
                          : 'Soyez le premier à partager une prière';
                      emptyIcon = Icons.pan_tool_outlined;
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          emptyIcon,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emptySubtitle,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedTab == 'all' || _selectedTab == 'my_prayers') ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToPrayerForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Créer une prière'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await _loadStats();
                    await _loadCategories();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: prayers.length,
                    itemBuilder: (context, index) {
                      final prayer = prayers[index];
                      final user = AuthService.currentUser;
                      final isMyPrayer = user != null && prayer.authorId == user.uid;

                      return PrayerCard(
                        prayer: prayer,
                        onTap: () => _navigateToPrayerDetail(prayer),
                        onEdit: isMyPrayer ? () => _navigateToPrayerForm(prayer) : null,
                        onDelete: isMyPrayer ? () async {
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
                        } : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () => _navigateToPrayerForm(),
          tooltip: 'Ajouter une prière',
          backgroundColor: Theme.of(context).colorScheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}