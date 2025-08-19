import 'package:flutter/material.dart';
import '../../compatibility/app_theme_bridge.dart';

class GroupSearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Function(List<String>, List<String>, bool) onFiltersChanged;
  final List<String> selectedTypeFilters;
  final List<String> selectedDayFilters;
  final bool showActiveOnly;

  const GroupSearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.selectedTypeFilters,
    required this.selectedDayFilters,
    required this.showActiveOnly,
  });

  @override
  State<GroupSearchFilterBar> createState() => _GroupSearchFilterBarState();
}

class _GroupSearchFilterBarState extends State<GroupSearchFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isFilterExpanded = false;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _groupTypes = [
    'Petit groupe',
    'Prière',
    'Jeunesse',
    'Étude biblique',
    'Louange',
    'Leadership',
    'Conseil',
    'Ministère',
    'Formation',
    'Autre',
  ];

  final List<String> _weekDays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });
    
    if (_isFilterExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTypeFilterChanged(String type, bool isSelected) {
    final newTypeFilters = List<String>.from(widget.selectedTypeFilters);
    if (isSelected) {
      newTypeFilters.add(type);
    } else {
      newTypeFilters.remove(type);
    }
    widget.onFiltersChanged(newTypeFilters, widget.selectedDayFilters, widget.showActiveOnly);
  }

  void _onDayFilterChanged(String day, bool isSelected) {
    final newDayFilters = List<String>.from(widget.selectedDayFilters);
    if (isSelected) {
      newDayFilters.add(day);
    } else {
      newDayFilters.remove(day);
    }
    widget.onFiltersChanged(widget.selectedTypeFilters, newDayFilters, widget.showActiveOnly);
  }

  void _onActiveFilterChanged(bool showActiveOnly) {
    widget.onFiltersChanged(widget.selectedTypeFilters, widget.selectedDayFilters, showActiveOnly);
  }

  void _clearAllFilters() {
    widget.onFiltersChanged([], [], true);
  }

  int get _totalActiveFilters {
    return widget.selectedTypeFilters.length + 
           widget.selectedDayFilters.length + 
           (widget.showActiveOnly ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: _isSearchFocused
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  focusNode: _searchFocusNode,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un groupe...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: _isSearchFocused
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: widget.searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              widget.searchController.clear();
                              widget.onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),
              // Filter Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _totalActiveFilters > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: _toggleFilters,
                      icon: Icon(
                        _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                        color: _totalActiveFilters > 0
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Filtres',
                    ),
                    if (_totalActiveFilters > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              _totalActiveFilters.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Filters Panel
        if (_isFilterExpanded)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Header
                    Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtres',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        if (_totalActiveFilters > 0)
                          TextButton(
                            onPressed: _clearAllFilters,
                            child: Text(
                              'Effacer tout',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Active Only Filter
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Groupes actifs uniquement',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: widget.showActiveOnly,
                            onChanged: _onActiveFilterChanged,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Type Filters
                    Text(
                      'Type de groupe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _groupTypes.map((type) {
                        final isSelected = widget.selectedTypeFilters.contains(type);
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) => _onTypeFilterChanged(type, selected),
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Day Filters
                    Text(
                      'Jour de la semaine',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekDays.map((day) {
                        final isSelected = widget.selectedDayFilters.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (selected) => _onDayFilterChanged(day, selected),
                          selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.secondary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}