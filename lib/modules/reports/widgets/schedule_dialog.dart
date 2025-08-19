import 'package:flutter/material.dart';
import '../services/scheduler_service.dart';

/// Dialog pour planifier un rapport
class ScheduleDialog extends StatefulWidget {
  final String reportId;
  final String reportName;
  final ScheduleConfig? initialConfig;
  
  const ScheduleDialog({
    Key? key,
    required this.reportId,
    required this.reportName,
    this.initialConfig,
  }) : super(key: key);

  @override
  State<ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  final SchedulerService _schedulerService = SchedulerService();
  
  ScheduleFrequency _frequency = ScheduleFrequency.daily;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _weekday = 1; // Lundi
  int _dayOfMonth = 1;
  DateTime? _customDateTime;
  bool _enabled = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _loadInitialConfig(widget.initialConfig!);
    }
  }
  
  void _loadInitialConfig(ScheduleConfig config) {
    _frequency = config.frequency;
    _time = TimeOfDay(
      hour: config.hour ?? 9,
      minute: config.minute ?? 0,
    );
    _weekday = config.weekday ?? 1;
    _dayOfMonth = config.dayOfMonth ?? 1;
    _customDateTime = config.customDateTime;
    _enabled = config.enabled;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.blue),
          const SizedBox(width: 8),
          Text(widget.initialConfig == null ? 'Planifier le rapport' : 'Modifier la planification'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du rapport
              _buildReportInfo(),
              const SizedBox(height: 24),
              
              // Statut de la planification
              _buildEnabledSwitch(),
              const SizedBox(height: 20),
              
              // Fréquence
              _buildFrequencySelector(),
              const SizedBox(height: 20),
              
              // Configuration selon la fréquence
              _buildFrequencyConfig(),
              const SizedBox(height: 20),
              
              // Aperçu de la prochaine exécution
              _buildNextExecutionPreview(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSchedule,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.initialConfig == null ? 'Planifier' : 'Modifier'),
        ),
      ],
    );
  }
  
  Widget _buildReportInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.assessment, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reportName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Génération automatique des données',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnabledSwitch() {
    return SwitchListTile(
      title: const Text('Planification active'),
      subtitle: Text(_enabled ? 'Le rapport sera généré automatiquement' : 'Planification désactivée'),
      value: _enabled,
      onChanged: (value) {
        setState(() {
          _enabled = value;
        });
      },
    );
  }
  
  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fréquence',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...ScheduleFrequency.values.map((frequency) {
          return RadioListTile<ScheduleFrequency>(
            title: Text(_getFrequencyLabel(frequency)),
            subtitle: Text(_getFrequencyDescription(frequency)),
            value: frequency,
            groupValue: _frequency,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _frequency = value;
                });
              }
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildFrequencyConfig() {
    if (!_enabled) return const SizedBox.shrink();
    
    switch (_frequency) {
      case ScheduleFrequency.hourly:
        return _buildHourlyConfig();
      case ScheduleFrequency.daily:
        return _buildDailyConfig();
      case ScheduleFrequency.weekly:
        return _buildWeeklyConfig();
      case ScheduleFrequency.monthly:
        return _buildMonthlyConfig();
      case ScheduleFrequency.custom:
        return _buildCustomConfig();
    }
  }
  
  Widget _buildHourlyConfig() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Le rapport sera généré toutes les heures.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
  
  Widget _buildDailyConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration quotidienne',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Heure de génération'),
              subtitle: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
              onTap: _selectTime,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeeklyConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration hebdomadaire',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Jour de la semaine'),
              subtitle: Text(_getWeekdayName(_weekday)),
              onTap: _selectWeekday,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Heure de génération'),
              subtitle: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
              onTap: _selectTime,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration mensuelle',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Jour du mois'),
              subtitle: Text('Le $_dayOfMonth de chaque mois'),
              onTap: _selectDayOfMonth,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Heure de génération'),
              subtitle: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
              onTap: _selectTime,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration personnalisée',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Date et heure'),
              subtitle: Text(_customDateTime != null 
                  ? '${_customDateTime!.day}/${_customDateTime!.month}/${_customDateTime!.year} à ${_customDateTime!.hour.toString().padLeft(2, '0')}:${_customDateTime!.minute.toString().padLeft(2, '0')}'
                  : 'Aucune date sélectionnée'),
              onTap: _selectCustomDateTime,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNextExecutionPreview() {
    if (!_enabled) return const SizedBox.shrink();
    
    final nextExecution = _calculateNextExecution();
    
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Prochaine exécution',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(nextExecution),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (time != null) {
      setState(() {
        _time = time;
      });
    }
  }
  
  Future<void> _selectWeekday() async {
    final weekdays = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Jour de la semaine'),
        children: weekdays.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final name = entry.value;
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(index),
            child: Text(name),
          );
        }).toList(),
      ),
    );
    
    if (selected != null) {
      setState(() {
        _weekday = selected;
      });
    }
  }
  
  Future<void> _selectDayOfMonth() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Jour du mois'),
        children: List.generate(28, (index) {
          final day = index + 1;
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(day),
            child: Text('Le $day'),
          );
        }),
      ),
    );
    
    if (selected != null) {
      setState(() {
        _dayOfMonth = selected;
      });
    }
  }
  
  Future<void> _selectCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _customDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_customDateTime ?? DateTime.now()),
      );
      
      if (time != null) {
        setState(() {
          _customDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  DateTime _calculateNextExecution() {
    final now = DateTime.now();
    
    switch (_frequency) {
      case ScheduleFrequency.hourly:
        return now.add(const Duration(hours: 1));
      case ScheduleFrequency.daily:
        return DateTime(now.year, now.month, now.day + 1, _time.hour, _time.minute);
      case ScheduleFrequency.weekly:
        final daysUntilWeekday = _weekday - now.weekday;
        final daysToAdd = daysUntilWeekday <= 0 ? daysUntilWeekday + 7 : daysUntilWeekday;
        return DateTime(now.year, now.month, now.day + daysToAdd, _time.hour, _time.minute);
      case ScheduleFrequency.monthly:
        var nextMonth = now.month + 1;
        var nextYear = now.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        return DateTime(nextYear, nextMonth, _dayOfMonth, _time.hour, _time.minute);
      case ScheduleFrequency.custom:
        return _customDateTime ?? now.add(const Duration(days: 1));
    }
  }
  
  Future<void> _saveSchedule() async {
    if (_frequency == ScheduleFrequency.custom && _customDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date pour la planification personnalisée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final config = ScheduleConfig(
        frequency: _frequency,
        hour: _frequency != ScheduleFrequency.hourly ? _time.hour : null,
        minute: _frequency != ScheduleFrequency.hourly ? _time.minute : null,
        weekday: _frequency == ScheduleFrequency.weekly ? _weekday : null,
        dayOfMonth: _frequency == ScheduleFrequency.monthly ? _dayOfMonth : null,
        customDateTime: _frequency == ScheduleFrequency.custom ? _customDateTime : null,
        enabled: _enabled,
      );
      
      if (widget.initialConfig == null) {
        await _schedulerService.scheduleReport(widget.reportId, config);
      } else {
        // TODO: Mettre à jour la planification existante
        // await _schedulerService.updateSchedule(scheduleId, config);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planification sauvegardée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _getFrequencyLabel(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.hourly:
        return 'Toutes les heures';
      case ScheduleFrequency.daily:
        return 'Quotidien';
      case ScheduleFrequency.weekly:
        return 'Hebdomadaire';
      case ScheduleFrequency.monthly:
        return 'Mensuel';
      case ScheduleFrequency.custom:
        return 'Personnalisé';
    }
  }
  
  String _getFrequencyDescription(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.hourly:
        return 'Génération automatique chaque heure';
      case ScheduleFrequency.daily:
        return 'Génération quotidienne à une heure fixe';
      case ScheduleFrequency.weekly:
        return 'Génération hebdomadaire un jour spécifique';
      case ScheduleFrequency.monthly:
        return 'Génération mensuelle un jour spécifique';
      case ScheduleFrequency.custom:
        return 'Génération à une date et heure précises';
    }
  }
  
  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return weekdays[weekday - 1];
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Fonction utilitaire pour afficher le dialog de planification
Future<bool?> showScheduleDialog(
  BuildContext context,
  String reportId,
  String reportName, {
  ScheduleConfig? initialConfig,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ScheduleDialog(
      reportId: reportId,
      reportName: reportName,
      initialConfig: initialConfig,
    ),
  );
}