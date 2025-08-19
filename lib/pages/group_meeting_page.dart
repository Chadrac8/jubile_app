import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/person_model.dart';
import '../services/groups_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class GroupMeetingPage extends StatefulWidget {
  final GroupModel group;
  final GroupMeetingModel? meeting;

  const GroupMeetingPage({
    super.key,
    required this.group,
    this.meeting,
  });

  @override
  State<GroupMeetingPage> createState() => _GroupMeetingPageState();
}

class _GroupMeetingPageState extends State<GroupMeetingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _reportController = TextEditingController();

  List<PersonModel> _groupMembers = [];
  Set<String> _presentMemberIds = <String>{};
  bool _isLoading = false;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _initializePage();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  void _initializePage() async {
    _titleController.text = widget.meeting?.title ?? 'Réunion du ${_formatDate(DateTime.now())}';
    _notesController.text = widget.meeting?.notes ?? '';
    _reportController.text = widget.meeting?.reportNotes ?? '';
    
    if (widget.meeting != null) {
      _presentMemberIds.addAll(widget.meeting!.presentMemberIds);
    }
    
    await _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    try {
      final members = await GroupsFirebaseService.getGroupMembersWithPersonData(widget.group.id);
      setState(() {
        _groupMembers = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des membres: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleAttendance(String personId) {
    setState(() {
      if (_presentMemberIds.contains(personId)) {
        _presentMemberIds.remove(personId);
      } else {
        _presentMemberIds.add(personId);
      }
    });
  }

  void _toggleAllAttendance(bool selectAll) {
    setState(() {
      if (selectAll) {
        _presentMemberIds.addAll(_groupMembers.map((m) => m.id));
      } else {
        _presentMemberIds.clear();
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_groupMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun membre trouvé dans ce groupe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final presentIds = _presentMemberIds.toList();
      final absentIds = _groupMembers
          .map((m) => m.id)
          .where((id) => !_presentMemberIds.contains(id))
          .toList();

      GroupMeetingModel meeting;
      
      if (widget.meeting == null) {
        // Create new meeting
        meeting = GroupMeetingModel(
          id: '',
          groupId: widget.group.id,
          title: _titleController.text.trim(),
          date: now,
          location: widget.group.location,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          reportNotes: _reportController.text.trim().isEmpty ? null : _reportController.text.trim(),
          presentMemberIds: presentIds,
          absentMemberIds: absentIds,
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
        );
        
        final meetingId = await GroupsFirebaseService.createMeeting(meeting);
        await GroupsFirebaseService.recordAttendance(meetingId, presentIds, absentIds);
      } else {
        // Update existing meeting
        meeting = widget.meeting!.copyWith(
          title: _titleController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          reportNotes: _reportController.text.trim().isEmpty ? null : _reportController.text.trim(),
          presentMemberIds: presentIds,
          absentMemberIds: absentIds,
          isCompleted: true,
          updatedAt: now,
        );
        
        await GroupsFirebaseService.updateMeeting(meeting);
        await GroupsFirebaseService.recordAttendance(widget.meeting!.id, presentIds, absentIds);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Présences enregistrées avec succès'),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color get _groupColor => Color(int.parse(widget.group.color.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.meeting == null ? 'Nouvelle présence' : 'Modifier présence'),
        backgroundColor: _groupColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveAttendance,
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header Card
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _groupColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups,
                      color: _groupColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Meeting Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de la réunion',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _groupColor, width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes de réunion (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _groupColor, width: 2),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),

        // Attendance Section
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Attendance Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _groupColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.how_to_reg,
                        color: _groupColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prise de présence',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _groupColor,
                              ),
                            ),
                            Text(
                              '${_presentMemberIds.length} / ${_groupMembers.length} présents',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _groupColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'select_all':
                              _toggleAllAttendance(true);
                              break;
                            case 'select_none':
                              _toggleAllAttendance(false);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'select_all',
                            child: Row(
                              children: [
                                Icon(Icons.select_all, size: 20),
                                SizedBox(width: 12),
                                Text('Tout sélectionner'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'select_none',
                            child: Row(
                              children: [
                                Icon(Icons.clear_all, size: 20),
                                SizedBox(width: 12),
                                Text('Tout désélectionner'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _groupColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: _groupColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Members List
                Expanded(
                  child: _isLoadingMembers
                      ? const Center(child: CircularProgressIndicator())
                      : _groupMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun membre dans ce groupe',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _groupMembers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final member = _groupMembers[index];
                                final isPresent = _presentMemberIds.contains(member.id);
                                return _buildMemberAttendanceCard(member, isPresent);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),

        // Report Section
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.note_alt,
                    color: _groupColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rapport de réunion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _groupColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reportController,
                decoration: InputDecoration(
                  hintText: 'Ajoutez des notes sur la réunion, les points clés, les décisions prises...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _groupColor, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMemberAttendanceCard(PersonModel member, bool isPresent) {
    return GestureDetector(
      onTap: () => _toggleAttendance(member.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPresent 
              ? _groupColor.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPresent 
                ? _groupColor
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isPresent ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image/Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPresent 
                      ? _groupColor.withOpacity(0.2)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: member.profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          Uri.parse(member.profileImageUrl!).data!.contentAsBytes(),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          member.displayInitials,
                          style: TextStyle(
                            color: isPresent 
                                ? _groupColor
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPresent 
                            ? _groupColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (member.phone != null)
                      Text(
                        member.phone!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Attendance Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isPresent ? _groupColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPresent 
                        ? _groupColor
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isPresent
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    return '${weekdays[date.weekday]} ${date.day} ${months[date.month]} ${date.year}';
  }
}