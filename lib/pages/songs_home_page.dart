import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../widgets/song_card.dart';
import '../widgets/song_search_filter_bar.dart';
import 'song_form_page.dart';
import 'song_detail_page.dart';
import 'setlist_form_page.dart';
import 'songs_import_export_page.dart';

/// Page d'administration des chants
class SongsHomePage extends StatefulWidget {
  const SongsHomePage({super.key});

  @override
  State<SongsHomePage> createState() => _SongsHomePageState();
}

class _SongsHomePageState extends State<SongsHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedStyle;
  String? _selectedKey;
  String? _selectedStatus;
  List<String> _selectedTags = [];
  List<String> _selectedSongs = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Gestion des Chants'),
        actions: [
          if (_isSelectionMode) ...[
            // Actions de sélection multiple
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Tout sélectionner',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Annuler la sélection',
            ),
            if (_selectedSongs.isNotEmpty)
              PopupMenuButton<String>(
                onSelected: _handleBulkAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(Icons.publish),
                        SizedBox(width: 8),
                        Text('Publier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive),
                        SizedBox(width: 8),
                        Text('Archiver'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ] else ...[
            // Actions normales
            IconButton(
              icon: const Icon(Icons.import_export),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SongsImportExportPage()),
              ),
              tooltip: 'Import/Export',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToSongForm(),
              tooltip: 'Ajouter un chant',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'Chants'),
            Tab(icon: Icon(Icons.playlist_play), text: 'Setlists'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          SongSearchFilterBar(
            showStatusFilter: true,
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
              setState(() {
                _selectedStatus = status;
              });
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
                _buildSongsTab(),
                _buildSetlistsTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _navigateToSongForm(),
              child: const Icon(Icons.add),
            )
          : _tabController.index == 1
              ? FloatingActionButton(
                  onPressed: () => _navigateToSetlistForm(),
                  child: const Icon(Icons.playlist_add),
                )
              : null,
    );
  }

  Widget _buildSongsTab() {
    return StreamBuilder<List<SongModel>>(
      stream: SongsFirebaseService.getSongs(),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Aucun chant trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToSongForm(),
                  child: const Text('Ajouter le premier chant'),
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
              showActions: true,
              isSelected: _selectedSongs.contains(songs[index].id),
              onSelectionChanged: _isSelectionMode
                  ? (selected) => _toggleSongSelection(songs[index].id, selected)
                  : null,
              onTap: () => _navigateToSongDetail(songs[index]),
              onEdit: () => _navigateToSongForm(song: songs[index]),
              onDelete: () => _confirmDeleteSong(songs[index]),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.playlist_play, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Aucune setlist créée',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToSetlistForm(),
                  child: const Text('Créer la première setlist'),
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _navigateToSetlistForm(setlist: setlist);
                break;
              case 'delete':
                _confirmDeleteSetlist(setlist);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToSetlistForm(setlist: setlist),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: SongsFirebaseService.getSongsStatistics(),
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

        final stats = snapshot.data ?? {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Statistiques générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiques générales',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total des chants',
                            '${stats['totalSongs'] ?? 0}',
                            Icons.music_note,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Publiés',
                            '${stats['publishedSongs'] ?? 0}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Brouillons',
                            '${stats['draftSongs'] ?? 0}',
                            Icons.edit,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Archivés',
                            '${stats['archivedSongs'] ?? 0}',
                            Icons.archive,
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistiques d'utilisation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Utilisation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total utilisations',
                            '${stats['totalUsage'] ?? 0}',
                            Icons.play_arrow,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Moyenne par chant',
                            '${(stats['averageUsage'] ?? 0).toStringAsFixed(1)}',
                            Icons.trending_up,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
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

    // Filtrer par statut
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered.where((song) => song.status == _selectedStatus).toList();
    }

    // Filtrer par tags
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((song) =>
          _selectedTags.any((tag) => song.tags.contains(tag))
      ).toList();
    }

    return filtered;
  }

  void _toggleSongSelection(String songId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSongs.add(songId);
      } else {
        _selectedSongs.remove(songId);
      }
      
      if (_selectedSongs.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll() {
    // Cette méthode nécessiterait d'avoir accès à la liste complète des chants
    // Pour l'instant, on active juste le mode sélection
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSongs.clear();
      _isSelectionMode = false;
    });
  }

  void _handleBulkAction(String action) async {
    switch (action) {
      case 'publish':
        await _bulkUpdateStatus('published');
        break;
      case 'archive':
        await _bulkUpdateStatus('archived');
        break;
      case 'delete':
        await _confirmBulkDelete();
        break;
    }
  }

  Future<void> _bulkUpdateStatus(String status) async {
    final messenger = ScaffoldMessenger.of(context);
    
    for (final songId in _selectedSongs) {
      final song = await SongsFirebaseService.getSong(songId);
      if (song != null) {
        await SongsFirebaseService.updateSong(
          songId,
          song.copyWith(status: status),
        );
      }
    }
    
    _clearSelection();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text('${_selectedSongs.length} chants mis à jour'),
      ),
    );
  }

  Future<void> _confirmBulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${_selectedSongs.length} chants ?'),
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
      final messenger = ScaffoldMessenger.of(context);
      
      for (final songId in _selectedSongs) {
        await SongsFirebaseService.deleteSong(songId);
      }
      
      _clearSelection();
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_selectedSongs.length} chants supprimés'),
        ),
      );
    }
  }

  void _navigateToSongForm({SongModel? song}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongFormPage(song: song),
      ),
    );
  }

  void _navigateToSongDetail(SongModel song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongDetailPage(song: song),
      ),
    );
  }

  void _navigateToSetlistForm({SetlistModel? setlist}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetlistFormPage(setlist: setlist),
      ),
    );
  }

  void _confirmDeleteSong(SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le chant "${song.title}" ?'),
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
      final success = await SongsFirebaseService.deleteSong(song.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chant supprimé avec succès')),
        );
      }
    }
  }

  void _confirmDeleteSetlist(SetlistModel setlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la setlist "${setlist.name}" ?'),
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
      final success = await SongsFirebaseService.deleteSetlist(setlist.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setlist supprimée avec succès')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}