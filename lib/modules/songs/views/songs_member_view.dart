import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../services/songs_service.dart';
import '../models/song.dart';
import '../models/song_category.dart';
import 'song_detail_view.dart';

/// Vue membre pour la gestion des chants
class SongsMemberView extends StatefulWidget {
  const SongsMemberView({Key? key}) : super(key: key);

  @override
  State<SongsMemberView> createState() => _SongsMemberViewState();
}

class _SongsMemberViewState extends State<SongsMemberView>
    with TickerProviderStateMixin {
  final SongsService _songsService = SongsService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  
  List<Song> _songs = [];
  List<Song> _favorites = [];
  List<Song> _recentSongs = [];
  List<Song> _popularSongs = [];
  List<SongCategory> _categories = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        _songsService.getFavoriteSongs('current_user_id'), // TODO: Remplacer par l'ID utilisateur réel
        _songsService.getRecentSongs(),
        _songsService.getPopularSongs(),
        _songsService.categories.getActiveCategories(),
      ]);

      if (mounted) {
        setState(() {
          _songs = results[0] as List<Song>;
          _favorites = results[1] as List<Song>;
          _recentSongs = results[2] as List<Song>;
          _popularSongs = results[3] as List<Song>;
          _categories = results[4] as List<SongCategory>;
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

  Future<void> _filterByCategory(String? categoryName) async {
    setState(() {
      _selectedCategory = categoryName;
      _isLoading = true;
    });

    try {
      final filteredSongs = categoryName == null
          ? await _songsService.getAll()
          : await _songsService.getSongsByCategory(categoryName);
      
      if (mounted) {
        setState(() {
          _songs = filteredSongs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du filtrage: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Song song) async {
    try {
      await _songsService.toggleFavorite(song.id!, 'current_user_id'); // TODO: Remplacer par l'ID utilisateur réel
      await _loadData(); // Recharger les données
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Recueil des Chants',
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
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

          // Filtres par catégorie
          if (_categories.isNotEmpty) ...[
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Tous'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => _filterByCategory(null),
                    ),
                  ),
                  ..._categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.name),
                          selected: _selectedCategory == category.name,
                          onSelected: (_) => _filterByCategory(category.name),
                          avatar: category.icon != null
                              ? Icon(
                                  _getIconData(category.icon!),
                                  size: 16,
                                  color: _selectedCategory == category.name
                                      ? Colors.white
                                      : category.color,
                                )
                              : null,
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Onglets
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Tous', icon: Icon(Icons.library_music)),
              Tab(text: 'Favoris', icon: Icon(Icons.favorite)),
              Tab(text: 'Récents', icon: Icon(Icons.access_time)),
              Tab(text: 'Populaires', icon: Icon(Icons.trending_up)),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsList(_songs),
                _buildSongsList(_favorites),
                _buildSongsList(_recentSongs),
                _buildSongsList(_popularSongs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList(List<Song> songs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun chant trouvé',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return _buildSongCard(song);
        },
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    final isFavorite = song.isFavoriteBy('current_user_id'); // TODO: Remplacer par l'ID utilisateur réel

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (song.author != null) ...[
              const SizedBox(height: 4),
              Text('Par ${song.author}'),
            ],
            if (song.categories.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: song.categories.take(2).map((category) => Chip(
                      label: Text(
                        category,
                        style: const TextStyle(fontSize: 10),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
              ),
            ],
            if (song.preview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                song.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.views > 0)
              Text(
                '${song.views} vues',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () => _toggleFavorite(song),
            ),
          ],
        ),
        onTap: () => _navigateToSongDetail(song),
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
        return Icons.music_note;
    }
  }
}