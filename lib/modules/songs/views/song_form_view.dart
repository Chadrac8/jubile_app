import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../models/song.dart';
import '../models/song_category.dart';
import '../services/songs_service.dart';

/// Vue de formulaire pour créer/modifier un chant
class SongFormView extends StatefulWidget {
  final Song? song;

  const SongFormView({
    Key? key,
    this.song,
  }) : super(key: key);

  @override
  State<SongFormView> createState() => _SongFormViewState();
}

class _SongFormViewState extends State<SongFormView> {
  final SongsService _songsService = SongsService();
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs de texte
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _authorController = TextEditingController();
  final _composerController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _tonalityController = TextEditingController();
  final _tempoController = TextEditingController();
  final _structureController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _musicSheetController = TextEditingController();

  // État du formulaire
  List<SongCategory> _availableCategories = [];
  List<String> _selectedCategories = [];
  List<String> _tags = [];
  String _newTag = '';
  bool _isPublic = true;
  bool _isApproved = false;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.song != null;
    _initializeForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _composerController.dispose();
    _lyricsController.dispose();
    _tonalityController.dispose();
    _tempoController.dispose();
    _structureController.dispose();
    _audioUrlController.dispose();
    _videoUrlController.dispose();
    _musicSheetController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    setState(() => _isLoading = true);

    try {
      await _songsService.initialize();
      _availableCategories = await _songsService.categories.getActiveCategories();

      if (_isEditMode && widget.song != null) {
        final song = widget.song!;
        _titleController.text = song.title;
        _subtitleController.text = song.subtitle ?? '';
        _authorController.text = song.author ?? '';
        _composerController.text = song.composer ?? '';
        _lyricsController.text = song.lyrics;
        _tonalityController.text = song.tonality ?? '';
        _tempoController.text = song.tempo?.toString() ?? '';
        _structureController.text = song.structure ?? '';
        _audioUrlController.text = song.audioUrl ?? '';
        _videoUrlController.text = song.videoUrl ?? '';
        _musicSheetController.text = song.musicSheet ?? '';
        
        _selectedCategories = List.from(song.categories);
        _tags = List.from(song.tags);
        _isPublic = song.isPublic;
        _isApproved = song.isApproved;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'initialisation: $e')),
        );
      }
    }
  }

  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final song = Song(
        id: _isEditMode ? widget.song!.id : null,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty 
            ? null 
            : _subtitleController.text.trim(),
        author: _authorController.text.trim().isEmpty 
            ? null 
            : _authorController.text.trim(),
        composer: _composerController.text.trim().isEmpty 
            ? null 
            : _composerController.text.trim(),
        lyrics: _lyricsController.text.trim(),
        tonality: _tonalityController.text.trim().isEmpty 
            ? null 
            : _tonalityController.text.trim(),
        tempo: _tempoController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_tempoController.text.trim()),
        structure: _structureController.text.trim().isEmpty 
            ? null 
            : _structureController.text.trim(),
        audioUrl: _audioUrlController.text.trim().isEmpty 
            ? null 
            : _audioUrlController.text.trim(),
        videoUrl: _videoUrlController.text.trim().isEmpty 
            ? null 
            : _videoUrlController.text.trim(),
        musicSheet: _musicSheetController.text.trim().isEmpty 
            ? null 
            : _musicSheetController.text.trim(),
        categories: _selectedCategories,
        tags: _tags,
        isPublic: _isPublic,
        isApproved: _isApproved,
        createdBy: 'current_user_id', // TODO: Remplacer par l'ID utilisateur réel
        createdAt: _isEditMode ? widget.song!.createdAt : now,
        updatedAt: now,
        views: _isEditMode ? widget.song!.views : 0,
        favorites: _isEditMode ? widget.song!.favorites : [],
      );

      if (_isEditMode) {
        await _songsService.update(song.id!, song);
      } else {
        await _songsService.create(song);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode 
                  ? 'Chant modifié avec succès' 
                  : 'Chant créé avec succès',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  void _toggleCategory(String categoryName) {
    setState(() {
      if (_selectedCategories.contains(categoryName)) {
        _selectedCategories.remove(categoryName);
      } else {
        _selectedCategories.add(categoryName);
      }
    });
  }

  void _addTag() {
    if (_newTag.trim().isNotEmpty && !_tags.contains(_newTag.trim())) {
      setState(() {
        _tags.add(_newTag.trim());
        _newTag = '';
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: _isEditMode ? 'Modifier le chant' : 'Nouveau chant',
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _saveSong,
            child: Text(_isEditMode ? 'Modifier' : 'Créer'),
          ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Informations de base
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),

                  // Paroles
                  _buildLyricsSection(),
                  const SizedBox(height: 24),

                  // Informations techniques
                  _buildTechnicalInfoSection(),
                  const SizedBox(height: 24),

                  // Catégories
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  // Tags
                  _buildTagsSection(),
                  const SizedBox(height: 24),

                  // Médias
                  _buildMediaSection(),
                  const SizedBox(height: 24),

                  // Paramètres
                  _buildSettingsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de base',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Sous-titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Auteur',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _composerController,
                    decoration: const InputDecoration(
                      labelText: 'Compositeur',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paroles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _lyricsController,
              decoration: const InputDecoration(
                labelText: 'Paroles du chant *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Les paroles sont obligatoires';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfoSection() {
    return CustomCard(
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
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tonalityController,
                    decoration: const InputDecoration(
                      labelText: 'Tonalité (ex: Do, Ré, Mi)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _tempoController,
                    decoration: const InputDecoration(
                      labelText: 'Tempo (BPM)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (int.tryParse(value) == null) {
                          return 'Nombre invalide';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _structureController,
              decoration: const InputDecoration(
                labelText: 'Structure (ex: Couplet-Refrain-Couplet)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catégories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_availableCategories.isEmpty)
              const Text('Aucune catégorie disponible')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category.name);
                  return FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) => _toggleCategory(category.name),
                    backgroundColor: category.color.withOpacity(0.1),
                    selectedColor: category.color.withOpacity(0.3),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mots-clés',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ajouter un mot-clé',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _newTag = value,
                    onFieldSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTag,
                  child: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return CustomCard(
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
            const SizedBox(height: 16),

            TextFormField(
              controller: _audioUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Audio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.audiotrack),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri?.hasAbsolutePath != true) {
                    return 'URL invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Vidéo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.video_library),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri?.hasAbsolutePath != true) {
                    return 'URL invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _musicSheetController,
              decoration: const InputDecoration(
                labelText: 'URL Partition',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.library_music),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri?.hasAbsolutePath != true) {
                    return 'URL invalide';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Chant public'),
              subtitle: const Text('Visible par tous les membres'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value ?? true),
            ),

            // Note: L'approbation ne devrait être modifiable que par les admins
            // if (userIsAdmin) // TODO: Vérifier les permissions utilisateur
            SwitchListTile(
              title: const Text('Chant approuvé'),
              subtitle: const Text('Visible dans la liste publique'),
              value: _isApproved,
              onChanged: (value) => setState(() => _isApproved = value ?? false),
            ),
          ],
        ),
      ),
    );
  }
}