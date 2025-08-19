import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/groups_firebase_service.dart';
import '../pages/group_meeting_page.dart';
// Removed unused import '../../compatibility/app_theme_bridge.dart';

class GroupMeetingsList extends StatefulWidget {
  final GroupModel group;

  const GroupMeetingsList({super.key, required this.group});

  @override
  State<GroupMeetingsList> createState() => _GroupMeetingsListState();
}

class _GroupMeetingsListState extends State<GroupMeetingsList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createMeeting() async {
    final result = await showDialog<GroupMeetingModel>(
      context: context,
      builder: (context) => _CreateMeetingDialog(group: widget.group),
    );

    if (result != null) {
      try {
        await GroupsFirebaseService.createMeeting(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réunion créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color get _groupColor => Color(int.parse(widget.group.color.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header with Add Button
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Réunions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _createMeeting,
                  icon: const Icon(Icons.event_note),
                  label: const Text('Nouvelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _groupColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Meetings List
          Expanded(
            child: StreamBuilder<List<GroupMeetingModel>>(
              stream: GroupsFirebaseService.getGroupMeetingsStream(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur lors du chargement',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final meetings = snapshot.data!;

                if (meetings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _groupColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.event_outlined,
                            size: 40,
                            color: _groupColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune réunion',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par planifier votre première réunion',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(179), // 0.7 * 255 ≈ 179
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _createMeeting,
                          icon: const Icon(Icons.event_note),
                          label: const Text('Créer une réunion'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _groupColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group meetings by month
                final groupedMeetings = _groupMeetingsByMonth(meetings);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: groupedMeetings.length,
                  itemBuilder: (context, index) {
                    final entry = groupedMeetings.entries.elementAt(index);
                    final monthLabel = entry.key;
                    final monthMeetings = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            monthLabel,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _groupColor,
                            ),
                          ),
                        ),
                        
                        // Meetings for this month
                        ...monthMeetings.map((meeting) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMeetingCard(meeting),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<GroupMeetingModel>> _groupMeetingsByMonth(List<GroupMeetingModel> meetings) {
    final grouped = <String, List<GroupMeetingModel>>{};
    
    for (final meeting in meetings) {
      final monthKey = _getMonthLabel(meeting.date);
      grouped.putIfAbsent(monthKey, () => []).add(meeting);
    }
    
    return grouped;
  }

  String _getMonthLabel(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    
    final now = DateTime.now();
    final year = date.year == now.year ? '' : ' ${date.year}';
    
    return '${months[date.month - 1]}$year';
  }

  Widget _buildMeetingCard(GroupMeetingModel meeting) {
    final isUpcoming = meeting.date.isAfter(DateTime.now());
    final isPast = meeting.date.isBefore(DateTime.now());
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: meeting.isCompleted 
            ? Border.all(
                color: Colors.green.withAlpha(77), // 0.3 * 255 ≈ 77
                width: 2,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: meeting.isCompleted 
                        ? Colors.green
                        : isUpcoming 
                            ? _groupColor
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Meeting Title
                Expanded(
                  child: Text(
                    meeting.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Actions Menu
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await _editMeeting(meeting);
                        break;
                      case 'attendance':
                        await _takeAttendance(meeting);
                        break;
                      case 'report':
                        await _addReport(meeting);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    if (!meeting.isCompleted)
                      const PopupMenuItem(
                        value: 'attendance',
                        child: Row(
                          children: [
                            Icon(Icons.how_to_reg, size: 20),
                            SizedBox(width: 12),
                            Text('Prendre les présences'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.note_add, size: 20),
                          SizedBox(width: 12),
                          Text('Ajouter un rapport'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date and Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(meeting.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(204), // 0.8 * 255 ≈ 204
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meeting.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                    ),
                  ),
                ),
              ],
            ),
            
            // Description
            if (meeting.description != null && meeting.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                meeting.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ],
            
            // Attendance Info
            if (meeting.isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.how_to_reg,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Présents: ${meeting.presentMemberIds.length} / ${meeting.totalMembers}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Taux: ${(meeting.attendanceRate * 100).round()}%',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isPast) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'En attente de prise de présence',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Report Notes
            if (meeting.reportNotes != null && meeting.reportNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _groupColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: _groupColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rapport de réunion',
                          style: TextStyle(
                            color: _groupColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meeting.reportNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editMeeting(GroupMeetingModel meeting) async {
    final result = await showDialog<GroupMeetingModel>(
      context: context,
      builder: (context) => _EditMeetingDialog(group: widget.group, meeting: meeting),
    );
    
    if (result != null) {
      try {
        await GroupsFirebaseService.updateMeeting(result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réunion modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _takeAttendance(GroupMeetingModel meeting) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupMeetingPage(
          group: widget.group, 
          meeting: meeting,
        ),
      ),
    );
    
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Présences enregistrées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _addReport(GroupMeetingModel meeting) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddReportDialog(meeting: meeting),
    );
    
    if (result != null && result.trim().isNotEmpty) {
      try {
        final updatedMeeting = meeting.copyWith(
          reportNotes: result.trim(),
          updatedAt: DateTime.now(),
        );
        
        await GroupsFirebaseService.updateMeeting(updatedMeeting);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rapport ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime date) {
    const weekdays = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final weekday = weekdays[date.weekday];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$weekday $day/$month/$year à ${hour}h$minute';
  }
}

class _CreateMeetingDialog extends StatefulWidget {
  final GroupModel group;

  const _CreateMeetingDialog({required this.group});

  @override
  State<_CreateMeetingDialog> createState() => _CreateMeetingDialogState();
}

class _CreateMeetingDialogState extends State<_CreateMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.group.location;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveMeeting() {
    if (_formKey.currentState!.validate()) {
      final meetingDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final meeting = GroupMeetingModel(
        id: '',
        groupId: widget.group.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        date: meetingDate,
        location: _locationController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, meeting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle réunion'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnelle)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le lieu est requis';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveMeeting,
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _EditMeetingDialog extends StatefulWidget {
  final GroupModel group;
  final GroupMeetingModel meeting;

  const _EditMeetingDialog({
    required this.group,
    required this.meeting,
  });

  @override
  State<_EditMeetingDialog> createState() => _EditMeetingDialogState();
}

class _EditMeetingDialogState extends State<_EditMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.meeting.title;
    _descriptionController.text = widget.meeting.description ?? '';
    _locationController.text = widget.meeting.location;
    _selectedDate = widget.meeting.date;
    _selectedTime = TimeOfDay.fromDateTime(widget.meeting.date);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveMeeting() {
    if (_formKey.currentState!.validate()) {
      final meetingDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedMeeting = widget.meeting.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        date: meetingDate,
        location: _locationController.text.trim(),
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, updatedMeeting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier la réunion'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnelle)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le lieu est requis';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveMeeting,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _AddReportDialog extends StatefulWidget {
  final GroupMeetingModel meeting;

  const _AddReportDialog({required this.meeting});

  @override
  State<_AddReportDialog> createState() => _AddReportDialogState();
}

class _AddReportDialogState extends State<_AddReportDialog> {
  final _reportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reportController.text = widget.meeting.reportNotes ?? '';
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rapport de réunion'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Réunion: ${widget.meeting.title}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reportController,
              decoration: const InputDecoration(
                labelText: 'Rapport',
                hintText: 'Ajoutez un rapport pour cette réunion...',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
              minLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _reportController.text);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}