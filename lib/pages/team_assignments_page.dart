import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';  
import '../models/person_model.dart';
import '../services/services_firebase_service.dart';
import '../services/firebase_service.dart';

class TeamAssignmentsPage extends StatefulWidget {
  final TeamModel team;

  const TeamAssignmentsPage({super.key, required this.team});

  @override
  State<TeamAssignmentsPage> createState() => _TeamAssignmentsPageState();
}

class _TeamAssignmentsPageState extends State<TeamAssignmentsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  
  List<ServiceAssignmentModel> _assignments = [];
  List<PositionModel> _positions = [];
  List<PersonModel> _persons = [];
  List<ServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les positions de l'équipe
      final positions = await ServicesFirebaseService.getPositionsForTeamAsList(widget.team.id)
          .timeout(const Duration(seconds: 10));
      _positions = positions;

      // Charger toutes les assignations liées aux positions de cette équipe
      if (_positions.isNotEmpty) {
        final positionIds = _positions.map((p) => p.id).toList();
        
        // Charger les assignations par batch (Firestore limite à 10 éléments pour whereIn)
        final List<ServiceAssignmentModel> allAssignments = [];
        
        for (int i = 0; i < positionIds.length; i += 10) {
          final batch = positionIds.skip(i).take(10).toList();
          
          try {
            final snapshot = await ServicesFirebaseService.getServiceAssignmentsByPositionIds(batch)
                .timeout(const Duration(seconds: 10));
            final batchAssignments = snapshot;
            
            allAssignments.addAll(batchAssignments);
          } catch (e) {
            print('Erreur lors du chargement des assignations pour batch ${i ~/ 10}: $e');
            // Continuer avec les autres batches
          }
        }
        
        _assignments = allAssignments;
      }

      // Charger les personnes
      final personsSnapshot = await FirebaseService.getPersonsStream()
          .first
          .timeout(const Duration(seconds: 10));
      _persons = personsSnapshot.where((person) => person.isActive).toList();

      // Charger les services
      final serviceIds = _assignments.map((a) => a.serviceId).toSet().toList();
      final List<ServiceModel> services = [];
      
      for (final serviceId in serviceIds.take(20)) { // Limiter à 20 services
        try {
          final service = await ServicesFirebaseService.getService(serviceId)
              .timeout(const Duration(seconds: 5));
          if (service != null) {
            services.add(service);
          }
        } catch (e) {
          print('Erreur lors du chargement du service $serviceId: $e');
        }
      }
      _services = services;

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6F61EF);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = _parseColor(widget.team.color);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assignations'),
            Text(
              widget.team.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: teamColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des assignations...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
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
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune assignation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cette équipe n\'a pas encore d\'assignations de service',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistiques
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_assignments.length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: _parseColor(widget.team.color),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Total'),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_assignments.where((a) => a.isConfirmed || a.isAccepted).length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Confirmées'),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_assignments.where((a) => a.isPending).length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('En attente'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Liste des assignations
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _assignments.length,
            itemBuilder: (context, index) {
              final assignment = _assignments[index];
              final person = _persons.firstWhere(
                (p) => p.id == assignment.personId,
                orElse: () => PersonModel(
                  id: '',
                  firstName: 'Personne',
                  lastName: 'inconnue',
                  email: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              final position = _positions.firstWhere(
                (p) => p.id == assignment.positionId,
                orElse: () => PositionModel(
                  id: '',
                  teamId: '',
                  name: 'Position inconnue',
                  description: '',
                  createdAt: DateTime.now(),
                ),
              );
              final service = _services.firstWhere(
                (s) => s.id == assignment.serviceId,
                orElse: () => ServiceModel(
                  id: '',
                  name: 'Service inconnu',
                  type: '',
                  dateTime: DateTime.now(),
                  location: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(assignment.status).withOpacity(0.2),
                    child: Icon(
                      _getStatusIcon(assignment.status),
                      color: _getStatusColor(assignment.status),
                    ),
                  ),
                  title: Text(
                    person.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(position.name),
                      Text(
                        service.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDate(service.dateTime),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(assignment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(assignment.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusText(assignment.status),
                      style: TextStyle(
                        color: _getStatusColor(assignment.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'invited':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'invited':
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmé';
      case 'accepted':
        return 'Accepté';
      case 'declined':
        return 'Refusé';
      case 'invited':
      case 'pending':
        return 'En attente';
      default:
        return 'Inconnu';
    }
  }
}