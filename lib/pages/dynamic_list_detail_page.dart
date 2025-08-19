import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dynamic_list_model.dart';
import '../services/dynamic_lists_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import '../widgets/custom_card.dart';
import 'dynamic_list_builder_page.dart';

/// Page de détail et d'affichage d'une liste dynamique
class DynamicListDetailPage extends StatefulWidget {
  final DynamicListModel list;

  const DynamicListDetailPage({Key? key, required this.list}) : super(key: key);

  @override
  State<DynamicListDetailPage> createState() => _DynamicListDetailPageState();
}

class _DynamicListDetailPageState extends State<DynamicListDetailPage> {
  late DynamicListModel _list;
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortField = '';
  String _sortDirection = 'asc';

  @override
  void initState() {
    super.initState();
    _list = widget.list;
    _loadData();
    _markAsUsed();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Simuler le chargement des données
      // En réalité, ici nous appellerions le service approprié selon le sourceModule
      final mockData = _generateMockData();
      
      setState(() {
        _data = mockData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _markAsUsed() async {
    try {
      await DynamicListsFirebaseService.markListAsUsed(_list.id);
    } catch (e) {
      // Erreur silencieuse pour les statistiques
    }
  }

  List<Map<String, dynamic>> _generateMockData() {
    // Générer des données fictives selon le module source
    switch (_list.sourceModule) {
      case 'people':
        return _generatePeopleData();
      case 'groups':
        return _generateGroupsData();
      case 'events':
        return _generateEventsData();
      case 'tasks':
        return _generateTasksData();
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _generatePeopleData() {
    return [
      {
        'firstName': 'Jean',
        'lastName': 'Dupont',
        'fullName': 'Jean Dupont',
        'email': 'jean.dupont@email.com',
        'phone': '01 23 45 67 89',
        'birthDate': DateTime(1980, 5, 15),
        'address': '123 Rue de la Paix',
        'city': 'Paris',
        'roles': ['Membre', 'Musicien'],
        'isActive': true,
        'joinDate': DateTime(2020, 1, 10),
      },
      {
        'firstName': 'Marie',
        'lastName': 'Martin',
        'fullName': 'Marie Martin',
        'email': 'marie.martin@email.com',
        'phone': '01 98 76 54 32',
        'birthDate': DateTime(1985, 8, 22),
        'address': '456 Avenue des Champs',
        'city': 'Lyon',
        'roles': ['Membre', 'Responsable'],
        'isActive': true,
        'joinDate': DateTime(2019, 6, 15),
      },
      {
        'firstName': 'Pierre',
        'lastName': 'Durand',
        'fullName': 'Pierre Durand',
        'email': 'pierre.durand@email.com',
        'phone': '01 11 22 33 44',
        'birthDate': DateTime(1975, 12, 3),
        'address': '789 Boulevard du Temple',
        'city': 'Marseille',
        'roles': ['Ancien', 'Enseignant'],
        'isActive': true,
        'joinDate': DateTime(2018, 3, 20),
      },
    ];
  }

  List<Map<String, dynamic>> _generateGroupsData() {
    return [
      {
        'name': 'Groupe de Jeunes',
        'description': 'Groupe pour les 18-35 ans',
        'category': 'Jeunesse',
        'leader': 'Marie Martin',
        'memberCount': 25,
        'meetingDay': 'Vendredi',
        'meetingTime': '19:00',
        'location': 'Salle 1',
        'isActive': true,
      },
      {
        'name': 'Groupe de Prière',
        'description': 'Intercession et prière',
        'category': 'Spiritualité',
        'leader': 'Pierre Durand',
        'memberCount': 15,
        'meetingDay': 'Mercredi',
        'meetingTime': '20:00',
        'location': 'Salle de prière',
        'isActive': true,
      },
    ];
  }

  List<Map<String, dynamic>> _generateEventsData() {
    return [
      {
        'title': 'Conférence Printemps',
        'description': 'Grande conférence annuelle',
        'startDate': DateTime.now().add(const Duration(days: 30)),
        'endDate': DateTime.now().add(const Duration(days: 32)),
        'location': 'Auditorium principal',
        'category': 'Conférence',
        'registrationCount': 150,
        'maxParticipants': 200,
        'status': 'Ouvert',
      },
      {
        'title': 'Sortie Famille',
        'description': 'Journée détente en famille',
        'startDate': DateTime.now().add(const Duration(days: 15)),
        'endDate': DateTime.now().add(const Duration(days: 15)),
        'location': 'Parc de Sceaux',
        'category': 'Sortie',
        'registrationCount': 45,
        'maxParticipants': 50,
        'status': 'Ouvert',
      },
    ];
  }

  List<Map<String, dynamic>> _generateTasksData() {
    return [
      {
        'title': 'Préparer la réunion',
        'description': 'Organiser la réunion mensuelle',
        'priority': 'Haute',
        'status': 'En cours',
        'dueDate': DateTime.now().add(const Duration(days: 5)),
        'assignedTo': 'Jean Dupont',
        'assignedBy': 'Marie Martin',
        'category': 'Administration',
      },
      {
        'title': 'Mise à jour site web',
        'description': 'Actualiser le contenu du site',
        'priority': 'Moyenne',
        'status': 'À faire',
        'dueDate': DateTime.now().add(const Duration(days: 10)),
        'assignedTo': 'Pierre Durand',
        'assignedBy': 'Marie Martin',
        'category': 'Communication',
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredData() {
    var filtered = _data;

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.values.any((value) {
          return value.toString().toLowerCase().contains(_searchQuery.toLowerCase());
        });
      }).toList();
    }

    // Appliquer le tri
    if (_sortField.isNotEmpty) {
      filtered.sort((a, b) {
        var aValue = a[_sortField];
        var bValue = b[_sortField];
        
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return 1;
        if (bValue == null) return -1;
        
        int comparison;
        if (aValue is DateTime && bValue is DateTime) {
          comparison = aValue.compareTo(bValue);
        } else if (aValue is num && bValue is num) {
          comparison = aValue.compareTo(bValue);
        } else {
          comparison = aValue.toString().compareTo(bValue.toString());
        }
        
        return _sortDirection == 'asc' ? comparison : -comparison;
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildDataView(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[700],
      title: Text(
        _list.name,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _showSearchDialog,
          tooltip: 'Rechercher',
        ),
        IconButton(
          icon: const Icon(Icons.sort, color: Colors.white),
          onPressed: _showSortDialog,
          tooltip: 'Trier',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Dupliquer'),
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Exporter'),
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Partager'),
              ),
            ),
            PopupMenuItem(
              value: 'favorite',
              child: ListTile(
                leading: Icon(_list.isFavorite ? Icons.star : Icons.star_border),
                title: Text(_list.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Actualiser'),
              ),
            ),
          ],
        ),
      ],
      bottom: _buildSearchBar(),
    );
  }

  PreferredSize _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Rechercher dans la liste...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDataView() {
    final filteredData = _getFilteredData();
    
    if (filteredData.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        _buildListInfo(filteredData.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                return _buildDataCard(filteredData[index], index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListInfo(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _getIconForSourceModule(_list.sourceModule),
            color: Theme.of(context).colorScheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            '$count résultat${count > 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primaryColor,
            ),
          ),
          const Spacer(),
          if (_list.lastUsed != null)
            Text(
              'Dernière utilisation: ${_formatDate(_list.lastUsed!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
              ? 'Aucun résultat pour "${_searchQuery}"'
              : 'Aucune donnée disponible',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(Map<String, dynamic> item, int index) {
    final visibleFields = _list.fields.where((f) => f.isVisible).toList();
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _getItemTitle(item),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          _getItemSubtitle(item),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: visibleFields.map((field) {
                final value = item[field.fieldKey];
                return _buildFieldRow(field, value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(DynamicListField field, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              field.displayName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatValue(value, field.fieldType),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          if (field.isClickable && value != null)
            IconButton(
              icon: Icon(
                _getActionIcon(field.fieldType),
                size: 16,
                color: Theme.of(context).colorScheme.primaryColor,
              ),
              onPressed: () => _handleFieldAction(field, value),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _editList,
      backgroundColor: Theme.of(context).colorScheme.primaryColor,
      foregroundColor: Colors.white,
      child: const Icon(Icons.edit),
      tooltip: 'Modifier la liste',
    );
  }

  String _getItemTitle(Map<String, dynamic> item) {
    // Essayer de trouver un champ titre approprié
    final titleFields = ['title', 'name', 'fullName', 'firstName'];
    for (final field in titleFields) {
      if (item.containsKey(field) && item[field] != null) {
        return item[field].toString();
      }
    }
    return 'Élément ${item.hashCode}';
  }

  String _getItemSubtitle(Map<String, dynamic> item) {
    // Essayer de trouver un champ sous-titre approprié
    final subtitleFields = ['description', 'email', 'category', 'status'];
    for (final field in subtitleFields) {
      if (item.containsKey(field) && item[field] != null) {
        return item[field].toString();
      }
    }
    return '';
  }

  String _formatValue(dynamic value, String fieldType) {
    if (value == null) return '-';
    
    switch (fieldType) {
      case 'date':
        if (value is DateTime) {
          return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
        }
        break;
      case 'datetime':
        if (value is DateTime) {
          return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
        }
        break;
      case 'boolean':
        return value == true ? 'Oui' : 'Non';
      case 'list':
        if (value is List) {
          return value.join(', ');
        }
        break;
    }
    
    return value.toString();
  }

  IconData _getActionIcon(String fieldType) {
    switch (fieldType) {
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'text':
        return Icons.open_in_new;
      default:
        return Icons.info;
    }
  }

  IconData _getIconForSourceModule(String sourceModule) {
    switch (sourceModule) {
      case 'people':
        return Icons.people;
      case 'groups':
        return Icons.groups;
      case 'events':
        return Icons.event;
      case 'tasks':
        return Icons.task_alt;
      case 'services':
        return Icons.church;
      default:
        return Icons.list_alt;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche'),
        content: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            labelText: 'Rechercher...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
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

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trier par'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _sortField.isEmpty ? null : _sortField,
              decoration: const InputDecoration(
                labelText: 'Champ',
                border: OutlineInputBorder(),
              ),
              items: _list.fields.map((field) {
                return DropdownMenuItem(
                  value: field.fieldKey,
                  child: Text(field.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _sortField = value ?? '');
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sortDirection,
              decoration: const InputDecoration(
                labelText: 'Ordre',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'asc', child: Text('Croissant')),
                DropdownMenuItem(value: 'desc', child: Text('Décroissant')),
              ],
              onChanged: (value) {
                setState(() => _sortDirection = value ?? 'asc');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) async {
    try {
      switch (action) {
        case 'edit':
          _editList();
          break;
        case 'duplicate':
          await _duplicateList();
          break;
        case 'export':
          _exportList();
          break;
        case 'share':
          _shareList();
          break;
        case 'favorite':
          await _toggleFavorite();
          break;
        case 'refresh':
          _loadData();
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _editList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicListBuilderPage(existingList: _list),
      ),
    ).then((result) {
      if (result != null) {
        setState(() => _list = result);
      }
    });
  }

  Future<void> _duplicateList() async {
    final nameController = TextEditingController(text: '${_list.name} (Copie)');
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dupliquer la liste'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom de la nouvelle liste',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Dupliquer'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await DynamicListsFirebaseService.duplicateList(_list.id, newName);
      _showSuccessSnackBar('Liste dupliquée avec succès');
    }
  }

  void _exportList() {
    _showErrorSnackBar('Fonctionnalité d\'export en cours de développement');
  }

  void _shareList() {
    _showErrorSnackBar('Fonctionnalité de partage en cours de développement');
  }

  Future<void> _toggleFavorite() async {
    await DynamicListsFirebaseService.toggleFavorite(_list.id, !_list.isFavorite);
    setState(() {
      _list = _list.copyWith(isFavorite: !_list.isFavorite);
    });
    _showSuccessSnackBar(_list.isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris');
  }

  void _handleFieldAction(DynamicListField field, dynamic value) {
    switch (field.fieldType) {
      case 'email':
        // TODO: Ouvrir l'application email
        _showErrorSnackBar('Fonctionnalité email en cours de développement');
        break;
      case 'phone':
        // TODO: Ouvrir l'application téléphone
        _showErrorSnackBar('Fonctionnalité téléphone en cours de développement');
        break;
      default:
        _showErrorSnackBar('Action non disponible pour ce type de champ');
        break;
    }
  }
}