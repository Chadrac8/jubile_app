import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../models/service.dart';
import '../models/service_assignment.dart';
import '../services/services_service.dart';
import '../../../extensions/datetime_extensions.dart';


/// Vue membre pour les services
class ServicesMemberView extends StatefulWidget {
  const ServicesMemberView({Key? key}) : super(key: key);

  @override
  State<ServicesMemberView> createState() => _ServicesMemberViewState();
}

class _ServicesMemberViewState extends State<ServicesMemberView>
    with SingleTickerProviderStateMixin {
  final ServicesService _servicesService = ServicesService();
  late TabController _tabController;
  
  List<Service> _upcomingServices = [];
  List<Service> _pastServices = [];
  List<ServiceAssignment> _myAssignments = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final upcoming = await _servicesService.getUpcomingServices(limit: 50);
      final past = await _servicesService.getPastServices(limit: 50);
      // TODO: Remplacer par l'ID utilisateur actuel
      final assignments = await _servicesService.getMemberAssignments('current_user_id');
      
      setState(() {
        _upcomingServices = upcoming;
        _pastServices = past;
        _myAssignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  List<Service> _filterServices(List<Service> services) {
    var filtered = services;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((service) {
        return service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               service.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               service.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_selectedType != null) {
      filtered = filtered.where((service) {
        return service.type.name == _selectedType;
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Services',
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildPastTab(),
                _buildMyAssignmentsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'À venir', icon: Icon(Icons.schedule)),
          Tab(text: 'Passés', icon: Icon(Icons.history)),
          Tab(text: 'Mes rôles', icon: Icon(Icons.assignment_ind)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher des services...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() => _selectedType = null);
                  },
                ),
                const SizedBox(width: 8),
                ...ServiceType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.displayName),
                      selected: _selectedType == type.name,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type.name : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredServices = _filterServices(_upcomingServices);

    if (filteredServices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun service à venir',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          final service = filteredServices[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredServices = _filterServices(_pastServices);

    if (filteredServices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun service passé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          final service = filteredServices[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildMyAssignmentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myAssignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune assignation',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de rôle assigné pour les services.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myAssignments.length,
        itemBuilder: (context, index) {
          final assignment = _myAssignments[index];
          return _buildAssignmentCard(assignment);
        },
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/service/detail',
            arguments: service,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image d'en-tête
            if (service.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  service.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          service.type.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: service.colorCode != null
                            ? Color(int.parse(service.colorCode!.replaceFirst('#', '0xff')))
                            : Theme.of(context).primaryColor,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (service.description.isNotEmpty)
                    Text(
                      service.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Informations pratiques
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDateTime(service.startDate)} - ${_formatTime(service.endDate)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.location,
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Statut et durée
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(service.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service.statusDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Durée: ${_formatDuration(service.duration)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
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

  Widget _buildAssignmentCard(ServiceAssignment assignment) {
    return FutureBuilder<Service?>(
      future: _servicesService.getById(assignment.serviceId),
      builder: (context, snapshot) {
        final service = snapshot.data;
        
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(assignment.statusColor.replaceFirst('#', '0xff'))),
              child: Icon(
                _getStatusIcon(assignment.status),
                color: Colors.white,
              ),
            ),
            title: Text(assignment.role),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service != null) 
                  Text(service.name),
                if (service != null)
                  Text(
                    _formatDateTime(service.startDate),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                if (assignment.responsibilities.isNotEmpty)
                  Text(
                    'Responsabilités: ${assignment.responsibilities.join(', ')}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(
                    assignment.status.displayName,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Color(int.parse(assignment.statusColor.replaceFirst('#', '0xff'))),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                if (assignment.isTeamLead)
                  const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ),
            onTap: service != null ? () {
              Navigator.of(context).pushNamed(
                '/service/detail',
                arguments: service,
              );
            } : null,
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.relativeDateTime;
  }

  String _formatTime(DateTime dateTime) {
    return dateTime.timeOnly;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return Colors.blue;
      case ServiceStatus.inProgress:
        return Colors.green;
      case ServiceStatus.completed:
        return Colors.grey;
      case ServiceStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return Icons.hourglass_empty;
      case AssignmentStatus.confirmed:
        return Icons.check_circle;
      case AssignmentStatus.declined:
        return Icons.cancel;
      case AssignmentStatus.completed:
        return Icons.done_all;
    }
  }
}