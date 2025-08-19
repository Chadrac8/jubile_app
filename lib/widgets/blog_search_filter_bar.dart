import 'package:flutter/material.dart';
import '../models/blog_model.dart';

class BlogSearchFilterBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function({
    List<String>? categories,
    List<String>? tags,
    BlogPostStatus? status,
    String? author,
  }) onFiltersChanged;
  final List<BlogCategory> availableCategories;
  final List<String> availableTags;
  final List<String> selectedCategories;
  final List<String> selectedTags;
  final String searchQuery;
  final BlogPostStatus? selectedStatus;
  final bool showStatusFilter;
  final VoidCallback onClearFilters;

  const BlogSearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.availableCategories,
    required this.availableTags,
    required this.selectedCategories,
    required this.selectedTags,
    required this.searchQuery,
    this.selectedStatus,
    this.showStatusFilter = true,
    required this.onClearFilters,
  });

  @override
  State<BlogSearchFilterBar> createState() => _BlogSearchFilterBarState();
}

class _BlogSearchFilterBarState extends State<BlogSearchFilterBar> {
  final _searchController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = widget.selectedCategories.isNotEmpty ||
        widget.selectedTags.isNotEmpty ||
        widget.selectedStatus != null ||
        widget.searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher des articles...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: widget.searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Bouton filtres
              Container(
                decoration: BoxDecoration(
                  color: hasActiveFilters 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    Icons.tune,
                    color: hasActiveFilters ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          
          // Filtres étendus
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            _buildExpandedFilters(),
          ],
          
          // Indicateur de filtres actifs
          if (hasActiveFilters && !_isExpanded) ...[
            const SizedBox(height: 12),
            _buildActiveFiltersIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statut (pour admin seulement)
        if (widget.showStatusFilter) ...[
          Text(
            'Statut',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(null, 'Tous'),
              ...BlogPostStatus.values.map(
                (status) => _buildStatusChip(status, status.displayName),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Catégories
        if (widget.availableCategories.isNotEmpty) ...[
          Text(
            'Catégories',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableCategories.map((category) {
              final isSelected = widget.selectedCategories.contains(category.name);
              return FilterChip(
                label: Text(category.name),
                selected: isSelected,
                onSelected: (selected) => _toggleCategory(category.name),
                backgroundColor: category.color != null
                    ? Color(_parseColor(category.color!).value & 0x1AFFFFFF | 0x1000000)
                    : null,
                selectedColor: category.color != null
                    ? Color(_parseColor(category.color!).value & 0x33FFFFFF | 0x2000000)
                    : null,
                checkmarkColor: category.color != null
                    ? _parseColor(category.color!)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Tags populaires
        if (widget.availableTags.isNotEmpty) ...[
          Text(
            'Tags populaires',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableTags.take(15).map((tag) {
              final isSelected = widget.selectedTags.contains(tag);
              return FilterChip(
                label: Text('#$tag'),
                selected: isSelected,
                onSelected: (selected) => _toggleTag(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Actions
        Row(
          children: [
            TextButton.icon(
              onPressed: widget.onClearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => setState(() => _isExpanded = false),
              icon: const Icon(Icons.check),
              label: const Text('Appliquer'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(BlogPostStatus? status, String label) {
    final isSelected = widget.selectedStatus == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        widget.onFiltersChanged(status: selected ? status : null);
      },
    );
  }

  Widget _buildActiveFiltersIndicator() {
    final activeFilters = <Widget>[];
    
    // Statut
    if (widget.selectedStatus != null) {
      activeFilters.add(_buildActiveFilterChip(
        widget.selectedStatus!.displayName,
        () => widget.onFiltersChanged(status: null),
      ));
    }
    
    // Catégories
    for (final category in widget.selectedCategories) {
      activeFilters.add(_buildActiveFilterChip(
        category,
        () => _toggleCategory(category),
      ));
    }
    
    // Tags
    for (final tag in widget.selectedTags.take(3)) {
      activeFilters.add(_buildActiveFilterChip(
        '#$tag',
        () => _toggleTag(tag),
      ));
    }
    
    // Indicateur des tags supplémentaires
    if (widget.selectedTags.length > 3) {
      activeFilters.add(Chip(
        label: Text('+${widget.selectedTags.length - 3}'),
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Filtres actifs:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.onClearFilters,
              child: const Text('Tout effacer'),
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: activeFilters,
        ),
      ],
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: const Color(0x1A1976D2), // 10% opacity of primaryColor (#1976D2)
      labelStyle: TextStyle(
        fontSize: 12,
        color: Theme.of(context).primaryColor,
      ),
      deleteIconColor: Theme.of(context).primaryColor,
    );
  }

  void _toggleCategory(String category) {
    final selectedCategories = List<String>.from(widget.selectedCategories);
    
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    
    widget.onFiltersChanged(categories: selectedCategories);
  }

  void _toggleTag(String tag) {
    final selectedTags = List<String>.from(widget.selectedTags);
    
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    
    widget.onFiltersChanged(tags: selectedTags);
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}