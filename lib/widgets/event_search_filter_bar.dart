import 'package:flutter/material.dart';
import '../theme.dart';

class EventSearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Function(List<String>, List<String>, DateTime?, DateTime?) onFiltersChanged;
  final List<String> selectedTypeFilters;
  final List<String> selectedStatusFilters;
  final DateTime? startDate;
  final DateTime? endDate;

  const EventSearchFilterBar({
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
  State<EventSearchFilterBar> createState() => _EventSearchFilterBarState();
}

class _EventSearchFilterBarState extends State<EventSearchFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isFilterExpanded = false;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  final List<Map<String, String>> _eventTypes = [
    {'value': 'celebration', 'label': 'Célébration'},
    {'value': 'bapteme', 'label': 'Baptême'},
    {'value': 'formation', 'label': 'Formation'},
    {'value': 'sortie', 'label': 'Sortie'},
    {'value': 'conference', 'label': 'Conférence'},
    {'value': 'reunion', 'label': 'Réunion'},
    {'value': 'autre', 'label': 'Autre'},
  ];

  final List<Map<String, String>> _eventStatuses = [
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
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
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
    setState(() => _isFilterExpanded = !_isFilterExpanded);
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
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null,
      locale: const Locale('fr'),
    );
    
    if (dateRange != null) {
      _onDateRangeChanged(dateRange.start, dateRange.end);
    }
  }

  int get _totalActiveFilters {
    return widget.selectedTypeFilters.length + 
           (widget.selectedStatusFilters.length != 2 ? 1 : 0) + // Default is 2 statuses
           (widget.startDate != null ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche principale
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                // Champ de recherche
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isSearchFocused 
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isSearchFocused 
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: widget.searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Rechercher des événements...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: _isSearchFocused 
                              ? AppTheme.primaryColor 
                              : AppTheme.textTertiaryColor,
                        ),
                        suffixIcon: widget.searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  widget.searchController.clear();
                                  widget.onSearchChanged('');
                                },
                                icon: const Icon(Icons.clear),
                                color: AppTheme.textTertiaryColor,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Bouton filtres
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isFilterExpanded || _totalActiveFilters > 0
                        ? AppTheme.primaryColor
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isFilterExpanded || _totalActiveFilters > 0
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: _toggleFilters,
                        icon: Icon(
                          Icons.tune,
                          color: _isFilterExpanded || _totalActiveFilters > 0
                              ? Colors.white
                              : AppTheme.textTertiaryColor,
                        ),
                      ),
                      if (_totalActiveFilters > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_totalActiveFilters',
                              style: const TextStyle(
                                color: Colors.white,
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
          
          // Section filtres extensible
          if (_isFilterExpanded)
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, _slideAnimation.value),
                end: Offset.zero,
              ).animate(_animationController),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.5),
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.textTertiaryColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête des filtres
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtres',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_totalActiveFilters > 0)
                            TextButton(
                              onPressed: _clearAllFilters,
                              child: const Text('Tout effacer'),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Types d'événements
                      Text(
                        'Types',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _eventTypes.map((type) {
                          final isSelected = widget.selectedTypeFilters.contains(type['value']);
                          return FilterChip(
                            label: Text(type['label']!),
                            selected: isSelected,
                            onSelected: (selected) => _onTypeFilterChanged(type['value']!, selected),
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryColor,
                            side: BorderSide(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.textTertiaryColor.withOpacity(0.3),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Statuts
                      Text(
                        'Statuts',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _eventStatuses.map((status) {
                          final isSelected = widget.selectedStatusFilters.contains(status['value']);
                          return FilterChip(
                            label: Text(status['label']!),
                            selected: isSelected,
                            onSelected: (selected) => _onStatusFilterChanged(status['value']!, selected),
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.secondaryColor.withOpacity(0.2),
                            checkmarkColor: AppTheme.secondaryColor,
                            side: BorderSide(
                              color: isSelected 
                                  ? AppTheme.secondaryColor 
                                  : AppTheme.textTertiaryColor.withOpacity(0.3),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Plage de dates
                      Row(
                        children: [
                          Text(
                            'Période',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(
                              widget.startDate != null && widget.endDate != null
                                  ? '${_formatDate(widget.startDate!)} - ${_formatDate(widget.endDate!)}'
                                  : 'Sélectionner',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                          if (widget.startDate != null)
                            IconButton(
                              onPressed: () => _onDateRangeChanged(null, null),
                              icon: const Icon(Icons.clear, size: 18),
                              color: AppTheme.textTertiaryColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}