import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../models/person_model.dart';
import '../services/services_firebase_service.dart';
import '../services/firebase_service.dart';

import 'service_assignments_page.dart' as sap;
import 'service_form_page.dart';

class AssignmentsOverviewPage extends StatefulWidget {
  const AssignmentsOverviewPage({super.key});

  @override
  State<AssignmentsOverviewPage> createState() => _AssignmentsOverviewPageState();
}

class _AssignmentsOverviewPageState extends State<AssignmentsOverviewPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _timeFilter = 'upcoming'; // 'upcoming', 'past', 'all'
  bool _isLoading = false;
  String? _errorMessage;
  
  List<ServiceModel> _services = [];
  List<PersonModel> _persons = [];
  List<ServiceAssignmentModel> _assignments = [];
  List<TeamModel> _teams = [];
  List<PositionModel> _positions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Test de base pour vérifier la connectivité
      print('Début du chargement des assignations...');
      
      // Load all services with timeout
      print('Chargement des services...');
      try {
        // Essayer d'abord avec tous les services sans filtre de statut
        final allServicesSnapshot = await ServicesFirebaseService.getServicesStream(
          searchQuery: '',
          statusFilters: null, // Pas de filtre de statut
          typeFilters: [],
          startDate: null,
          endDate: null,
        ).first.timeout(const Duration(seconds: 10));
        _services = allServicesSnapshot;
        print('Services chargés (sans filtre): ${_services.length}');
        
        if (_services.isNotEmpty) {
          // Log des différents status disponibles
          final statusCounts = <String, int>{};
          for (final service in _services) {
            statusCounts[service.status] = (statusCounts[service.status] ?? 0) + 1;
          }
          print('Répartition des status: $statusCounts');
        } else {
          print('⚠️ Aucun service trouvé dans la base de données');
        }
      } catch (e) {
        print('❌ Erreur lors du chargement des services: $e');
        _services = [];
        
        // Si on a une erreur de services, pas la peine de continuer
        throw Exception('Impossible de charger les services: $e');
      }

      // Load all persons with timeout
      print('Chargement des personnes...');
      final personsSnapshot = await FirebaseService.getPersonsStream()
          .first
          .timeout(const Duration(seconds: 10));
      _persons = personsSnapshot.where((person) => person.isActive).toList();
      print('Personnes chargées: ${_persons.length}');

      // Load all teams with timeout
      print('Chargement des équipes...');
      final teamsSnapshot = await ServicesFirebaseService.getTeamsStream()
          .first
          .timeout(const Duration(seconds: 10));
      _teams = teamsSnapshot;
      print('Équipes chargées: ${_teams.length}');

      // Load all positions with optimized method
      print('Chargement des positions...');
      try {
        // Utiliser la nouvelle méthode Future optimisée pour charger toutes les positions
        _positions = await ServicesFirebaseService
            .getAllPositionsList()
            .timeout(const Duration(seconds: 15));
        print('Positions chargées: ${_positions.length}');
      } catch (e) {
        print('❌ Erreur lors du chargement des positions (méthode optimisée): $e');
        // Fallback 1: essayer avec l'ancienne méthode Stream
        try {
          print('Tentative de fallback 1: méthode Stream...');
          _positions = await ServicesFirebaseService
              .getAllPositionsStream()
              .first
              .timeout(const Duration(seconds: 20));
          print('Positions chargées via fallback 1: ${_positions.length}');
        } catch (streamError) {
          print('❌ Erreur lors du fallback 1: $streamError');
          // Fallback 2: chargement par équipe avec timeout plus long
          try {
            print('Tentative de fallback 2: chargement par équipe...');
            final allPositions = <PositionModel>[];
            final limitedTeams = _teams.take(15).toList(); // Limite réduite pour éviter les timeouts
            
            for (final team in limitedTeams) {
              try {
                final teamPositions = await ServicesFirebaseService
                    .getPositionsForTeamAsList(team.id)
                    .timeout(const Duration(seconds: 12)); // Timeout augmenté
                allPositions.addAll(teamPositions);
                print('Positions chargées pour équipe ${team.name}: ${teamPositions.length}');
              } catch (teamError) {
                print('⚠️ Erreur position Équipe ${team.name}: $teamError');
                // Continue avec les autres équipes
              }
            }
            _positions = allPositions;
            print('Positions chargées via fallback 2: ${_positions.length}');
          } catch (fallbackError) {
            print('❌ Erreur lors du fallback 2: $fallbackError');
            _positions = [];
          }
        }
      }

      // Load assignments using the new efficient method
      print('Chargement des assignations...');
      try {
        if (_services.isNotEmpty) {
          final serviceIds = _services.map((service) => service.id).toList();
          _assignments = await ServicesFirebaseService
              .getAssignmentsForServices(serviceIds)
              .timeout(const Duration(seconds: 15));
          print('Assignations chargées: ${_assignments.length}');
        } else {
          _assignments = [];
          print('Aucun service disponible, assignations vides');
        }
      } catch (e) {
        print('Erreur lors du chargement des assignations: $e');
        // Fallback: utiliser la méthode générale
        try {
          _assignments = await ServicesFirebaseService
              .getAllAssignments(limit: 200)
              .timeout(const Duration(seconds: 10));
          print('Assignations chargées via fallback: ${_assignments.length}');
        } catch (e2) {
          print('Erreur lors du fallback des assignations: $e2');
          _assignments = [];
        }
      }

      print('Chargement terminé avec succès!');

    } catch (e) {
      print('Erreur globale lors du chargement: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: _loadData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ServiceModel> _getFilteredServices() {
    // Si on est en cours de chargement, retourner la liste actuelle des services
    // (cela permet d'afficher un état cohérent même pendant le chargement)
    if (_isLoading && _services.isEmpty) {
      return [];
    }
    
    var filtered = _services.where((service) {
      // Time filter
      final now = DateTime.now();
      switch (_timeFilter) {
        case 'upcoming':
          if (service.dateTime.isBefore(now)) return false;
          break;
        case 'past':
          if (service.dateTime.isAfter(now)) return false;
          break;
        case 'all':
          // Pas de filtre temporel
          break;
        default:
          // Valeur par défaut si _timeFilter est invalide
          break;
      }
      
      // Search filter avec protection
      if (_searchQuery.isNotEmpty && _searchQuery.trim().isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase().trim();
        final serviceName = service.name.toLowerCase();
        final serviceLocation = service.location.toLowerCase();
        
        if (!serviceName.contains(searchLower) && !serviceLocation.contains(searchLower)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Sort by date (upcoming first, then past)
    filtered.sort((a, b) {
      final now = DateTime.now();
      final aIsUpcoming = a.dateTime.isAfter(now);
      final bIsUpcoming = b.dateTime.isAfter(now);
      
      if (aIsUpcoming && !bIsUpcoming) return -1;
      if (!aIsUpcoming && bIsUpcoming) return 1;
      
      if (aIsUpcoming) {
        return a.dateTime.compareTo(b.dateTime); // Ascending for upcoming
      } else {
        return b.dateTime.compareTo(a.dateTime); // Descending for past
      }
    });

    return filtered;
  }

  List<ServiceAssignmentModel> _getFilteredAssignments() {
    // Si on est en cours de chargement, retourner la liste actuelle des assignations
    // (cela permet d'afficher un état cohérent même pendant le chargement)
    if (_isLoading && _assignments.isEmpty) {
      return [];
    }
    
    var filtered = _assignments.where((assignment) {
      // Status filter avec protection
      if (_statusFilter != 'all' && _statusFilter.isNotEmpty && assignment.status != _statusFilter) {
        return false;
      }
      
      // Time filter - based on service date avec protection
      ServiceModel? service;
      try {
        service = _services.firstWhere(
          (s) => s.id == assignment.serviceId,
        );
      } catch (e) {
        // Service non trouvé, utiliser une valeur par défaut ou ignorer
        service = null;
      }
      
      if (service == null) {
        // Si le service n'est pas trouvé, inclure l'assignation par défaut
        // (plutôt que de la rejeter complètement)
        if (_timeFilter == 'upcoming' || _timeFilter == 'past') {
          return false; // Exclure si on cherche des dates spécifiques
        }
      } else {
        final now = DateTime.now();
        switch (_timeFilter) {
          case 'upcoming':
            if (service.dateTime.isBefore(now)) return false;
            break;
          case 'past':
            if (service.dateTime.isAfter(now)) return false;
            break;
          case 'all':
            // Pas de filtre temporel
            break;
          default:
            // Valeur par défaut si _timeFilter est invalide
            break;
        }
      }
      
      // Search filter avec protection
      if (_searchQuery.isNotEmpty && _searchQuery.trim().isNotEmpty) {
        PersonModel? person;
        PositionModel? position;
        
        try {
          person = _persons.firstWhere((p) => p.id == assignment.personId);
        } catch (e) {
          person = null;
        }
        
        try {
          position = _positions.firstWhere((p) => p.id == assignment.positionId);
        } catch (e) {
          position = null;
        }
        
        final searchLower = _searchQuery.toLowerCase().trim();
        
        bool matchFound = false;
        
        // Vérifier le nom de la personne
        if (person != null) {
          final fullName = person.fullName.toLowerCase();
          if (fullName.contains(searchLower)) {
            matchFound = true;
          }
        }
        
        // Vérifier le nom de la position
        if (!matchFound && position != null) {
          final positionName = position.name.toLowerCase();
          if (positionName.contains(searchLower)) {
            matchFound = true;
          }
        }
        
        // Vérifier le nom du service
        if (!matchFound && service != null) {
          final serviceName = service.name.toLowerCase();
          if (serviceName.contains(searchLower)) {
            matchFound = true;
          }
        }
        
        if (!matchFound) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Sort by service date and then by status avec protection
    try {
      filtered.sort((a, b) {
        ServiceModel? serviceA;
        ServiceModel? serviceB;
        
        try {
          serviceA = _services.firstWhere((s) => s.id == a.serviceId);
        } catch (e) {
          serviceA = null;
        }
        
        try {
          serviceB = _services.firstWhere((s) => s.id == b.serviceId);
        } catch (e) {
          serviceB = null;
        }
        
        // Si les deux services sont null, trier par date de création de l'assignation
        if (serviceA == null && serviceB == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        
        // Si un service est null, l'autre prend priorité
        if (serviceA == null) return 1;
        if (serviceB == null) return -1;
        
        // Sort by date first
        final dateComparison = serviceA.dateTime.compareTo(serviceB.dateTime);
        if (dateComparison != 0) return dateComparison;
        
        // Then by status (confirmed first, then pending, then declined)
        final statusOrder = ['confirmed', 'accepted', 'invited', 'pending', 'declined'];
        final aIndex = statusOrder.indexOf(a.status);
        final bIndex = statusOrder.indexOf(b.status);
        
        return aIndex.compareTo(bIndex);
      });
    } catch (e) {
      // En cas d'erreur de tri, trier par date de création
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  Map<String, dynamic> _getAssignmentsStats() {
    final now = DateTime.now();
    final upcomingServices = _services.where((s) => s.dateTime.isAfter(now)).length;
    final totalAssignments = _assignments.length;
    final pendingAssignments = _assignments.where((a) => a.isPending).length;
    final confirmedAssignments = _assignments.where((a) => a.isConfirmed).length;
    final declinedAssignments = _assignments.where((a) => a.isDeclined).length;
    
    return {
      'upcomingServices': upcomingServices,
      'totalAssignments': totalAssignments,
      'pendingAssignments': pendingAssignments,
      'confirmedAssignments': confirmedAssignments,
      'declinedAssignments': declinedAssignments,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignations et Affectations'),
        actions: [

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vue d\'ensemble', icon: Icon(Icons.dashboard)),
            Tab(text: 'Par services', icon: Icon(Icons.event)),
            Tab(text: 'Par personnes', icon: Icon(Icons.people)),
          ],
        ),
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildServicesByServicesTab(),
                    _buildByPersonsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _getAssignmentsStats();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://pixabay.com/get/g0d5e61cb3c35cfa9c47998f5fb75fd460171c73af707cdfc233e6c62c7c50b3b352b54422f5da8cb7f573bee163d17404fada6af3036ce658ff2ddededcef39a_1280.jpg"),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xB3000000), // 70% opacity black
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Assignations',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Vue d\'ensemble des affectations aux services',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Statistics cards
          Text(
            'Statistiques',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Services à venir',
                stats['upcomingServices'].toString(),
                Icons.event,
                Colors.blue,
              ),
              _buildStatCard(
                'Total assignations',
                stats['totalAssignments'].toString(),
                Icons.assignment,
                Colors.green,
              ),
              _buildStatCard(
                'En attente',
                stats['pendingAssignments'].toString(),
                Icons.schedule,
                Colors.orange,
              ),
              _buildStatCard(
                'Confirmées',
                stats['confirmedAssignments'].toString(),
                Icons.verified,
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent assignments
          Text(
            'Assignations récentes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._assignments
              .take(5)
              .map((assignment) => _buildAssignmentCard(assignment))
              .toList(),
          
          if (_assignments.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () => _tabController.animateTo(2),
                  child: const Text('Voir toutes les assignations'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesByServicesTab() {
    return Column(
      children: [

        
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un service...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('À venir'),
                      selected: _timeFilter == 'upcoming',
                      onSelected: (selected) {
                        if (selected && _timeFilter != 'upcoming') {
                          setState(() => _timeFilter = 'upcoming');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Passés'),
                      selected: _timeFilter == 'past',
                      onSelected: (selected) {
                        if (selected && _timeFilter != 'past') {
                          setState(() => _timeFilter = 'past');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _timeFilter == 'all',
                      onSelected: (selected) {
                        if (selected && _timeFilter != 'all') {
                          setState(() => _timeFilter = 'all');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Services list
        Expanded(
          child: _buildServicesList(),
        ),
      ],
    );
  }

  Widget _buildByPersonsTab() {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher une personne ou un poste...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _statusFilter == 'all',
                      onSelected: (selected) {
                        if (selected && _statusFilter != 'all') {
                          setState(() => _statusFilter = 'all');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('En attente'),
                      selected: _statusFilter == 'invited',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'invited');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Acceptés'),
                      selected: _statusFilter == 'accepted',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'accepted');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Confirmés'),
                      selected: _statusFilter == 'confirmed',
                      onSelected: (selected) {
                        if (selected) setState(() => _statusFilter = 'confirmed');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Assignments list
        Expanded(
          child: _buildAssignmentsList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    final filteredServices = _getFilteredServices();
    
    // Debug info
    print('_buildServicesList called:');
    print('- _isLoading: $_isLoading');
    print('- _services.length: ${_services.length}');
    print('- filteredServices.length: ${filteredServices.length}');
    print('- _timeFilter: $_timeFilter');
    print('- _searchQuery: $_searchQuery');
    
    if (filteredServices.isEmpty) {
      // Si on est en cours de chargement, afficher un indicateur
      if (_isLoading) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des services...'),
            ],
          ),
        );
      }
      
      // Si aucun service n'est trouvé après le chargement
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun service trouvé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _services.isEmpty 
                ? 'Il n\'y a aucun service dans la base de données.\nVeuillez créer un service d\'abord depuis la page Services.'
                : 'Aucun service ne correspond aux filtres sélectionnés.\nEssayez de modifier les filtres ou la recherche.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (_timeFilter != 'all' || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _timeFilter = 'all';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Effacer les filtres'),
              ),
            ],
            if (_services.isEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceFormPage(),
                    ),
                  );
                  if (result == true) {
                    _loadData(); // Recharger les données
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer un service'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        final serviceAssignments = _assignments
            .where((a) => a.serviceId == service.id)
            .toList();
        
        final now = DateTime.now();
        final isUpcoming = service.dateTime.isAfter(now);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isUpcoming ? Colors.green : Colors.grey,
              child: Icon(
                isUpcoming ? Icons.schedule : Icons.history,
                color: Colors.white,
              ),
            ),
            title: Text(service.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR')
                      .format(service.dateTime),
                ),
                const SizedBox(height: 4),
                Text(
                  '${serviceAssignments.length} assignation(s)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (serviceAssignments.isNotEmpty) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        serviceAssignments
                            .where((a) => a.isConfirmed || a.isAccepted)
                            .length
                            .toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'OK',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        serviceAssignments
                            .where((a) => a.isPending)
                            .length
                            .toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Text(
                        'Attente',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => sap.ServiceAssignmentsPage(service: service),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsList() {
    final filteredAssignments = _getFilteredAssignments();
    
    if (filteredAssignments.isEmpty) {
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
              'Aucune assignation trouvée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredAssignments.length,
      itemBuilder: (context, index) {
        final assignment = filteredAssignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentCard(ServiceAssignmentModel assignment) {
    final person = _persons.firstWhere(
      (p) => p.id == assignment.personId,
      orElse: () => PersonModel(
        id: assignment.personId,
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
        id: assignment.positionId,
        teamId: '',
        name: 'Position inconnue',
        description: '',
        createdAt: DateTime.now(),
      ),
    );
    final team = _teams.firstWhere(
      (t) => t.id == position.teamId,
      orElse: () => TeamModel(
        id: position.teamId,
        name: 'Équipe inconnue',
        description: '',
        color: '#6F61EF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final service = _services.firstWhere(
      (s) => s.id == assignment.serviceId,
      orElse: () => ServiceModel(
        id: assignment.serviceId,
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
          backgroundColor: Color(int.parse(team.color.replaceAll('#', '0xFF'))),
          child: Text(
            person.fullName.isNotEmpty 
                ? person.fullName.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(person.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${team.name} • ${position.name}'),
            const SizedBox(height: 2),
            Text(
              service.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              DateFormat('d MMM yyyy à HH:mm', 'fr_FR').format(service.dateTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor(assignment.status).withAlpha(25), // ~10% opacity
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            assignment.statusLabel,
            style: TextStyle(
              color: _getStatusColor(assignment.status),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => sap.ServiceAssignmentsPage(service: service),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'invited':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'tentative':
        return Colors.orange;
      case 'confirmed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}