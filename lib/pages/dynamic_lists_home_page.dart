import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dynamic_list_model.dart';
import '../services/dynamic_lists_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import '../widgets/custom_card.dart';
import 'dynamic_list_builder_page.dart';
import 'dynamic_list_detail_page.dart';

/// Page d'accueil des listes dynamiques
class DynamicListsHomePage extends StatefulWidget {
  const DynamicListsHomePage({Key? key}) : super(key: key);

  @override
  State<DynamicListsHomePage> createState() => _DynamicListsHomePageState();
}

class _DynamicListsHomePageState extends State<DynamicListsHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<DynamicListModel> _myLists = [];
  List<DynamicListModel> _sharedLists = [];
  List<DynamicListModel> _favoriteLists = [];
  List<DynamicListModel> _recentLists = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Toutes';

  final List<String> _categories = [
    'Toutes',
    'Personnes',
    'Groupes',
    'Événements',
    'Tâches',
    'Ministère',
    'Administration',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    
    try {
      final userLists = await DynamicListsFirebaseService.getUserLists();
      final sharedLists = await DynamicListsFirebaseService.getSharedLists();
      
      setState(() {
        _myLists = userLists;
        _sharedLists = sharedLists;
        _favoriteLists = [...userLists, ...sharedLists]
            .where((list) => list.isFavorite)
            .toList();
        _recentLists = [...userLists, ...sharedLists]
            .where((list) => list.lastUsed != null)
            .toList()
            ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des listes: $e');
    }
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

  List<DynamicListModel> _getFilteredLists(List<DynamicListModel> lists) {
    var filtered = lists;

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((list) {
        return list.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               list.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtrer par catégorie
    if (_selectedCategory != 'Toutes') {
      filtered = filtered.where((list) {
        return list.category == _selectedCategory.toLowerCase() ||
               list.sourceModule == _selectedCategory.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildTabView(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[700],
      elevation: 0,
      title: Text(
        'Listes Dynamiques',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        // Bouton de recherche
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _showSearchDialog,
          tooltip: 'Rechercher',
        ),
        // Menu templates
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'templates',
              child: ListTile(
                leading: Icon(Icons.dashboard_customize),
                title: Text('Templates'),
                subtitle: Text('Créer à partir d\'un modèle'),
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Actualiser'),
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Aide'),
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Rechercher une liste...',
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
              underline: Container(),
              dropdownColor: Colors.blue[700],
              style: const TextStyle(color: Colors.white),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'Mes listes'),
        Tab(text: 'Partagées'),
        Tab(text: 'Favoris'),
        Tab(text: 'Récentes'),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildListView(_getFilteredLists(_myLists), 'Aucune liste créée'),
        _buildListView(_getFilteredLists(_sharedLists), 'Aucune liste partagée'),
        _buildListView(_getFilteredLists(_favoriteLists), 'Aucun favori'),
        _buildListView(_getFilteredLists(_recentLists), 'Aucune utilisation récente'),
      ],
    );
  }

  Widget _buildListView(List<DynamicListModel> lists, String emptyMessage) {
    if (lists.isEmpty) {
      return _buildEmptyView(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _loadLists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lists.length,
        itemBuilder: (context, index) {
          return _buildListCard(lists[index]);
        },
      ),
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewList,
            icon: const Icon(Icons.add),
            label: const Text('Créer une liste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(DynamicListModel list) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getIconForSourceModule(list.sourceModule),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          list.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              list.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  list.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                if (list.lastUsed != null) ...[
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Utilisée ${_formatLastUsed(list.lastUsed!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (list.isFavorite)
              Icon(Icons.star, color: Colors.amber, size: 20),
            if (list.isPublic)
              Icon(Icons.public, color: Colors.green, size: 20),
            if (list.sharedWith.isNotEmpty)
              Icon(Icons.share, color: Colors.blue, size: 20),
            PopupMenuButton<String>(
              onSelected: (action) => _handleListAction(action, list),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('Voir'),
                  ),
                ),
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
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Partager'),
                  ),
                ),
                PopupMenuItem(
                  value: 'favorite',
                  child: ListTile(
                    leading: Icon(list.isFavorite ? Icons.star : Icons.star_border),
                    title: Text(list.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _openList(list),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _createNewList,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle liste'),
    );
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

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche avancée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                labelText: 'Rechercher...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'templates':
        _showTemplatesDialog();
        break;
      case 'refresh':
        _loadLists();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _showTemplatesDialog() {
    final templates = DynamicListTemplatesService.getAllTemplates();
    final templatesByCategory = DynamicListTemplatesService.getTemplatesByCategory();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              AppBar(
                title: const Text('Templates de listes'),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: templatesByCategory.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(
                        entry.key,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      children: entry.value.map((template) {
                        return ListTile(
                          leading: Icon(_getIconForSourceModule(template.sourceModule)),
                          title: Text(template.name),
                          subtitle: Text(template.description),
                          onTap: () {
                            Navigator.pop(context);
                            _createFromTemplate(template);
                          },
                          trailing: const Icon(Icons.arrow_forward_ios),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide - Listes Dynamiques'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Les listes dynamiques vous permettent de créer des vues personnalisées de vos données.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('• Créez des listes sur mesure à partir de vos modules'),
              Text('• Appliquez des filtres et des tris'),
              Text('• Partagez vos listes avec d\'autres utilisateurs'),
              Text('• Utilisez des templates prédéfinis'),
              Text('• Exportez vos données'),
              SizedBox(height: 16),
              Text(
                'Pour commencer, cliquez sur le bouton + ou choisissez un template.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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

  void _handleListAction(String action, DynamicListModel list) async {
    try {
      switch (action) {
        case 'view':
          _openList(list);
          break;
        case 'edit':
          _editList(list);
          break;
        case 'duplicate':
          await _duplicateList(list);
          break;
        case 'share':
          _shareList(list);
          break;
        case 'favorite':
          await _toggleFavorite(list);
          break;
        case 'delete':
          await _deleteList(list);
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _createNewList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DynamicListBuilderPage(),
      ),
    ).then((_) => _loadLists());
  }

  void _createFromTemplate(DynamicListTemplate template) {
    final user = AuthService.currentUser;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicListBuilderPage(
          template: template,
        ),
      ),
    ).then((_) => _loadLists());
  }

  void _openList(DynamicListModel list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicListDetailPage(list: list),
      ),
    );
  }

  void _editList(DynamicListModel list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicListBuilderPage(existingList: list),
      ),
    ).then((_) => _loadLists());
  }

  Future<void> _duplicateList(DynamicListModel list) async {
    final nameController = TextEditingController(text: '${list.name} (Copie)');
    
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
      await DynamicListsFirebaseService.duplicateList(list.id, newName);
      _showSuccessSnackBar('Liste dupliquée avec succès');
      _loadLists();
    }
  }

  void _shareList(DynamicListModel list) {
    // TODO: Implémenter le partage de liste
    _showErrorSnackBar('Fonctionnalité de partage en cours de développement');
  }

  Future<void> _toggleFavorite(DynamicListModel list) async {
    await DynamicListsFirebaseService.toggleFavorite(list.id, !list.isFavorite);
    _showSuccessSnackBar(list.isFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris');
    _loadLists();
  }

  Future<void> _deleteList(DynamicListModel list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la liste'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${list.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DynamicListsFirebaseService.deleteList(list.id);
      _showSuccessSnackBar('Liste supprimée');
      _loadLists();
    }
  }
}