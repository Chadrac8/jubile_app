import 'package:flutter/material.dart';
import '../models/service_model.dart';
// Removed unused import '../../compatibility/app_theme_bridge.dart';

class ServiceCalendarView extends StatefulWidget {
  final List<ServiceModel> services;
  final Function(ServiceModel) onServiceTap;
  final Function(ServiceModel) onServiceLongPress;
  final bool isSelectionMode;
  final List<ServiceModel> selectedServices;
  final Function(ServiceModel, bool) onSelectionChanged;

  const ServiceCalendarView({
    super.key,
    required this.services,
    required this.onServiceTap,
    required this.onServiceLongPress,
    required this.isSelectionMode,
    required this.selectedServices,
    required this.onSelectionChanged,
  });

  @override
  State<ServiceCalendarView> createState() => _ServiceCalendarViewState();
}

class _ServiceCalendarViewState extends State<ServiceCalendarView> {
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

  List<ServiceModel> _getServicesForDate(DateTime date) {
    return widget.services.where((service) {
      return service.dateTime.year == date.year &&
             service.dateTime.month == date.month &&
             service.dateTime.day == date.day;
    }).toList();
  }

  Color _getServiceColor(ServiceModel service) {
    switch (service.status) {
      case 'publie': return Colors.green;
      case 'brouillon': return Colors.orange;
      case 'archive': return Colors.grey;
      case 'annule': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _getMonthYear(_currentMonth),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

        // Weekday Headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77), // 0.3 opacity
          ),
          child: Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(179), // 0.7 opacity
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Calendar Grid
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Calculate days to show (including previous/next month days)
    final totalCells = ((daysInMonth + firstWeekday - 1) / 7).ceil() * 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: firstWeekday - 1));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final isCurrentMonth = date.month == _currentMonth.month;
        final isToday = _isToday(date);
        final services = _getServicesForDate(date);

        return _buildCalendarCell(date, isCurrentMonth, isToday, services);
      },
    );
  }

  Widget _buildCalendarCell(DateTime date, bool isCurrentMonth, bool isToday, List<ServiceModel> services) {
    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primary.withAlpha(25) // 0.1 opacity
            : Colors.transparent,
        border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(51), // 0.2 opacity
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: services.isNotEmpty ? () => _showDayServices(date, services) : null,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              // Date number
              Text(
                date.day.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentMonth
                      ? (isToday 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface)
                      : Theme.of(context).colorScheme.onSurface.withAlpha(102), // 0.4 opacity
                ),
              ),
              
              // Service indicators
              Expanded(
                child: services.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            ...services.take(3).map((service) {
                              return Container(
                                width: double.infinity,
                                height: 3,
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getServiceColor(service),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              );
                            }).toList(),
                            if (services.length > 3)
                              Text(
                                '+${services.length - 3}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 opacity
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayServices(DateTime date, List<ServiceModel> services) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(51), // 0.2 opacity
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Services du ${_formatDate(date)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Services list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: _getServiceColor(service),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(
                        service.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.typeLabel),
                          Text(_formatTime(service.dateTime)),
                          Text(service.location),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getServiceColor(service),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service.statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onServiceTap(service);
                      },
                      onLongPress: () {
                        Navigator.pop(context);
                        widget.onServiceLongPress(service);
                      },
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
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${hour}h$minute';
  }
}