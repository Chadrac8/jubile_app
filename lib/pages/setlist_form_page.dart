import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';

/// Page de création/édition d'une setlist
class SetlistFormPage extends StatefulWidget {
  final SetlistModel? setlist;

  const SetlistFormPage({
    super.key,
    this.setlist,
  });

  @override
  State<SetlistFormPage> createState() => _SetlistFormPageState();
}

class _SetlistFormPageState extends State<SetlistFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  DateTime _serviceDate = DateTime.now();
  String? _serviceType;
  List<String> _selectedSongIds = [];
  List<SongModel> _availableSongs = [];
  List<SongModel> _selectedSongs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _serviceTypes = [
    'Culte du dimanche',
    'Prière du mercredi',
    'Réunion de jeunes',
    'Réunion d\'enfants',
    'Service spécial',
    'Baptême',
    'Mariage',
    'Funérailles',
    'Concert',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAvailableSongs();
  }

  void _initializeControllers() {
    if (widget.setlist != null) {
      _nameController = TextEditingController(text: widget.setlist!.name);
      _descriptionController = TextEditingController(text: widget.setlist!.description);
      _notesController = TextEditingController(text: widget.setlist!.notes);
      _serviceDate = widget.setlist!.serviceDate;
      _serviceType = widget.setlist!.serviceType;
      _selectedSongIds = List.from(widget.setlist!.songIds);
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  void _loadAvailableSongs() async {
    try {
      final songs = await SongsFirebaseService.getPublishedSongs().first;
      
      if (widget.setlist != null) {
        final selectedSongs = await SongsFirebaseService.getSetlistSongs(_selectedSongIds);
        setState(() {
          _availableSongs = songs;
          _selectedSongs = selectedSongs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _availableSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des chants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setlist == null ? 'Nouvelle setlist' : 'Modifier la setlist'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TextButton(
              onPressed: _saveSetlist,
              child: const Text('Enregistrer'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Formulaire
            Expanded(
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
                          
                          // Nom de la setlist
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom de la setlist *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est obligatoire';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Date du service
                          InkWell(
                            onTap: _selectServiceDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date du service *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                '${_serviceDate.day.toString().padLeft(2, '0')}/${_serviceDate.month.toString().padLeft(2, '0')}/${_serviceDate.year}',
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Type de service
                          DropdownButtonFormField<String>(
                            value: _serviceType,
                            decoration: const InputDecoration(
                              labelText: 'Type de service',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Sélectionner un type'),
                              ),
                              ..._serviceTypes.map((type) =>
                                DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _serviceType = value;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Notes
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Liste des chants sélectionnés
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Chants sélectionnés (${_selectedSongs.length})',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _showSongSelection,
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter'),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          if (_selectedSongs.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.music_off,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Aucun chant sélectionné',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _showSongSelection,
                                    child: const Text('Ajouter des chants'),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedSongs.length,
                              onReorder: _reorderSongs,
                              itemBuilder: (context, index) {
                                final song = _selectedSongs[index];
                                return Card(
                                  key: ValueKey(song.id),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(song.title),
                                    subtitle: Text('${song.authors} • ${song.originalKey}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.drag_handle),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => _removeSong(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectServiceDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _serviceDate = date;
      });
    }
  }

  void _showSongSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SongSelectionBottomSheet(
        availableSongs: _availableSongs,
        selectedSongIds: _selectedSongs.map((s) => s.id).toList(),
        onSongsSelected: (selectedSongs) {
          setState(() {
            _selectedSongs = selectedSongs;
            _selectedSongIds = selectedSongs.map((s) => s.id).toList();
          });
        },
      ),
    );
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final song = _selectedSongs.removeAt(oldIndex);
      _selectedSongs.insert(newIndex, song);
      _selectedSongIds = _selectedSongs.map((s) => s.id).toList();
    });
  }

  void _removeSong(int index) {
    setState(() {
      _selectedSongs.removeAt(index);
      _selectedSongIds = _selectedSongs.map((s) => s.id).toList();
    });
  }

  void _saveSetlist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un chant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final setlist = SetlistModel(
        id: widget.setlist?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        songIds: _selectedSongIds,
        serviceDate: _serviceDate,
        serviceType: _serviceType,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: widget.setlist?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.setlist?.createdBy ?? '',
        modifiedBy: widget.setlist?.modifiedBy,
      );

      bool success = false;
      if (widget.setlist == null) {
        final setlistId = await SongsFirebaseService.createSetlist(setlist);
        success = setlistId != null;
      } else {
        success = await SongsFirebaseService.updateSetlist(widget.setlist!.id, setlist);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.setlist == null 
                ? 'Setlist créée avec succès' 
                : 'Setlist modifiée avec succès'),
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

/// Widget pour la sélection de chants
class SongSelectionBottomSheet extends StatefulWidget {
  final List<SongModel> availableSongs;
  final List<String> selectedSongIds;
  final Function(List<SongModel>) onSongsSelected;

  const SongSelectionBottomSheet({
    super.key,
    required this.availableSongs,
    required this.selectedSongIds,
    required this.onSongsSelected,
  });

  @override
  State<SongSelectionBottomSheet> createState() => _SongSelectionBottomSheetState();
}

class _SongSelectionBottomSheetState extends State<SongSelectionBottomSheet> {
  late List<String> _tempSelectedSongIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelectedSongIds = List.from(widget.selectedSongIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = widget.availableSongs.where((song) {
      if (_searchQuery.isEmpty) return true;
      return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             song.authors.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
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
            // Poignée
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
              child: Row(
                children: [
                  Text(
                    'Sélectionner des chants',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${_tempSelectedSongIds.length} sélectionnés',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un chant...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des chants
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = filteredSongs[index];
                  final isSelected = _tempSelectedSongIds.contains(song.id);
                  
                  return CheckboxListTile(
                    title: Text(song.title),
                    subtitle: Text('${song.authors} • ${song.originalKey}'),
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _tempSelectedSongIds.add(song.id);
                        } else {
                          _tempSelectedSongIds.remove(song.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            
            // Boutons d'action
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedSongs = widget.availableSongs
                            .where((song) => _tempSelectedSongIds.contains(song.id))
                            .toList();
                        widget.onSongsSelected(selectedSongs);
                        Navigator.pop(context);
                      },
                      child: const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}