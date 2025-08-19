import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/page_model.dart';
import '../services/pages_firebase_service.dart';
import '../widgets/page_components/component_renderer.dart';
import '../widgets/custom_page_app_bar.dart';
import 'page_builder_page.dart';
import '../../compatibility/app_theme_bridge.dart';

class PagePreviewPage extends StatefulWidget {
  final CustomPageModel page;

  const PagePreviewPage({
    super.key,
    required this.page,
  });

  @override
  State<PagePreviewPage> createState() => _PagePreviewPageState();
}

class _PagePreviewPageState extends State<PagePreviewPage>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  CustomPageModel? _currentPage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.page;
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
    
    // Enregistrer la vue de la page
    _recordPageView();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _recordPageView() async {
    try {
      await PagesFirebaseService.recordPageView(widget.page.id, null);
    } catch (e) {
      // Erreur silencieuse pour les statistiques
    }
  }

  Future<void> _refreshPageData() async {
    setState(() => _isLoading = true);
    
    try {
      final updatedPage = await PagesFirebaseService.getPage(widget.page.id);
      if (updatedPage != null && mounted) {
        setState(() => _currentPage = updatedPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rafraîchissement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageBuilderPage(page: _currentPage),
      ),
    );

    if (result == true) {
      _refreshPageData();
    }
  }

  Future<void> _publishPage() async {
    if (_currentPage?.status != 'draft') return;

    try {
      await PagesFirebaseService.publishPage(_currentPage!.id);
      _showSnackBar('Page publiée avec succès', Colors.green);
      _refreshPageData();
    } catch (e) {
      _showSnackBar('Erreur lors de la publication: $e', Colors.red);
    }
  }

  Future<void> _duplicatePage() async {
    final newTitle = '${_currentPage!.title} (Copie)';
    final newSlug = '${_currentPage!.slug}-copie';

    try {
      final newPageId = await PagesFirebaseService.duplicatePage(
        _currentPage!.id,
        newTitle,
        newSlug,
      );
      
      _showSnackBar('Page dupliquée avec succès', Colors.green);
      
      // Navigation vers l'éditeur de la nouvelle page
      final newPage = await PagesFirebaseService.getPage(newPageId);
      if (newPage != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PageBuilderPage(page: newPage),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la duplication: $e', Colors.red);
    }
  }

  void _copyPageUrl() {
    final url = 'https://app.churchflow.com/pages/${_currentPage!.slug}';
    Clipboard.setData(ClipboardData(text: url));
    _showSnackBar('URL copiée: /${_currentPage!.slug}', Theme.of(context).colorScheme.primaryColor);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color get _statusColor {
    switch (_currentPage?.status) {
      case 'published':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (_currentPage?.status) {
      case 'published':
        return Icons.public;
      case 'draft':
        return Icons.edit;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPage == null) {
      return Scaffold(
        appBar: const CustomPageAppBar(
          title: 'Page introuvable',
          showBackButton: true,
          showLogo: false,
        ),
        body: const Center(
          child: Text('La page demandée n\'existe pas ou a été supprimée.'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomPageAppBar(
        title: _currentPage!.title,
        showBackButton: true,
        showLogo: false,
        additionalActions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Gérer les actions du menu
              switch (value) {
                case 'edit':
                  // Action éditer
                  break;
                case 'copy_url':
                  // Action copier URL
                  break;
                case 'duplicate':
                  // Action dupliquer
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Modifier'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'copy_url',
                child: ListTile(
                  leading: Icon(Icons.link),
                  title: Text('Copier l\'URL'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  title: Text('Dupliquer'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.copy),
                ),
              ),
              if (_currentPage!.status == 'draft')
                const PopupMenuItem(
                  value: 'publish',
                  child: ListTile(
                    leading: Icon(Icons.publish, color: Colors.green),
                    title: Text('Publier'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Statistiques'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPageData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildPageContent(),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _editPage,
          backgroundColor: Theme.of(context).colorScheme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    // Récupération des paramètres d'arrière-plan
    final backgroundType = _currentPage!.settings['backgroundType'] ?? 'color';
    final backgroundColor = _currentPage!.settings['backgroundColor'] ?? '#FFFFFF';
    final backgroundImageUrl = _currentPage!.settings['backgroundImageUrl'] ?? '';

    Widget pageContent = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la page
          if (_currentPage!.coverImageUrl != null && _currentPage!.coverImageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_currentPage!.coverImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Le titre et la description ne s'affichent plus dans le rendu de la page

                const SizedBox(height: 16),

                // Composants de la page
                if (_currentPage!.components.isEmpty)
                  _buildEmptyState()
                else
                  ..._currentPage!.components.map((component) {
                    final componentSpacing = (_currentPage!.settings['componentSpacing'] ?? 16.0).toDouble();
                    final componentMargin = (_currentPage!.settings['componentMargin'] ?? 0.0).toDouble();
                    return Padding(
                      padding: EdgeInsets.only(bottom: componentSpacing),
                      child: Padding(
                        padding: EdgeInsets.all(componentMargin),
                        child: ComponentRenderer(
                          component: component,
                          isPreview: true,
                        ),
                      ),
                    );
                  }),

                // Espacement de fin
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );

    // Application de l'arrière-plan selon le type
    if (backgroundType == 'color') {
      return Container(
        color: Color(
          int.parse(backgroundColor.replaceFirst('#', '0xFF'))
        ),
        child: pageContent,
      );
    } else if (backgroundType == 'image' && backgroundImageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(backgroundImageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: pageContent,
      );
    } else {
      return pageContent;
    }
  }

  // La méthode _buildPageHeader() a été supprimée car le titre ne s'affiche plus dans le rendu



  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.web, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Page vide',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette page ne contient encore aucun contenu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _editPage,
            icon: const Icon(Icons.edit),
            label: const Text('Ajouter du contenu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }





  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        _editPage();
        break;
      case 'copy_url':
        _copyPageUrl();
        break;
      case 'duplicate':
        _duplicatePage();
        break;
      case 'publish':
        _publishPage();
        break;
      case 'statistics':
        _showStatistics();
        break;
    }
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques de la page'),
        content: const Text(
          'Les statistiques détaillées seront disponibles prochainement.\n\n'
          'Fonctionnalités prévues :\n'
          '• Nombre de vues\n'
          '• Visiteurs uniques\n'
          '• Interactions par composant\n'
          '• Évolution dans le temps',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Demain';
    } else if (difference.inDays == -1) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}