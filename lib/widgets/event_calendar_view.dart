import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme.dart';

class EventCalendarView extends StatefulWidget {
  final List<EventModel> events;
  final Function(EventModel) onEventTap;
  final Function(EventModel) onEventLongPress;
  final bool isSelectionMode;
  final List<EventModel> selectedEvents;
  final Function(EventModel, bool) onSelectionChanged;

  const EventCalendarView({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.onEventLongPress,
    required this.isSelectionMode,
    required this.selectedEvents,
    required this.onSelectionChanged,
  });

  @override
  State<EventCalendarView> createState() => _EventCalendarViewState();
}

class _EventCalendarViewState extends State<EventCalendarView> {
  late DateTime _currentMonth;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  List<EventModel> _getEventsForDate(DateTime date) {
    return widget.events.where((event) {
      final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return eventDate == targetDate;
    }).toList();
  }

  Color _getEventColor(EventModel event) {
    switch (event.status) {
      case 'publie': return AppTheme.successColor;
      case 'brouillon': return AppTheme.warningColor;
      case 'archive': return AppTheme.textTertiaryColor;
      case 'annule': return AppTheme.errorColor;
      default: return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête du calendrier
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _getMonthYear(_currentMonth),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _goToToday,
                child: const Text('Aujourd\'hui'),
              ),
            ],
          ),
        ),
        
        // Jours de la semaine
        Container(
          color: AppTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Grille du calendrier
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculer les jours à afficher (incluant les jours des mois précédent/suivant)
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfWeek - 1));
    final totalDays = ((daysInMonth + firstDayOfWeek - 1) / 7).ceil() * 7;
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: totalDays,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final isCurrentMonth = date.month == _currentMonth.month;
        final isToday = _isToday(date);
        final events = _getEventsForDate(date);
        
        return _buildCalendarCell(date, isCurrentMonth, isToday, events);
      },
    );
  }

  Widget _buildCalendarCell(DateTime date, bool isCurrentMonth, bool isToday, List<EventModel> events) {
    return GestureDetector(
      onTap: events.isNotEmpty ? () => _showDayEvents(date, events) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isToday 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isToday 
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : Border.all(color: AppTheme.backgroundColor),
        ),
        child: Column(
          children: [
            // Numéro du jour
            Container(
              height: 32,
              child: Center(
                child: Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentMonth 
                        ? (isToday ? AppTheme.primaryColor : AppTheme.textPrimaryColor)
                        : AppTheme.textTertiaryColor,
                  ),
                ),
              ),
            ),
            
            // Indicateurs d'événements
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(2),
                child: events.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          // Afficher jusqu'à 3 événements
                          ...events.take(3).map((event) {
                            return Container(
                              width: double.infinity,
                              height: 12,
                              margin: const EdgeInsets.only(bottom: 1),
                              decoration: BoxDecoration(
                                color: _getEventColor(event),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }),
                          
                          // Indicateur pour les événements supplémentaires
                          if (events.length > 3)
                            Container(
                              width: double.infinity,
                              height: 10,
                              child: Center(
                                child: Text(
                                  '+${events.length - 3}',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayEvents(DateTime date, List<EventModel> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.textTertiaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(date),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${events.length} événement${events.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Liste des événements
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: events.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isSelected = widget.selectedEvents.any((e) => e.id == event.id);
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEventTap(event);
                    },
                    onLongPress: () {
                      Navigator.pop(context);
                      widget.onEventLongPress(event);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryColor, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Indicateur de couleur
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getEventColor(event),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Informations de l'événement
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTime(event.startDate),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.location,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Badge de statut
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getEventColor(event).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.statusLabel,
                              style: TextStyle(
                                color: _getEventColor(event),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
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
    const weekdays = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    return '${weekday.capitalize()} $day $month $year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${hour}h$minute';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}