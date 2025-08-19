import 'package:flutter/material.dart';
import '../shared/widgets/base_list_page.dart';
import '../shared/widgets/custom_card.dart';
import '../models/person_module_model.dart';
import '../services/people_module_service.dart';

/// Vue administrateur pour les personnes (Module)
class PeopleAdminModuleView extends StatefulWidget {
  const PeopleAdminModuleView({Key? key}) : super(key: key);

  @override
  State<PeopleAdminModuleView> createState() => _PeopleAdminModuleViewState();
}

class _PeopleAdminModuleViewState extends State<PeopleAdminModuleView> {
  final PeopleModuleService _peopleService = PeopleModuleService();
  String _searchQuery = '';
  bool _showInactive = false;
  List<Person>? _searchResults;

  @override
  Widget build(BuildContext context) {
    return BaseListPage<Person>(
      title: 'Gestion des Personnes (Module)',
      loadItems: () => _loadPeople(),
      buildItem: (person) => _buildPersonCard(person),
      searchWidget: _buildSearchAndFilters(),
      emptyMessage: 'Aucune personne trouvée',
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPerson,
        child: const Icon(Icons.add),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.list_alt),
          onPressed: _openLists,
          tooltip: 'Listes intelligentes',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showAdvancedSearch,
          tooltip: 'Recherche avancée',
        ),
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: _showStatistics,
          tooltip: 'Statistiques rapides',
        ),
        IconButton(
          icon: const Icon(Icons.upload),
          onPressed: _importPeople,
          tooltip: 'Importer',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportPeople,
          tooltip: 'Exporter',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'bulk_edit',
              child: Text('Modification groupée'),
            ),
            const PopupMenuItem(
              value: 'merge_duplicates',
              child: Text('Fusionner les doublons'),
            ),
            const PopupMenuItem(
              value: 'archive_inactive',
              child: Text('Archiver inactifs'),
            ),
          ],
        ),
      ],
    );
  }

  Future<List<Person>> _loadPeople() async {
    if (_searchResults != null) {
      return _searchResults!;
    }

    if (_searchQuery.isNotEmpty) {
      return await _peopleService.search(_searchQuery);
    }

    final allPeople = await _peopleService.getAll();
    if (_showInactive) {
      return allPeople;
    } else {
      return allPeople.where((person) => person.isActive).toList();
    }
  }

  Widget _buildPersonCard(Person person) {
    return CustomCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: person.isActive ? Colors.green : Colors.grey,
          child: Text(
            person.firstName.isNotEmpty ? person.firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          person.fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: person.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.email != null && person.email!.isNotEmpty)
              Text(person.email!),
            if (person.phone != null && person.phone!.isNotEmpty)
              Text(person.phone!),
            if (person.roles.isNotEmpty)
              Wrap(
                spacing: 4,
                children: person.roles
                    .map((role) => Chip(
                          label: Text(
                            role,
                            style: const TextStyle(fontSize: 10),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePersonAction(value, person),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Voir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Dupliquer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: person.isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(person.isActive ? Icons.archive : Icons.unarchive),
                title: Text(person.isActive ? 'Désactiver' : 'Activer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _handlePersonAction('view', person),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher une personne...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _searchResults = null;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Afficher inactifs'),
                    value: _showInactive,
                    onChanged: (value) {
                      setState(() {
                        _showInactive = value ?? false;
                      });
                    },
                    dense: true,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Effacer'),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchResults = null;
                      _showInactive = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewPerson() {
    Navigator.pushNamed(context, '/person/form');
  }

  void _openLists() {
    Navigator.pushNamed(context, '/people/lists');
  }

  void _showAdvancedSearch() {
    // Implémentation de la recherche avancée
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche avancée'),
        content: const Text('Fonctionnalité en développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() async {
    final stats = await _peopleService.getStatistics();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques rapides'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${stats['total'] ?? 0}'),
            Text('Actives: ${stats['actives'] ?? 0}'),
            Text('Inactives: ${stats['inactives'] ?? 0}'),
            Text('Avec email: ${stats['withEmail'] ?? 0}'),
            Text('Avec telephone: ${stats['withPhone'] ?? 0}'),
            Text('Avec date de naissance: ${stats['withBirthDate'] ?? 0}'),
          ],
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

  void _importPeople() {
    // Implémentation de l'import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalite d importation en developpement')),
    );
  }

  void _exportPeople() async {
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'bulk_edit':
        // Implémentation modification groupée
        break;
      case 'merge_duplicates':
        // Implémentation fusion doublons
        break;
      case 'archive_inactive':
        // Implémentation archivage
        break;
    }
  }

  void _handlePersonAction(String action, Person person) {
    switch (action) {
      case 'view':
        Navigator.pushNamed(context, '/person/detail', arguments: person.id);
        break;
      case 'edit':
        Navigator.pushNamed(context, '/person/form', arguments: person.id);
        break;
      case 'duplicate':
        // Implémentation duplication
        break;
      case 'activate':
      case 'deactivate':
        _togglePersonStatus(person);
        break;
      case 'delete':
        _deletePerson(person);
        break;
    }
  }

  void _togglePersonStatus(Person person) async {
    final updatedPerson = person.copyWith(
      isActive: !person.isActive,
      updatedAt: DateTime.now(),
    );

    try {
      await _peopleService.update(person.id!, updatedPerson);
      if (!mounted) return;

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.fullName} ${person.isActive ? 'desactive' : 'active'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la modification')),
      );
    }
  }

  void _deletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${person.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _peopleService.delete(person.id!);
        if (!mounted) return;

        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${person.fullName} supprime')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    }
  }
}