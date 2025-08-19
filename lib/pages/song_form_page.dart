import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';

/// Page de création/édition d'un chant
class SongFormPage extends StatefulWidget {
  final SongModel? song;

  const SongFormPage({
    super.key,
    this.song,
  });

  @override
  State<SongFormPage> createState() => _SongFormPageState();
}

class _SongFormPageState extends State<SongFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorsController;
  late TextEditingController _lyricsController;
  late TextEditingController _audioUrlController;
  late TextEditingController _privateNotesController;
  late TextEditingController _bibleReferencesController;
  late TextEditingController _tempoController;

  String _selectedStyle = 'Adoration';
  String _selectedKey = 'C';
  String _selectedStatus = 'draft';
  String _selectedVisibility = 'members_only';
  List<String> _tags = [];
  List<String> _bibleReferences = [];
  
  bool _isSaving = false;

  // Tags prédéfinis
  final List<String> _availableTags = [
    'Noël', 'Pâques', 'Baptême', 'Communion', 'Mariage', 'Funérailles',
    'Enfants', 'Jeunes', 'Prière du matin', 'Prière du soir', 'Intercession',
    'Action de grâce', 'Repentance', 'Guérison', 'Évangélisation', 'Mission',
    'Francophone', 'Anglophone', 'Traditionnel', 'Contemporain', 'Gospel',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.song != null) {
      _titleController = TextEditingController(text: widget.song!.title);
      _authorsController = TextEditingController(text: widget.song!.authors);
      _lyricsController = TextEditingController(text: widget.song!.lyrics);
      _audioUrlController = TextEditingController(text: widget.song!.audioUrl);
      _privateNotesController = TextEditingController(text: widget.song!.privateNotes);
      _bibleReferencesController = TextEditingController(
        text: widget.song!.bibleReferences.join(', '),
      );
      _tempoController = TextEditingController(
        text: widget.song!.tempo?.toString() ?? '',
      );
      
      _selectedStyle = widget.song!.style;
      _selectedKey = widget.song!.originalKey;
      _selectedStatus = widget.song!.status;
      _selectedVisibility = widget.song!.visibility;
      _tags = List.from(widget.song!.tags);
      _bibleReferences = List.from(widget.song!.bibleReferences);
    } else {
      _titleController = TextEditingController();
      _authorsController = TextEditingController();
      _lyricsController = TextEditingController();
      _audioUrlController = TextEditingController();
      _privateNotesController = TextEditingController();
      _bibleReferencesController = TextEditingController();
      _tempoController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _lyricsController.dispose();
    _audioUrlController.dispose();
    _privateNotesController.dispose();
    _bibleReferencesController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song == null ? 'Nouveau chant' : 'Modifier le chant'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TextButton(
              onPressed: _saveSong,
              child: const Text('Enregistrer'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations de base
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations générales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Titre
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre du chant *',
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
                    
                    // Auteurs
                    TextFormField(
                      controller: _authorsController,
                      decoration: const InputDecoration(
                        labelText: 'Auteurs/Compositeurs',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: John Doe, Jane Smith',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Style et Tonalité
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStyle,
                            decoration: const InputDecoration(
                              labelText: 'Style',
                              border: OutlineInputBorder(),
                            ),
                            items: SongModel.availableStyles.map((style) =>
                              DropdownMenuItem<String>(
                                value: style,
                                child: Text(style),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStyle = value;
                                });
                              }
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedKey,
                            decoration: const InputDecoration(
                              labelText: 'Tonalité',
                              border: OutlineInputBorder(),
                            ),
                            items: SongModel.availableKeys.map((key) =>
                              DropdownMenuItem<String>(
                                value: key,
                                child: Text(key),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedKey = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tempo
                    TextFormField(
                      controller: _tempoController,
                      decoration: const InputDecoration(
                        labelText: 'Tempo (BPM)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 120',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final tempo = int.tryParse(value);
                          if (tempo == null || tempo < 40 || tempo > 200) {
                            return 'Le tempo doit être entre 40 et 200 BPM';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Paroles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paroles et Accords',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tapez les paroles avec les accords. Les accords doivent être placés au-dessus des mots correspondants.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _lyricsController,
                      decoration: const InputDecoration(
                        labelText: 'Paroles *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 15,
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
            ),
            
            const SizedBox(height: 16),
            
            // Tags
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _tags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _tags.add(tag);
                              } else {
                                _tags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Références bibliques
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Références bibliques',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _bibleReferencesController,
                      decoration: const InputDecoration(
                        labelText: 'Références bibliques',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Psaume 23:1, Jean 3:16',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Médias
            Card(
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
                    
                    // URL Audio
                    TextFormField(
                      controller: _audioUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Audio/Vidéo',
                        border: OutlineInputBorder(),
                        hintText: 'https://youtube.com/watch?v=...',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final uri = Uri.tryParse(value);
                          if (uri == null || !uri.hasScheme) {
                            return 'URL invalide';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Paramètres de publication
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres de publication',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Statut',
                              border: OutlineInputBorder(),
                            ),
                            items: SongModel.availableStatuses.map((status) =>
                              DropdownMenuItem<String>(
                                value: status,
                                child: Text(_getStatusDisplayName(status)),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              }
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedVisibility,
                            decoration: const InputDecoration(
                              labelText: 'Visibilité',
                              border: OutlineInputBorder(),
                            ),
                            items: SongModel.availableVisibilities.map((visibility) =>
                              DropdownMenuItem<String>(
                                value: visibility,
                                child: Text(_getVisibilityDisplayName(visibility)),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedVisibility = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes privées
                    TextFormField(
                      controller: _privateNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes privées (visibles uniquement par les administrateurs)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'published':
        return 'Publié';
      case 'draft':
        return 'Brouillon';
      case 'archived':
        return 'Archivé';
      default:
        return status;
    }
  }

  String _getVisibilityDisplayName(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Privé';
      case 'members_only':
        return 'Membres uniquement';
      default:
        return visibility;
    }
  }

  void _saveSong() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Préparer les références bibliques
      final bibleRefs = _bibleReferencesController.text
          .split(',')
          .map((ref) => ref.trim())
          .where((ref) => ref.isNotEmpty)
          .toList();

      // Créer ou mettre à jour le chant
      final song = SongModel(
        id: widget.song?.id ?? '',
        title: _titleController.text.trim(),
        authors: _authorsController.text.trim(),
        lyrics: _lyricsController.text.trim(),
        originalKey: _selectedKey,
        style: _selectedStyle,
        tags: _tags,
        bibleReferences: bibleRefs,
        tempo: _tempoController.text.isNotEmpty ? int.tryParse(_tempoController.text) : null,
        audioUrl: _audioUrlController.text.trim().isNotEmpty ? _audioUrlController.text.trim() : null,
        attachmentUrls: [],
        status: _selectedStatus,
        visibility: _selectedVisibility,
        privateNotes: _privateNotesController.text.trim().isNotEmpty ? _privateNotesController.text.trim() : null,
        usageCount: widget.song?.usageCount ?? 0,
        lastUsedAt: widget.song?.lastUsedAt,
        createdAt: widget.song?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.song?.createdBy ?? '',
        modifiedBy: widget.song?.modifiedBy,
        metadata: widget.song?.metadata ?? {},
      );

      bool success = false;
      if (widget.song == null) {
        final songId = await SongsFirebaseService.createSong(song);
        success = songId != null;
      } else {
        success = await SongsFirebaseService.updateSong(widget.song!.id, song);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.song == null 
                ? 'Chant créé avec succès' 
                : 'Chant modifié avec succès'),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}