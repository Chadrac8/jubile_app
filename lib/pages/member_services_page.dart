import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/service_model.dart';
import '../services/services_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';


class MemberServicesPage extends StatefulWidget {
  const MemberServicesPage({super.key});

  @override
  State<MemberServicesPage> createState() => _MemberServicesPageState();
}

class _MemberServicesPageState extends State<MemberServicesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ServiceAssignmentModel> _myAssignments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final Map<String, String> _statusFilters = {
    'all': 'Tous',
    'invited': 'Invité',
    'accepted': 'Accepté',
    'declined': 'Refusé',
    'tentative': 'Incertain',
    'confirmed': 'Confirmé',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAssignments();
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

  Future<void> _loadAssignments() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final assignments = await ServicesFirebaseService.getPersonAssignments(
        user.uid,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      if (mounted) {
        setState(() {
          _myAssignments = assignments ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement : $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _updateAssignmentStatus(ServiceAssignmentModel assignment, String newStatus) async {
    try {
      final updatedAssignment = ServiceAssignmentModel(
        id: assignment.id,
        serviceId: assignment.serviceId,
        positionId: assignment.positionId,
        personId: assignment.personId,
        status: newStatus,
        notes: assignment.notes,
        respondedAt: DateTime.now(),
        lastReminderSent: assignment.lastReminderSent,
        createdAt: assignment.createdAt,
        updatedAt: DateTime.now(),
        assignedBy: assignment.assignedBy,
      );

      await ServicesFirebaseService.updateAssignment(updatedAssignment);
      
      setState(() {
        final index = _myAssignments.indexWhere((a) => a.id == assignment.id);
        if (index != -1) {
          _myAssignments[index] = updatedAssignment;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour : ${_getStatusLabel(newStatus)}'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour : $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _updateAvailability() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disponibilités'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gestion des disponibilités'),
            SizedBox(height: 16),
            Text(
              'Cette fonctionnalité permet de définir vos créneaux de disponibilité pour les services.',
              style: TextStyle(color: Theme.of(context).colorScheme.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la gestion des disponibilités
            },
            child: const Text('Gérer'),
          ),
        ],
      ),
    );
  }

  List<ServiceAssignmentModel> get _filteredAssignments {
    if (_selectedFilter == 'all') {
      return _myAssignments;
    }
    return _myAssignments.where((a) => a.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Services'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.textPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available),
            onPressed: _updateAvailability,
            tooltip: 'Mes disponibilités',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildFilterSelector(),
                  _buildStatsRow(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadAssignments,
                      child: _buildAssignmentsList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final entry = _statusFilters.entries.elementAt(index);
          final isSelected = _selectedFilter == entry.key;
          final count = entry.key == 'all' 
              ? _myAssignments.length 
              : _myAssignments.where((a) => a.status == entry.key).length;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.value),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Theme.of(context).colorScheme.primaryColor : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = entry.key;
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.textPrimaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    final pendingCount = _myAssignments.where((a) => a.isPending).length;
    final acceptedCount = _myAssignments.where((a) => a.isAccepted).length;
    final upcomingCount = _myAssignments.where((a) {
      // Approximation - dans une vraie app, on chargerait les services
      return a.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'En attente',
              '$pendingCount',
              Icons.pending_actions,
              Theme.of(context).colorScheme.warningColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Acceptés',
              '$acceptedCount',
              Icons.check_circle,
              Theme.of(context).colorScheme.successColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'À venir',
              '$upcomingCount',
              Icons.upcoming,
              Theme.of(context).colorScheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    final assignments = _filteredAssignments;
    
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.church_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all' 
                  ? 'Aucune affectation de service'
                  : 'Aucune affectation avec ce statut',
              style: const TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vos affectations aux équipes de service apparaîtront ici',
              style: TextStyle(
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentCard(ServiceAssignmentModel assignment) {
    final statusColor = _getStatusColor(assignment.status);
    final isUpcoming = assignment.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(assignment.status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service ID: ${assignment.serviceId}', // TODO: Charger le nom du service
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Position ID: ${assignment.positionId}', // TODO: Charger le nom de la position
                        style: const TextStyle(
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(assignment.status),
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
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Créé le ${_formatDate(assignment.createdAt)}',
                      style: const TextStyle(
                        color: Theme.of(context).colorScheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                
                if (assignment.respondedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Répondu le ${_formatDate(assignment.respondedAt!)}',
                        style: const TextStyle(
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes :',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignment.notes!,
                          style: const TextStyle(
                            color: Theme.of(context).colorScheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Actions
                if (assignment.isPending && isUpcoming) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateAssignmentStatus(assignment, 'declined'),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Refuser'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateAssignmentStatus(assignment, 'accepted'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accepter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (assignment.isAccepted && isUpcoming) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Voir la feuille de service
                      },
                      icon: const Icon(Icons.description, size: 18),
                      label: const Text('Voir la feuille de service'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'invited':
        return Theme.of(context).colorScheme.warningColor;
      case 'accepted':
        return Theme.of(context).colorScheme.successColor;
      case 'declined':
        return Theme.of(context).colorScheme.errorColor;
      case 'tentative':
        return Colors.orange;
      case 'confirmed':
        return Theme.of(context).colorScheme.primaryColor;
      default:
        return Theme.of(context).colorScheme.textSecondaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'invited':
        return Icons.mail_outline;
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'tentative':
        return Icons.help_outline;
      case 'confirmed':
        return Icons.verified;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    return _statusFilters[status] ?? status;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}