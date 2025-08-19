import 'package:flutter/material.dart';
// Removed unused import '../../compatibility/app_theme_bridge.dart';

class ServiceSearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Function(List<String>, List<String>, DateTime?, DateTime?) onFiltersChanged;
  final List<String> selectedTypeFilters;
  final List<String> selectedStatusFilters;
  final DateTime? startDate;
  final DateTime? endDate;

  const ServiceSearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.selectedTypeFilters,
    required this.selectedStatusFilters,
    this.startDate,
    this.endDate,
  });

  @override
  State<ServiceSearchFilterBar> createState() => _ServiceSearchFilterBarState();
}

class _ServiceSearchFilterBarState extends State<ServiceSearchFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isFilterExpanded = false;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  final List<Map<String, String>> _serviceTypes = [
    {'value': 'culte', 'label': 'Culte'},
    {'value': 'repetition', 'label': 'Répétition'},
    {'value': 'evenement_special', 'label': 'Événement spécial'},
    {'value': 'reunion', 'label': 'Réunion'},
  ];

  final List<Map<String, String>> _serviceStatuses = [
    {'value': 'brouillon', 'label': 'Brouillon'},
    {'value': 'publie', 'label': 'Publié'},
    {'value': 'archive', 'label': 'Archivé'},
    {'value': 'annule', 'label': 'Annulé'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });

    widget.searchController.addListener(() {
      widget.onSearchChanged(widget.searchController.text);
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
    final newFilters = List<String>.from(widget.selectedTypeFilters);
    if (isSelected) {
      newFilters.add(type);
    } else {
      newFilters.remove(type);
    }
    widget.onFiltersChanged(newFilters, widget.selectedStatusFilters, widget.startDate, widget.endDate);
  }

  void _onStatusFilterChanged(String status, bool isSelected) {
    final newFilters = List<String>.from(widget.selectedStatusFilters);
    if (isSelected) {
      newFilters.add(status);
    } else {
      newFilters.remove(status);
    }
    widget.onFiltersChanged(widget.selectedTypeFilters, newFilters, widget.startDate, widget.endDate);
  }

  void _onDateRangeChanged(DateTime? startDate, DateTime? endDate) {
    widget.onFiltersChanged(widget.selectedTypeFilters, widget.selectedStatusFilters, startDate, endDate);
  }

  void _clearAllFilters() {
    widget.onFiltersChanged([], ['publie', 'brouillon'], null, null);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _onDateRangeChanged(picked.start, picked.end);
    }
  }

  int get _totalActiveFilters {
    return widget.selectedTypeFilters.length + 
           (widget.selectedStatusFilters.length - 2) + // Default is 2 statuses
           (widget.startDate != null && widget.endDate != null ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isSearchFocused
                          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSearchFocused
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: widget.searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Rechercher des services...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: _isSearchFocused
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isFilterExpanded || _totalActiveFilters > 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: _toggleFilters,
                        icon: Icon(
                          Icons.tune,
                          color: _isFilterExpanded || _totalActiveFilters > 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (_totalActiveFilters > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _totalActiveFilters.toString(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expandable Filters
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _slideAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Header
                          Row(
                            children: [
                              Text(
                                'Filtres',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (_totalActiveFilters > 0)
                                TextButton(
                                  onPressed: _clearAllFilters,
                                  child: const Text('Effacer tout'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Service Types
                          Text(
                            'Type de service',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _serviceTypes.map((type) {
                              final isSelected = widget.selectedTypeFilters.contains(type['value']);
                              return FilterChip(
                                label: Text(type['label']!),
                                selected: isSelected,
                                onSelected: (selected) => _onTypeFilterChanged(type['value']!, selected),
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                checkmarkColor: Theme.of(context).colorScheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Service Status
                          Text(
                            'Statut',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _serviceStatuses.map((status) {
                              final isSelected = widget.selectedStatusFilters.contains(status['value']);
                              return FilterChip(
                                label: Text(status['label']!),
                                selected: isSelected,
                                onSelected: (selected) => _onStatusFilterChanged(status['value']!, selected),
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                                checkmarkColor: Theme.of(context).colorScheme.secondary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onSecondaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Date Range
                          Text(
                            'Période',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _selectDateRange,
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    widget.startDate != null && widget.endDate != null
                                        ? '${_formatDate(widget.startDate!)} - ${_formatDate(widget.endDate!)}'
                                        : 'Sélectionner une période',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: widget.startDate != null && widget.endDate != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    side: BorderSide(
                                      color: widget.startDate != null && widget.endDate != null
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.startDate != null && widget.endDate != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _onDateRangeChanged(null, null),
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Effacer la période',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}