import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../models/song.dart';
import '../services/songs_service.dart';

/// Vue de détail d'un chant
class SongDetailView extends StatefulWidget {
  final Song song;

  const SongDetailView({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<SongDetailView> createState() => _SongDetailViewState();
}

class _SongDetailViewState extends State<SongDetailView> {
  final SongsService _songsService = SongsService();
  late Song _song;
  bool _isFavorite = false;
  double _fontSize = 16.0;
  
  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _isFavorite = _song.isFavoriteBy('current_user_id'); // TODO: Remplacer par l'ID utilisateur réel
    _incrementViews();
  }

  Future<void> _incrementViews() async {
    try {
      await _songsService.incrementViews(_song.id!);
    } catch (e) {
      // L'erreur ne doit pas bloquer l'affichage
      print('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await _songsService.toggleFavorite(_song.id!, 'current_user_id'); // TODO: Remplacer par l'ID utilisateur réel
      setState(() {
        _isFavorite = !_isFavorite;
        if (_isFavorite) {
          _song = _song.copyWith(
            favorites: [..._song.favorites, 'current_user_id'],
          );
        } else {
          _song = _song.copyWith(
            favorites: _song.favorites.where((id) => id != 'current_user_id').toList(),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _shareSheet() {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à venir')),
    );
  }

  void _copyLyrics() {
    Clipboard.setData(ClipboardData(text: _song.lyrics));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paroles copiées dans le presse-papiers')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: _song.title,
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : null,
          ),
          onPressed: _toggleFavorite,
          tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copier les paroles'),
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Partager'),
              ),
            ),
            const PopupMenuItem(
              value: 'font_size',
              child: ListTile(
                leading: Icon(Icons.text_fields),
                title: Text('Taille du texte'),
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'copy':
                _copyLyrics();
                break;
              case 'share':
                _shareSheet();
                break;
              case 'font_size':
                _showFontSizeDialog();
                break;
            }
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du chant
            _buildSongHeader(),
            const SizedBox(height: 24),

            // Informations techniques
            if (_song.tonality != null || _song.tempo != null || _song.estimatedDuration != 'Non spécifiée')
              _buildTechnicalInfo(),

            // Catégories et tags
            if (_song.categories.isNotEmpty || _song.tags.isNotEmpty)
              _buildCategoriesAndTags(),

            // Paroles
            _buildLyrics(),

            // Médias
            if (_song.audioUrl != null || _song.videoUrl != null || _song.musicSheet != null)
              _buildMediaSection(),

            // Statistiques
            _buildStatistics(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSongHeader() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et sous-titre
            Text(
              _song.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_song.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                _song.subtitle!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Auteur et compositeur
            if (_song.author != null || _song.composer != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        if (_song.author != null) 'Auteur: ${_song.author}',
                        if (_song.composer != null) 'Compositeur: ${_song.composer}',
                      ].join(' • '),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Statut d'approbation
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _song.isApproved ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _song.isApproved ? 'Approuvé' : 'En attente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Créé le ${_song.createdAt.day}/${_song.createdAt.month}/${_song.createdAt.year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfo() {
    return Column(
      children: [
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations techniques',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_song.tonality != null) ...[
                      _buildInfoChip('Tonalité', _song.tonality!, Icons.music_note),
                      const SizedBox(width: 12),
                    ],
                    if (_song.tempo != null) ...[
                      _buildInfoChip('Tempo', '${_song.tempo} BPM', Icons.speed),
                      const SizedBox(width: 12),
                    ],
                    if (_song.estimatedDuration != 'Non spécifiée')
                      _buildInfoChip('Durée', _song.estimatedDuration, Icons.access_time),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesAndTags() {
    return Column(
      children: [
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_song.categories.isNotEmpty) ...[
                  const Text('Catégories:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _song.categories.map((category) => Chip(
                      label: Text(category),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    )).toList(),
                  ),
                ],

                if (_song.categories.isNotEmpty && _song.tags.isNotEmpty)
                  const SizedBox(height: 16),

                if (_song.tags.isNotEmpty) ...[
                  const Text('Mots-clés:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _song.tags.map((tag) => Chip(
                      label: Text('#$tag'),
                      backgroundColor: Colors.grey[200],
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLyrics() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Paroles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  onPressed: _showFontSizeDialog,
                  tooltip: 'Ajuster la taille du texte',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              _song.lyrics,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Médias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_song.audioUrl != null) ...[
                  ListTile(
                    leading: const Icon(Icons.audiotrack),
                    title: const Text('Audio'),
                    subtitle: const Text('Écouter le chant'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      // TODO: Implémenter la lecture audio
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lecture audio à venir')),
                      );
                    },
                  ),
                ],

                if (_song.videoUrl != null) ...[
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text('Vidéo'),
                    subtitle: const Text('Regarder le chant'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      // TODO: Implémenter la lecture vidéo
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lecture vidéo à venir')),
                      );
                    },
                  ),
                ],

                if (_song.musicSheet != null) ...[
                  ListTile(
                    leading: const Icon(Icons.library_music),
                    title: const Text('Partition'),
                    subtitle: const Text('Voir la partition'),
                    trailing: const Icon(Icons.visibility),
                    onTap: () {
                      // TODO: Implémenter l'affichage de la partition
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Affichage partition à venir')),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Column(
      children: [
        const SizedBox(height: 16),
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.visibility, color: Colors.grey[600]),
                      const SizedBox(height: 4),
                      Text(
                        _song.views.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Vues',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.favorite, color: Colors.grey[600]),
                      const SizedBox(height: 4),
                      Text(
                        _song.favorites.length.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Favoris',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taille du texte'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Taille: ${_fontSize.round()}px'),
              Slider(
                value: _fontSize,
                min: 12,
                max: 24,
                divisions: 12,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                  this.setState(() {
                    _fontSize = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}