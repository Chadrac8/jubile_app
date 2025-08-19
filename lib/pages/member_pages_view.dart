import 'package:flutter/material.dart';
import '../models/page_model.dart';
import '../services/pages_firebase_service.dart';
import '../widgets/page_components/component_renderer.dart';
import '../widgets/custom_page_app_bar.dart';
import '../theme.dart';

class MemberPagesView extends StatefulWidget {
  final String? pageId; // Pour afficher une page spécifique par ID
  final String? pageSlug; // Pour afficher une page spécifique par slug

  const MemberPagesView({super.key, this.pageId, this.pageSlug});

  @override
  State<MemberPagesView> createState() => _MemberPagesViewState();
}

class _MemberPagesViewState extends State<MemberPagesView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<CustomPageModel> _pages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  Future<void> _loadPages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      if (widget.pageId != null) {
        // Charger une page spécifique par ID
        final page = await PagesFirebaseService.getPage(widget.pageId!);
        if (page != null && page.isPublished) {
          setState(() {
            _pages = [page];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Page non trouvée ou non publiée';
            _isLoading = false;
          });
        }
      } else if (widget.pageSlug != null) {
        // Charger une page spécifique par slug
        final page = await PagesFirebaseService.getPageBySlug(widget.pageSlug!);
        if (page != null && page.isVisible) {
          setState(() {
            _pages = [page];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Page non trouvée ou non disponible';
            _isLoading = false;
          });
        }
      } else {
        // Charger toutes les pages publiques
        final pagesStream = PagesFirebaseService.getPublicPagesStream();
        
        pagesStream.listen(
          (pages) {
            if (mounted) {
              setState(() {
                _pages = pages.where((page) => page.isPublished).toList();
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Erreur lors du chargement des pages: $error';
                _isLoading = false;
              });
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPages() async {
    await _loadPages();
  }

  void _navigateToPage(CustomPageModel page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberPageDetailView(page: page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomPageAppBar(
        title: 'Pages',
        showBackButton: true,
        showLogo: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des pages...',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            SizedBox(height: 16),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPages,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_pages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web_asset_off, size: 64, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text(
              'Aucune page disponible',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aucune page n\'a été publiée pour le moment.',
              style: TextStyle(color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si on affiche une page spécifique, afficher directement son contenu
    if (widget.pageId != null && _pages.isNotEmpty) {
      return MemberPageDetailView(page: _pages.first);
    }

    // Sinon, afficher la liste des pages
    return RefreshIndicator(
      onRefresh: _refreshPages,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return _buildPageCard(_pages[index]);
        },
      ),
    );
  }

  Widget _buildPageCard(CustomPageModel page) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToPage(page),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Image de couverture
            if (page.coverImageUrl != null && page.coverImageUrl!.isNotEmpty)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(page.coverImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    page.iconName != null ? Icons.web : Icons.article,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    page.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description
                  if (page.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      page.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Flèche de navigation
                  Row(
                    children: [
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
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
}

class MemberPageDetailView extends StatefulWidget {
  final CustomPageModel page;

  const MemberPageDetailView({
    super.key,
    required this.page,
  });

  @override
  State<MemberPageDetailView> createState() => _MemberPageDetailViewState();
}

class _MemberPageDetailViewState extends State<MemberPageDetailView> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Enregistrer la vue de la page
    _recordPageView();
  }

  Future<void> _recordPageView() async {
    try {
      await PagesFirebaseService.recordPageView(widget.page.id, null);
    } catch (e) {
      // Erreur silencieuse pour les statistiques
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomPageAppBar(
        title: widget.page.title,
        showBackButton: true,
        showLogo: false,
        additionalActions: [
          IconButton(
            onPressed: _shareePage,
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPageContent(),
    );
  }

  Widget _buildPageComponents() {
    final layoutType = widget.page.settings['layoutType'] ?? 'linear';
    
    if (layoutType == 'grid') {
      return _buildGridLayoutComponents();
    } else {
      return _buildLinearLayoutComponents();
    }
  }

  Widget _buildLinearLayoutComponents() {
    final componentSpacing = (widget.page.settings['componentSpacing'] ?? 16.0).toDouble();
    final componentMargin = (widget.page.settings['componentMargin'] ?? 0.0).toDouble();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.page.components.map((component) {
        return Padding(
          padding: EdgeInsets.only(bottom: componentSpacing),
          child: Padding(
            padding: EdgeInsets.all(componentMargin),
            child: ComponentRenderer(
              component: component,
              isPreview: false,
              isGridMode: false,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridLayoutComponents() {
    if (widget.page.components.isEmpty) return const SizedBox();
    
    final gridColumns = (widget.page.settings['gridColumns'] as num? ?? 2).toInt();
    final componentSpacing = (widget.page.settings['componentSpacing'] ?? 16.0).toDouble();
    final componentMargin = (widget.page.settings['componentMargin'] ?? 0.0).toDouble();
    
    List<Widget> gridItems = [];
    
    for (int i = 0; i < widget.page.components.length; i += gridColumns) {
      List<Widget> rowItems = [];
      
      for (int j = 0; j < gridColumns && (i + j) < widget.page.components.length; j++) {
        final component = widget.page.components[i + j];
        rowItems.add(
          Expanded(
            child: Container(
              margin: EdgeInsets.all(componentMargin / 2),
              child: ComponentRenderer(
                component: component,
                isPreview: false,
                isGridMode: true,
              ),
            ),
          ),
        );
      }
      
      // Remplir la ligne si elle n'est pas complète avec des espaces vides
      while (rowItems.length < gridColumns) {
        rowItems.add(
          Expanded(
            child: Container(
              margin: EdgeInsets.all(componentMargin / 2),
              child: const SizedBox(),
            ),
          ),
        );
      }
      
      gridItems.add(
        Container(
          margin: EdgeInsets.only(bottom: componentSpacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rowItems,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: gridItems,
    );
  }

  Widget _buildPageContent() {
    // Récupération des paramètres d'arrière-plan
    final backgroundType = widget.page.settings['backgroundType'] ?? 'color';
    final backgroundColor = widget.page.settings['backgroundColor'] ?? '#FFFFFF';
    final backgroundImageUrl = widget.page.settings['backgroundImageUrl'] ?? '';

    Widget pageContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec image de couverture
          if (widget.page.coverImageUrl != null && widget.page.coverImageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.page.coverImageUrl!),
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

                // Composants de la page
                if (widget.page.components.isEmpty)
                  _buildEmptyContent()
                else
                  _buildPageComponents(),
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

  Widget _buildEmptyContent() {
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
            'Contenu à venir',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette page sera bientôt mise à jour avec du contenu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _shareePage() {
    // Fonctionnalité de partage
    // Peut utiliser le package share_plus pour partager l'URL de la page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de la page : /${widget.page.slug}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}