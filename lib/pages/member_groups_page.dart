import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/group_model.dart';
import '../models/person_model.dart';
import '../services/groups_firebase_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import 'group_detail_page.dart';


class MemberGroupsPage extends StatefulWidget {
  const MemberGroupsPage({super.key});

  @override
  State<MemberGroupsPage> createState() => _MemberGroupsPageState();
}

class _MemberGroupsPageState extends State<MemberGroupsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<GroupModel> _myGroups = [];
  List<GroupModel> _availableGroups = [];
  Map<String, GroupMeetingModel?> _nextMeetings = {};
  bool _isLoading = true;
  String _selectedTab = 'my_groups';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadGroupsData();
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

  Future<void> _loadGroupsData() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      // Charger tous les groupes et filtrer selon l'appartenance
      final allGroupsStream = GroupsFirebaseService.getGroupsStream(
        activeOnly: true,
        limit: 100,
      );

      await for (final groups in allGroupsStream.take(1)) {
        final myGroups = <GroupModel>[];
        final availableGroups = <GroupModel>[];

        for (final group in groups) {
          final members = await GroupsFirebaseService.getGroupMembersWithPersonData(group.id);
          final isMember = members.any((member) => member.id == user.uid);
          
          if (isMember) {
            myGroups.add(group);
            // Charger la prochaine réunion avec gestion d'erreur
            try {
              final nextMeeting = await GroupsFirebaseService.getNextMeeting(group.id);
              _nextMeetings[group.id] = nextMeeting;
            } catch (e) {
              print('Erreur lors du chargement de la prochaine réunion pour ${group.name}: $e');
              _nextMeetings[group.id] = null;
            }
          } else {
            availableGroups.add(group);
          }
        }

        if (mounted) {
          setState(() {
            _myGroups = myGroups ?? [];
            _availableGroups = availableGroups ?? [];
            _isLoading = false;
          });
        }
        break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _reportAbsence(GroupModel group, GroupMeetingModel? meeting) async {
    if (meeting == null) return;

    final user = AuthService.currentUser;
    if (user == null) return;

    // Vérifier si l'absence a déjà été signalée
    final hasReported = await GroupsFirebaseService.hasReportedAbsence(
      group.id,
      meeting.id,
      user.uid,
    );

    if (hasReported) {
      // Proposer d'annuler le signalement
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Absence déjà signalée'),
          content: Text(
            'Vous avez déjà signalé votre absence pour la réunion "${meeting.title}" du ${_formatDate(meeting.date)}.\n\nVoulez-vous annuler ce signalement ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Annuler le signalement'),
            ),
          ],
        ),
      );

      if (result == true) {
        try {
          await GroupsFirebaseService.cancelAbsenceReport(
            group.id,
            meeting.id,
            user.uid,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signalement d\'absence annulé'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'annulation : $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
      return;
    }

    // Dialogue pour signaler une nouvelle absence
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AbsenceReportDialog(
        groupName: group.name,
        meetingTitle: meeting.title,
        meetingDate: meeting.date,
      ),
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await GroupsFirebaseService.reportAbsence(
          group.id,
          meeting.id,
          user.uid,
          result['reason'] ?? 'Aucune raison spécifiée',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Absence signalée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du signalement : $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _joinGroup(GroupModel group) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      await GroupsFirebaseService.addMemberToGroup(group.id, user.uid, 'member');
      
      setState(() {
        _myGroups.add(group);
        _availableGroups.remove(group);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez rejoint le groupe "${group.name}"'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _launchMeetingLink(String? link) async {
    if (link == null || link.isEmpty) return;
    
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le lien'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Groupes'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildTabSelector(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadGroupsData,
                      child: _selectedTab == 'my_groups'
                          ? _buildMyGroupsList()
                          : _buildAvailableGroupsList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'my_groups',
              'Mes Groupes',
              Icons.groups,
              _myGroups.length,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'available',
              'Disponibles',
              Icons.add_circle_outline,
              _availableGroups.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String title, IconData icon, int count) {
    final isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsList() {
    if (_myGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous n\'appartenez à aucun groupe',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explorez les groupes disponibles pour rejoindre une communauté',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedTab = 'available'),
              icon: const Icon(Icons.explore),
              label: const Text('Explorer les groupes'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myGroups.length,
      itemBuilder: (context, index) {
        final group = _myGroups[index];
        return _buildMyGroupCard(group);
      },
    );
  }

  Widget _buildAvailableGroupsList() {
    if (_availableGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successColor,
            ),
            SizedBox(height: 16),
            Text(
              'Vous faites partie de tous les groupes !',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableGroups.length,
      itemBuilder: (context, index) {
        final group = _availableGroups[index];
        return _buildAvailableGroupCard(group);
      },
    );
  }

  Widget _buildMyGroupCard(GroupModel group) {
    final nextMeeting = _nextMeetings[group.id];
    final groupColor = Color(int.parse(group.color.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailPage(group: group),
            ),
          );
        },
        child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  groupColor,
                  groupColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Image de fond
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildGroupImage(group),
                ),
                // Overlay avec dégradé
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        groupColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Contenu
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        group.type,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du groupe
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${group.dayName} à ${group.time}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        group.location,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Prochaine réunion
                if (nextMeeting != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.secondaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.upcoming,
                              size: 16,
                              color: AppTheme.secondaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Prochaine réunion',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nextMeeting.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          _formatDateTime(nextMeeting.date),
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    if (group.meetingLink != null && group.meetingLink!.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchMeetingLink(group.meetingLink),
                          icon: const Icon(Icons.video_call, size: 18),
                          label: const Text('Rejoindre'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    if (group.meetingLink != null && group.meetingLink!.isNotEmpty)
                      const SizedBox(width: 12),
                    Expanded(
                      child: _buildAbsenceButton(group, nextMeeting),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAvailableGroupCard(GroupModel group) {
    final groupColor = Color(int.parse(group.color.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getGroupIcon(group.type),
                    color: groupColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        group.type,
                        style: TextStyle(
                          color: groupColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              group.description,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.dayName} à ${group.time}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.location,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _joinGroup(group),
                icon: const Icon(Icons.add),
                label: const Text('Rejoindre le groupe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: groupColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceButton(GroupModel group, GroupMeetingModel? nextMeeting) {
    if (nextMeeting == null) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.event_busy, size: 18),
        label: const Text('Pas de réunion'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.textTertiaryColor,
        ),
      );
    }

    final user = AuthService.currentUser;
    if (user == null) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.event_busy, size: 18),
        label: const Text('Non connecté'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.textTertiaryColor,
        ),
      );
    }

    return FutureBuilder<bool>(
      future: GroupsFirebaseService.hasReportedAbsence(
        group.id,
        nextMeeting.id,
        user.uid,
      ),
      builder: (context, snapshot) {
        final hasReported = snapshot.data ?? false;
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ElevatedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            label: const Text('Vérification...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.textTertiaryColor,
            ),
          );
        }

        if (hasReported) {
          return ElevatedButton.icon(
            onPressed: () => _reportAbsence(group, nextMeeting),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Absence signalée'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: () => _reportAbsence(group, nextMeeting),
          icon: const Icon(Icons.event_busy, size: 18),
          label: const Text('Signaler absence'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warningColor,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildGroupImage(GroupModel group) {
    final imageUrl = "https://pixabay.com/get/g6710919a4dd10ba119b7531c05c80a6ec58f007e340f1520afb19cd997e112cc2bb69f1a303e6c2fe4aa00d00775a94936278e4746a38fe7937a76f74596317b_1280.jpg";

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 120,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.groups,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  IconData _getGroupIcon(String type) {
    switch (type.toLowerCase()) {
      case 'petit groupe':
        return Icons.people;
      case 'prière':
        return Icons.favorite;
      case 'jeunesse':
        return Icons.celebration;
      case 'étude biblique':
        return Icons.menu_book;
      case 'louange':
        return Icons.music_note;
      case 'leadership':
        return Icons.star;
      case 'ministère':
        return Icons.church;
      case 'formation':
        return Icons.school;
      default:
        return Icons.groups;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference < 7) {
      return 'Dans $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AbsenceReportDialog extends StatefulWidget {
  final String groupName;
  final String meetingTitle;
  final DateTime meetingDate;

  const _AbsenceReportDialog({
    required this.groupName,
    required this.meetingTitle,
    required this.meetingDate,
  });

  @override
  State<_AbsenceReportDialog> createState() => _AbsenceReportDialogState();
}

class _AbsenceReportDialogState extends State<_AbsenceReportDialog> {
  final _reasonController = TextEditingController();
  String _selectedReason = 'Autre';
  bool _isCustomReason = false;

  final List<String> _predefinedReasons = [
    'Maladie',
    'Voyage',
    'Obligations familiales',
    'Obligations professionnelles',
    'Problème de transport',
    'Urgence',
    'Autre',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatMeetingDate() {
    final now = DateTime.now();
    final difference = widget.meetingDate.difference(now).inDays;
    
    if (difference == 0) {
      return 'aujourd\'hui';
    } else if (difference == 1) {
      return 'demain';
    } else if (difference < 7) {
      return 'dans $difference jours';
    } else {
      return 'le ${widget.meetingDate.day}/${widget.meetingDate.month}/${widget.meetingDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.event_busy,
            color: AppTheme.warningColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Signaler une absence',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de la réunion
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.groups,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 18,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.meetingTitle,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 18,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Réunion ${_formatMeetingDate()}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Sélection de la raison
            const Text(
              'Raison de l\'absence :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Raisons prédéfinies
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedReasons.map((reason) {
                final isSelected = _selectedReason == reason && !_isCustomReason;
                return FilterChip(
                  label: Text(reason),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedReason = reason;
                        _isCustomReason = false;
                        if (reason != 'Autre') {
                          _reasonController.clear();
                        }
                      }
                    });
                  },
                  backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
            
            // Raison personnalisée
            if (_selectedReason == 'Autre' || _isCustomReason) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Précisez la raison',
                  hintText: 'Entrez votre raison...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  setState(() {
                    _isCustomReason = value.isNotEmpty;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            String finalReason;
            if (_isCustomReason && _reasonController.text.isNotEmpty) {
              finalReason = _reasonController.text.trim();
            } else if (_selectedReason != 'Autre') {
              finalReason = _selectedReason;
            } else {
              finalReason = 'Aucune raison spécifiée';
            }
            
            Navigator.pop(context, {
              'confirmed': true,
              'reason': finalReason,
            });
          },
          icon: const Icon(Icons.send),
          label: const Text('Signaler'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warningColor,
          ),
        ),
      ],
    );
  }
}