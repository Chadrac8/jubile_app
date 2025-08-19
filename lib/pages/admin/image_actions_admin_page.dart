import 'package:flutter/material.dart';
import '../../models/page_model.dart';
import '../../models/image_action_model.dart';
import '../../services/pages_firebase_service.dart';
import '../../widgets/page_components/component_editor.dart';

class ImageActionsAdminPage extends StatefulWidget {
  const ImageActionsAdminPage({super.key});

  @override
  State<ImageActionsAdminPage> createState() => _ImageActionsAdminPageState();
}

class _ImageActionsAdminPageState extends State<ImageActionsAdminPage> {
  bool _isLoading = false;
  List<CustomPageModel> _pages = [];
  List<PageComponent> _imageComponentsWithActions = [];

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    setState(() => _isLoading = true);
    
    try {
      final pages = await PagesFirebaseService.getPagesStream().first;
      final imageComponents = <PageComponent>[];
      
      for (final page in pages) {
        for (final component in page.components) {
          if (component.type == 'image' && component.data['action'] != null) {
            imageComponents.add(component);
          }
        }
      }
      
      setState(() {
        _pages = pages;
        _imageComponentsWithActions = imageComponents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Actions d\'Image'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExamples,
        icon: const Icon(Icons.visibility),
        label: const Text('Voir Exemples'),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 16),
        Expanded(
          child: _imageComponentsWithActions.isEmpty
              ? _buildEmptyState()
              : _buildImageActionsList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final totalPages = _pages.length;
    final pagesWithImageActions = _pages.where((page) => 
        page.components.any((c) => c.type == 'image' && c.data['action'] != null)
    ).length;
    final totalImageActions = _imageComponentsWithActions.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Pages Totales',
              value: totalPages.toString(),
              icon: Icons.pages,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Pages avec Actions',
              value: pagesWithImageActions.toString(),
              icon: Icons.touch_app,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Actions Totales',
              value: totalImageActions.toString(),
              icon: Icons.link,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune action d\'image configurée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des actions à vos images via le Constructeur de Pages',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showExamples,
            icon: const Icon(Icons.school),
            label: const Text('Voir les Exemples'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageActionsList() {
    // Grouper par page
    final pageGroups = <String, List<PageComponent>>{};
    final pageMap = <String, CustomPageModel>{};
    
    for (final page in _pages) {
      pageMap[page.id] = page;
      for (final component in page.components) {
        if (component.type == 'image' && component.data['action'] != null) {
          pageGroups.putIfAbsent(page.id, () => []).add(component);
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pageGroups.length,
      itemBuilder: (context, index) {
        final pageId = pageGroups.keys.elementAt(index);
        final page = pageMap[pageId]!;
        final components = pageGroups[pageId]!;
        
        return _buildPageGroup(page, components);
      },
    );
  }

  Widget _buildPageGroup(CustomPageModel page, List<PageComponent> components) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(
          Icons.pages,
          color: page.isPublished ? Colors.green : Colors.orange,
        ),
        title: Text(
          page.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${components.length} action(s) d\'image • ${page.statusLabel}',
        ),
        children: components.map((component) => _buildActionItem(page, component)).toList(),
      ),
    );
  }

  Widget _buildActionItem(CustomPageModel page, PageComponent component) {
    final action = ImageAction.fromMap(component.data['action']);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActionColor(action.type),
        child: Icon(
          _getActionIcon(action.type),
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(component.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getActionDescription(action)),
          if (action.parameters != null && action.parameters!.isNotEmpty)
            Text(
              'Paramètres: ${action.parameters!.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleActionMenu(value, page, component),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'test',
            child: ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Tester'),
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
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Supprimer'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String type) {
    switch (type) {
      case 'url':
        return Colors.blue;
      case 'member_page':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'url':
        return Icons.link;
      case 'member_page':
        return Icons.arrow_forward;
      default:
        return Icons.touch_app;
    }
  }

  String _getActionDescription(ImageAction action) {
    switch (action.type) {
      case 'url':
        return 'Lien: ${action.url}';
      case 'member_page':
        final page = MemberPagesRegistry.findByKey(action.memberPage!);
        return 'Page: ${page?.name ?? action.memberPage}';
      default:
        return 'Action: ${action.type}';
    }
  }

  void _handleActionMenu(String action, CustomPageModel page, PageComponent component) {
    switch (action) {
      case 'test':
        _testAction(component);
        break;
      case 'edit':
        _editAction(page, component);
        break;
      case 'delete':
        _deleteAction(page, component);
        break;
    }
  }

  void _testAction(PageComponent component) {
    final action = ImageAction.fromMap(component.data['action']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test de l\'action: ${_getActionDescription(action)}'),
        action: SnackBarAction(
          label: 'Exécuter',
          onPressed: () {
            // TODO: Implémenter l'exécution de test
          },
        ),
      ),
    );
  }

  void _editAction(CustomPageModel page, PageComponent component) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${component.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ComponentEditor(
            component: component,
            onSave: (updatedComponent) async {
              // TODO: Implémenter la sauvegarde
              Navigator.of(context).pop();
              _loadPages();
            },
          ),
        ),
      ),
    );
  }

  void _deleteAction(CustomPageModel page, PageComponent component) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'action'),
        content: Text('Voulez-vous supprimer l\'action de "${component.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implémenter la suppression
              Navigator.of(context).pop();
              _loadPages();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showExamples() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Placeholder(), // Exemple à remplacer ou supprimer
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide - Actions d\'Image'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Les actions d\'image permettent d\'ajouter de l\'interactivité à vos pages personnalisées.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Types d\'actions disponibles:'),
              SizedBox(height: 8),
              Text('• Lien URL: Ouvre un site web externe'),
              Text('• Page Membre: Navigue vers une page de l\'application'),
              SizedBox(height: 16),
              Text('Pour ajouter une action:'),
              SizedBox(height: 8),
              Text('1. Allez dans le Constructeur de Pages'),
              Text('2. Sélectionnez un composant Image'),
              Text('3. Activez "Action au clic"'),
              Text('4. Configurez votre action'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: _showExamples,
            child: const Text('Voir Exemples'),
          ),
        ],
      ),
    );
  }
}