import 'package:flutter/material.dart';
import '../../models/page_model.dart';
import '../../models/image_action_model.dart';
import '../../models/component_action_model.dart';
import '../../services/image_action_service.dart';
import '../../services/component_action_service.dart';
import '../../services/youtube_service.dart';
import '../../services/soundcloud_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import '../image_picker_widget.dart';
import '../youtube_picker_widget.dart';
import '../soundcloud_picker_widget.dart';
import '../media_player_config_widget.dart';
import '../component_action_editor.dart';

class ComponentEditor extends StatefulWidget {
  final PageComponent component;
  final Function(PageComponent) onSave;

  const ComponentEditor({
    super.key,
    required this.component,
    required this.onSave,
  });

  @override
  State<ComponentEditor> createState() => _ComponentEditorState();
}

class _ComponentEditorState extends State<ComponentEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  late Map<String, dynamic> _data;
  late Map<String, dynamic> _styling;
  late Map<String, dynamic> _settings;
  ComponentAction? _currentAction;
  late List<PageComponent> _children;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.component.name;
    _data = Map.from(widget.component.data);
    _styling = Map.from(widget.component.styling);
    _settings = Map.from(widget.component.settings);
    _currentAction = widget.component.action;
    _children = List<PageComponent>.from(widget.component.children);
    
    // Initialiser les paramètres de lecteur média par défaut
    if (widget.component.type == 'video' || widget.component.type == 'audio') {
      _data['playbackMode'] ??= 'integrated';
      _data['autoplay'] ??= false;
      _data['showControls'] ??= true;
      _data['loop'] ??= false;
      
      if (widget.component.type == 'video') {
        _data['mute'] ??= false;
        _data['hideControls'] ??= false;
      }
      
      if (widget.component.type == 'audio') {
        _data['showComments'] ??= true;
        _data['source_type'] ??= 'direct';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveComponent() {
    if (!_formKey.currentState!.validate()) return;

    // Validation supplémentaire pour les composants image
    if (widget.component.type == 'image') {
      final imageUrl = _data['url'];
      if (imageUrl == null || imageUrl.toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final updatedComponent = widget.component.copyWith(
      name: _nameController.text.trim(),
      data: _data,
      styling: _styling,
      settings: _settings,
      action: _currentAction,
      children: _children,
    );

    widget.onSave(updatedComponent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getComponentIcon(widget.component.type),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modifier ${widget.component.typeLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du composant
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du composant',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Éditeur spécifique au type
                      _buildTypeSpecificEditor(),
                      
                      const SizedBox(height: 24),
                      
                      // Éditeur d'actions (pour les composants supportés)
                      if (ComponentActionService.supportsActions(widget.component.type))
                        ComponentActionEditor(
                          action: _currentAction,
                          componentType: widget.component.type,
                          onActionChanged: (action) {
                            setState(() {
                              _currentAction = action;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveComponent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sauvegarder'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificEditor() {
    switch (widget.component.type) {
      case 'text':
        return _buildTextEditor();
      case 'image':
        return _buildImageEditor();
      case 'button':
        return _buildButtonEditor();
      case 'video':
        return _buildVideoEditor();
      case 'list':
        return _buildListEditor();

      case 'scripture':
        return _buildScriptureEditor();
      case 'banner':
        return _buildBannerEditor();
      case 'map':
        return _buildMapEditor();
      case 'audio':
        return _buildAudioEditor();
      case 'googlemap':
        return _buildGoogleMapEditor();
      case 'html':
        return _buildHtmlEditor();
      case 'webview':
        return _buildWebViewEditor();
      case 'quote':
        return _buildQuoteEditor();
      case 'groups':
        return _buildGroupsEditor();
      case 'events':
        return _buildEventsEditor();







      case 'prayer_wall':
        return _buildPrayerWallEditor();
      case 'grid_card':
        return _buildGridCardEditor();
      case 'grid_stat':
        return _buildGridStatEditor();
      case 'grid_icon_text':
        return _buildGridIconTextEditor();
      case 'grid_image_card':
        return _buildGridImageCardEditor();
      case 'grid_progress':
        return _buildGridProgressEditor();
      case 'grid_container':
        return _buildGridContainerEditor();
      default:
        return _buildGenericEditor();
    }
  }

  Widget _buildTextEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenu du texte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['content'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte',
            border: OutlineInputBorder(),
            helperText: 'Supporté: Markdown basique (##, **, *, [lien](url))',
          ),
          maxLines: 8,
          onChanged: (value) => _data['content'] = value,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['textAlign'] ?? 'left',
                decoration: const InputDecoration(
                  labelText: 'Alignement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'left', child: Text('Gauche')),
                  DropdownMenuItem(value: 'center', child: Text('Centre')),
                  DropdownMenuItem(value: 'right', child: Text('Droite')),
                  DropdownMenuItem(value: 'justify', child: Text('Justifié')),
                ],
                onChanged: (value) => setState(() => _data['textAlign'] = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: (_data['fontSize'] ?? 16).toString(),
                decoration: const InputDecoration(
                  labelText: 'Taille de police',
                  border: OutlineInputBorder(),
                  suffixText: 'px',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['fontSize'] = int.tryParse(value) ?? 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de l\'image',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ImagePickerWidget(
          initialUrl: _data['url'] ?? '',
          onImageSelected: (url) {
            setState(() {
              if (url != null && url.isNotEmpty) {
                _data['url'] = url;
              } else {
                _data.remove('url');
              }
            });
          },
          isRequired: true,
          label: 'Source de l\'image',
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['alt'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte alternatif',
            border: OutlineInputBorder(),
            helperText: 'Description de l\'image pour l\'accessibilité',
          ),
          onChanged: (value) => _data['alt'] = value,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['height'] ?? 200).toString(),
                decoration: const InputDecoration(
                  labelText: 'Hauteur',
                  border: OutlineInputBorder(),
                  suffixText: 'px',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['height'] = int.tryParse(value) ?? 200,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['fit'] ?? 'cover',
                decoration: const InputDecoration(
                  labelText: 'Ajustement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cover', child: Text('Couvrir')),
                  DropdownMenuItem(value: 'contain', child: Text('Contenir')),
                  DropdownMenuItem(value: 'fill', child: Text('Remplir')),
                  DropdownMenuItem(value: 'fitWidth', child: Text('Largeur')),
                  DropdownMenuItem(value: 'fitHeight', child: Text('Hauteur')),
                ],
                onChanged: (value) => setState(() => _data['fit'] = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildImageActionEditor(),
      ],
    );
  }

  Widget _buildImageActionEditor() {
    final hasAction = _data['action'] != null;
    final action = hasAction ? ImageAction.fromMap(_data['action']) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Action au clic',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Switch(
              value: hasAction,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _data['action'] = const ImageAction(type: 'url').toMap();
                  } else {
                    _data.remove('action');
                  }
                });
              },
            ),
          ],
        ),
        if (hasAction) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: action?.type ?? 'url',
            decoration: const InputDecoration(
              labelText: 'Type d\'action',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'url', child: Text('Ouvrir un lien internet')),
              DropdownMenuItem(value: 'member_page', child: Text('Aller vers une page membre')),
            ],
            onChanged: (value) {
              setState(() {
                if (value != null) {
                  _data['action'] = ImageAction(type: value).toMap();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (action?.type == 'url') _buildUrlActionEditor(action!),
          if (action?.type == 'member_page') _buildMemberPageActionEditor(action!),
        ],
      ],
    );
  }

  Widget _buildUrlActionEditor(ImageAction action) {
    return TextFormField(
      initialValue: action.url ?? '',
      decoration: const InputDecoration(
        labelText: 'URL du lien',
        border: OutlineInputBorder(),
        helperText: 'URL complète (ex: https://example.com)',
        prefixIcon: Icon(Icons.link),
      ),
      onChanged: (value) {
        final currentAction = ImageAction.fromMap(_data['action']);
        _data['action'] = currentAction.copyWith(url: value).toMap();
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'L\'URL est requise';
        }
        if (!value.startsWith('http://') && !value.startsWith('https://')) {
          return 'L\'URL doit commencer par http:// ou https://';
        }
        return null;
      },
    );
  }

  Widget _buildMemberPageActionEditor(ImageAction action) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: action.memberPage,
          decoration: const InputDecoration(
            labelText: 'Page membre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pages),
          ),
          items: MemberPagesRegistry.availablePages
              .map((page) => DropdownMenuItem(
                    value: page.key,
                    child: Row(
                      children: [
                        if (page.icon != null) ...[
                          Icon(_getIconData(page.icon!), size: 16),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: Text(page.name)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            final currentAction = ImageAction.fromMap(_data['action']);
            _data['action'] = currentAction.copyWith(
              memberPage: value,
              parameters: {},
            ).toMap();
            setState(() {});
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner une page membre';
            }
            return null;
          },
        ),
        if (action.memberPage != null) ...[
          const SizedBox(height: 16),
          _buildMemberPageParameters(action),
        ],
      ],
    );
  }

  Widget _buildMemberPageParameters(ImageAction action) {
    final pageDefinition = MemberPagesRegistry.findByKey(action.memberPage!);
    if (pageDefinition?.supportedParameters == null ||
        pageDefinition!.supportedParameters!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...pageDefinition.supportedParameters!.map((param) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildParameterField(action, param, pageDefinition),
          );
        }),
      ],
    );
  }

  Widget _buildParameterField(
    ImageAction action,
    String paramName,
    MemberPageDefinition pageDefinition,
  ) {
    final currentValue = action.parameters?[paramName]?.toString() ?? '';

    String labelText = paramName;
    String? helperText;
    IconData? icon;

    switch (paramName) {
      case 'category':
        labelText = 'Catégorie';
        helperText = 'Nom de la catégorie de blog';
        icon = Icons.category;
        break;
      case 'formId':
        labelText = 'ID du formulaire';
        helperText = 'Identifiant unique du formulaire';
        icon = Icons.assignment;
        break;
    }

    return TextFormField(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        helperText: helperText,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      onChanged: (value) {
        final currentAction = ImageAction.fromMap(_data['action']);
        final currentParams = Map<String, dynamic>.from(currentAction.parameters ?? {});
        currentParams[paramName] = value;
        _data['action'] = currentAction.copyWith(parameters: currentParams).toMap();
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$labelText est requis pour ${pageDefinition.name}';
        }
        return null;
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'group':
        return Icons.group;
      case 'event':
        return Icons.event;
      case 'music_note':
        return Icons.music_note;
      case 'article':
        return Icons.article;
      case 'favorite':
        return Icons.favorite;
      case 'schedule':
        return Icons.schedule;
      case 'work':
        return Icons.work;
      case 'assignment':
        return Icons.assignment;
      case 'task':
        return Icons.task;
      case 'dashboard':
        return Icons.dashboard;
      case 'person':
        return Icons.person;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.pages;
    }
  }

  Widget _buildButtonEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration du bouton',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['text'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte du bouton',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['text'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le texte du bouton est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['url'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Lien URL',
            border: OutlineInputBorder(),
            helperText: 'URL externe ou chemin interne (/groupes, /events)',
          ),
          onChanged: (value) => _data['url'] = value,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['style'] ?? 'primary',
                decoration: const InputDecoration(
                  labelText: 'Style',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'primary', child: Text('Principal')),
                  DropdownMenuItem(value: 'secondary', child: Text('Secondaire')),
                  DropdownMenuItem(value: 'outline', child: Text('Contour')),
                  DropdownMenuItem(value: 'text', child: Text('Texte')),
                ],
                onChanged: (value) => setState(() => _data['style'] = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['size'] ?? 'medium',
                decoration: const InputDecoration(
                  labelText: 'Taille',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Petit')),
                  DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                  DropdownMenuItem(value: 'large', child: Text('Grand')),
                ],
                onChanged: (value) => setState(() => _data['size'] = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la vidéo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Widget spécialisé YouTube
        YouTubePickerWidget(
          initialUrl: _data['url'] ?? '',
          onUrlChanged: (url) => setState(() => _data['url'] = url),
          isRequired: true,
          label: 'Source vidéo YouTube',
        ),
        
        const SizedBox(height: 24),
        
        // Titre personnalisé (optionnel)
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre personnalisé (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Laissez vide pour utiliser le titre YouTube',
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        
        const SizedBox(height: 16),
        
        // Options avancées
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Options de lecture',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('Lecture automatique'),
                  subtitle: const Text('Démarrer la vidéo automatiquement'),
                  value: _data['autoplay'] ?? false,
                  onChanged: (value) => setState(() => _data['autoplay'] = value),
                  contentPadding: EdgeInsets.zero,
                ),
                
                SwitchListTile(
                  title: const Text('Lecture en boucle'),
                  subtitle: const Text('Répéter la vidéo en continu'),
                  value: _data['loop'] ?? false,
                  onChanged: (value) => setState(() => _data['loop'] = value),
                  contentPadding: EdgeInsets.zero,
                ),
                
                SwitchListTile(
                  title: const Text('Contrôles masqués'),
                  subtitle: const Text('Cacher les contrôles de lecture'),
                  value: _data['hideControls'] ?? false,
                  onChanged: (value) => setState(() => _data['hideControls'] = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Configuration du lecteur
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration du lecteur',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                MediaPlayerConfigWidget(
                  componentType: 'video',
                  data: Map<String, dynamic>.from(_data),
                  onDataChanged: (newData) {
                    setState(() {
                      // Mise à jour avec toutes les nouvelles données
                      _data.addAll(newData);
                      
                      // S'assurer que les clés importantes sont bien définies
                      _data['playbackMode'] ??= 'integrated';
                      _data['autoplay'] ??= newData['autoPlay'] ?? false;
                      _data['mute'] ??= newData['mute'] ?? false;
                      _data['hideControls'] ??= !(newData['showControls'] ?? true);
                      _data['loop'] ??= newData['loop'] ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Prévisualisation du type de contenu
        if (_data['url'] != null && (_data['url'] as String).isNotEmpty)
          _buildVideoPreviewCard(),
      ],
    );
  }
  
  Widget _buildVideoPreviewCard() {
    final url = _data['url'] as String;
    final urlInfo = YouTubeService.parseYouTubeUrl(url);
    
    if (!urlInfo.isValid) return const SizedBox.shrink();
    
    return Card(
      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getVideoContentIcon(urlInfo.contentType),
                  color: Theme.of(context).colorScheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Type: ${urlInfo.displayType}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            if (urlInfo.videoId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ID Vidéo: ${urlInfo.videoId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
            
            if (urlInfo.playlistId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'ID Playlist: ${urlInfo.playlistId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getVideoContentIcon(YouTubeContentType contentType) {
    switch (contentType) {
      case YouTubeContentType.video:
        return Icons.play_circle_outline;
      case YouTubeContentType.playlist:
        return Icons.playlist_play;
      case YouTubeContentType.videoInPlaylist:
        return Icons.video_collection;
      default:
        return Icons.video_library;
    }
  }

  Widget _buildListEditor() {
    final items = List<Map<String, dynamic>>.from(_data['items'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la liste',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre de la liste',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['listType'] ?? 'simple',
          decoration: const InputDecoration(
            labelText: 'Type de liste',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'simple', child: Text('Liste simple')),
            DropdownMenuItem(value: 'numbered', child: Text('Liste numérotée')),
            DropdownMenuItem(value: 'cards', child: Text('Cartes')),
            DropdownMenuItem(value: 'links', child: Text('Liens')),
          ],
          onChanged: (value) => setState(() => _data['listType'] = value),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Éléments de la liste',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  items.add({
                    'title': 'Nouvel élément',
                    'description': '',
                    'icon': 'circle',
                    'action': '',
                  });
                  _data['items'] = items;
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: item['title'] ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Titre',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            items[index]['title'] = value;
                            _data['items'] = items;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            items.removeAt(index);
                            _data['items'] = items;
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: item['description'] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      items[index]['description'] = value;
                      _data['items'] = items;
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }



  Widget _buildScriptureEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration du verset',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['verse'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte du verset',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) => _data['verse'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le texte du verset est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['reference'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Référence',
                  border: OutlineInputBorder(),
                  helperText: 'Ex: Jean 3:16',
                ),
                onChanged: (value) => _data['reference'] = value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['version'] ?? 'LSG',
                decoration: const InputDecoration(
                  labelText: 'Version',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'LSG', child: Text('Louis Segond')),
                  DropdownMenuItem(value: 'NEG', child: Text('NEG 1979')),
                  DropdownMenuItem(value: 'S21', child: Text('Segond 21')),
                  DropdownMenuItem(value: 'BDS', child: Text('Bible du Semeur')),
                ],
                onChanged: (value) => setState(() => _data['version'] = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBannerEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la bannière',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le titre est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['subtitle'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Sous-titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['backgroundColor'] ?? '#6F61EF',
                decoration: const InputDecoration(
                  labelText: 'Couleur de fond',
                  border: OutlineInputBorder(),
                  helperText: 'Code couleur hex (#RRGGBB)',
                ),
                onChanged: (value) => _data['backgroundColor'] = value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _data['textColor'] ?? '#FFFFFF',
                decoration: const InputDecoration(
                  labelText: 'Couleur du texte',
                  border: OutlineInputBorder(),
                  helperText: 'Code couleur hex (#RRGGBB)',
                ),
                onChanged: (value) => _data['textColor'] = value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la carte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['address'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Adresse',
            border: OutlineInputBorder(),
            helperText: 'Adresse complète du lieu',
          ),
          onChanged: (value) => _data['address'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'adresse est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['latitude'] ?? 0.0).toString(),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['latitude'] = double.tryParse(value) ?? 0.0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: (_data['longitude'] ?? 0.0).toString(),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['longitude'] = double.tryParse(value) ?? 0.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: (_data['zoom'] ?? 15).toString(),
          decoration: const InputDecoration(
            labelText: 'Niveau de zoom',
            border: OutlineInputBorder(),
            helperText: '1-20 (15 recommandé)',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['zoom'] = int.tryParse(value) ?? 15,
        ),
      ],
    );
  }

  Widget _buildAudioEditor() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration audio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Onglets pour choisir le type d'audio
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const TabBar(
              labelColor: Theme.of(context).colorScheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primaryColor,
              tabs: [
                Tab(
                  icon: Icon(Icons.audiotrack),
                  text: 'SoundCloud',
                ),
                Tab(
                  icon: Icon(Icons.music_note),
                  text: 'Fichier Direct',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Configuration du lecteur audio
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration du lecteur',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MediaPlayerConfigWidget(
                    componentType: 'audio',
                    data: Map<String, dynamic>.from(_data),
                    onDataChanged: (newData) {
                      setState(() {
                        // Mise à jour avec toutes les nouvelles données
                        _data.addAll(newData);
                        
                        // S'assurer que les clés importantes sont bien définies
                        _data['playbackMode'] ??= 'integrated';
                        _data['autoplay'] ??= newData['autoPlay'] ?? false;
                        _data['showComments'] ??= newData['showComments'] ?? true;
                        _data['loop'] ??= newData['loop'] ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contenu des onglets
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildSoundCloudAudioEditor(),
                _buildDirectFileAudioEditor(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCloudAudioEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section SoundCloud
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Intégrez facilement des pistes, playlists ou profils SoundCloud. Collez simplement l\'URL depuis votre navigateur.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Widget de sélection SoundCloud
          SoundCloudPickerWidget(
            initialUrl: _data['soundcloud_url'] ?? '',
            onUrlSelected: (url) {
              setState(() {
                if (url != null && url.isNotEmpty) {
                  _data['soundcloud_url'] = url;
                  _data['source_type'] = 'soundcloud';
                  
                  // Analyse de l'URL pour extraire les métadonnées
                  final info = SoundCloudService.parseSoundCloudUrl(url);
                  if (info.isValid) {
                    _data['title'] = _data['title'] ?? info.userName;
                    _data['artist'] = _data['artist'] ?? info.userName;
                  }
                } else {
                  _data.remove('soundcloud_url');
                  if (_data['source_type'] == 'soundcloud') {
                    _data.remove('source_type');
                  }
                }
              });
            },
            isRequired: true,
            label: 'URL SoundCloud',
            helperText: 'Piste, playlist ou profil SoundCloud',
          ),
          
          const SizedBox(height: 20),
          
          // Options d'intégration SoundCloud
          if (_data['soundcloud_url'] != null) ...[
            Text(
              'Options d\'intégration',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSoundCloudOptions(),
          ],
          
          const SizedBox(height: 20),
          
          // Métadonnées personnalisables
          _buildAudioMetadataEditor(),
        ],
      ),
    );
  }

  Widget _buildSoundCloudOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lecture automatique
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lecture automatique',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Démarre la lecture dès le chargement',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _data['autoplay'] ?? false,
                onChanged: (value) => setState(() => _data['autoplay'] = value),
              ),
            ],
          ),
          
          const Divider(),
          
          // Masquer les éléments associés
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masquer les contenus associés',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Cache les suggestions de pistes similaires',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _data['hide_related'] ?? false,
                onChanged: (value) => setState(() => _data['hide_related'] = value),
              ),
            ],
          ),
          
          const Divider(),
          
          // Affichage visuel
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode visuel',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Affiche la pochette de l\'album',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _data['visual'] ?? true,
                onChanged: (value) => setState(() => _data['visual'] = value),
              ),
            ],
          ),
          
          const Divider(),
          
          // Couleur du lecteur
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Couleur du lecteur',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Couleur de l\'interface SoundCloud',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _data['color'] ?? 'ff5500',
                items: const [
                  DropdownMenuItem(value: 'ff5500', child: Text('Orange (défaut)')),
                  DropdownMenuItem(value: '0066cc', child: Text('Bleu')),
                  DropdownMenuItem(value: '006600', child: Text('Vert')),
                  DropdownMenuItem(value: 'cc0000', child: Text('Rouge')),
                  DropdownMenuItem(value: '663399', child: Text('Violet')),
                  DropdownMenuItem(value: '000000', child: Text('Noir')),
                ],
                onChanged: (value) => setState(() => _data['color'] = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectFileAudioEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Information sur les fichiers directs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pour les fichiers audio hébergés directement (MP3, WAV, etc.). L\'URL doit pointer vers le fichier audio.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // URL du fichier
          TextFormField(
            initialValue: _data['url'] ?? '',
            decoration: const InputDecoration(
              labelText: 'URL du fichier audio',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
              helperText: 'URL directe vers le fichier (MP3, WAV, OGG, etc.)',
            ),
            onChanged: (value) {
              setState(() {
                _data['url'] = value;
                _data['source_type'] = 'direct';
              });
            },
            validator: (value) {
              if (_data['source_type'] == 'direct' && (value == null || value.trim().isEmpty)) {
                return 'L\'URL du fichier audio est requise';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Métadonnées
          _buildAudioMetadataEditor(),
        ],
      ),
    );
  }

  Widget _buildAudioMetadataEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations audio',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Titre personnalisé
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre de l\'audio',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
            helperText: 'Titre personnalisé (optionnel)',
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        
        const SizedBox(height: 16),
        
        // Artiste/Auteur
        TextFormField(
          initialValue: _data['artist'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Artiste/Auteur',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
            helperText: 'Nom de l\'artiste ou auteur',
          ),
          onChanged: (value) => _data['artist'] = value,
        ),
        
        const SizedBox(height: 16),
        
        // Durée
        TextFormField(
          initialValue: _data['duration'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Durée',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.access_time),
            helperText: 'Format: 3:45 ou 3 min 45 sec',
          ),
          onChanged: (value) => _data['duration'] = value,
        ),
        
        const SizedBox(height: 16),
        
        // Description
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            helperText: 'Description de l\'audio (optionnel)',
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
      ],
    );
  }

  Widget _buildGoogleMapEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Google Maps',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saisissez une adresse et elle sera automatiquement reconnue par Google Maps',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['address'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Adresse',
            border: OutlineInputBorder(),
            helperText: 'Ex: 1 Rue de la Paix, 75001 Paris, France',
          ),
          onChanged: (value) => _data['address'] = value,
          validator: (value) {
            if ((value == null || value.trim().isEmpty) && 
                (_data['latitude'] == null || _data['longitude'] == null)) {
              return 'L\'adresse est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Ou saisissez les coordonnées GPS :',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['latitude'] ?? '').toString(),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _data['latitude'] = value.isNotEmpty ? double.tryParse(value) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: (_data['longitude'] ?? '').toString(),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _data['longitude'] = value.isNotEmpty ? double.tryParse(value) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['zoom'] ?? 15).toString(),
                decoration: const InputDecoration(
                  labelText: 'Niveau de zoom',
                  border: OutlineInputBorder(),
                  helperText: '1-20 (15 recommandé)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['zoom'] = int.tryParse(value) ?? 15,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['mapType'] ?? 'roadmap',
                decoration: const InputDecoration(
                  labelText: 'Type de carte',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'roadmap', child: Text('Route')),
                  DropdownMenuItem(value: 'satellite', child: Text('Satellite')),
                  DropdownMenuItem(value: 'hybrid', child: Text('Hybride')),
                  DropdownMenuItem(value: 'terrain', child: Text('Terrain')),
                ],
                onChanged: (value) => setState(() => _data['mapType'] = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHtmlEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration HTML',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attention : Le code HTML sera exécuté tel quel. Assurez-vous qu\'il soit sûr.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre du composant (optionnel)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['content'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Code HTML',
            border: OutlineInputBorder(),
            helperText: 'Saisissez votre code HTML personnalisé',
          ),
          maxLines: 10,
          onChanged: (value) => _data['content'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le contenu HTML est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuoteEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la citation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['quote'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte de la citation',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) => _data['quote'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le texte de la citation est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['author'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Auteur de la citation',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['author'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['context'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Contexte (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Ex: Livre, discours, date, etc.',
          ),
          onChanged: (value) => _data['context'] = value,
        ),
        const SizedBox(height: 16),
        Text(
          'Couleurs personnalisées',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['backgroundColor'] ?? '#F5F5F5',
                decoration: const InputDecoration(
                  labelText: 'Couleur de fond',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #FFFFFF',
                ),
                onChanged: (value) => _data['backgroundColor'] = value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _data['textColor'] ?? '#333333',
                decoration: const InputDecoration(
                  labelText: 'Couleur du texte',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #000000',
                ),
                onChanged: (value) => _data['textColor'] = value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration des groupes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? 'Nos Groupes',
          decoration: const InputDecoration(
            labelText: 'Titre de la section',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['subtitle'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Sous-titre (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Description courte des groupes',
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['displayMode'] ?? 'cards',
          decoration: const InputDecoration(
            labelText: 'Mode d\'affichage',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'cards', child: Text('Cartes')),
            DropdownMenuItem(value: 'list', child: Text('Liste')),
            DropdownMenuItem(value: 'grid', child: Text('Grille')),
          ],
          onChanged: (value) => setState(() => _data['displayMode'] = value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Afficher les informations de contact'),
          subtitle: const Text('Email et téléphone des responsables'),
          value: _data['showContact'] ?? true,
          onChanged: (value) => setState(() => _data['showContact'] = value),
        ),
        SwitchListTile(
          title: const Text('Permettre l\'inscription directe'),
          subtitle: const Text('Bouton "Rejoindre" sur chaque groupe'),
          value: _data['allowDirectJoin'] ?? false,
          onChanged: (value) => setState(() => _data['allowDirectJoin'] = value),
        ),
        SwitchListTile(
          title: const Text('Afficher le nombre de membres'),
          subtitle: const Text('Compteur de membres par groupe'),
          value: _data['showMemberCount'] ?? true,
          onChanged: (value) => setState(() => _data['showMemberCount'] = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['filterBy'] ?? 'all',
          decoration: const InputDecoration(
            labelText: 'Filtrer les groupes',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tous les groupes')),
            DropdownMenuItem(value: 'active', child: Text('Groupes actifs seulement')),
            DropdownMenuItem(value: 'joinable', child: Text('Groupes ouverts à l\'inscription')),
            DropdownMenuItem(value: 'category', child: Text('Par catégorie')),
          ],
          onChanged: (value) => setState(() => _data['filterBy'] = value),
        ),
        if (_data['filterBy'] == 'category') ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _data['category'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Catégorie à afficher',
              border: OutlineInputBorder(),
              helperText: 'Ex: Ministères, Études bibliques, Jeunesse, etc.',
            ),
            onChanged: (value) => _data['category'] = value,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Couleurs personnalisées',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['cardBackgroundColor'] ?? '#FFFFFF',
                decoration: const InputDecoration(
                  labelText: 'Couleur de fond des cartes',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #FFFFFF',
                ),
                onChanged: (value) => _data['cardBackgroundColor'] = value,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _data['accentColor'] ?? '#2196F3',
                decoration: const InputDecoration(
                  labelText: 'Couleur d\'accent',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #2196F3',
                ),
                onChanged: (value) => _data['accentColor'] = value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenericEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration générique',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Éditeur spécialisé non disponible pour ce type de composant.\n'
            'Type: ${widget.component.type}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  // Éditeur pour les événements
  Widget _buildEventsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration des événements',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? 'Nos Événements',
          decoration: const InputDecoration(
            labelText: 'Titre de la section',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['subtitle'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Sous-titre (optionnel)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['displayMode'] ?? 'cards',
          decoration: const InputDecoration(
            labelText: 'Mode d\'affichage',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'cards', child: Text('Cartes')),
            DropdownMenuItem(value: 'list', child: Text('Liste')),
            DropdownMenuItem(value: 'calendar', child: Text('Calendrier')),
          ],
          onChanged: (value) => setState(() => _data['displayMode'] = value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Afficher les dates'),
          subtitle: const Text('Inclure les dates des événements'),
          value: _data['showDates'] ?? true,
          onChanged: (value) => setState(() => _data['showDates'] = value),
        ),
        SwitchListTile(
          title: const Text('Permettre inscription'),
          subtitle: const Text('Bouton d\'inscription sur les événements'),
          value: _data['allowRegistration'] ?? true,
          onChanged: (value) => setState(() => _data['allowRegistration'] = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['primaryColor'] ?? '#2196F3',
          decoration: const InputDecoration(
            labelText: 'Couleur principale',
            border: OutlineInputBorder(),
            hintText: '#2196F3',
          ),
          onChanged: (value) => _data['primaryColor'] = value,
        ),
      ],
    );
  }

  // Éditeur pour les articles de blog




  // Éditeur pour les formulaires avancés
  Widget _buildAdvancedFormEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration du formulaire avancé',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? 'Formulaire',
          decoration: const InputDecoration(
            labelText: 'Titre du formulaire',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['submitText'] ?? 'Envoyer',
          decoration: const InputDecoration(
            labelText: 'Texte du bouton',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['submitText'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['formType'] ?? 'contact',
          decoration: const InputDecoration(
            labelText: 'Type de formulaire',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'contact', child: Text('Contact')),
            DropdownMenuItem(value: 'registration', child: Text('Inscription')),
            DropdownMenuItem(value: 'prayer', child: Text('Demande de prière')),
            DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
          ],
          onChanged: (value) => setState(() => _data['formType'] = value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Champ nom requis'),
          value: _data['requireName'] ?? true,
          onChanged: (value) => setState(() => _data['requireName'] = value),
        ),
        SwitchListTile(
          title: const Text('Champ email requis'),
          value: _data['requireEmail'] ?? true,
          onChanged: (value) => setState(() => _data['requireEmail'] = value),
        ),
        SwitchListTile(
          title: const Text('Champ téléphone'),
          value: _data['includePhone'] ?? false,
          onChanged: (value) => setState(() => _data['includePhone'] = value),
        ),
      ],
    );
  }

  // Éditeur pour les tâches
  Widget _buildTaskEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la tâche',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? 'Nouvelle tâche',
          decoration: const InputDecoration(
            labelText: 'Titre de la tâche',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['priority'] ?? 'medium',
          decoration: const InputDecoration(
            labelText: 'Priorité',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Faible')),
            DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
            DropdownMenuItem(value: 'high', child: Text('Élevée')),
            DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
          ],
          onChanged: (value) => setState(() => _data['priority'] = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['status'] ?? 'pending',
          decoration: const InputDecoration(
            labelText: 'Statut',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('En attente')),
            DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
            DropdownMenuItem(value: 'completed', child: Text('Terminée')),
            DropdownMenuItem(value: 'cancelled', child: Text('Annulée')),
          ],
          onChanged: (value) => setState(() => _data['status'] = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['assignedTo'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Assignée à',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['assignedTo'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['dueDate'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Date d\'échéance (YYYY-MM-DD)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['dueDate'] = value,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Afficher la progression'),
          value: _data['showProgress'] ?? false,
          onChanged: (value) => setState(() => _data['showProgress'] = value),
        ),
      ],
    );
  }



  Widget _buildAppointmentEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration des rendez-vous',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? 'Rendez-vous',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['dateTime'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Date et heure (YYYY-MM-DD HH:MM)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['dateTime'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['location'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Lieu',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['location'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['duration'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Durée (ex: 1h30)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['duration'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['status'] ?? 'scheduled',
          decoration: const InputDecoration(
            labelText: 'Statut',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'scheduled', child: Text('Planifié')),
            DropdownMenuItem(value: 'confirmed', child: Text('Confirmé')),
            DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
            DropdownMenuItem(value: 'completed', child: Text('Terminé')),
          ],
          onChanged: (value) => setState(() => _data['status'] = value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Permettre les réservations'),
          value: _data['allowBooking'] ?? true,
          onChanged: (value) => setState(() => _data['allowBooking'] = value),
        ),
        SwitchListTile(
          title: const Text('Afficher les participants'),
          value: _data['showParticipants'] ?? false,
          onChanged: (value) => setState(() => _data['showParticipants'] = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['maxParticipants'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Nombre maximum de participants',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['maxParticipants'] = value,
        ),
      ],
    );
  }

  Widget _buildPersonEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la personne',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['fullName'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['fullName'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre/Fonction',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description/Biographie',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) => _data['description'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['imageUrl'] ?? '',
          decoration: const InputDecoration(
            labelText: 'URL de la photo',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['imageUrl'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['email'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['email'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['phone'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['phone'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['displayStyle'] ?? 'card',
          decoration: const InputDecoration(
            labelText: 'Style d\'affichage',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'card', child: Text('Carte')),
            DropdownMenuItem(value: 'profile', child: Text('Profil')),
            DropdownMenuItem(value: 'simple', child: Text('Simple')),
          ],
          onChanged: (value) => setState(() => _data['displayStyle'] = value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Afficher l\'email'),
          value: _data['showEmail'] ?? false,
          onChanged: (value) => setState(() => _data['showEmail'] = value),
        ),
        SwitchListTile(
          title: const Text('Afficher le téléphone'),
          value: _data['showPhone'] ?? false,
          onChanged: (value) => setState(() => _data['showPhone'] = value),
        ),
        SwitchListTile(
          title: const Text('Permettre le contact'),
          value: _data['allowContact'] ?? true,
          onChanged: (value) => setState(() => _data['allowContact'] = value),
        ),
      ],
    );
  }

  Widget _buildPrayerWallEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration du Mur de prière',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Titre et sous-titre
        TextFormField(
          initialValue: _data['title'] ?? 'Mur de prière',
          decoration: const InputDecoration(
            labelText: 'Titre du mur de prière',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['subtitle'] ?? 'Partagez vos demandes de prière et témoignages',
          decoration: const InputDecoration(
            labelText: 'Sous-titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: 16),
        
        // Mode d'affichage
        DropdownButtonFormField<String>(
          value: _data['displayMode'] ?? 'cards',
          decoration: const InputDecoration(
            labelText: 'Mode d\'affichage',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'cards', child: Text('Cartes')),
            DropdownMenuItem(value: 'timeline', child: Text('Timeline')),
            DropdownMenuItem(value: 'compact', child: Text('Compact')),
            DropdownMenuItem(value: 'masonry', child: Text('Masonry')),
          ],
          onChanged: (value) => setState(() => _data['displayMode'] = value),
        ),
        const SizedBox(height: 16),
        
        // Types de contenu
        Text(
          'Types de contenu autorisés',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Demandes de prière'),
          subtitle: const Text('Permettre aux utilisateurs de soumettre des demandes'),
          value: _data['allowRequests'] ?? true,
          onChanged: (value) => setState(() => _data['allowRequests'] = value),
        ),
        SwitchListTile(
          title: const Text('Témoignages'),
          subtitle: const Text('Permettre le partage de témoignages et réponses'),
          value: _data['allowTestimonies'] ?? true,
          onChanged: (value) => setState(() => _data['allowTestimonies'] = value),
        ),
        SwitchListTile(
          title: const Text('Prières d\'intercession'),
          subtitle: const Text('Permettre les prières pour les autres'),
          value: _data['allowIntercession'] ?? true,
          onChanged: (value) => setState(() => _data['allowIntercession'] = value),
        ),
        SwitchListTile(
          title: const Text('Actions de grâce'),
          subtitle: const Text('Permettre les messages de remerciement'),
          value: _data['allowThanksgiving'] ?? true,
          onChanged: (value) => setState(() => _data['allowThanksgiving'] = value),
        ),
        const SizedBox(height: 16),
        
        // Catégories
        Text(
          'Catégories disponibles',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data['categories'] ?? 'Santé,Famille,Travail,Église,Finances,Relation,Spiritualité,Autre',
          decoration: const InputDecoration(
            labelText: 'Catégories (séparées par virgule)',
            border: OutlineInputBorder(),
            helperText: 'Ex: Santé,Famille,Travail,Église',
          ),
          maxLines: 2,
          onChanged: (value) => _data['categories'] = value,
        ),
        const SizedBox(height: 16),
        
        // Fonctionnalités avancées
        Text(
          'Fonctionnalités communautaires',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Système de "Je prie pour toi"'),
          subtitle: const Text('Permettre aux utilisateurs d\'indiquer qu\'ils prient'),
          value: _data['allowPrayerCount'] ?? true,
          onChanged: (value) => setState(() => _data['allowPrayerCount'] = value),
        ),
        SwitchListTile(
          title: const Text('Commentaires'),
          subtitle: const Text('Permettre les commentaires d\'encouragement'),
          value: _data['allowComments'] ?? true,
          onChanged: (value) => setState(() => _data['allowComments'] = value),
        ),
        SwitchListTile(
          title: const Text('Partage anonyme'),
          subtitle: const Text('Permettre la soumission anonyme'),
          value: _data['allowAnonymous'] ?? true,
          onChanged: (value) => setState(() => _data['allowAnonymous'] = value),
        ),
        SwitchListTile(
          title: const Text('Modération'),
          subtitle: const Text('Modération des publications avant affichage'),
          value: _data['enableModeration'] ?? false,
          onChanged: (value) => setState(() => _data['enableModeration'] = value),
        ),
        const SizedBox(height: 16),
        
        // Paramètres d'affichage
        Text(
          'Paramètres d\'affichage',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data['maxItemsPerPage']?.toString() ?? '10',
          decoration: const InputDecoration(
            labelText: 'Nombre maximum d\'éléments par page',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['maxItemsPerPage'] = int.tryParse(value) ?? 10,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Afficher les dates'),
          value: _data['showDates'] ?? true,
          onChanged: (value) => setState(() => _data['showDates'] = value),
        ),
        SwitchListTile(
          title: const Text('Afficher les auteurs'),
          value: _data['showAuthors'] ?? true,
          onChanged: (value) => setState(() => _data['showAuthors'] = value),
        ),
        SwitchListTile(
          title: const Text('Afficher les catégories'),
          value: _data['showCategories'] ?? true,
          onChanged: (value) => setState(() => _data['showCategories'] = value),
        ),
        SwitchListTile(
          title: const Text('Tri par date (récent en premier)'),
          value: _data['sortByDate'] ?? true,
          onChanged: (value) => setState(() => _data['sortByDate'] = value),
        ),
        const SizedBox(height: 16),
        
        // Couleurs et style
        Text(
          'Personnalisation visuelle',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data['primaryColor'] ?? '#E91E63',
          decoration: const InputDecoration(
            labelText: 'Couleur principale',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB (ex: #E91E63)',
          ),
          onChanged: (value) => _data['primaryColor'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['accentColor'] ?? '#FCE4EC',
          decoration: const InputDecoration(
            labelText: 'Couleur d\'accent',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB (ex: #FCE4EC)',
          ),
          onChanged: (value) => _data['accentColor'] = value,
        ),
        const SizedBox(height: 16),
        
        // Textes configurables
        Text(
          'Textes personnalisés',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data['submitButtonText'] ?? 'Partager une demande',
          decoration: const InputDecoration(
            labelText: 'Texte du bouton de soumission',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['submitButtonText'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['emptyStateText'] ?? 'Aucune demande de prière pour le moment.\nSoyez le premier à partager.',
          decoration: const InputDecoration(
            labelText: 'Message quand vide',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) => _data['emptyStateText'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['prayerCountText'] ?? 'personnes prient',
          decoration: const InputDecoration(
            labelText: 'Texte du compteur de prière',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['prayerCountText'] = value,
        ),
      ],
    );
  }

  // Éditeurs pour les composants Grid
  Widget _buildGridCardEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la carte Grid',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['subtitle'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Sous-titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['iconName'] ?? 'star',
          decoration: const InputDecoration(
            labelText: 'Icône',
            border: OutlineInputBorder(),
          ),
          items: _getIconOptions(),
          onChanged: (value) => setState(() => _data['iconName'] = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['backgroundColor'] ?? '#6F61EF',
          decoration: const InputDecoration(
            labelText: 'Couleur de fond',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB',
          ),
          onChanged: (value) => _data['backgroundColor'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['textColor'] ?? '#FFFFFF',
          decoration: const InputDecoration(
            labelText: 'Couleur du texte',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB',
          ),
          onChanged: (value) => _data['textColor'] = value,
        ),
      ],
    );
  }

  Widget _buildGridStatEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la statistique Grid',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre de la statistique',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['value'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Valeur',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['value'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['unit'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Unité (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Ex: %, €, personnes, etc.',
          ),
          onChanged: (value) => _data['unit'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['trend'] ?? 'stable',
          decoration: const InputDecoration(
            labelText: 'Tendance',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'up', child: Text('En hausse')),
            DropdownMenuItem(value: 'down', child: Text('En baisse')),
            DropdownMenuItem(value: 'stable', child: Text('Stable')),
          ],
          onChanged: (value) => setState(() => _data['trend'] = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['iconName'] ?? 'trending_up',
          decoration: const InputDecoration(
            labelText: 'Icône',
            border: OutlineInputBorder(),
          ),
          items: _getIconOptions(),
          onChanged: (value) => setState(() => _data['iconName'] = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['color'] ?? '#4CAF50',
          decoration: const InputDecoration(
            labelText: 'Couleur',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB',
          ),
          onChanged: (value) => _data['color'] = value,
        ),
      ],
    );
  }

  Widget _buildGridIconTextEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Icône + Texte Grid',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['iconName'] ?? 'favorite',
          decoration: const InputDecoration(
            labelText: 'Icône',
            border: OutlineInputBorder(),
          ),
          items: _getIconOptions(),
          onChanged: (value) => setState(() => _data['iconName'] = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['iconColor'] ?? '#FF5722',
          decoration: const InputDecoration(
            labelText: 'Couleur de l\'icône',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB',
          ),
          onChanged: (value) => _data['iconColor'] = value,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _data['textAlign'] ?? 'center',
          decoration: const InputDecoration(
            labelText: 'Alignement du texte',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'center', child: Text('Centré')),
            DropdownMenuItem(value: 'left', child: Text('À gauche')),
            DropdownMenuItem(value: 'right', child: Text('À droite')),
          ],
          onChanged: (value) => setState(() => _data['textAlign'] = value),
        ),
      ],
    );
  }

  Widget _buildGridImageCardEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la carte image Grid',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Sélecteur d'image
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _data['imageUrl'] != null && _data['imageUrl'].isNotEmpty
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _data['imageUrl'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => setState(() => _data['imageUrl'] = ''),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => ImagePickerWidget(
                        onImageSelected: (url) {
                          setState(() => _data['imageUrl'] = url);
                        },
                      ),
                    );
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Cliquez pour ajouter une image',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre de l\'image',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['imageHeight']?.toString() ?? '120',
          decoration: const InputDecoration(
            labelText: 'Hauteur de l\'image (pixels)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['imageHeight'] = int.tryParse(value) ?? 120,
        ),
      ],
    );
  }

  Widget _buildGridProgressEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la progression Grid',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: 16),
        Text(
          'Progression: ${((_data['progress'] ?? 0.0) * 100).round()}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: (_data['progress'] ?? 0.0).toDouble(),
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: '${((_data['progress'] ?? 0.0) * 100).round()}%',
          onChanged: (value) => setState(() => _data['progress'] = value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Afficher le pourcentage'),
          value: _data['showPercentage'] ?? true,
          onChanged: (value) => setState(() => _data['showPercentage'] = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['color'] ?? '#2196F3',
          decoration: const InputDecoration(
            labelText: 'Couleur de la barre',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB',
          ),
          onChanged: (value) => _data['color'] = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _data['backgroundColor'] ?? '#E3F2FD',
          decoration: const InputDecoration(
            labelText: 'Couleur de fond',
            border: OutlineInputBorder(),
            helperText: 'Format: #RRGGBB',
          ),
          onChanged: (value) => _data['backgroundColor'] = value,
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _getIconOptions() {
    final icons = {
      'star': 'Étoile',
      'favorite': 'Cœur',
      'trending_up': 'Tendance haussière',
      'trending_down': 'Tendance baissière',
      'trending_flat': 'Tendance stable',
      'analytics': 'Analytiques',
      'dashboard': 'Tableau de bord',
      'people': 'Personnes',
      'group': 'Groupe',
      'event': 'Événement',
      'calendar': 'Calendrier',
      'church': 'Église',
      'home': 'Accueil',
      'settings': 'Paramètres',
      'info': 'Information',
      'help': 'Aide',
      'phone': 'Téléphone',
      'email': 'Email',
      'location': 'Localisation',
      'music': 'Musique',
      'pray': 'Prière',
      'bible': 'Bible',
      'heart': 'Cœur vide',
      'cross': 'Croix',
      'community': 'Communauté',
    };

    return icons.entries
        .map((entry) => DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Icon(_getIconFromName(entry.key), size: 18),
                  const SizedBox(width: 8),
                  Text(entry.value),
                ],
              ),
            ))
        .toList();
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'trending_up': return Icons.trending_up;
      case 'trending_down': return Icons.trending_down;
      case 'trending_flat': return Icons.trending_flat;
      case 'analytics': return Icons.analytics;
      case 'dashboard': return Icons.dashboard;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'event': return Icons.event;
      case 'calendar': return Icons.calendar_today;
      case 'church': return Icons.church;
      case 'home': return Icons.home;
      case 'settings': return Icons.settings;
      case 'info': return Icons.info;
      case 'help': return Icons.help;
      case 'phone': return Icons.phone;
      case 'email': return Icons.email;
      case 'location': return Icons.location_on;
      case 'music': return Icons.music_note;
      case 'pray': return Icons.volunteer_activism;
      case 'bible': return Icons.menu_book;
      case 'heart': return Icons.favorite_border;
      case 'cross': return Icons.add;
      case 'community': return Icons.groups;
      default: return Icons.star;
    }
  }

  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'button':
        return Icons.smart_button;
      case 'video':
        return Icons.video_library;
      case 'list':
        return Icons.list;
      case 'form':
        return Icons.assignment;
      case 'scripture':
        return Icons.menu_book;
      case 'banner':
        return Icons.campaign;
      case 'map':
        return Icons.map;
      case 'audio':
        return Icons.music_note;
      case 'googlemap':
        return Icons.location_on;
      case 'html':
        return Icons.code;
      case 'quote':
        return Icons.format_quote;
      case 'groups':
        return Icons.groups;
      case 'events':
        return Icons.event;
      case 'blog_article':
        return Icons.article;
      case 'service':
        return Icons.room_service;
      case 'advanced_form':
        return Icons.dynamic_form;
      case 'task':
        return Icons.task_alt;
      case 'songs':
        return Icons.music_note;
      case 'appointment':
        return Icons.schedule;
      case 'person':
        return Icons.person;
      case 'prayer_wall':
        return Icons.favorite;
      case 'grid_card':
        return Icons.crop_landscape;
      case 'grid_stat':
        return Icons.analytics;
      case 'grid_icon_text':
        return Icons.text_rotate_vertical;
      case 'grid_image_card':
        return Icons.image_aspect_ratio;
      case 'grid_progress':
        return Icons.pie_chart;
      case 'grid_container':
        return Icons.grid_view;
      default:
        return Icons.extension;
    }
  }

  Widget _buildGridContainerEditor() {
    final columns = _data['columns'] ?? 2;
    final mainAxisSpacing = _data['mainAxisSpacing'] ?? 12.0;
    final crossAxisSpacing = _data['crossAxisSpacing'] ?? 12.0;
    final childAspectRatio = _data['childAspectRatio'] ?? 1.0;
    final padding = _data['padding'] ?? 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuration de la Grille',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Nombre de colonnes
        const Text('Nombre de colonnes', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: columns.toDouble(),
                min: 1,
                max: 6,
                divisions: 5,
                label: columns.toString(),
                onChanged: (value) {
                  setState(() {
                    _data['columns'] = value.toInt();
                  });
                },
              ),
            ),
            Container(
              width: 40,
              child: Text(
                columns.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Espacement principal (vertical)
        const Text('Espacement vertical', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: mainAxisSpacing,
                min: 0,
                max: 50,
                divisions: 10,
                label: mainAxisSpacing.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _data['mainAxisSpacing'] = value;
                  });
                },
              ),
            ),
            Container(
              width: 40,
              child: Text(
                mainAxisSpacing.toInt().toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Espacement croisé (horizontal)
        const Text('Espacement horizontal', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: crossAxisSpacing,
                min: 0,
                max: 50,
                divisions: 10,
                label: crossAxisSpacing.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _data['crossAxisSpacing'] = value;
                  });
                },
              ),
            ),
            Container(
              width: 40,
              child: Text(
                crossAxisSpacing.toInt().toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Ratio d'aspect
        const Text('Ratio d\'aspect (largeur/hauteur)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: childAspectRatio,
                min: 0.5,
                max: 3.0,
                divisions: 10,
                label: childAspectRatio.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _data['childAspectRatio'] = value;
                  });
                },
              ),
            ),
            Container(
              width: 40,
              child: Text(
                childAspectRatio.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Padding (marge interne)
        const Text('Marge interne du container', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: padding,
                min: 0,
                max: 40,
                divisions: 8,
                label: padding.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _data['padding'] = value;
                  });
                },
              ),
            ),
            Container(
              width: 40,
              child: Text(
                padding.toInt().toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section pour gérer les composants enfants
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Composants dans la grille',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddChildComponentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Liste des composants enfants
        if (_children.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Aucun composant ajouté. Utilisez le bouton "Ajouter" ci-dessus.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ..._children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getComponentIcon(child.type), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          child.typeLabel,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editChildComponent(index),
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    onPressed: () => _removeChildComponent(index),
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  void _showAddChildComponentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un composant'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sélectionnez le type de composant à ajouter :'),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _getAvailableChildComponentTypes().map((type) {
                      return ListTile(
                        leading: Icon(_getComponentIcon(type['type'] ?? '')),
                        title: Text(type['label'] ?? ''),
                        onTap: () {
                          Navigator.pop(context);
                          // Attendre que la dialog se ferme avant d'ajouter le composant
                          Future.delayed(const Duration(milliseconds: 200), () {
                            _addChildComponent(type['type'] ?? '');
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getAvailableChildComponentTypes() {
    return [
      {'type': 'text', 'label': 'Texte'},
      {'type': 'image', 'label': 'Image'},
      {'type': 'button', 'label': 'Bouton'},
      {'type': 'grid_card', 'label': 'Carte'},
      {'type': 'grid_stat', 'label': 'Statistique'},
      {'type': 'grid_icon_text', 'label': 'Icône + Texte'},
      {'type': 'grid_image_card', 'label': 'Carte Image'},
    ];
  }

  void _addChildComponent(String type) {
    try {
      final newComponent = PageComponent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        name: 'Nouveau ${_getComponentTypeLabel(type)}',
        data: _getDefaultDataForType(type),
        order: _children.length,
      );

      setState(() {
        _children.add(newComponent);
      });
      
      // Afficher un message de confirmation et permettre l'édition manuelle
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Composant "${_getComponentTypeLabel(type)}" ajouté avec succès !'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Modifier',
              onPressed: () {
                // Ouvrir l'éditeur pour le nouveau composant après un délai
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _editChildComponent(_children.length - 1);
                  }
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout du composant : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editChildComponent(int index) {
    if (index < 0 || index >= _children.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : Composant non trouvé'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final child = _children[index];
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComponentEditor(
            component: child,
            onSave: (updatedChild) {
              setState(() {
                _children[index] = updatedChild;
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture de l\'éditeur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeChildComponent(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le composant'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce composant ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _children.removeAt(index);
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _getComponentTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Texte';
      case 'image':
        return 'Image';
      case 'button':
        return 'Bouton';
      case 'webview':
        return 'WebView';
      case 'grid_card':
        return 'Carte';
      case 'grid_stat':
        return 'Statistique';
      case 'grid_icon_text':
        return 'Icône + Texte';
      case 'grid_image_card':
        return 'Carte Image';
      default:
        return 'Composant';
    }
  }

  Map<String, dynamic> _getDefaultDataForType(String type) {
    switch (type) {
      case 'text':
        return {'content': 'Votre texte ici', 'fontSize': 16.0, 'color': '#000000'};
      case 'image':
        return {'url': '', 'alt': 'Image'};
      case 'button':
        return {
          'text': 'Bouton',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
          'borderRadius': 8.0,
        };
      case 'grid_card':
        return {
          'title': 'Titre',
          'subtitle': 'Sous-titre',
          'description': 'Description',
          'iconName': 'star',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
        };
      case 'grid_stat':
        return {
          'title': 'Statistique',
          'value': '0',
          'unit': '',
          'trend': 'stable',
          'color': '#4CAF50',
          'iconName': 'trending_up',
        };
      case 'grid_icon_text':
        return {
          'title': 'Titre',
          'description': 'Description',
          'iconName': 'star',
          'iconColor': '#FF5722',
          'textAlign': 'center',
        };
      case 'grid_image_card':
        return {
          'title': 'Titre',
          'subtitle': 'Sous-titre',
          'imageUrl': '',
          'overlayColor': '#000000',
          'overlayOpacity': 0.3,
        };
      case 'webview':
        return {
          'url': '',
          'title': 'Page Web',
          'height': 400.0,
          'showAppBar': true,
          'allowNavigation': true,
          'allowZoom': true,
          'backgroundColor': 'white',
          'debuggingEnabled': false,
          'allowsInlineMediaPlayback': true,
          'mediaPlaybackRequiresUserAction': false,
        };
      default:
        return {};
    }
  }

  Widget _buildWebViewEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration WebView',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // URL
        TextFormField(
          initialValue: _data['url'] ?? '',
          decoration: const InputDecoration(
            labelText: 'URL du site web *',
            border: OutlineInputBorder(),
            helperText: 'Ex: https://www.google.com ou www.exemple.com',
            prefixIcon: Icon(Icons.link),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'URL est requise';
            }
            return null;
          },
          onChanged: (value) => setState(() => _data['url'] = value),
        ),
        
        const SizedBox(height: 16),
        
        // Titre
        TextFormField(
          initialValue: _data['title'] ?? 'Page Web',
          decoration: const InputDecoration(
            labelText: 'Titre de la WebView',
            border: OutlineInputBorder(),
            helperText: 'Nom affiché dans la barre de titre',
          ),
          onChanged: (value) => setState(() => _data['title'] = value),
        ),
        
        const SizedBox(height: 16),
        
        // Hauteur
        TextFormField(
          initialValue: (_data['height'] ?? 400.0).toString(),
          decoration: const InputDecoration(
            labelText: 'Hauteur (px)',
            border: OutlineInputBorder(),
            helperText: 'Hauteur de la WebView en pixels',
            suffixText: 'px',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final height = double.tryParse(value) ?? 400.0;
            setState(() => _data['height'] = height);
          },
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Options d\'affichage',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Afficher la barre de navigation
        SwitchListTile(
          title: const Text('Afficher la barre de navigation'),
          subtitle: const Text('Titre et boutons de navigation'),
          value: _data['showAppBar'] ?? true,
          onChanged: (value) => setState(() => _data['showAppBar'] = value),
        ),
        
        // Permettre la navigation
        SwitchListTile(
          title: const Text('Permettre la navigation'),
          subtitle: const Text('Boutons précédent/suivant et liens'),
          value: _data['allowNavigation'] ?? true,
          onChanged: (value) => setState(() => _data['allowNavigation'] = value),
        ),
        
        // Permettre le zoom
        SwitchListTile(
          title: const Text('Permettre le zoom'),
          subtitle: const Text('Permettre aux utilisateurs de zoomer'),
          value: _data['allowZoom'] ?? true,
          onChanged: (value) => setState(() => _data['allowZoom'] = value),
        ),
        
        const SizedBox(height: 16),
        
        // Couleur d'arrière-plan
        DropdownButtonFormField<String>(
          value: _data['backgroundColor'] ?? 'white',
          decoration: const InputDecoration(
            labelText: 'Couleur d\'arrière-plan',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'white', child: Text('Blanc')),
            DropdownMenuItem(value: 'black', child: Text('Noir')),
            DropdownMenuItem(value: 'transparent', child: Text('Transparent')),
            DropdownMenuItem(value: 'grey', child: Text('Gris')),
          ],
          onChanged: (value) => setState(() => _data['backgroundColor'] = value),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Options avancées',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // User Agent personnalisé
        TextFormField(
          initialValue: _data['userAgent'] ?? '',
          decoration: const InputDecoration(
            labelText: 'User Agent personnalisé (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Identifiant du navigateur personnalisé',
          ),
          onChanged: (value) => setState(() => _data['userAgent'] = value),
        ),
        
        const SizedBox(height: 16),
        
        // JavaScript initial
        TextFormField(
          initialValue: _data['initialJavaScript'] ?? '',
          decoration: const InputDecoration(
            labelText: 'JavaScript initial (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Code JavaScript exécuté au chargement',
          ),
          maxLines: 3,
          onChanged: (value) => setState(() => _data['initialJavaScript'] = value),
        ),
        
        const SizedBox(height: 16),
        
        // Options média
        SwitchListTile(
          title: const Text('Lecture média inline'),
          subtitle: const Text('Permettre la lecture vidéo/audio dans la page'),
          value: _data['allowsInlineMediaPlayback'] ?? true,
          onChanged: (value) => setState(() => _data['allowsInlineMediaPlayback'] = value),
        ),
        
        SwitchListTile(
          title: const Text('Action utilisateur requise pour média'),
          subtitle: const Text('L\'utilisateur doit cliquer pour lire'),
          value: _data['mediaPlaybackRequiresUserAction'] ?? false,
          onChanged: (value) => setState(() => _data['mediaPlaybackRequiresUserAction'] = value),
        ),
        
        // Mode débogage
        SwitchListTile(
          title: const Text('Mode débogage'),
          subtitle: const Text('Activer le débogage WebView (développement)'),
          value: _data['debuggingEnabled'] ?? false,
          onChanged: (value) => setState(() => _data['debuggingEnabled'] = value),
        ),
        
        const SizedBox(height: 24),
        
        // Note d'aide
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Conseils d\'utilisation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• Assurez-vous que l\'URL commence par http:// ou https://\n'
                '• Certains sites bloquent l\'intégration (ex: YouTube, Facebook)\n'
                '• Testez sur différents appareils pour la compatibilité\n'
                '• Utilisez HTTPS pour éviter les problèmes de sécurité',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}