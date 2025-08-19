import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/page_model.dart';

import '../services/pages_firebase_service.dart';
import '../widgets/page_components/component_editor.dart';
import '../widgets/page_components/component_renderer.dart';
import '../widgets/image_picker_widget.dart';

import '../../compatibility/app_theme_bridge.dart';

class PageBuilderPage extends StatefulWidget {
  final CustomPageModel? page;
  final PageTemplate? template;

  const PageBuilderPage({
    super.key,
    this.page,
    this.template,
  });

  @override
  State<PageBuilderPage> createState() => _PageBuilderPageState();
}

class _PageBuilderPageState extends State<PageBuilderPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _slugController = TextEditingController();
  
  // Form values
  String? _iconName;
  String? _coverImageUrl;
  int _displayOrder = 0;
  String _status = 'draft';
  String _visibility = 'public';
  List<String> _visibilityTargets = [];
  DateTime? _publishDate;
  DateTime? _unpublishDate;
  List<PageComponent> _components = [];
  
  // Grid layout settings
  String _layoutType = 'linear'; // 'linear' ou 'grid'
  int _gridColumns = 2;
  double _gridSpacing = 16;
  Map<String, dynamic> _settings = {};
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isPreviewMode = false;
  
  // Configuration espacement et marges
  double _componentSpacing = 16.0; // Espacement entre composants
  double _componentMargin = 0.0;   // Marge autour des composants
  
  // Configuration arrière-plan de page
  String _backgroundType = 'color'; // 'color' ou 'image'
  String _backgroundColor = '#FFFFFF'; // Couleur d'arrière-plan
  String _backgroundImageUrl = ''; // URL de l'image d'arrière-plan
  


  final Map<String, List<Map<String, dynamic>>> _componentCategories = {
    'Contenu textuel': [
      {'type': 'text', 'label': 'Texte', 'icon': Icons.text_fields, 'color': Colors.blue, 'description': 'Paragraphe de texte avec formatage'},
      {'type': 'scripture', 'label': 'Verset biblique', 'icon': Icons.menu_book, 'color': Colors.indigo, 'description': 'Citation biblique avec référence'},
      {'type': 'banner', 'label': 'Bannière', 'icon': Icons.campaign, 'color': Colors.amber, 'description': 'Message d\'annonce avec style'},
      {'type': 'quote', 'label': 'Citation', 'icon': Icons.format_quote, 'color': Colors.deepPurple, 'description': 'Citation avec auteur et contexte'},

    ],
    'Médias': [
      {'type': 'image', 'label': 'Image', 'icon': Icons.image, 'color': Colors.green, 'description': 'Photo ou illustration'},
      {'type': 'video', 'label': 'Vidéo', 'icon': Icons.video_library, 'color': Colors.red, 'description': 'Vidéo YouTube ou fichier'},
      {'type': 'audio', 'label': 'Audio', 'icon': Icons.music_note, 'color': Colors.pink, 'description': 'Fichier audio ou musique'},
    ],
    'Interactif': [
      {'type': 'button', 'label': 'Bouton', 'icon': Icons.smart_button, 'color': Colors.orange, 'description': 'Bouton d\'action cliquable'},
      {'type': 'html', 'label': 'HTML', 'icon': Icons.code, 'color': Colors.cyan, 'description': 'Code HTML personnalisé'},
      {'type': 'webview', 'label': 'WebView', 'icon': Icons.web, 'color': Colors.blue, 'description': 'Intégrer une page web externe dans votre application'},
    ],

    'Organisation': [
      {'type': 'list', 'label': 'Liste', 'icon': Icons.list, 'color': Colors.purple, 'description': 'Liste d\'éléments à puces ou numérotée'},
      {'type': 'grid_container', 'label': 'Container Grid', 'icon': Icons.grid_view, 'color': Colors.deepPurple, 'description': 'Container configurable pour organiser des composants en grille'},
      {'type': 'map', 'label': 'Carte', 'icon': Icons.map, 'color': Colors.brown, 'description': 'Carte géographique interactive'},
      {'type': 'googlemap', 'label': 'Google Map', 'icon': Icons.location_on, 'color': Colors.redAccent, 'description': 'Carte Google avec reconnaissance d\'adresse'},
      {'type': 'groups', 'label': 'Groupes', 'icon': Icons.groups, 'color': Colors.deepOrange, 'description': 'Affichage et gestion des groupes d\'utilisateurs'},
      {'type': 'events', 'label': 'Evénements', 'icon': Icons.event, 'color': Colors.green, 'description': 'Calendrier et liste d\'événements'},




      {'type': 'prayer_wall', 'label': 'Mur de prière', 'icon': Icons.favorite, 'color': Colors.pink, 'description': 'Mur de prière interactif avec demandes, témoignages et communauté'},
    ],
    'Composants Grid': [
      {'type': 'grid_card', 'label': 'Carte Grid', 'icon': Icons.crop_landscape, 'color': Colors.deepPurple, 'description': 'Carte optimisée pour affichage en grille'},
      {'type': 'grid_stat', 'label': 'Statistique Grid', 'icon': Icons.analytics, 'color': Colors.teal, 'description': 'Statistique compacte pour grille'},
      {'type': 'grid_icon_text', 'label': 'Icône + Texte Grid', 'icon': Icons.text_rotate_vertical, 'color': Colors.indigo, 'description': 'Icône avec texte pour disposition en grille'},
      {'type': 'grid_image_card', 'label': 'Image Card Grid', 'icon': Icons.image_aspect_ratio, 'color': Colors.orange, 'description': 'Carte avec image optimisée pour grille'},
      {'type': 'grid_progress', 'label': 'Progression Grid', 'icon': Icons.pie_chart, 'color': Colors.green, 'description': 'Indicateur de progression pour grille'},
    ],
  };

  final List<String> _visibilityOptions = [
    'public',
    'members',
    'groups',
    'roles',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePage();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _slugController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Forcer la mise à jour de l'UI quand l'onglet change
      });
    });
    _animationController.forward();
  }

  void _initializePage() {
    if (widget.page != null) {
      // Mode édition
      final page = widget.page!;
      _titleController.text = page.title;
      _descriptionController.text = page.description;
      _slugController.text = page.slug;
      _iconName = page.iconName;
      _coverImageUrl = page.coverImageUrl;
      _displayOrder = page.displayOrder;
      _status = page.status;
      _visibility = page.visibility;
      _visibilityTargets = List.from(page.visibilityTargets);
      _publishDate = page.publishDate;
      _unpublishDate = page.unpublishDate;
      _components = List.from(page.components);
      _settings = Map.from(page.settings);
      
      // Charger les paramètres d'espacement
      _componentSpacing = (_settings['componentSpacing'] ?? 16.0).toDouble();
      _componentMargin = (_settings['componentMargin'] ?? 0.0).toDouble();
      _layoutType = _settings['layoutType'] ?? 'linear';
      _gridColumns = _settings['gridColumns'] ?? 2;
      _gridSpacing = (_settings['gridSpacing'] ?? 16.0).toDouble();
      
      // Charger les paramètres d'arrière-plan
      _backgroundType = _settings['backgroundType'] ?? 'color';
      _backgroundColor = _settings['backgroundColor'] ?? '#FFFFFF';
      _backgroundImageUrl = _settings['backgroundImageUrl'] ?? '';

    } else if (widget.template != null) {
      // Mode création depuis template
      final template = widget.template!;
      _titleController.text = 'Nouvelle page - ${template.name}';
      _slugController.text = _generateSlug('nouvelle-page-${template.name}');
      _components = template.components.map((comp) => PageComponent(
        id: _uuid.v4(),
        type: comp.type,
        name: comp.name,
        data: Map.from(comp.data),
        styling: Map.from(comp.styling),
        settings: Map.from(comp.settings),
        order: comp.order,
      )).toList();
      _settings = Map.from(template.defaultSettings);
    } else {
      // Mode création nouvelle page
      _titleController.text = '';
      _slugController.text = '';
    }

    // Listener pour détecter les changements
    _titleController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _slugController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _savePage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Mettre à jour les settings avec les paramètres de mise en page
      _settings['componentSpacing'] = _componentSpacing;
      _settings['componentMargin'] = _componentMargin;
      _settings['layoutType'] = _layoutType;
      _settings['gridColumns'] = _gridColumns;
      _settings['gridSpacing'] = _gridSpacing;
      
      // Mettre à jour les settings avec les paramètres d'arrière-plan
      _settings['backgroundType'] = _backgroundType;
      _settings['backgroundColor'] = _backgroundColor;
      _settings['backgroundImageUrl'] = _backgroundImageUrl;
      
      final page = CustomPageModel(
        id: widget.page?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        slug: _slugController.text.trim(),
        iconName: _iconName,
        coverImageUrl: _coverImageUrl,
        displayOrder: _displayOrder,
        status: _status,
        visibility: _visibility,
        visibilityTargets: _visibilityTargets,
        publishDate: _publishDate,
        unpublishDate: _unpublishDate,
        components: _components,
        settings: _settings,
        createdAt: widget.page?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.page != null) {
        await PagesFirebaseService.updatePage(page);
      } else {
        await PagesFirebaseService.createPage(page);
      }

      setState(() => _hasUnsavedChanges = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.page != null ? 'Page mise à jour' : 'Page créée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
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

  void _addComponent(String type) {
    final component = PageComponent(
      id: _uuid.v4(),
      type: type,
      name: _getDefaultComponentName(type),
      order: _components.length,
      data: _getDefaultComponentData(type),
      children: type == 'grid_container' ? [] : const [], // Initialiser avec une liste vide pour les containers
    );

    setState(() {
      _components.add(component);
      _markAsChanged();
    });
  }

  void _addGridDemo() {
    final demoComponents = [
      PageComponent(
        id: _uuid.v4(),
        type: 'grid_stat',
        name: 'Statistique Membres',
        order: _components.length,
        data: {
          'title': 'Membres',
          'value': '247',
          'unit': 'personnes',
          'trend': 'up',
          'color': '#4CAF50',
          'iconName': 'people',
        },
      ),
      PageComponent(
        id: _uuid.v4(),
        type: 'grid_stat',
        name: 'Statistique Événements',
        order: _components.length + 1,
        data: {
          'title': 'Événements',
          'value': '12',
          'unit': 'ce mois',
          'trend': 'up',
          'color': '#2196F3',
          'iconName': 'event',
        },
      ),
      PageComponent(
        id: _uuid.v4(),
        type: 'grid_icon_text',
        name: 'Culte Dominical',
        order: _components.length + 2,
        data: {
          'iconName': 'church',
          'title': 'Culte Dominical',
          'description': 'Chaque dimanche à 10h00',
          'iconColor': '#FF5722',
          'textAlign': 'center',
        },
      ),
      PageComponent(
        id: _uuid.v4(),
        type: 'grid_icon_text',
        name: 'Étude Biblique',
        order: _components.length + 3,
        data: {
          'iconName': 'bible',
          'title': 'Étude Biblique',
          'description': 'Mercredi à 19h30',
          'iconColor': '#9C27B0',
          'textAlign': 'center',
        },
      ),
      PageComponent(
        id: _uuid.v4(),
        type: 'grid_progress',
        name: 'Objectif Annuel',
        order: _components.length + 4,
        data: {
          'title': 'Objectif Annuel',
          'progress': 0.68,
          'showPercentage': true,
          'color': '#FF9800',
          'backgroundColor': '#FFF3E0',
        },
      ),
      PageComponent(
        id: _uuid.v4(),
        type: 'grid_card',
        name: 'Bienvenue',
        order: _components.length + 5,
        data: {
          'title': 'Bienvenue',
          'subtitle': 'Nouvelle église',
          'description': 'Découvrez notre communauté',
          'iconName': 'favorite',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
        },
      ),
    ];

    setState(() {
      _components.addAll(demoComponents);
      _markAsChanged();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exemples de composants Grid ajoutés !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getDefaultComponentName(String type) {
    // Rechercher dans toutes les catégories
    for (final components in _componentCategories.values) {
      for (final component in components) {
        if (component['type'] == type) {
          return 'Nouveau ${component['label']}';
        }
      }
    }
    return 'Nouveau composant';
  }

  Map<String, dynamic> _getDefaultComponentData(String type) {
    switch (type) {
      case 'text':
        return {
          'content': 'Votre texte ici...',
          'fontSize': 16,
          'textAlign': 'left',
          'fontWeight': 'normal',
        };
      case 'image':
        return {
          'url': '',
          'alt': '',
          'width': double.infinity,
          'height': 200,
          'fit': 'cover',
        };
      case 'button':
        return {
          'text': 'Cliquez ici',
          'url': '',
          'style': 'primary',
          'size': 'medium',
        };
      case 'video':
        return {
          'url': '',
          'title': '',
          'autoplay': false,
        };
      case 'list':
        return {
          'title': 'Liste d\'éléments',
          'items': [],
          'listType': 'simple',
        };
      case 'form':
        return {
          'formId': '',
          'title': 'Formulaire',
        };
      case 'scripture':
        return {
          'verse': '',
          'reference': '',
          'version': 'LSG',
        };
      case 'banner':
        return {
          'title': 'Titre de la bannière',
          'subtitle': '',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
        };
      case 'map':
        return {
          'address': '',
          'latitude': 0.0,
          'longitude': 0.0,
          'zoom': 15,
        };
      case 'video':
        return {
          'url': '',
          'title': '',
          'playbackMode': 'integrated',
          'autoplay': false,
          'autoPlay': false,
          'loop': false,
          'mute': false,
          'hideControls': false,
          'showControls': true,
        };
      case 'audio':
        return {
          'source_type': 'direct',
          'url': '',
          'soundcloud_url': '',
          'title': '',
          'artist': '',
          'duration': '',
          'description': '',
          'playbackMode': 'integrated',
          'autoplay': false,
          'autoPlay': false,
          'showComments': true,
          'color': 'ff5500',
        };
      case 'grid_card':
        return {
          'title': 'Titre de la carte',
          'subtitle': 'Sous-titre',
          'description': 'Description courte...',
          'iconName': 'star',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
        };
      case 'grid_stat':
        return {
          'title': 'Statistique',
          'value': '42',
          'unit': '',
          'trend': 'up', // up, down, stable
          'color': '#4CAF50',
          'iconName': 'trending_up',
        };
      case 'grid_icon_text':
        return {
          'iconName': 'favorite',
          'title': 'Titre',
          'description': 'Description',
          'iconColor': '#FF5722',
          'textAlign': 'center',
        };
      case 'grid_image_card':
        return {
          'imageUrl': '',
          'title': 'Titre de l\'image',
          'description': 'Description de l\'image',
          'imageHeight': 120,
        };
      case 'grid_progress':
        return {
          'title': 'Progression',
          'progress': 0.75, // 0.0 à 1.0
          'showPercentage': true,
          'color': '#2196F3',
          'backgroundColor': '#E3F2FD',
        };
      case 'grid_container':
        return {
          'columns': 2,
          'mainAxisSpacing': 12.0,
          'crossAxisSpacing': 12.0,
          'childAspectRatio': 1.0,
          'padding': 16.0,
        };
      default:
        return {};
    }
  }

  void _editComponent(PageComponent component) {
    showDialog(
      context: context,
      builder: (context) => ComponentEditor(
        component: component,
        onSave: (updatedComponent) {
          setState(() {
            final index = _components.indexWhere((c) => c.id == component.id);
            if (index != -1) {
              _components[index] = updatedComponent;
              _markAsChanged();
            }
          });
        },
      ),
    );
  }

  void _deleteComponent(PageComponent component) {
    setState(() {
      _components.removeWhere((c) => c.id == component.id);
      // Réorganiser les ordres
      for (int i = 0; i < _components.length; i++) {
        _components[i] = _components[i].copyWith(order: i);
      }
      _markAsChanged();
    });
  }

  void _reorderComponents(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final component = _components.removeAt(oldIndex);
      _components.insert(newIndex, component);
      
      // Mettre à jour les ordres
      for (int i = 0; i < _components.length; i++) {
        _components[i] = _components[i].copyWith(order: i);
      }
      _markAsChanged();
    });
  }

  void _togglePreview() {
    setState(() => _isPreviewMode = !_isPreviewMode);
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
          'Vous avez des modifications non sauvegardées. '
          'Voulez-vous quitter sans sauvegarder ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter sans sauvegarder'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
              _savePage();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.page != null ? 'Modifier la page' : 'Nouvelle page'),
          backgroundColor: Theme.of(context).colorScheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _togglePreview,
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
              tooltip: _isPreviewMode ? 'Mode édition' : 'Aperçu',
            ),
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sauvegarder'),
                ),
              ),
          ],
        ),
        body: _isPreviewMode ? _buildPreview() : _buildTabbedEditor(),
        floatingActionButton: !_isPreviewMode && _tabController.index == 1
            ? FloatingActionButton(
                onPressed: _showComponentSelector,
                backgroundColor: Theme.of(context).colorScheme.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildTabbedEditor() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Barre d'onglets
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Theme.of(context).colorScheme.primaryColor,
                indicatorWeight: 3.0,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.settings),
                    text: 'Informations de la page',
                  ),
                  Tab(
                    icon: Icon(Icons.extension),
                    text: 'Composants',
                  ),
                ],
              ),
            ),
            
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet 1: Informations de la page (combiné)
                  _buildPageInfoTab(),
                  
                  // Onglet 2: Composants uniquement
                  _buildComponentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            // Panneau de configuration (gauche)
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: _buildConfigPanel(),
            ),
            
            // Zone d'édition (droite)
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: _buildComponentsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout() {
    if (_components.isEmpty) return const SizedBox();
    
    // Créer une grille avec les composants
    List<Widget> gridItems = [];
    
    for (int i = 0; i < _components.length; i += _gridColumns) {
      List<Widget> rowItems = [];
      
      for (int j = 0; j < _gridColumns && (i + j) < _components.length; j++) {
        final component = _components[i + j];
        rowItems.add(
          Expanded(
            child: Container(
              margin: EdgeInsets.all(_componentMargin / 2),
              child: ComponentRenderer(
  component: component,
  isGridMode: true,
),
            ),
          ),
        );
      }
      
      // Remplir la ligne si elle n'est pas complète avec des espaces vides
      while (rowItems.length < _gridColumns) {
        rowItems.add(
          Expanded(
            child: Container(
              margin: EdgeInsets.all(_componentMargin / 2),
              child: const SizedBox(),
            ),
          ),
        );
      }
      
      gridItems.add(
        Container(
          margin: EdgeInsets.only(bottom: _componentSpacing),
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

  Widget _buildPreview() {
    Widget previewContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la page
          if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(_coverImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Le titre et la description ne s'affichent plus dans la prévisualisation
          
          const SizedBox(height: 16),
          
          // Composants - Linear ou Grid selon le choix
          if (_layoutType == 'linear') ...[
            ..._components.map((component) => Padding(
              padding: EdgeInsets.only(bottom: _componentSpacing),
              child: Padding(
                padding: EdgeInsets.all(_componentMargin),
                child: ComponentRenderer(
                  component: component,
                  isGridMode: false,
                ),
              ),
            )),
          ] else if (_layoutType == 'grid' && _components.isNotEmpty) ...[
            _buildGridLayout(),
          ],
        ],
      ),
    );

    // Application de l'arrière-plan selon le type
    if (_backgroundType == 'color') {
      return Container(
        color: Color(
          int.parse(_backgroundColor.replaceFirst('#', '0xFF'))
        ),
        child: previewContent,
      );
    } else if (_backgroundType == 'image' && _backgroundImageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(_backgroundImageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: previewContent,
      );
    } else {
      return Container(
        color: Colors.white,
        child: previewContent,
      );
    }
  }

  Widget _buildConfigPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales
            _buildSection(
              title: 'Informations générales',
              icon: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la page *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre est requis';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_slugController.text.isEmpty || 
                        _slugController.text == _generateSlug(_titleController.text)) {
                      _slugController.text = _generateSlug(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildCoverImageSection(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _slugController,
                  decoration: const InputDecoration(
                    labelText: 'URL personnalisée *',
                    prefixText: '/',
                    border: OutlineInputBorder(),
                    helperText: 'Ex: bienvenue, jeunesse, contact',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'URL est requise';
                    }
                    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                      return 'Seules les lettres, chiffres et tirets sont autorisés';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Paramètres de visibilité
            _buildSection(
              title: 'Visibilité',
              icon: Icons.visibility,
              children: [
                DropdownButtonFormField<String>(
                  value: _visibility,
                  decoration: const InputDecoration(
                    labelText: 'Qui peut voir cette page ?',
                    border: OutlineInputBorder(),
                  ),
                  items: _visibilityOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(_getVisibilityLabel(option)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _visibility = value!;
                      _markAsChanged();
                    });
                  },
                ),
                if (_visibility == 'groups' || _visibility == 'roles') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Groupes/Rôles autorisés :',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Sélection des groupes/rôles\n(à implémenter)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Paramètres de mise en page
            _buildSection(
              title: 'Mise en page',
              icon: Icons.view_quilt,
              children: [
                // Type de disposition
                DropdownButtonFormField<String>(
                  value: _layoutType,
                  decoration: const InputDecoration(
                    labelText: 'Type de disposition',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.view_module),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'linear',
                      child: Row(
                        children: [
                          Icon(Icons.view_stream, size: 18),
                          SizedBox(width: 8),
                          Text('Linéaire (vertical)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'grid',
                      child: Row(
                        children: [
                          Icon(Icons.grid_view, size: 18),
                          SizedBox(width: 8),
                          Text('Grille (colonnes)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _layoutType = value!;
                      _markAsChanged();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Paramètres spécifiques à la grille
                if (_layoutType == 'grid') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nombre de colonnes',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _gridColumns.toDouble(),
                              min: 1,
                              max: 4,
                              divisions: 3,
                              label: '$_gridColumns colonnes',
                              onChanged: (value) {
                                setState(() {
                                  _gridColumns = value.round();
                                  _markAsChanged();
                                });
                              },
                            ),
                            Text(
                              '$_gridColumns colonnes',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Espacement de la grille',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _gridSpacing,
                              min: 0,
                              max: 50,
                              divisions: 50,
                              label: '${_gridSpacing.round()}px',
                              onChanged: (value) {
                                setState(() {
                                  _gridSpacing = value;
                                  _markAsChanged();
                                });
                              },
                            ),
                            Text(
                              '${_gridSpacing.round()} pixels',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Paramètres pour la disposition linéaire
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Espacement entre composants',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _componentSpacing,
                              min: 0,
                              max: 50,
                              divisions: 50,
                              label: '${_componentSpacing.round()}px',
                              onChanged: (value) {
                                setState(() {
                                  _componentSpacing = value;
                                  _markAsChanged();
                                });
                              },
                            ),
                            Text(
                              '${_componentSpacing.round()} pixels',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Marge commune à tous les types
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marge autour des composants',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _componentMargin,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            label: '${_componentMargin.round()}px',
                            onChanged: (value) {
                              setState(() {
                                _componentMargin = value;
                                _markAsChanged();
                              });
                            },
                          ),
                          Text(
                            '${_componentMargin.round()} pixels',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _layoutType == 'grid' 
                                ? 'En mode grille, les composants sont organisés en colonnes. Ajustez le nombre de colonnes et l\'espacement selon vos préférences.'
                                : 'En mode linéaire, les composants sont empilés verticalement. L\'espacement contrôle la distance entre chaque composant.',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_layoutType == 'grid') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addGridDemo,
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('Ajouter des exemples Grid'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Arrière-plan de page
            _buildSection(
              title: 'Arrière-plan de page',
              icon: Icons.wallpaper,
              children: [
                DropdownButtonFormField<String>(
                  value: _backgroundType,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'arrière-plan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'color', child: Text('Couleur unie')),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _backgroundType = value!;
                      _markAsChanged();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_backgroundType == 'color') ...[
                  TextFormField(
                    initialValue: _backgroundColor,
                    decoration: const InputDecoration(
                      labelText: 'Couleur d\'arrière-plan',
                      border: OutlineInputBorder(),
                      helperText: 'Format: #FFFFFF (blanc) ou #000000 (noir)',
                      prefixIcon: Icon(Icons.palette),
                    ),
                    onChanged: (value) {
                      _backgroundColor = value;
                      _markAsChanged();
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La couleur est requise';
                      }
                      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value.trim())) {
                        return 'Format invalide. Utilisez #FFFFFF par exemple';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(_backgroundColor.replaceFirst('#', '0xFF'))
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Text(
                        'Aperçu de la couleur',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 2,
                            ),
                            Shadow(
                              color: Colors.white54,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else if (_backgroundType == 'image') ...[
                  TextFormField(
                    initialValue: _backgroundImageUrl,
                    decoration: const InputDecoration(
                      labelText: 'URL de l\'image d\'arrière-plan',
                      border: OutlineInputBorder(),
                      helperText: 'URL complète vers l\'image (JPEG, PNG)',
                      prefixIcon: Icon(Icons.image),
                    ),
                    onChanged: (value) {
                      _backgroundImageUrl = value;
                      _markAsChanged();
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'URL de l\'image est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_backgroundImageUrl.isNotEmpty)
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                        image: DecorationImage(
                          image: NetworkImage(_backgroundImageUrl),
                          fit: BoxFit.cover,
                          onError: (error, stackTrace) {
                            // Gestion d'erreur pour image invalide
                          },
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: const Center(
                          child: Text(
                            'Aperçu de l\'arrière-plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'L\'arrière-plan sera appliqué à toute la page. Pour les images, privilégiez des images de haute qualité et optimisées pour le web.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Paramètres de publication
            _buildSection(
              title: 'Publication',
              icon: Icons.publish,
              children: [
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                    DropdownMenuItem(value: 'published', child: Text('Publié')),
                    DropdownMenuItem(value: 'archived', child: Text('Archivé')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                      _markAsChanged();
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Ordre d\'affichage',
                    border: OutlineInputBorder(),
                    helperText: '0 = premier',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _displayOrder.toString(),
                  onChanged: (value) {
                    _displayOrder = int.tryParse(value) ?? 0;
                    _markAsChanged();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),


          ],
        ),
      ),
    );
  }

  Widget _buildPageInfoTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de l'onglet
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de la page',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Configurez les paramètres de base et la structure de votre page',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Informations générales
              _buildSection(
                title: 'Détails de la page',
                icon: Icons.edit,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la page *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre est requis';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (_slugController.text.isEmpty || 
                          _slugController.text == _generateSlug(_titleController.text)) {
                        _slugController.text = _generateSlug(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildCoverImageSection(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _slugController,
                    decoration: const InputDecoration(
                      labelText: 'URL personnalisée *',
                      prefixText: '/',
                      border: OutlineInputBorder(),
                      helperText: 'Ex: bienvenue, jeunesse, contact',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'URL est requise';
                      }
                      if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                        return 'Seules les lettres, chiffres et tirets sont autorisés';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Paramètres de visibilité
              _buildSection(
                title: 'Visibilité',
                icon: Icons.visibility,
                children: [
                  DropdownButtonFormField<String>(
                    value: _visibility,
                    decoration: const InputDecoration(
                      labelText: 'Qui peut voir cette page ?',
                      border: OutlineInputBorder(),
                    ),
                    items: _visibilityOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(_getVisibilityLabel(option)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _visibility = value!;
                        _markAsChanged();
                      });
                    },
                  ),
                  if (_visibility == 'groups' || _visibility == 'roles') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Groupes/Rôles autorisés :',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Sélection des groupes/rôles\n(à implémenter)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // Paramètres de publication
              _buildSection(
                title: 'Publication',
                icon: Icons.publish,
                children: [
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                      DropdownMenuItem(value: 'published', child: Text('Publié')),
                      DropdownMenuItem(value: 'archived', child: Text('Archivé')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                        _markAsChanged();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ordre d\'affichage',
                      border: OutlineInputBorder(),
                      helperText: '0 = premier',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _displayOrder.toString(),
                    onChanged: (value) {
                      _displayOrder = int.tryParse(value) ?? 0;
                      _markAsChanged();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Structure de la page  
              _buildSection(
                title: 'Structure de la page',
                icon: Icons.view_quilt,
                children: [
                  Text(
                    'Paramètres de mise en page et d\'affichage',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _layoutType,
                    decoration: const InputDecoration(
                      labelText: 'Type de disposition',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.view_module),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'linear',
                        child: Text('Linéaire (vertical)'),
                      ),
                      DropdownMenuItem(
                        value: 'grid',
                        child: Text('Grille'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _layoutType = value!;
                        _markAsChanged();
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Espacement et marges
              _buildSection(
                title: 'Espacement et marges',
                icon: Icons.space_bar,
                children: [
                  Text(
                    'Configurez l\'espacement entre les composants et les marges horizontales',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Espacement entre composants
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Espacement entre composants: ${_componentSpacing.toInt()}px',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Theme.of(context).colorScheme.primaryColor,
                          thumbColor: Theme.of(context).colorScheme.primaryColor,
                          overlayColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                          valueIndicatorColor: Theme.of(context).colorScheme.primaryColor,
                        ),
                        child: Slider(
                          value: _componentSpacing,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${_componentSpacing.toInt()}px',
                          onChanged: (value) {
                            setState(() {
                              _componentSpacing = value;
                              _markAsChanged();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Marges horizontales
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marges horizontales: ${_componentMargin.toInt()}px',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _componentMargin == 0 
                          ? 'Les composants couvrent toute la largeur' 
                          : 'Marge identique à gauche et à droite',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Theme.of(context).colorScheme.primaryColor,
                          thumbColor: Theme.of(context).colorScheme.primaryColor,
                          overlayColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                          valueIndicatorColor: Theme.of(context).colorScheme.primaryColor,
                        ),
                        child: Slider(
                          value: _componentMargin,
                          min: 0,
                          max: 40,
                          divisions: 40,
                          label: _componentMargin == 0 
                            ? 'Aucune marge' 
                            : '${_componentMargin.toInt()}px',
                          onChanged: (value) {
                            setState(() {
                              _componentMargin = value;
                              _markAsChanged();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Aperçu visuel
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aperçu:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 80,
                          child: Column(
                            children: [
                              // Premier composant simulé
                              Container(
                                height: 30,
                                margin: EdgeInsets.symmetric(horizontal: _componentMargin),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    'Composant 1',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: _componentSpacing / 2),
                              // Deuxième composant simulé
                              Container(
                                height: 30,
                                margin: EdgeInsets.symmetric(horizontal: _componentMargin),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    'Composant 2',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Arrière-plan
              _buildSection(
                title: 'Arrière-plan',
                icon: Icons.palette,
                children: [
                  DropdownButtonFormField<String>(
                    value: _backgroundType,
                    decoration: const InputDecoration(
                      labelText: 'Type d\'arrière-plan',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'color', child: Text('Couleur unie')),
                      DropdownMenuItem(value: 'image', child: Text('Image')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _backgroundType = value!;
                        _markAsChanged();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_backgroundType == 'color')
                    TextFormField(
                      initialValue: _backgroundColor,
                      decoration: const InputDecoration(
                        labelText: 'Couleur d\'arrière-plan',
                        border: OutlineInputBorder(),
                        helperText: 'Format: #FFFFFF',
                        prefixIcon: Icon(Icons.palette),
                      ),
                      onChanged: (value) {
                        _backgroundColor = value;
                        _markAsChanged();
                      },
                    ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentsTab() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // En-tête de l'onglet
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.extension,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Composants',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Gérez les composants de votre page',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des composants
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildComponentsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsList() {
    if (_components.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Votre page est vide',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des composants pour créer votre contenu',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showComponentSelector,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      onReorder: _reorderComponents,
      itemCount: _components.length,
      itemBuilder: (context, index) {
        final component = _components[index];
        return Card(
          key: ValueKey(component.id),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(component.name),
            subtitle: Text(component.typeLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editComponent(component),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => _deleteComponent(component),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'members':
        return 'Membres connectés';
      case 'groups':
        return 'Groupes spécifiques';
      case 'roles':
        return 'Rôles spécifiques';
      default:
        return visibility;
    }
  }

  void _showComponentSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ajouter un composant',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez le type de contenu à ajouter à votre page',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Categories list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _componentCategories.keys.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, categoryIndex) {
                    final categoryName = _componentCategories.keys.elementAt(categoryIndex);
                    final components = _componentCategories[categoryName]!;
                    
                    return _buildComponentCategory(categoryName, components);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentCategory(String categoryName, List<Map<String, dynamic>> components) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        initiallyExpanded: true,
        title: Text(
          categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(categoryName),
            color: Theme.of(context).colorScheme.primaryColor,
            size: 20,
          ),
        ),
        children: components.map((component) => _buildComponentItem(component)).toList(),
      ),
    );
  }

  Widget _buildComponentItem(Map<String, dynamic> component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _addComponent(component['type']);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (component['color'] as Color).withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (component['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  component['icon'],
                  color: component['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component['label'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      component['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.add_circle,
                color: component['color'],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image de couverture',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Affichage de l'image actuelle ou bouton d'ajout
        if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) ...[
          // Image actuelle avec overlay d'actions
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, 
                                 size: 48, 
                                 color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Erreur de chargement',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Overlay avec actions
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _changeCoverImage,
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        tooltip: 'Modifier l\'image',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: _removeCoverImage,
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        tooltip: 'Supprimer l\'image',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Badge "Couverture"
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.image, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Image de couverture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else ...[
          // Bouton d'ajout amélioré
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.05),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryColor.withOpacity(0.05),
                  Theme.of(context).colorScheme.primaryColor.withOpacity(0.02),
                ],
              ),
            ),
            child: InkWell(
              onTap: _addCoverImage,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Theme.of(context).colorScheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ajouter une image de couverture',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Depuis la galerie ou par URL',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommandé : 1200x600 pixels',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        Text(
          'Cette image sera affichée en haut de votre page. Elle remplace l\'affichage du titre et de la description.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _addCoverImage() {
    _showImageSelectionDialog();
  }

  void _changeCoverImage() {
    _showImageSelectionDialog();
  }

  void _removeCoverImage() {
    setState(() {
      _coverImageUrl = null;
      _markAsChanged();
    });
  }

  void _showImageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête du dialog
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Choisir une image de couverture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Contenu du dialog avec ImagePickerWidget
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Sélectionnez une image depuis la galerie ou renseignez une URL :',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Widget de sélection d'image
                      Expanded(
                        child: ImagePickerWidget(
                          initialUrl: _coverImageUrl,
                          onImageSelected: (imageUrl) {
                            setState(() {
                              _coverImageUrl = imageUrl;
                              _markAsChanged();
                            });
                            Navigator.of(context).pop();
                            
                            // Afficher un message de confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  imageUrl != null 
                                    ? 'Image de couverture mise à jour !' 
                                    : 'Image de couverture supprimée',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          height: 250,
                          label: 'Image de couverture',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Options d'images suggérées
                      Text(
                        'Ou choisissez une image suggérée :',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            {'category': 'church', 'keyword': 'église moderne architecture', 'label': 'Église'},
                            {'category': 'nature', 'keyword': 'paysage paisible lumière', 'label': 'Nature'},
                            {'category': 'people', 'keyword': 'communauté chrétienne prière', 'label': 'Communauté'},
                            {'category': 'abstract', 'keyword': 'lumière espoir foi', 'label': 'Spirituel'},
                            {'category': 'event', 'keyword': 'événement célébration joie', 'label': 'Événement'},
                          ].map((option) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                _selectImageFromCategory(option['keyword']!, option['category']!);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 80,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getCategoryIconForImage(option['category']!),
                                      color: Theme.of(context).colorScheme.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['label']!,
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIconForImage(String category) {
    switch (category) {
      case 'church':
        return Icons.church;
      case 'nature':
        return Icons.landscape;
      case 'people':
        return Icons.group;
      case 'abstract':
        return Icons.auto_awesome;
      case 'event':
        return Icons.celebration;
      default:
        return Icons.image;
    }
  }

  void _selectImageFromCategory(String keyword, String category) {
    setState(() => _isLoading = true);
    
    try {
      final imageUrl = "https://images.unsplash.com/photo-1565733293249-df7f8059d3f8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTAyOTMyNTl8&ixlib=rb-4.1.0&q=80&w=1080";
      
      setState(() {
        _coverImageUrl = imageUrl;
        _isLoading = false;
        _markAsChanged();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Contenu textuel':
        return Icons.article;
      case 'Médias':
        return Icons.perm_media;
      case 'Interactif':
        return Icons.touch_app;
      case 'Organisation':
        return Icons.dashboard;
      default:
        return Icons.extension;
    }
  }
}