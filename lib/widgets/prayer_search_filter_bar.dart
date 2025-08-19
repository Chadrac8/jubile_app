import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../theme.dart';

class PrayerSearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final PrayerType? selectedType;
  final String? selectedCategory;
  final List<String> availableCategories;
  final bool showApprovedOnly;
  final bool showActiveOnly;
  final Function(String) onSearchChanged;
  final Function(PrayerType?) onTypeChanged;
  final Function(String?) onCategoryChanged;
  final Function(bool) onApprovedOnlyChanged;
  final Function(bool) onActiveOnlyChanged;
  final VoidCallback? onClearFilters;

  const PrayerSearchFilterBar({
    Key? key,
    required this.searchController,
    required this.searchQuery,
    this.selectedType,
    this.selectedCategory,
    required this.availableCategories,
    required this.showApprovedOnly,
    required this.showActiveOnly,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onApprovedOnlyChanged,
    required this.onActiveOnlyChanged,
    this.onClearFilters,
  }) : super(key: key);

  @override
  State<PrayerSearchFilterBar> createState() => _PrayerSearchFilterBarState();
}

class _PrayerSearchFilterBarState extends State<PrayerSearchFilterBar>
    with TickerProviderStateMixin {
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  bool _isFilterOpen = false;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _isFilterOpen = !_isFilterOpen;
    });
    if (_isFilterOpen) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  Color _getTypeColor(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return Colors.orange;
      case PrayerType.testimony:
        return Colors.green;
      case PrayerType.intercession:
        return Colors.blue;
      case PrayerType.thanksgiving:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return Icons.pan_tool;
      case PrayerType.testimony:
        return Icons.star;
      case PrayerType.intercession:
        return Icons.favorite;
      case PrayerType.thanksgiving:
        return Icons.celebration;
    }
  }

  bool get _hasActiveFilters {
    return widget.selectedType != null ||
        widget.selectedCategory != null ||
        !widget.showApprovedOnly ||
        !widget.showActiveOnly ||
        widget.searchQuery.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Barre de recherche principale
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher des prières...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: widget.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton filtres
                Container(
                  decoration: BoxDecoration(
                    color: _hasActiveFilters 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: _hasActiveFilters 
                        ? Border.all(color: AppTheme.primaryColor, width: 1)
                        : null,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: _hasActiveFilters ? AppTheme.primaryColor : Colors.grey,
                    ),
                    onPressed: _toggleFilters,
                    tooltip: 'Filtres',
                  ),
                ),
                if (_hasActiveFilters && widget.onClearFilters != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.red),
                      onPressed: widget.onClearFilters,
                      tooltip: 'Effacer les filtres',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Panneau de filtres avancés
          SizeTransition(
            sizeFactor: _filterAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  
                  // Filtres par type
                  const Text(
                    'Type de prière',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Option "Tous"
                      ChoiceChip(
                        label: const Text('Tous'),
                        selected: widget.selectedType == null,
                        onSelected: (selected) {
                          if (selected) {
                            widget.onTypeChanged(null);
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        backgroundColor: Colors.grey.withOpacity(0.1),
                      ),
                      // Options par type
                      ...PrayerType.values.map((type) => ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(type),
                              size: 16,
                              color: widget.selectedType == type 
                                  ? _getTypeColor(type)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(type.label),
                          ],
                        ),
                        selected: widget.selectedType == type,
                        onSelected: (selected) {
                          widget.onTypeChanged(selected ? type : null);
                        },
                        selectedColor: _getTypeColor(type).withOpacity(0.2),
                        backgroundColor: Colors.grey.withOpacity(0.1),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filtres par catégorie
                  if (widget.availableCategories.isNotEmpty) ...[
                    const Text(
                      'Catégorie',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: widget.selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'Sélectionner une catégorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Toutes les catégories'),
                        ),
                        ...widget.availableCategories.map((category) =>
                          DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                      ],
                      onChanged: widget.onCategoryChanged,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Options d'affichage
                  const Text(
                    'Options d\'affichage',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Approuvées uniquement'),
                    subtitle: const Text('Afficher seulement les prières approuvées'),
                    value: widget.showApprovedOnly,
                    onChanged: (value) => widget.onApprovedOnlyChanged(value ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Actives uniquement'),
                    subtitle: const Text('Masquer les prières archivées'),
                    value: widget.showActiveOnly,
                    onChanged: (value) => widget.onActiveOnlyChanged(value ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher les filtres actifs en mode compact
class ActiveFiltersBar extends StatelessWidget {
  final PrayerType? selectedType;
  final String? selectedCategory;
  final Function(PrayerType?) onTypeChanged;
  final Function(String?) onCategoryChanged;
  final VoidCallback? onClearAll;

  const ActiveFiltersBar({
    Key? key,
    this.selectedType,
    this.selectedCategory,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    this.onClearAll,
  }) : super(key: key);

  Color _getTypeColor(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return Colors.orange;
      case PrayerType.testimony:
        return Colors.green;
      case PrayerType.intercession:
        return Colors.blue;
      case PrayerType.thanksgiving:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedType != null || selectedCategory != null;
    
    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (selectedType != null)
                  Chip(
                    label: Text(selectedType!.label),
                    backgroundColor: _getTypeColor(selectedType!).withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onTypeChanged(null),
                  ),
                if (selectedCategory != null)
                  Chip(
                    label: Text(selectedCategory!),
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onCategoryChanged(null),
                  ),
              ],
            ),
          ),
          if (onClearAll != null)
            TextButton.icon(
              onPressed: onClearAll,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Tout effacer'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}