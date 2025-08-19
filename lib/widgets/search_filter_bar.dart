import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/firebase_service.dart';
import '../services/roles_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class SearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Function(List<String>, bool) onFiltersChanged;
  final List<String> selectedRoleFilters;
  final bool showActiveOnly;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.selectedRoleFilters,
    required this.showActiveOnly,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isFilterExpanded = false;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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

  void _onRoleFilterChanged(String roleId, bool isSelected) {
    final newFilters = List<String>.from(widget.selectedRoleFilters);
    if (isSelected) {
      newFilters.add(roleId);
    } else {
      newFilters.remove(roleId);
    }
    widget.onFiltersChanged(newFilters, widget.showActiveOnly);
  }

  void _onActiveFilterChanged(bool showActiveOnly) {
    widget.onFiltersChanged(widget.selectedRoleFilters, showActiveOnly);
  }

  void _clearAllFilters() {
    widget.onFiltersChanged([], true);
    widget.searchController.clear();
    widget.onSearchChanged('');
  }

  int get _totalActiveFilters {
    int count = 0;
    if (widget.selectedRoleFilters.isNotEmpty) count++;
    if (!widget.showActiveOnly) count++;
    if (widget.searchController.text.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _isSearchFocused
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSearchFocused
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: _isSearchFocused ? 2 : 1,
                    ),
                    boxShadow: _isSearchFocused
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    focusNode: _searchFocusNode,
                    onChanged: widget.onSearchChanged,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, email ou téléphone...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isSearchFocused
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      suffixIcon: widget.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Filter Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isFilterExpanded || _totalActiveFilters > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFilterExpanded || _totalActiveFilters > 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  boxShadow: _isFilterExpanded
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _toggleFilters,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            color: _isFilterExpanded || _totalActiveFilters > 0
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          if (_totalActiveFilters > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onPrimary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _totalActiveFilters.toString(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Filter Panel
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _slideAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Header
                          Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filtres',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
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
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Status Filter
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Theme.of(context).colorScheme.outline,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Statut:',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 16),
                              FilterChip(
                                label: const Text('Actifs uniquement'),
                                selected: widget.showActiveOnly,
                                onSelected: _onActiveFilterChanged,
                                selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                checkmarkColor: Theme.of(context).colorScheme.secondary,
                                labelStyle: TextStyle(
                                  color: widget.showActiveOnly
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Role Filters
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.outline,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rôles:',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StreamBuilder<List<RoleModel>>(
                                  stream: RolesFirebaseService.getRolesStream(activeOnly: true),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox(
                                        height: 20,
                                        child: Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    }
                                    
                                    final roles = snapshot.data!;
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: roles.where((role) => role != null).map((role) {
                                        final isSelected = widget.selectedRoleFilters.contains(role!.id);
                                        return FilterChip(
                                          label: Text(role.name),
                                          selected: isSelected,
                                          onSelected: (selected) => _onRoleFilterChanged(role.id, selected),
                                          selectedColor: Color(int.parse(role.color.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                                          checkmarkColor: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                                          avatar: isSelected
                                              ? null
                                              : Icon(
                                                  _getIconFromString(role.icon),
                                                  size: 16,
                                                  color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                                                ),
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? Color(int.parse(role.color.replaceFirst('#', '0xFF')))
                                                : Theme.of(context).colorScheme.onSurface,
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
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

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'star':
        return Icons.star;
      case 'church':
        return Icons.church;
      case 'groups':
        return Icons.groups;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      default:
        return Icons.person;
    }
  }
}