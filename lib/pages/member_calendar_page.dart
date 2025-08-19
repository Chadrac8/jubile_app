import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/group_model.dart';
import '../models/service_model.dart';
import '../../compatibility/app_theme_bridge.dart';

class MemberCalendarPage extends StatefulWidget {
  const MemberCalendarPage({super.key});

  @override
  State<MemberCalendarPage> createState() => _MemberCalendarPageState();
}

class _MemberCalendarPageState extends State<MemberCalendarPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  DateTime _currentMonth = DateTime.now();
  String _selectedView = 'month';
  Set<String> _selectedTypes = {'events', 'groups', 'services'};
  
  bool _isLoading = false;

  // Données d'exemple
  final List<Map<String, dynamic>> _sampleItems = [
    {
      'type': 'event',
      'title': 'Conférence Famille',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '19:00',
      'location': 'Grande salle',
      'color': Colors.purple,
      'icon': Icons.event,
    },
    {
      'type': 'group',
      'title': 'Groupe de prière',
      'date': DateTime.now().add(const Duration(days: 1)),
      'time': '19:30',
      'location': 'Salle B',
      'color': Theme.of(context).colorScheme.secondaryColor,
      'icon': Icons.groups,
    },
    {
      'type': 'service',
      'title': 'Culte dominical',
      'date': DateTime.now().add(const Duration(days: 5)),
      'time': '10:00',
      'location': 'Sanctuaire',
      'color': Colors.orange,
      'icon': Icons.church,
    },
    {
      'type': 'event',
      'title': 'Baptême',
      'date': DateTime.now().add(const Duration(days: 7)),
      'time': '14:00',
      'location': 'Baptistère',
      'color': Colors.blue,
      'icon': Icons.water_drop,
    },
    {
      'type': 'group',
      'title': 'Étude biblique',
      'date': DateTime.now().add(const Duration(days: 8)),
      'time': '20:00',
      'location': 'Salle A',
      'color': Colors.green,
      'icon': Icons.menu_book,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
    });
  }

  List<Map<String, dynamic>> _getItemsForDate(DateTime date) {
    return _sampleItems.where((item) {
      final itemDate = item['date'] as DateTime;
      return _selectedTypes.contains(item['type']) &&
             itemDate.year == date.year &&
             itemDate.month == date.month &&
             itemDate.day == date.day;
    }).toList();
  }

  List<Map<String, dynamic>> _getWeekItems() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return _sampleItems.where((item) {
      final itemDate = item['date'] as DateTime;
      return _selectedTypes.contains(item['type']) &&
             itemDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             itemDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Calendrier'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.textPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Aujourd\'hui',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_module),
            onSelected: (view) {
              setState(() {
                _selectedView = view;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 18),
                    SizedBox(width: 8),
                    Text('Vue mensuelle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.view_week, size: 18),
                    SizedBox(width: 8),
                    Text('Vue hebdomadaire'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildFilters(),
                  if (_selectedView == 'month') ...[
                    _buildMonthHeader(),
                    Expanded(child: _buildMonthView()),
                  ] else ...[
                    _buildWeekHeader(),
                    Expanded(child: _buildWeekView()),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Afficher :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('events', 'Événements', Icons.event, Colors.purple),
              _buildFilterChip('groups', 'Groupes', Icons.groups, Theme.of(context).colorScheme.secondaryColor),
              _buildFilterChip('services', 'Services', Icons.church, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedTypes.contains(type);
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTypes.add(type);
          } else {
            _selectedTypes.remove(type);
          }
        });
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            _getMonthYear(_currentMonth),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textPrimaryColor,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Semaine du ${startOfWeek.day}/${startOfWeek.month} au ${endOfWeek.day}/${endOfWeek.month}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.textPrimaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMonthView() {
    return _buildCalendarGrid();
  }

  Widget _buildWeekView() {
    final weekItems = _getWeekItems();
    
    if (weekItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Theme.of(context).colorScheme.textSecondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun événement cette semaine',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekItems.length,
      itemBuilder: (context, index) {
        final item = weekItems[index];
        return _buildWeekItemCard(item);
      },
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    final totalCells = ((daysInMonth + firstWeekday - 1) / 7).ceil() * 7;

    return Column(
      children: [
        // En-têtes des jours
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        
        // Grille du calendrier
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekday + 2;
              
              if (dayNumber <= 0 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              
              final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final items = _getItemsForDate(date);
              final isToday = _isToday(date);
              
              return _buildCalendarCell(date, isToday, items);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCell(DateTime date, bool isToday, List<Map<String, dynamic>> items) {
    return GestureDetector(
      onTap: () => _showDayDetails(date, items),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday 
              ? Border.all(color: Theme.of(context).colorScheme.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Theme.of(context).colorScheme.primaryColor : Theme.of(context).colorScheme.textPrimaryColor,
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: items.take(2).map((item) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  height: 12,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )).toList(),
              ),
            ),
            if (items.length > 2)
              Text(
                '+${items.length - 2}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.textSecondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekItemCard(Map<String, dynamic> item) {
    final date = item['date'] as DateTime;
    final color = item['color'] as Color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['icon'] as IconData,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(date)} à ${item['time']}',
                        style: const TextStyle(
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).colorScheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['location'] as String,
                        style: const TextStyle(
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTypeLabel(item['type'] as String),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(DateTime date, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildDayDetailItem(item)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetailItem(Map<String, dynamic> item) {
    final color = item['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${item['time']} - ${item['location']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
           date.month == today.month &&
           date.day == today.day;
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'event':
        return 'Événement';
      case 'group':
        return 'Groupe';
      case 'service':
        return 'Service';
      default:
        return type;
    }
  }
}