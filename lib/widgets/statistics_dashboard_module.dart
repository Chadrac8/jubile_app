import 'package:flutter/material.dart';
import '../services/people_module_service.dart';
import '../shared/widgets/custom_card.dart';

/// Dashboard des statistiques des personnes (Module)
class StatisticsDashboardModule extends StatefulWidget {
  const StatisticsDashboardModule({Key? key}) : super(key: key);

  @override
  State<StatisticsDashboardModule> createState() => _StatisticsDashboardModuleState();
}

class _StatisticsDashboardModuleState extends State<StatisticsDashboardModule> {
  final PeopleModuleService _peopleService = PeopleModuleService();
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _peopleService.getStatistics();
      
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur lors du chargement des statistiques',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_statistics == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 16),
            _buildContactSection(),
            const SizedBox(height: 16),
            _buildRolesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d ensemble',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'Total',
              _statistics!['total']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Actives',
              _statistics!['actives']?.toString() ?? '0',
              Icons.person,
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'Inactives',
              _statistics!['inactives']?.toString() ?? '0',
              Icons.person_outline,
              Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Taux d activite',
              _calculateActivityRate(),
              Icons.trending_up,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de contact',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'Avec email',
              _statistics!['withEmail']?.toString() ?? '0',
              Icons.email,
              Colors.indigo,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Avec telephone',
              _statistics!['withPhone']?.toString() ?? '0',
              Icons.phone,
              Colors.teal,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'Avec date naissance',
              _statistics!['withBirthDate']?.toString() ?? '0',
              Icons.cake,
              Colors.pink,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Completude profil',
              _calculateProfileCompleteness(),
              Icons.account_circle,
              Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRolesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(
              'Anniversaires du mois',
              Icons.celebration,
              () => _showBirthdays(),
            ),
            _buildActionChip(
              'Exporter données',
              Icons.download,
              () => _exportData(),
            ),
            _buildActionChip(
              'Profils incomplets',
              Icons.warning_amber,
              () => _showIncompleteProfiles(),
            ),
            _buildActionChip(
              'Statistiques detaillees',
              Icons.analytics,
              () => _showDetailedStats(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  String _calculateActivityRate() {
    final total = _statistics!['total'] ?? 0;
    final active = _statistics!['actives'] ?? 0;
    
    if (total == 0) return '0%';
    
    final rate = (active / total * 100).round();
    return '$rate%';
  }

  String _calculateProfileCompleteness() {
    final active = _statistics!['actives'] ?? 0;
    final withEmail = _statistics!['withEmail'] ?? 0;
    final withPhone = _statistics!['withPhone'] ?? 0;
    final withBirthDate = _statistics!['withBirthDate'] ?? 0;
    
    if (active == 0) return '0%';
    
    // Score basé sur la présence d'informations de contact et date de naissance
    final totalFields = active * 3; // 3 champs considérés
    final filledFields = withEmail + withPhone + withBirthDate;
    final rate = (filledFields / totalFields * 100).round();
    
    return '$rate%';
  }

  void _showBirthdays() async {
    final birthdays = await _peopleService.getBirthdaysThisMonth();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anniversaires du mois'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: birthdays.length,
            itemBuilder: (context, index) {
              final person = birthdays[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(person.firstName[0].toUpperCase()),
                ),
                title: Text(person.fullName),
                subtitle: person.birthDate != null
                    ? Text('Age: ${person.age ?? '?'} ans')
                    : null,
                trailing: person.birthDate != null
                    ? Text('${person.birthDate!.day}/${person.birthDate!.month}')
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    try {
      final data = await _peopleService.exportPeople();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export reussi: ${data.length} personnes')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l export')),
      );
    }
  }

  void _showIncompleteProfiles() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonctionnalite en developpement')),
    );
  }

  void _showDetailedStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques detaillees'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total des personnes', _statistics!['total'] ?? 0),
              _buildStatRow('Personnes actives', _statistics!['actives'] ?? 0),
              _buildStatRow('Personnes inactives', _statistics!['inactives'] ?? 0),
              const Divider(),
              _buildStatRow('Avec adresse email', _statistics!['withEmail'] ?? 0),
              _buildStatRow('Avec numero telephone', _statistics!['withPhone'] ?? 0),
              _buildStatRow('Avec date naissance', _statistics!['withBirthDate'] ?? 0),
              const Divider(),
              _buildStatRow('Taux d activite', _calculateActivityRate()),
              _buildStatRow('Completude profil', _calculateProfileCompleteness()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}