import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../services/songs_service.dart';
import '../models/song.dart';
import '../models/song_category.dart';
import 'song_detail_view.dart';
import 'song_form_view.dart';

/// Vue admin pour la gestion des chants
class SongsAdminView extends StatefulWidget {
  const SongsAdminView({Key? key}) : super(key: key);

  @override
  State<SongsAdminView> createState() => _SongsAdminViewState();
}

class _SongsAdminViewState extends State<SongsAdminView>
    with TickerProviderStateMixin {
  final SongsService _songsService = SongsService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  
  List<Song> _songs = [];
  List<Song> _pendingSongs = [];
  List<SongCategory> _categories = [];
  Map<String, int> _statistics = {};
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      await _songsService.initialize();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _songsService.getAll(),
        _songsService.getPendingSongs(),
        _songsService.categories.getActiveCategories(),
        _songsService.getStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _songs = results[0] as List<Song>;
          _pendingSongs = results[1] as List<Song>;
          _categories = results[2] as List<SongCategory>;
          _statistics = results[3] as Map<String, int>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      await _loadData();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final searchResults = await _songsService.searchSongs(_searchQuery);
      if (mounted) {
        setState(() {
          _songs = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la recherche: $e')),
        );
      }
    }
  }

  Future<void> _approveSong(Song song) async {
    try {
      await _songsService.approveSong(song.id!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chant approuvé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'approbation: $e')),
        );
      }
    }
  }

  Future<void> _rejectSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le chant'),
        content: Text('Êtes-vous sûr de vouloir rejeter "${song.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _songsService.rejectSong(song.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chant rejeté')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du rejet: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le chant'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${song.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _songsService.delete(song.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chant supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  void _navigateToSongDetail(Song song) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SongDetailView(song: song),
      ),
    );
  }

  void _navigateToSongForm([Song? song]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SongFormView(song: song),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Administration des Chants',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToSongForm(),
          tooltip: 'Ajouter un chant',
        ),
      ],
      body: Column(
        children: [
          // Statistiques
          if (_statistics.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      _statistics['total'] ?? 0,
                      Icons.library_music,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Approuvés',
                      _statistics['approved'] ?? 0,
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'En attente',
                      _statistics['pending'] ?? 0,
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un chant...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _loadData();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(height: 16),

          // Onglets
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: 'Tous (${_songs.length})',
                icon: const Icon(Icons.library_music),
              ),
              Tab(
                text: 'En attente (${_pendingSongs.length})',
                icon: const Icon(Icons.pending),
              ),
              const Tab(
                text: 'Catégories',
                icon: Icon(Icons.category),
              ),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllSongsTab(),
                _buildPendingSongsTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSongsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Text('Aucun chant trouvé'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return _buildSongCard(song, isAdmin: true);
        },
      ),
    );
  }

  Widget _buildPendingSongsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingSongs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Aucun chant en attente d\'approbation'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingSongs.length,
        itemBuilder: (context, index) {
          final song = _pendingSongs[index];
          return _buildPendingSongCard(song);
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildSongCard(Song song, {bool isAdmin = false}) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: song.isApproved 
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            song.isApproved ? Icons.check_circle : Icons.pending,
            color: song.isApproved ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (song.author != null) Text('Par ${song.author}'),
            Text('${song.views} vues • ${song.favorites.length} favoris'),
            if (song.categories.isNotEmpty)
              Text('Catégories: ${song.categories.join(', ')}'),
          ],
        ),
        trailing: isAdmin
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Voir'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifier'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer'),
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _navigateToSongDetail(song);
                      break;
                    case 'edit':
                      _navigateToSongForm(song);
                      break;
                    case 'delete':
                      _deleteSong(song);
                      break;
                  }
                },
              )
            : null,
        onTap: () => _navigateToSongDetail(song),
      ),
    );
  }

  Widget _buildPendingSongCard(Song song) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pending, color: Colors.orange),
            ),
            title: Text(
              song.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (song.author != null) Text('Par ${song.author}'),
                Text('Créé le ${song.createdAt.day}/${song.createdAt.month}/${song.createdAt.year}'),
                if (song.preview.isNotEmpty)
                  Text(
                    song.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
            onTap: () => _navigateToSongDetail(song),
          ),
          const Divider(height: 1),
          ButtonBar(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Rejeter'),
                onPressed: () => _rejectSong(song),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Approuver'),
                onPressed: () => _approveSong(song),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(SongCategory category) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconData(category.icon ?? ''),
            color: category.color,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(category.description),
        trailing: Switch(
          value: category.isActive,
          onChanged: (value) {
            // TODO: Implémenter la mise à jour du statut de la catégorie
          },
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'favorite':
        return Icons.favorite;
      case 'church':
        return Icons.church;
      case 'share':
        return Icons.share;
      case 'star':
        return Icons.star;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'child_friendly':
        return Icons.child_friendly;
      case 'library_music':
        return Icons.library_music;
      default:
        return Icons.category;
    }
  }
}