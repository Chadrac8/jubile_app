import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../widgets/song_card.dart';
import '../widgets/song_search_filter_bar.dart';
import '../widgets/song_lyrics_viewer.dart';
import 'song_projection_page.dart';

/// Page des chants pour les membres
class MemberSongsPage extends StatefulWidget {
  const MemberSongsPage({super.key});

  @override
  State<MemberSongsPage> createState() => _MemberSongsPageState();
}

class _MemberSongsPageState extends State<MemberSongsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedStyle;
  String? _selectedKey;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recueil des Chants'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.whatshot), text: 'Populaires'),
            Tab(icon: Icon(Icons.access_time), text: 'Récents'),
            Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
            Tab(icon: Icon(Icons.playlist_play), text: 'Setlists'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          SongSearchFilterBar(
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            onStyleChanged: (style) {
              setState(() {
                _selectedStyle = style;
              });
            },
            onKeyChanged: (key) {
              setState(() {
                _selectedKey = key;
              });
            },
            onStatusChanged: (status) {
              // Les membres ne filtrent pas par statut
            },
            onTagsChanged: (tags) {
              setState(() {
                _selectedTags = tags;
              });
            },
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPopularSongsTab(),
                _buildRecentSongsTab(),
                _buildFavoriteSongsTab(),
                _buildSetlistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSongsTab() {
    return StreamBuilder<List<SongModel>>(
      stream: SongsFirebaseService.getPopularSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final songs = _filterSongs(snapshot.data ?? []);

        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun chant populaire trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return SongCard(
              song: songs[index],
              onTap: () => _showSongDetails(songs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSongsTab() {
    return StreamBuilder<List<SongModel>>(
      stream: SongsFirebaseService.getRecentSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final songs = _filterSongs(snapshot.data ?? []);

        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun chant récent trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return SongCard(
              song: songs[index],
              onTap: () => _showSongDetails(songs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteSongsTab() {
    return StreamBuilder<List<SongModel>>(
      stream: SongsFirebaseService.getFavoriteSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final songs = _filterSongs(snapshot.data ?? []);

        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun chant favori',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Ajoutez des chants à vos favoris en touchant le cœur',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return SongCard(
              song: songs[index],
              onTap: () => _showSongDetails(songs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildSetlistsTab() {
    return StreamBuilder<List<SetlistModel>>(
      stream: SongsFirebaseService.getSetlists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final setlists = snapshot.data ?? [];

        if (setlists.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_play, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune setlist disponible',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: setlists.length,
          itemBuilder: (context, index) {
            return _buildSetlistCard(setlists[index]);
          },
        );
      },
    );
  }

  Widget _buildSetlistCard(SetlistModel setlist) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.playlist_play),
        title: Text(setlist.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (setlist.description.isNotEmpty) Text(setlist.description),
            const SizedBox(height: 4),
            Text(
              'Service du ${_formatDate(setlist.serviceDate)} • ${setlist.songIds.length} chants',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showSetlistDetails(setlist),
      ),
    );
  }

  List<SongModel> _filterSongs(List<SongModel> songs) {
    var filtered = songs;

    // Filtrer par recherche textuelle
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((song) =>
          song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.authors.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.lyrics.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    // Filtrer par style
    if (_selectedStyle != null && _selectedStyle!.isNotEmpty) {
      filtered = filtered.where((song) => song.style == _selectedStyle).toList();
    }

    // Filtrer par tonalité
    if (_selectedKey != null && _selectedKey!.isNotEmpty) {
      filtered = filtered.where((song) => song.originalKey == _selectedKey).toList();
    }

    // Filtrer par tags
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((song) =>
          _selectedTags.any((tag) => song.tags.contains(tag))
      ).toList();
    }

    return filtered;
  }

  void _showSongDetails(SongModel song) {
    // Incrémenter le compteur d'utilisation
    SongsFirebaseService.incrementSongUsage(song.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Poignée de déplacement
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Barre d'actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.present_to_all),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongProjectionPage(song: song),
                          ),
                        );
                      },
                      tooltip: 'Mode projection',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Contenu des paroles
              Expanded(
                child: SongLyricsViewer(
                  song: song,
                  onToggleProjection: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongProjectionPage(song: song),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetlistDetails(SetlistModel setlist) async {
    final songs = await SongsFirebaseService.getSetlistSongs(setlist.songIds);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Poignée de déplacement
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // En-tête
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            setlist.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    if (setlist.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(setlist.description),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Service du ${_formatDate(setlist.serviceDate)} • ${songs.length} chants',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Liste des chants
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(songs[index].title),
                      subtitle: Text('${songs[index].authors} • ${songs[index].originalKey}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showSongDetails(songs[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}