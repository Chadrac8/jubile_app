import 'package:flutter/material.dart';
import '../models/song_model.dart';

/// Widget de recherche et filtrage pour les chants
class SongSearchFilterBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStyleChanged;
  final Function(String?) onKeyChanged;
  final Function(String?) onStatusChanged;
  final Function(List<String>) onTagsChanged;
  final bool showStatusFilter;
  final String? initialSearch;
  final String? initialStyle;
  final String? initialKey;
  final String? initialStatus;

  const SongSearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onStyleChanged,
    required this.onKeyChanged,
    required this.onStatusChanged,
    required this.onTagsChanged,
    this.showStatusFilter = false,
    this.initialSearch,
    this.initialStyle,
    this.initialKey,
    this.initialStatus,
  });

  @override
  State<SongSearchFilterBar> createState() => _SongSearchFilterBarState();
}

class _SongSearchFilterBarState extends State<SongSearchFilterBar> {
  late TextEditingController _searchController;
  String? _selectedStyle;
  String? _selectedKey;
  String? _selectedStatus;
  List<String> _selectedTags = [];
  bool _showFilters = false;

  // Tags prédéfinis disponibles
  final List<String> _availableTags = [
    'Noël', 'Pâques', 'Baptême', 'Communion', 'Mariage', 'Funérailles',
    'Enfants', 'Jeunes', 'Prière du matin', 'Prière du soir', 'Intercession',
    'Action de grâce', 'Repentance', 'Guérison', 'Évangélisation', 'Mission',
    'Francophone', 'Anglophone', 'Traditionnel', 'Contemporain', 'Gospel',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    _selectedStyle = widget.initialStyle;
    _selectedKey = widget.initialKey;
    _selectedStatus = widget.initialStatus;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStyle = null;
      _selectedKey = null;
      _selectedStatus = null;
      _selectedTags.clear();
    });
    
    widget.onSearchChanged('');
    widget.onStyleChanged(null);
    widget.onKeyChanged(null);
    widget.onStatusChanged(null);
    widget.onTagsChanged([]);
  }

  bool get _hasActiveFilters {
    return _searchController.text.isNotEmpty ||
           _selectedStyle != null ||
           _selectedKey != null ||
           _selectedStatus != null ||
           _selectedTags.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // 10% opacity black
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche principale
          Row(
            children: [
              // Champ de recherche
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un chant, auteur, paroles...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Bouton filtres
              IconButton(
                icon: Badge(
                  isLabelVisible: _hasActiveFilters,
                  child: Icon(
                    _showFilters ? Icons.filter_list : Icons.tune,
                    color: _hasActiveFilters ? Theme.of(context).primaryColor : null,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
              
              // Bouton effacer les filtres
              if (_hasActiveFilters)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: _clearFilters,
                  tooltip: 'Effacer tous les filtres',
                ),
            ],
          ),
          
          // Panneau de filtres détaillés
          if (_showFilters) ...[
            const SizedBox(height: 16),
            _buildFiltersPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0x0D1976D2), // 5% opacity of primaryColor (#1976D2)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres avancés',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Première ligne: Style et Tonalité
          Row(
            children: [
              // Filtre par style
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Style',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedStyle,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tous les styles'),
                    ),
                    ...SongModel.availableStyles.map((style) =>
                      DropdownMenuItem<String>(
                        value: style,
                        child: Text(style),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStyle = value;
                    });
                    widget.onStyleChanged(value);
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Filtre par tonalité
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tonalité',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedKey,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Toutes les tonalités'),
                    ),
                    ...SongModel.availableKeys.map((key) =>
                      DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedKey = value;
                    });
                    widget.onKeyChanged(value);
                  },
                ),
              ),
            ],
          ),
          
          // Deuxième ligne: Statut (si affiché)
          if (widget.showStatusFilter) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
              ),
              value: _selectedStatus,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tous les statuts'),
                ),
                ...SongModel.availableStatuses.map((status) =>
                  DropdownMenuItem<String>(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
                widget.onStatusChanged(value);
              },
            ),
          ],
          
          // Tags
          const SizedBox(height: 16),
          Text(
            'Tags',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                  widget.onTagsChanged(_selectedTags);
                },
                backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                selectedColor: Color(0x331976D2), // 20% opacity of primaryColor (#1976D2)
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Effacer tout'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showFilters = false;
                  });
                },
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
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
}