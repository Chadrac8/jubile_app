import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/page_model.dart';
import '../../models/image_action_model.dart';
// Removed unused import '../../models/component_action_model.dart';
import '../../services/image_action_service.dart';
import '../../services/component_action_service.dart';
import '../../services/youtube_service.dart';
import '../../services/soundcloud_service.dart';
import '../../services/media_player_service.dart';
import '../../theme.dart';

class ComponentRenderer extends StatelessWidget {
  final PageComponent component;
  final bool isPreview;
  final bool isGridMode;

  const ComponentRenderer({
    super.key,
    required this.component,
    this.isPreview = false,
    this.isGridMode = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (component.type) {
      case 'text':
        return _buildTextComponent(context);
      case 'image':
        return _buildImageComponent(context);
      case 'button':
        return _buildButtonComponent(context);
      case 'video':
        return _buildVideoComponent();
      case 'list':
        return _buildListComponent(context);

      case 'scripture':
        return _buildScriptureComponent(context);
      case 'banner':
        return _buildBannerComponent(context);
      case 'map':
        return _buildMapComponent();
      case 'audio':
        return _buildAudioComponent();
      case 'googlemap':
        return _buildGoogleMapComponent();
      case 'html':
        return _buildHtmlComponent();
      case 'webview':
        return _buildWebViewComponent();
      case 'quote':
        return _buildQuoteComponent();
      case 'groups':
        return _buildGroupsComponent();
      case 'events':
        return _buildEventsComponent();







      case 'prayer_wall':
        return _buildPrayerWallComponent(context);
      case 'grid_card':
        return _buildGridCardComponent(context);
      case 'grid_stat':
        return _buildGridStatComponent(context);
      case 'grid_icon_text':
        return _buildGridIconTextComponent(context);
      case 'grid_image_card':
        return _buildGridImageCardComponent(context);
      case 'grid_progress':
        return _buildGridProgressComponent(context);
      case 'grid_container':
        return _buildGridContainerComponent(context);
      default:
        return _buildUnsupportedComponent();
    }
  }

  Widget _buildTextComponent(BuildContext context) {
    final content = component.data['content'] ?? '';
    final fontSize = (component.data['fontSize'] ?? 16).toDouble();
    final textAlign = _getTextAlign(component.data['textAlign'] ?? 'left');
    final fontWeight = component.data['fontWeight'] == 'bold' 
        ? FontWeight.bold 
        : FontWeight.normal;

    // Adaptation pour le mode grid
    if (isGridMode) {
      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Container(
          height: 120, // Hauteur fixe pour uniformité en grid
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              _parseMarkdown(content),
              style: TextStyle(
                fontSize: fontSize * 0.9, // Légèrement plus petit en grid
                fontWeight: fontWeight,
                color: AppTheme.textPrimaryColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // Mode linéaire (par défaut)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _parseMarkdown(content),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: AppTheme.textPrimaryColor,
          height: 1.5,
        ),
        textAlign: textAlign,
      ),
    );
  }

  Widget _buildImageComponent(BuildContext context) {
    final url = component.data['url'] ?? '';
    final alt = component.data['alt'] ?? '';
    final height = (component.data['height'] ?? 200).toDouble();
    final fit = _getBoxFit(component.data['fit'] ?? 'cover');
    
    // Vérifier s'il y a une action configurée
    final hasAction = component.data['action'] != null;
    final action = hasAction ? ImageAction.fromMap(component.data['action']) : null;

    // Adaptation pour le mode grid
    final gridHeight = isGridMode ? 150.0 : height;
    final gridFit = isGridMode ? BoxFit.cover : fit;

    if (url.isEmpty) {
      return Container(
        height: gridHeight,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: isGridMode ? 32 : 48, color: Colors.grey),
              SizedBox(height: isGridMode ? 4 : 8),
              Text(
                'Image non configurée',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isGridMode ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget imageWidget = Container(
      height: gridHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // 0.1 opacity
            blurRadius: isGridMode ? 2 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: gridFit,
              width: double.infinity,
              height: gridHeight,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );

    // Si une action est configurée, encapsuler dans un GestureDetector
    if (hasAction && action != null && !isPreview) {
      return GestureDetector(
        onTap: () => _handleImageAction(context, action),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  void _handleImageAction(BuildContext context, ImageAction action) {
    ImageActionService.handleImageAction(context, action);
  }

  Widget _buildButtonComponent(BuildContext context) {
    final text = component.data['text'] ?? 'Bouton';
    final url = component.data['url'] ?? '';
    final style = component.data['style'] ?? 'primary';
    final size = component.data['size'] ?? 'medium';

    Widget buttonWidget;

    // Adaptation pour le mode grid
    if (isGridMode) {
      buttonWidget = Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Container(
          height: 120,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 32,
                      color: _getButtonColor(style),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getButtonColor(style),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mode linéaire (par défaut)
      buttonWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: ElevatedButton(
            onPressed: () => _handleButtonAction(context),
            style: _getButtonStyle(style, size),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text),
              ],
            ),
          ),
        ),
      );
    }

    // Encapsuler dans GestureDetector si mode grid et action configurée
    if (isGridMode && component.action != null && !isPreview) {
      return GestureDetector(
        onTap: () => _handleButtonAction(context),
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }

  void _handleButtonAction(BuildContext context) {
    if (component.action != null) {
      ComponentActionService.handleComponentAction(context, component.action!);
    } else {
      // Fallback vers l'ancienne méthode URL
      final url = component.data['url'] ?? '';
      if (url.isNotEmpty) {
        _handleButtonPress(url);
      }
    }
  }

  Widget _buildVideoComponent() {
    final url = component.data['url'] ?? '';
    final title = component.data['title'] ?? '';
    final autoplay = component.data['autoplay'] ?? false;
    final loop = component.data['loop'] ?? false;
    final hideControls = component.data['hideControls'] ?? false;
    final mute = component.data['mute'] ?? false;
    final playbackMode = component.data['playbackMode'] ?? 'integrated'; // 'integrated' ou 'external'

    if (url.isEmpty) {
      return Container(
        height: isGridMode ? 120 : 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: isGridMode ? 32 : 48, color: Colors.grey),
              SizedBox(height: isGridMode ? 4 : 8),
              Text(
                'Vidéo non configurée',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isGridMode ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Analyse de l'URL YouTube avec le nouveau service
    final urlInfo = YouTubeService.parseYouTubeUrl(url);
    
    if (!urlInfo.isValid) {
      return Container(
        height: isGridMode ? 120 : 200,
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: isGridMode ? 32 : 48, color: Colors.red[400]),
              SizedBox(height: isGridMode ? 4 : 8),
              Text(
                'URL YouTube invalide',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: isGridMode ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mode de lecture intégré
    if (playbackMode == 'integrated') {
      return MediaPlayerService.buildYouTubePlayer(
        url: url,
        autoPlay: component.data['autoPlay'] ?? autoplay,
        mute: component.data['mute'] ?? mute,
        showControls: component.data['showControls'] ?? !hideControls,
        loop: component.data['loop'] ?? loop,
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // 0.1 opacity
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image de fond/miniature
            if (urlInfo.thumbnailUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: urlInfo.thumbnailUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Icon(
                      _getContentTypeIcon(urlInfo.contentType),
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Container(
                color: Colors.grey[800],
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Icon(
                    _getContentTypeIcon(urlInfo.contentType),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x66000000), // 0.4 opacity
                  ],
                ),
              ),
            ),
            
            // Badge du type de contenu (en haut à droite)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xB3000000), // 0.7 opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getContentTypeIcon(urlInfo.contentType),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      urlInfo.displayType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Indicateurs d'options (en haut à gauche)
            if (autoplay || loop || hideControls)
              Positioned(
                top: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (autoplay)
                      _buildOptionBadge(Icons.play_arrow, 'Auto'),
                    if (loop)
                      _buildOptionBadge(Icons.repeat, 'Boucle'),
                    if (hideControls)
                      _buildOptionBadge(Icons.videocam_off, 'Sans contrôles'),
                  ],
                ),
              ),
            
            // Bouton de lecture central
            Center(
              child: GestureDetector(
                onTap: () => _handleVideoPlay(url, urlInfo),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xF2FFFFFF), // 0.95 opacity
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000), // 0.2 opacity
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    urlInfo.contentType == YouTubeContentType.playlist 
                      ? Icons.playlist_play 
                      : Icons.play_arrow,
                    size: 36,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            
            // Informations en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xCC000000), // 0.8 opacity
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Informations techniques
                    Row(
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                            color: Color(0xCCFFFFFF), // 0.8 opacity
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ouvrir sur YouTube',
                          style: TextStyle(
                          color: Color(0xCCFFFFFF), // 0.8 opacity
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (urlInfo.videoId.isNotEmpty)
                          Text(
                            'ID: ${urlInfo.videoId.substring(0, 8)}...',
                            style: TextStyle(
                              color: Color(0x99FFFFFF), // 0.6 opacity
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionBadge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(230), // 0.9 opacity
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getContentTypeIcon(YouTubeContentType contentType) {
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

  Widget _buildListComponent(BuildContext context) {
    final title = component.data['title'] ?? '';
    final listType = component.data['listType'] ?? 'simple';
    final items = List<Map<String, dynamic>>.from(component.data['items'] ?? []);

    // Adaptation pour le mode grid
    if (isGridMode) {
      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.list, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.isNotEmpty ? title : 'Liste',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  items.isEmpty 
                    ? 'Liste vide' 
                    : '${items.length} élément${items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mode linéaire (par défaut)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Aucun élément dans cette liste',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildListItem(context, item, index, listType);
          }),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> item, int index, String listType) {
    final title = item['title'] ?? '';
    final description = item['description'] ?? '';
    final action = item['action'] ?? '';

    switch (listType) {
      case 'cards':
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withAlpha(25), // 0.1 opacity
              child: Icon(
                Icons.circle,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            title: Text(title),
            subtitle: description.isNotEmpty ? Text(description) : null,
            trailing: action.isNotEmpty ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
            onTap: action.isNotEmpty ? () => _handleAction(action) : null,
          ),
        );
      
      case 'numbered':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      
      case 'links':
        return InkWell(
          onTap: action.isNotEmpty ? () => _handleAction(action) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action.isNotEmpty)
                  Icon(
                    Icons.open_in_new,
                    color: AppTheme.textTertiaryColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      
      default: // simple
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }



  Widget _buildScriptureComponent(BuildContext context) {
    final verse = component.data['verse'] ?? '';
    final reference = component.data['reference'] ?? '';
    final version = component.data['version'] ?? 'LSG';

    // Adaptation pour le mode grid
    if (isGridMode) {
      if (verse.isEmpty) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 32, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Verset non configuré',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withAlpha(13), // 0.05 opacity
                AppTheme.secondaryColor.withAlpha(13), // 0.05 opacity
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withAlpha(51), // 0.2 opacity
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Verset',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  verse,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimaryColor,
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (reference.isNotEmpty)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    reference,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Mode linéaire (par défaut)
    if (verse.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Verset non configuré',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withAlpha(13), // 0.05 opacity
            AppTheme.secondaryColor.withAlpha(13), // 0.05 opacity
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(51), // 0.2 opacity
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.format_quote,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  verse,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimaryColor,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          if (reference.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '— $reference',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (version != 'LSG') ...[
                  const SizedBox(width: 8),
                  Text(
                    '($version)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerComponent(BuildContext context) {
    final title = component.data['title'] ?? '';
    final subtitle = component.data['subtitle'] ?? '';
    final backgroundColor = Color(
      int.parse((component.data['backgroundColor'] ?? '#6F61EF').replaceFirst('#', '0xFF'))
    );
    final textColor = Color(
      int.parse((component.data['textColor'] ?? '#FFFFFF').replaceFirst('#', '0xFF'))
    );

    Widget bannerWidget;
    
    // Adaptation pour le mode grid
    if (isGridMode) {
      bannerWidget = Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withAlpha(77), // 0.3 opacity
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          ],
        ),
      );
    } else {
      // Mode linéaire (par défaut)
      bannerWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor.withAlpha(230), // 0.9 opacity
                    ),
                  ),
                ],
              ],
            ),

          ],
        ),
      );
    }

    // Encapsuler dans GestureDetector si action configurée
    if (component.action != null && !isPreview) {
      return GestureDetector(
        onTap: () => ComponentActionService.handleComponentAction(context, component.action!),
        child: bannerWidget,
      );
    }

    return bannerWidget;
  }

  Widget _buildMapComponent() {
    final address = component.data['address'] ?? '';
    
    if (address.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Carte non configurée',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              color: Colors.grey[200],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Carte interactive'),
                    Text('(nécessite Google Maps)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            
            // Overlay avec adresse
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioComponent() {
    final sourceType = component.data['source_type'] ?? 'direct';
    final soundCloudUrl = component.data['soundcloud_url'] ?? '';
    final directUrl = component.data['url'] ?? '';
    final title = component.data['title'] ?? '';
    final artist = component.data['artist'] ?? '';
    final duration = component.data['duration'] ?? '';
    final description = component.data['description'] ?? '';
    final playbackMode = component.data['playbackMode'] ?? 'integrated'; // 'integrated' ou 'external'
    final autoplay = component.data['autoplay'] ?? false;
    final showComments = component.data['showComments'] ?? true;
    final color = component.data['color'] ?? 'ff5500';

    // Détermine l'URL principale à utiliser
    final primaryUrl = sourceType == 'soundcloud' ? soundCloudUrl : directUrl;
    
    if (primaryUrl.isEmpty) {
      return _buildEmptyAudioComponent();
    }

    // Mode de lecture intégré
    if (playbackMode == 'integrated') {
      if (sourceType == 'soundcloud') {
        return MediaPlayerService.buildSoundCloudPlayer(
          url: soundCloudUrl,
          autoPlay: component.data['autoPlay'] ?? autoplay,
          showComments: component.data['showComments'] ?? showComments,
          color: color,
        );
      } else {
        return MediaPlayerService.buildAudioFilePlayer(
          url: directUrl,
          title: title,
          artist: artist,
          autoPlay: component.data['autoPlay'] ?? autoplay,
        );
      }
    }

    // Mode externe (comportement actuel)
    if (sourceType == 'soundcloud') {
      return _buildSoundCloudAudioComponent(soundCloudUrl, title, artist, duration, description);
    } else {
      return _buildDirectFileAudioComponent(directUrl, title, artist, duration, description);
    }
  }

  Widget _buildEmptyAudioComponent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.music_note, size: 48, color: Colors.grey),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio non configuré',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Veuillez configurer une source audio',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCloudAudioComponent(String url, String title, String artist, String duration, String description) {
    final info = SoundCloudService.parseSoundCloudUrl(url);
    
    if (!info.isValid) {
      return _buildErrorAudioComponent('URL SoundCloud invalide', url);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec informations SoundCloud
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              // Logo/icône SoundCloud
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSoundCloudIcon(info.contentType),
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SoundCloud',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            info.displayType,
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title.isNotEmpty ? title : info.userName,
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (artist.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        artist,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Boutons d'action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (duration.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        duration,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _launchUrl(url),
                    icon: Icon(
                      Icons.open_in_new,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    tooltip: 'Ouvrir sur SoundCloud',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lecteur SoundCloud intégré (simulé)
        Container(
          height: info.contentType == SoundCloudContentType.track ? 166 : 400,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  size: 64,
                  color: Colors.orange[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Lecteur SoundCloud',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliquez pour ouvrir sur SoundCloud',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Description si présente
        if (description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDirectFileAudioComponent(String url, String title, String artist, String duration, String description) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Bouton play/pause
                GestureDetector(
                  onTap: () => _handleAudioPlay(url),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations audio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Fichier Audio',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      
                      if (artist.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      if (duration.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.textTertiaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: TextStyle(
                                color: AppTheme.textTertiaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Boutons d'action
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _launchUrl(url),
                      icon: Icon(
                        Icons.open_in_new,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      tooltip: 'Ouvrir le fichier',
                    ),
                    if (url.toLowerCase().contains('.mp3') || 
                        url.toLowerCase().contains('.wav') ||
                        url.toLowerCase().contains('.ogg'))
                      Icon(
                        Icons.audiotrack,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Barre de progression simulée
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.0, // Pas de progression par défaut
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          // Description si présente
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                description,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildErrorAudioComponent(String error, String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erreur Audio',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSoundCloudIcon(SoundCloudContentType type) {
    switch (type) {
      case SoundCloudContentType.track:
        return Icons.music_note;
      case SoundCloudContentType.playlist:
        return Icons.playlist_play;
      case SoundCloudContentType.user:
        return Icons.person;
      default:
        return Icons.audiotrack;
    }
  }

  Widget _buildGoogleMapComponent() {
    final address = component.data['address'] ?? '';
    final latitude = component.data['latitude'] ?? '';
    final longitude = component.data['longitude'] ?? '';
    final zoom = component.data['zoom'] ?? 15;
    final mapType = component.data['mapType'] ?? 'roadmap';
    
    if (address.isEmpty && latitude.isEmpty && longitude.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Google Map non configurée',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                'Veuillez saisir une adresse',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Construction de l'URL Google Maps
    String mapUrl = 'https://www.google.com/maps/embed/v1/place?key=YOUR_API_KEY&q=';
    if (address.isNotEmpty) {
      mapUrl += Uri.encodeComponent(address);
    } else if (latitude.isNotEmpty && longitude.isNotEmpty) {
      mapUrl += '$latitude,$longitude';
    }
    mapUrl += '&zoom=$zoom&maptype=$mapType';

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Placeholder de la carte
            Container(
              color: Colors.grey[300],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Google Maps'),
                    Text('(Intégration nécessaire)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            
            // Overlay avec adresse
            if (address.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Bouton pour ouvrir dans Google Maps
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _openInGoogleMaps(address, latitude, longitude),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlComponent() {
    final htmlContent = component.data['content'] ?? '';
    final title = component.data['title'] ?? '';
    
    if (htmlContent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.code, size: 48, color: Colors.grey),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contenu HTML non configuré',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Veuillez saisir le code HTML',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.code, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contenu HTML intégré',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le contenu HTML sera rendu ici dans l\'application finale.',
                  style: TextStyle(
                    color: AppTheme.textTertiaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    htmlContent.length > 100 
                        ? '${htmlContent.substring(0, 100)}...'
                        : htmlContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteComponent() {
    final quote = component.data['quote'] ?? '';
    final author = component.data['author'] ?? '';
    final context = component.data['context'] ?? '';
    final backgroundColor = Color(
      int.parse((component.data['backgroundColor'] ?? '#F5F5F5').replaceFirst('#', '0xFF'))
    );
    final textColor = Color(
      int.parse((component.data['textColor'] ?? '#333333').replaceFirst('#', '0xFF'))
    );
    
    // Adaptation pour le mode grid
    if (isGridMode) {
      if (quote.isEmpty) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.format_quote, size: 32, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Citation non configurée',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_quote,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Citation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  quote,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: textColor,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (author.isNotEmpty)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '— $author',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Mode linéaire (par défaut)
    if (quote.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.format_quote, size: 48, color: Colors.grey),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Citation non configurée',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Veuillez saisir le texte de la citation',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(25), // 0.1 opacity
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.format_quote,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quote,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (author.isNotEmpty || context.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (author.isNotEmpty)
                        Text(
                          '— $author',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      if (context.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          context,
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupsComponent() {
    final title = component.data['title'] ?? 'Nos Groupes';
    final subtitle = component.data['subtitle'] ?? '';
    final displayMode = component.data['displayMode'] ?? 'cards';
    final showContact = component.data['showContact'] ?? true;
    final allowDirectJoin = component.data['allowDirectJoin'] ?? false;
    final showMemberCount = component.data['showMemberCount'] ?? true;
    final filterBy = component.data['filterBy'] ?? 'all';
    final category = component.data['category'] ?? '';
    
    final cardBackgroundColor = Color(
      int.parse((component.data['cardBackgroundColor'] ?? '#FFFFFF').replaceFirst('#', '0xFF'))
    );
    final accentColor = Color(
      int.parse((component.data['accentColor'] ?? '#2196F3').replaceFirst('#', '0xFF'))
    );

    // Données d'exemple pour les groupes
    final sampleGroups = [
      {
        'name': 'Groupe de Jeunes',
        'description': 'Pour les 18-35 ans, rencontres le vendredi soir',
        'category': 'Jeunesse',
        'memberCount': 24,
        'leader': 'Jean Martin',
        'email': 'jeunes@eglise.com',
        'phone': '06 12 34 56 78',
        'isActive': true,
        'isJoinable': true,
      },
      {
        'name': 'Étude Biblique Femmes',
        'description': 'Étude approfondie de la Bible, le mardi matin',
        'category': 'Études bibliques',
        'memberCount': 15,
        'leader': 'Marie Dubois',
        'email': 'femmes@eglise.com',
        'phone': '06 98 76 54 32',
        'isActive': true,
        'isJoinable': true,
      },
      {
        'name': 'Ministère de Louange',
        'description': 'Équipe de musiciens et chanteurs',
        'category': 'Ministères',
        'memberCount': 12,
        'leader': 'Paul Morel',
        'email': 'louange@eglise.com',
        'phone': '06 11 22 33 44',
        'isActive': true,
        'isJoinable': false,
      },
    ];

    // Filtrage des groupes selon les critères
    List<Map<String, dynamic>> filteredGroups = sampleGroups.where((group) {
      switch (filterBy) {
        case 'active':
          return group['isActive'] == true;
        case 'joinable':
          return group['isJoinable'] == true;
        case 'category':
          return category.isEmpty || group['category'] == category;
        default:
          return true;
      }
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.groups,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Affichage des groupes selon le mode choisi
          if (displayMode == 'cards') 
            _buildGroupsCards(filteredGroups, cardBackgroundColor, accentColor, showContact, allowDirectJoin, showMemberCount)
          else if (displayMode == 'grid')
            _buildGroupsGrid(filteredGroups, cardBackgroundColor, accentColor, showContact, allowDirectJoin, showMemberCount)
          else
            _buildGroupsList(filteredGroups, cardBackgroundColor, accentColor, showContact, allowDirectJoin, showMemberCount),

          // Message si aucun groupe
          if (filteredGroups.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun groupe trouvé',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  if (filterBy == 'category' && category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'pour la catégorie "$category"',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupsCards(List<Map<String, dynamic>> groups, Color cardColor, Color accentColor, bool showContact, bool allowDirectJoin, bool showMemberCount) {
    return Column(
      children: groups.map((group) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showMemberCount) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group['memberCount']} membres',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group['category'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (allowDirectJoin && group['isJoinable']) ...[
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Rejoindre'),
                  ),
                ],
              ],
            ),
            if (showContact) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Responsable: ${group['leader']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    group['email'],
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    group['phone'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildGroupsGrid(List<Map<String, dynamic>> groups, Color cardColor, Color accentColor, bool showContact, bool allowDirectJoin, bool showMemberCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                group['description'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (showMemberCount) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group['memberCount']} membres',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (allowDirectJoin && group['isJoinable']) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Rejoindre', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupsList(List<Map<String, dynamic>> groups, Color cardColor, Color accentColor, bool showContact, bool allowDirectJoin, bool showMemberCount) {
    return Column(
      children: groups.map((group) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group['description'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (showContact) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Responsable: ${group['leader']}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showMemberCount) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${group['memberCount']}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (allowDirectJoin && group['isJoinable']) ...[
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Rejoindre', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  // Méthode utilitaire pour obtenir les icônes
  IconData _getIconData(String iconName) {
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

  // Composants Grid
  Widget _buildGridCardComponent(BuildContext context) {
    final title = component.data['title'] ?? 'Titre de la carte';
    final subtitle = component.data['subtitle'] ?? 'Sous-titre';
    final description = component.data['description'] ?? 'Description';
    final iconName = component.data['iconName'] ?? 'star';
    final backgroundColor = _parseColor(component.data['backgroundColor'] ?? '#6F61EF');
    final textColor = _parseColor(component.data['textColor'] ?? '#FFFFFF');

    Widget cardWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconData(iconName),
                    color: textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),

        ],
      ),
    );

    // Encapsuler dans GestureDetector si action configurée
    if (component.action != null && !isPreview) {
      return GestureDetector(
        onTap: () => ComponentActionService.handleComponentAction(context, component.action!),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildGridStatComponent(BuildContext context) {
    final title = component.data['title'] ?? 'Statistique';
    final value = component.data['value'] ?? '0';
    final unit = component.data['unit'] ?? '';
    final trend = component.data['trend'] ?? 'stable';
    final color = _parseColor(component.data['color'] ?? '#4CAF50');
    final iconName = component.data['iconName'] ?? 'trending_up';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                _getIconData(iconName),
                color: color,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridIconTextComponent(BuildContext context) {
    final iconName = component.data['iconName'] ?? 'favorite';
    final title = component.data['title'] ?? 'Titre';
    final description = component.data['description'] ?? 'Description';
    final iconColor = _parseColor(component.data['iconColor'] ?? '#FF5722');
    final textAlign = component.data['textAlign'] ?? 'center';

    Widget gridWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: textAlign == 'center' 
            ? CrossAxisAlignment.center 
            : textAlign == 'left' 
              ? CrossAxisAlignment.start 
              : CrossAxisAlignment.end,
          mainAxisAlignment: textAlign == 'center' 
            ? MainAxisAlignment.center 
            : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(iconName),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: textAlign == 'center' 
                ? TextAlign.center 
                : textAlign == 'left' 
                  ? TextAlign.start 
                  : TextAlign.end,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: textAlign == 'center' 
                ? TextAlign.center 
                : textAlign == 'left' 
                  ? TextAlign.start 
                  : TextAlign.end,
            ),
          ],
        ),
      ),
    );

    // Encapsuler dans GestureDetector si action configurée
    if (component.action != null && !isPreview) {
      return GestureDetector(
        onTap: () => ComponentActionService.handleComponentAction(context, component.action!),
        child: gridWidget,
      );
    }

    return gridWidget;
  }

  Widget _buildGridImageCardComponent(BuildContext context) {
    final imageUrl = component.data['imageUrl'] ?? '';
    final title = component.data['title'] ?? 'Titre de l\'image';
    final description = component.data['description'] ?? 'Description';
    final imageHeight = (component.data['imageHeight'] ?? 120).toDouble();

    Widget imageCardWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: imageHeight,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: imageHeight,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        ],
      ),
    );

    // Encapsuler dans GestureDetector si action configurée
    if (component.action != null && !isPreview) {
      return GestureDetector(
        onTap: () => ComponentActionService.handleComponentAction(context, component.action!),
        child: imageCardWidget,
      );
    }

    return imageCardWidget;
  }

  Widget _buildGridProgressComponent(BuildContext context) {
    final title = component.data['title'] ?? 'Progression';
    final progress = (component.data['progress'] ?? 0.0).toDouble();
    final showPercentage = component.data['showPercentage'] ?? true;
    final color = _parseColor(component.data['color'] ?? '#2196F3');
    final backgroundColor = _parseColor(component.data['backgroundColor'] ?? '#E3F2FD');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (showPercentage)
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridContainerComponent(BuildContext context) {
    final columns = component.data['columns'] ?? 2;
    final mainAxisSpacing = (component.data['mainAxisSpacing'] ?? 12.0).toDouble();
    final crossAxisSpacing = (component.data['crossAxisSpacing'] ?? 12.0).toDouble();
    final childAspectRatio = (component.data['childAspectRatio'] ?? 1.0).toDouble();
    final padding = (component.data['padding'] ?? 16.0).toDouble();

    // Filtrer les composants enfants visibles
    final visibleChildren = component.children.where((child) {
      // Ici, vous pourriez ajouter la logique de visibilité si nécessaire
      // Pour l'instant, on affiche tous les enfants
      return true;
    }).toList();

    if (visibleChildren.isEmpty) {
      // Affichage en mode preview pour l'édition
      if (isPreview) {
        return Container(
          padding: EdgeInsets.all(padding),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.grid_view,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Grid Container (${columns} colonnes)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ajoutez des composants pour les voir ici',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }
      // En mode normal, ne rien afficher si pas de contenu
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: visibleChildren.length,
        itemBuilder: (context, index) {
          final childComponent = visibleChildren[index];
          
          // Créer un ComponentRenderer pour chaque enfant en mode grid
          return ComponentRenderer(
            component: childComponent,
            isPreview: isPreview,
            isGridMode: true, // Les enfants d'un grid container sont toujours en mode grid
          );
        },
      ),
    );
  }

  Widget _buildUnsupportedComponent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Composant non supporté',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Type: ${component.type}',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Composant Événements
  Widget _buildEventsComponent() {
    final title = component.data['title'] ?? 'Nos Événements';
    final subtitle = component.data['subtitle'] ?? '';
    final displayMode = component.data['displayMode'] ?? 'cards';
    final showDates = component.data['showDates'] ?? true;
    final allowRegistration = component.data['allowRegistration'] ?? true;
    final primaryColor = _parseColor(component.data['primaryColor'] ?? '#2196F3');

    // Données d'exemple
    final events = [
      {
        'title': 'Culte du Dimanche',
        'description': 'Service de culte hebdomadaire avec prédication et louange',
        'date': '2024-01-14',
        'time': '10:00',
        'location': 'Sanctuaire principal',
        'registrationOpen': true,
      },
      {
        'title': 'Étude Biblique',
        'description': 'Étude approfondie des Écritures en groupe',
        'date': '2024-01-17',
        'time': '19:00',
        'location': 'Salle de conférence',
        'registrationOpen': true,
      },
      {
        'title': 'Retraite Spirituelle',
        'description': 'Week-end de retraite et de ressourcement',
        'date': '2024-01-20',
        'time': '09:00',
        'location': 'Centre de retraite',
        'registrationOpen': false,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (displayMode == 'cards')
            _buildEventsCards(events, showDates, allowRegistration, primaryColor)
          else if (displayMode == 'list')
            _buildEventsList(events, showDates, allowRegistration, primaryColor)
          else
            _buildEventsCalendar(events, showDates, allowRegistration, primaryColor),
        ],
      ),
    );
  }

  Widget _buildEventsCards(List<Map<String, dynamic>> events, bool showDates, bool allowRegistration, Color primaryColor) {
    return Column(
      children: events.map((event) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event['description'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (showDates) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${event['date']} à ${event['time']}',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    event['location'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (allowRegistration && event['registrationOpen']) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('S\'inscrire'),
              ),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEventsList(List<Map<String, dynamic>> events, bool showDates, bool allowRegistration, Color primaryColor) {
    return Column(
      children: events.map((event) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showDates) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${event['date']} à ${event['time']}',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (allowRegistration && event['registrationOpen'])
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('S\'inscrire', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEventsCalendar(List<Map<String, dynamic>> events, bool showDates, bool allowRegistration, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Mode calendrier - ${events.length} événements',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...events.map((event) => ListTile(
            leading: Icon(Icons.event, color: primaryColor),
            title: Text(event['title']),
            subtitle: showDates ? Text('${event['date']} à ${event['time']}') : null,
            trailing: allowRegistration && event['registrationOpen']
                ? Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor)
                : null,
            onTap: () {},
          )),
        ],
      ),
    );
  }











  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Méthodes utilitaires
  
  TextAlign _getTextAlign(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  BoxFit _getBoxFit(String fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
    }
  }

  ButtonStyle _getButtonStyle(String style, String size) {
    // Taille
    Size buttonSize;
    switch (size) {
      case 'small':
        buttonSize = const Size(0, 32);
        break;
      case 'large':
        buttonSize = const Size(0, 48);
        break;
      default:
        buttonSize = const Size(0, 40);
    }

    // Style
    switch (style) {
      case 'secondary':
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          minimumSize: buttonSize,
        );
      case 'outline':
        return OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor),
          minimumSize: buttonSize,
        );
      case 'text':
        return TextButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          minimumSize: buttonSize,
        );
      default:
         return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: buttonSize,
        );
    }
  }

  Color _getButtonColor(String style) {
    switch (style) {
      case 'secondary':
        return AppTheme.secondaryColor;
      case 'outline':
      case 'text':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }





  Widget _buildAppointmentDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }











  String _parseMarkdown(String text) {
    // Parsing Markdown simple pour l'affichage
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Gras
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Italique
        .replaceAll(RegExp(r'#{1,6}\s'), ''); // Titres
  }

  String _extractVideoId(String url) {
    // Extraction d'ID YouTube/Vimeo
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final regex = RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)');
      final match = regex.firstMatch(url);
      return match?.group(1) ?? '';
    } else if (url.contains('vimeo.com')) {
      final regex = RegExp(r'vimeo\.com\/(\d+)');
      final match = regex.firstMatch(url);
      return match?.group(1) ?? '';
    }
    return '';
  }

  String _getVideoThumbnail(String url, String videoId) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    } else if (url.contains('vimeo.com')) {
      return ''; // Vimeo nécessite une API pour les thumbnails
    }
    return '';
  }

  void _handleButtonPress(String url) {
    if (url.startsWith('/')) {
      // Navigation interne
      // À implémenter selon votre système de navigation
    } else {
      // URL externe
      _launchUrl(url);
    }
  }

  void _handleVideoPlay(String url, YouTubeUrlInfo urlInfo) {
    // Détermine la meilleure URL à ouvrir selon le type de contenu
    String targetUrl;
    
    switch (urlInfo.contentType) {
      case YouTubeContentType.playlist:
        targetUrl = urlInfo.watchUrl; // URL de playlist
        break;
      case YouTubeContentType.videoInPlaylist:
        targetUrl = urlInfo.watchUrl; // URL avec vidéo et playlist
        break;
      case YouTubeContentType.video:
        targetUrl = urlInfo.watchUrl; // URL de vidéo
        break;
      default:
        targetUrl = url; // URL originale en cas de problème
    }
    
    _launchUrl(targetUrl);
  }

  void _handleAction(String action) {
    if (action.startsWith('/')) {
      // Navigation interne
      // À implémenter selon votre système de navigation
    } else if (action.startsWith('http')) {
      // URL externe
      _launchUrl(action);
    } else {
      // Action spécifique (groupes, events, etc.)
      // À implémenter selon vos besoins
    }
  }

  void _handleAudioPlay(String url) {
    // Ouvrir le lecteur audio ou navigateur
    _launchUrl(url);
  }
  
  void _openInGoogleMaps(String address, String latitude, String longitude) {
    String mapsUrl;
    if (address.isNotEmpty) {
      mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    } else if (latitude.isNotEmpty && longitude.isNotEmpty) {
      mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    } else {
      return;
    }
    _launchUrl(mapsUrl);
  }

  Widget _buildPrayerWallComponent(BuildContext context) {
    final title = component.data['title'] ?? 'Mur de prière';
    final subtitle = component.data['subtitle'] ?? 'Partagez vos demandes de prière et témoignages';
    final displayMode = component.data['displayMode'] ?? 'cards';
    final allowRequests = component.data['allowRequests'] ?? true;
    final allowTestimonies = component.data['allowTestimonies'] ?? true;
    final allowIntercession = component.data['allowIntercession'] ?? true;
    final allowThanksgiving = component.data['allowThanksgiving'] ?? true;
    final allowPrayerCount = component.data['allowPrayerCount'] ?? true;
    final allowComments = component.data['allowComments'] ?? true;
    final allowAnonymous = component.data['allowAnonymous'] ?? true;
    final showDates = component.data['showDates'] ?? true;
    final showAuthors = component.data['showAuthors'] ?? true;
    final showCategories = component.data['showCategories'] ?? true;
    final primaryColor = _parseColor(component.data['primaryColor'] ?? '#E91E63');
    final accentColor = _parseColor(component.data['accentColor'] ?? '#FCE4EC');
    final submitButtonText = component.data['submitButtonText'] ?? 'Partager une demande';
    final emptyStateText = component.data['emptyStateText'] ?? 'Aucune demande de prière pour le moment.\nSoyez le premier à partager.';
    final prayerCountText = component.data['prayerCountText'] ?? 'personnes prient';
    final categories = (component.data['categories'] ?? 'Santé,Famille,Travail,Église,Finances,Relation,Spiritualité,Autre').split(',');

    // Données d'exemple pour démonstration
    final samplePrayers = _getSamplePrayerData();

    return Container(
      margin: EdgeInsets.all(component.styling['margin']?.toDouble() ?? 16.0),
      padding: EdgeInsets.all(component.styling['padding']?.toDouble() ?? 16.0),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et bouton d'ajout
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              FloatingActionButton.extended(
                onPressed: () => _showPrayerSubmissionDialog(
                  context, allowRequests, allowTestimonies, allowIntercession, 
                  allowThanksgiving, allowAnonymous, categories, primaryColor
                ),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(submitButtonText),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filtres par catégorie
          if (showCategories) ...[
            _buildCategoryFilter(categories, primaryColor),
            const SizedBox(height: 16),
          ],

          // Statistiques
          if (allowPrayerCount) ...[
            _buildPrayerStats(samplePrayers, prayerCountText, primaryColor),
            const SizedBox(height: 16),
          ],

          // Liste des prières selon le mode d'affichage
          if (samplePrayers.isNotEmpty) ...[
            _buildPrayerList(
              context, samplePrayers, displayMode, showDates, showAuthors, 
              showCategories, allowPrayerCount, allowComments,
              primaryColor, accentColor, prayerCountText
            ),
          ] else ...[
            _buildEmptyState(emptyStateText, primaryColor),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories, Color primaryColor) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Tout'),
                selected: true,
                onSelected: (selected) {},
                selectedColor: primaryColor.withOpacity(0.2),
                checkmarkColor: primaryColor,
              ),
            );
          }
          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: false,
              onSelected: (selected) {},
              selectedColor: primaryColor.withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerStats(List<Map<String, dynamic>> prayers, String prayerCountText, Color primaryColor) {
    final totalPrayers = prayers.length;
    final totalPrayerCount = prayers.fold<int>(0, (sum, prayer) => sum + (prayer['prayerCount'] as int));
    final todayPrayers = prayers.where((p) {
      final date = DateTime.parse(p['date']);
      final today = DateTime.now();
      return date.year == today.year && date.month == today.month && date.day == today.day;
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.favorite,
              label: 'Demandes',
              value: totalPrayers.toString(),
              color: primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.people,
              label: prayerCountText,
              value: totalPrayerCount.toString(),
              color: primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.today,
              label: 'Aujourd\'hui',
              value: todayPrayers.toString(),
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrayerList(
    BuildContext context,
    List<Map<String, dynamic>> prayers,
    String displayMode,
    bool showDates,
    bool showAuthors,
    bool showCategories,
    bool allowPrayerCount,
    bool allowComments,
    Color primaryColor,
    Color accentColor,
    String prayerCountText,
  ) {
    switch (displayMode) {
      case 'timeline':
        return _buildTimelineView(context, prayers, showDates, showAuthors, showCategories, allowPrayerCount, allowComments, primaryColor, accentColor, prayerCountText);
      case 'compact':
        return _buildCompactView(context, prayers, showDates, showAuthors, showCategories, allowPrayerCount, primaryColor, prayerCountText);
      case 'masonry':
        return _buildMasonryView(context, prayers, showDates, showAuthors, showCategories, allowPrayerCount, allowComments, primaryColor, accentColor, prayerCountText);
      default:
        return _buildCardsView(context, prayers, showDates, showAuthors, showCategories, allowPrayerCount, allowComments, primaryColor, accentColor, prayerCountText);
    }
  }

  Widget _buildCardsView(
    BuildContext context,
    List<Map<String, dynamic>> prayers,
    bool showDates,
    bool showAuthors,
    bool showCategories,
    bool allowPrayerCount,
    bool allowComments,
    Color primaryColor,
    Color accentColor,
    String prayerCountText,
  ) {
    return Column(
      children: prayers.map((prayer) => 
        _buildPrayerCard(context, prayer, showDates, showAuthors, showCategories, allowPrayerCount, allowComments, primaryColor, accentColor, prayerCountText)
      ).toList(),
    );
  }

  Widget _buildTimelineView(
    BuildContext context,
    List<Map<String, dynamic>> prayers,
    bool showDates,
    bool showAuthors,
    bool showCategories,
    bool allowPrayerCount,
    bool allowComments,
    Color primaryColor,
    Color accentColor,
    String prayerCountText,
  ) {
    return Column(
      children: prayers.asMap().entries.map((entry) {
        final index = entry.key;
        final prayer = entry.value;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPrayerTypeColor(prayer['type'], primaryColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index < prayers.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildPrayerCard(context, prayer, showDates, showAuthors, showCategories, allowPrayerCount, allowComments, primaryColor, accentColor, prayerCountText),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactView(
    BuildContext context,
    List<Map<String, dynamic>> prayers,
    bool showDates,
    bool showAuthors,
    bool showCategories,
    bool allowPrayerCount,
    Color primaryColor,
    String prayerCountText,
  ) {
    return Column(
      children: prayers.map((prayer) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getPrayerTypeIcon(prayer['type']),
                    color: _getPrayerTypeColor(prayer['type'], primaryColor),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prayer['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (allowPrayerCount) ...[
                    Icon(Icons.favorite, color: primaryColor, size: 14),
                    const SizedBox(width: 4),
                    Text('${prayer['prayerCount']}', style: TextStyle(fontSize: 12, color: primaryColor)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                prayer['content'],
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showDates || showAuthors) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (showAuthors) ...[
                      Text(
                        prayer['author'],
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      if (showDates) const Text(' • ', style: TextStyle(fontSize: 11)),
                    ],
                    if (showDates)
                      Text(
                        _formatDate(prayer['date']),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ],
            ],
          ),
        )
      ).toList(),
    );
  }

  Widget _buildMasonryView(
    BuildContext context,
    List<Map<String, dynamic>> prayers,
    bool showDates,
    bool showAuthors,
    bool showCategories,
    bool allowPrayerCount,
    bool allowComments,
    Color primaryColor,
    Color accentColor,
    String prayerCountText,
  ) {
    // Simulation d'un layout en masonry avec deux colonnes
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];
    
    for (int i = 0; i < prayers.length; i++) {
      final card = _buildPrayerCard(context, prayers[i], showDates, showAuthors, showCategories, allowPrayerCount, allowComments, primaryColor, accentColor, prayerCountText);
      if (i % 2 == 0) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: leftColumn),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(children: rightColumn),
        ),
      ],
    );
  }

  Widget _buildPrayerCard(
    BuildContext context,
    Map<String, dynamic> prayer,
    bool showDates,
    bool showAuthors,
    bool showCategories,
    bool allowPrayerCount,
    bool allowComments,
    Color primaryColor,
    Color accentColor,
    String prayerCountText,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec type et catégorie
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPrayerTypeColor(prayer['type'], primaryColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPrayerTypeIcon(prayer['type']),
                          size: 14,
                          color: _getPrayerTypeColor(prayer['type'], primaryColor),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPrayerTypeLabel(prayer['type']),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getPrayerTypeColor(prayer['type'], primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showCategories && prayer['category'] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        prayer['category'],
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Titre
              Text(
                prayer['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Contenu
              Text(
                prayer['content'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Informations auteur et date
              if (showAuthors || showDates) ...[
                Row(
                  children: [
                    if (showAuthors) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Text(
                          prayer['author'][0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        prayer['author'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (showDates) ...[
                        const Text(' • '),
                        Text(
                          _formatDate(prayer['date']),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ] else if (showDates) ...[
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(prayer['date']),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Actions
              Row(
                children: [
                  if (allowPrayerCount) ...[
                    TextButton.icon(
                      onPressed: () => _handlePrayerAction(context, prayer),
                      icon: Icon(
                        prayer['userPrayed'] == true ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: primaryColor,
                      ),
                      label: Text(
                        '${prayer['prayerCount']} $prayerCountText',
                        style: TextStyle(color: primaryColor),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                  if (allowComments) ...[
                    TextButton.icon(
                      onPressed: () => _showCommentsDialog(context, prayer, primaryColor),
                      icon: Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                      label: Text(
                        '${prayer['commentCount']} commentaires',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => _sharePrayer(context, prayer),
                    icon: Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String emptyStateText, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            emptyStateText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSamplePrayerData() {
    return [
      {
        'id': '1',
        'type': 'request',
        'title': 'Prière pour la guérison',
        'content': 'Prions pour Marie qui traverse une période difficile avec sa santé. Elle a besoin de notre soutien et de nos prières pour sa guérison complète.',
        'author': 'Jean Dupont',
        'date': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'category': 'Santé',
        'prayerCount': 12,
        'commentCount': 3,
        'userPrayed': false,
      },
      {
        'id': '2',
        'type': 'testimony',
        'title': 'Témoignage de guérison',
        'content': 'Je veux témoigner de la bonté de Dieu ! Après des mois de prière, j\'ai enfin trouvé un emploi qui correspond parfaitement à mes compétences. Gloire à Dieu !',
        'author': 'Sophie Martin',
        'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'category': 'Travail',
        'prayerCount': 8,
        'commentCount': 5,
        'userPrayed': true,
      },
      {
        'id': '3',
        'type': 'intercession',
        'title': 'Prière pour l\'unité familiale',
        'content': 'Demandons au Seigneur de restaurer l\'harmonie dans la famille de Paul. Les relations sont tendues et ils ont besoin de réconciliation.',
        'author': 'Anonyme',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'category': 'Famille',
        'prayerCount': 15,
        'commentCount': 2,
        'userPrayed': false,
      },
      {
        'id': '4',
        'type': 'thanksgiving',
        'title': 'Action de grâce pour les bénédictions',
        'content': 'Rendons grâce à Dieu pour toutes ses bénédictions sur notre communauté. Cette année a été riche en réponses à nos prières !',
        'author': 'Pasteur Michel',
        'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'category': 'Église',
        'prayerCount': 25,
        'commentCount': 8,
        'userPrayed': true,
      },
    ];
  }

  Color _getPrayerTypeColor(String type, Color primaryColor) {
    switch (type) {
      case 'request':
        return Colors.orange;
      case 'testimony':
        return Colors.green;
      case 'intercession':
        return Colors.blue;
      case 'thanksgiving':
        return Colors.purple;
      default:
        return primaryColor;
    }
  }

  IconData _getPrayerTypeIcon(String type) {
    switch (type) {
      case 'request':
        return Icons.help_outline;
      case 'testimony':
        return Icons.celebration;
      case 'intercession':
        return Icons.people_outline;
      case 'thanksgiving':
        return Icons.favorite;
      default:
        return Icons.favorite_border;
    }
  }

  String _getPrayerTypeLabel(String type) {
    switch (type) {
      case 'request':
        return 'Demande';
      case 'testimony':
        return 'Témoignage';
      case 'intercession':
        return 'Intercession';
      case 'thanksgiving':
        return 'Action de grâce';
      default:
        return 'Prière';
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showPrayerSubmissionDialog(
    BuildContext context,
    bool allowRequests,
    bool allowTestimonies,
    bool allowIntercession,
    bool allowThanksgiving,
    bool allowAnonymous,
    List<String> categories,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager une prière'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Formulaire de soumission de prière'),
              SizedBox(height: 16),
              Text('Cette fonctionnalité sera connectée à votre base de données.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handlePrayerAction(BuildContext context, Map<String, dynamic> prayer) {
    // Simulation de l'action "Je prie pour toi"
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          prayer['userPrayed'] == true 
            ? 'Vous ne priez plus pour cette demande' 
            : 'Vous priez maintenant pour cette demande'
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCommentsDialog(BuildContext context, Map<String, dynamic> prayer, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commentaires - ${prayer['title']}'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Système de commentaires'),
              SizedBox(height: 16),
              Text('Les commentaires d\'encouragement seront affichés ici.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _sharePrayer(BuildContext context, Map<String, dynamic> prayer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
        duration: Duration(seconds: 2),
      ),
    );
  }



  Widget _buildWebViewComponent() {
    return _WebViewComponentWidget(component: component);
  }

  Color _parseWebViewColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'transparent':
        return Colors.transparent;
      case 'grey':
        return Colors.grey;
      default:
        return _parseColor(colorName);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _WebViewComponentWidget extends StatefulWidget {
  final PageComponent component;

  const _WebViewComponentWidget({required this.component});

  @override
  State<_WebViewComponentWidget> createState() => _WebViewComponentWidgetState();
}

class _WebViewComponentWidgetState extends State<_WebViewComponentWidget> {
  WebViewController? controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebView();
    });
  }

  @override
  void dispose() {
    controller = null;
    super.dispose();
  }

  void _initializeWebView() async {
    if (!mounted) return;
    
    final url = widget.component.data['url'] ?? '';
    final initialJavaScript = widget.component.data['initialJavaScript'] ?? '';
    final userAgent = widget.component.data['userAgent'] ?? '';
    final backgroundColor = widget.component.data['backgroundColor'] ?? 'white';
    final allowNavigation = widget.component.data['allowNavigation'] ?? true;
    final debuggingEnabled = widget.component.data['debuggingEnabled'] ?? true;

    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'URL non configurée - Veuillez ajouter une URL dans les paramètres du composant';
          _isLoading = false;
        });
      }
      return;
    }

    Uri? uri;
    try {
      // Nettoyage et validation de l'URL
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      
      uri = Uri.parse(cleanUrl);
      
      // Vérification additionnelle de l'URI
      if (!uri.hasAuthority) {
        throw const FormatException('URL malformée');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'URL invalide: $url\nErreur: ${e.toString()}';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(_parseWebViewColor(backgroundColor))
        ..enableZoom(widget.component.data['allowZoom'] ?? true);

      // Configuration du debugging si activé (note: la méthode enableDebugging n'est plus disponible dans webview_flutter 4.x)
      // if (debuggingEnabled) {
      //   await controller!.enableDebugging(true);
      // }

      // Configuration des cookies et du cache
      final currentController = controller;
      if (currentController != null) {
        try {
          await currentController.clearCache();
          await currentController.clearLocalStorage();
        } catch (e) {
          debugPrint('Erreur lors du nettoyage du cache WebView: $e');
        }
      }

      // Configuration du User Agent si spécifié
      if (userAgent.isNotEmpty && currentController != null) {
        try {
          await currentController.setUserAgent(userAgent);
        } catch (e) {
          debugPrint('Erreur lors de la configuration du User Agent: $e');
        }
      }

      // Configuration du delegate de navigation
      if (currentController != null) {
        try {
          await currentController.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView Loading progress: $progress%');
          },
          onPageStarted: (String pageUrl) {
            debugPrint('WebView Page started loading: $pageUrl');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _errorMessage = '';
              });
            }
          },
          onPageFinished: (String pageUrl) async {
            debugPrint('WebView Page finished loading: $pageUrl');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isInitialized = true;
              });
              
              // Exécution du JavaScript initial si spécifié
              if (initialJavaScript.isNotEmpty && currentController != null) {
                try {
                  await currentController.runJavaScript(initialJavaScript);
                } catch (e) {
                  debugPrint('Erreur lors de l\'exécution du JavaScript: $e');
                }
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Resource Error: ${error.errorCode} - ${error.description}');
            
            // Filtrer les erreurs mineures qui ne devraient pas interrompre l'affichage
            if (error.errorCode == -2 || // ERR_INTERNET_DISCONNECTED
                error.errorCode == -3 || // ERR_NAME_NOT_RESOLVED
                error.errorCode == -6 || // ERR_CONNECTION_REFUSED
                error.errorCode == -8) { // ERR_TIMED_OUT
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = 'Impossible de charger la page:\n${error.description}\n\nVérifiez votre connexion internet ou essayez une autre URL.';
                });
              }
            }
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('WebView HTTP Error: ${error.response?.statusCode}');
            if (mounted && error.response != null && error.response!.statusCode >= 400) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = 'Erreur HTTP ${error.response!.statusCode}: Impossible de charger la page demandée.';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('WebView Navigation request to: ${request.url}');
            
            if (!allowNavigation && request.url != uri.toString()) {
              return NavigationDecision.prevent;
            }
            
            // Permettre la navigation vers les URL HTTPS sécurisées
            if (request.url.startsWith('https://') || request.url.startsWith('http://')) {
              return NavigationDecision.navigate;
            }
            
            return NavigationDecision.prevent;
          },
        ),
      );
        } catch (e) {
          debugPrint('Erreur lors de la configuration du delegate de navigation: $e');
        }
      }

      // Chargement de l'URL avec un délai pour s'assurer que tout est initialisé
      await Future.delayed(const Duration(milliseconds: 100));
      final finalController = controller;
      if (mounted && finalController != null) {
        try {
          await finalController.loadRequest(uri);
        } catch (e) {
          debugPrint('Erreur lors du chargement de l\'URL: $e');
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Erreur lors du chargement de l\'URL:\n${e.toString()}';
              _isLoading = false;
            });
          }
        }
      }
      
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation WebView: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Erreur d\'initialisation WebView:\n${e.toString()}\n\nEssayez de redémarrer l\'application.';
          _isLoading = false;
        });
      }
    }
  }

  Color _parseWebViewColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'transparent':
        return Colors.transparent;
      case 'grey':
        return Colors.grey;
      default:
        return _parseColor(colorName);
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Vérifie si le controller WebView est valide et disponible
  bool _isControllerValid() {
    return controller != null && _isInitialized && !_hasError;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.component.data['url'] ?? '';
    final title = widget.component.data['title'] ?? 'WebView';
    final height = (widget.component.data['height'] ?? 400).toDouble();
    final showAppBar = widget.component.data['showAppBar'] ?? true;
    final allowNavigation = widget.component.data['allowNavigation'] ?? true;

    // Affichage en cas d'erreur
    if (_hasError) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red[300]!),
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[50]!, Colors.red[100]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erreur d\'affichage WebView',
                  style: TextStyle(
                    color: Colors.red[700], 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                          _isInitialized = false;
                        });
                        _initializeWebView();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (url.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(url),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ouvrir dans le navigateur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'URL testée: $url',
                          style: TextStyle(color: Colors.blue[700], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Affichage si l'URL n'est pas configurée
    if (url.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.grey[100]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.web_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Composant WebView',
                style: TextStyle(
                  color: Colors.grey[700], 
                  fontSize: 18, 
                  fontWeight: FontWeight.w600
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'URL non configurée',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Veuillez modifier ce composant pour ajouter une URL',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Contenu principal WebView
    Widget webViewContent;
    
    if (!_isControllerValid()) {
      // État de chargement initial
      webViewContent = Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _isLoading ? 'Initialisation WebView...' : 'Préparation...',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  url,
                  style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // WebView avec overlay de chargement si nécessaire
      // Double vérification de sécurité pour éviter l'erreur null check
      final currentController = controller;
      if (currentController != null) {
        webViewContent = Stack(
          children: [
            WebViewWidget(controller: currentController),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.9),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Chargement de la page...',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      } else {
        // Fallback si le controller devient null de manière inattendue
        webViewContent = Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange[400]),
                const SizedBox(height: 16),
                Text(
                  'Erreur d\'initialisation WebView',
                  style: TextStyle(
                    color: Colors.orange[700], 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                      _isInitialized = false;
                    });
                    _initializeWebView();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    Widget webViewWidget = Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: webViewContent,
      ),
    );

    // Ajouter une app bar si demandé
    if (showAppBar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.web, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (allowNavigation && _isControllerValid()) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final currentController = controller;
                      if (currentController != null) {
                        try {
                          await currentController.reload();
                        } catch (e) {
                          debugPrint('Erreur lors du rechargement: $e');
                        }
                      }
                    },
                    iconSize: 20,
                    tooltip: 'Actualiser',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      final currentController = controller;
                      if (currentController != null) {
                        try {
                          await currentController.goBack();
                        } catch (e) {
                          debugPrint('Erreur lors de la navigation arrière: $e');
                        }
                      }
                    },
                    iconSize: 20,
                    tooltip: 'Précédent',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      final currentController = controller;
                      if (currentController != null) {
                        try {
                          await currentController.goForward();
                        } catch (e) {
                          debugPrint('Erreur lors de la navigation avant: $e');
                        }
                      }
                    },
                    iconSize: 20,
                    tooltip: 'Suivant',
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _launchUrl(url),
                  iconSize: 20,
                  tooltip: 'Ouvrir dans le navigateur',
                ),
              ],
            ),
          ),
          Container(
            height: height - 60, // Soustraire la hauteur de l'app bar
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
                right: BorderSide(color: Colors.grey[300]!),
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: webViewContent,
            ),
          ),
        ],
      );
    }

    return webViewWidget;
  }
}