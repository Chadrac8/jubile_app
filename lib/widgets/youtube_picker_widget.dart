import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/youtube_service.dart';
import '../theme.dart';

class YouTubePickerWidget extends StatefulWidget {
  final String initialUrl;
  final Function(String) onUrlChanged;
  final bool isRequired;
  final String? label;

  const YouTubePickerWidget({
    super.key,
    this.initialUrl = '',
    required this.onUrlChanged,
    this.isRequired = false,
    this.label,
  });

  @override
  State<YouTubePickerWidget> createState() => _YouTubePickerWidgetState();
}

class _YouTubePickerWidgetState extends State<YouTubePickerWidget> {
  late TextEditingController _urlController;
  YouTubeUrlInfo? _urlInfo;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    if (widget.initialUrl.isNotEmpty) {
      _validateUrl(widget.initialUrl);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl(String url) {
    setState(() {
      _isValidating = true;
    });

    // Délai pour éviter la validation excessive pendant la saisie
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _urlController.text == url) {
        final urlInfo = YouTubeService.parseYouTubeUrl(url);
        setState(() {
          _urlInfo = urlInfo;
          _isValidating = false;
        });
        widget.onUrlChanged(url);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Champ de saisie URL
        TextFormField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'URL YouTube',
            hintText: 'https://www.youtube.com/watch?v=... ou playlist',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link),
            suffixIcon: _isValidating 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _urlInfo != null && _urlInfo!.isValid
                ? Icon(Icons.check_circle, color: Colors.green[600])
                : _urlController.text.isNotEmpty
                  ? Icon(Icons.error, color: Colors.red[600])
                  : null,
          ),
          onChanged: _validateUrl,
          validator: widget.isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'URL YouTube est requise';
            }
            if (_urlInfo != null && !_urlInfo!.isValid) {
              return 'URL YouTube invalide';
            }
            return null;
          } : null,
        ),
        
        const SizedBox(height: 16),
        
        // Prévisualisation
        if (_urlInfo != null && _urlInfo!.isValid) 
          _buildPreview()
        else if (_urlController.text.isNotEmpty && !_isValidating)
          _buildErrorPreview(),
        
        const SizedBox(height: 8),
        
        // Aide
        _buildHelpText(),
      ],
    );
  }

  Widget _buildPreview() {
    if (_urlInfo == null || !_urlInfo!.isValid) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec type
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getContentTypeIcon(),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _urlInfo!.displayType,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showUrlDetails(),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Détails'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu de prévisualisation
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Miniature
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 120,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _urlInfo!.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _urlInfo!.thumbnailUrl,
                          width: 120,
                          height: 68,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(
                              _getContentTypeIcon(),
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : Icon(
                          _getContentTypeIcon(),
                          color: Colors.grey[600],
                          size: 32,
                        ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_urlInfo!.videoId.isNotEmpty) ...[
                        Text(
                          'ID Vidéo: ${_urlInfo!.videoId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      
                      if (_urlInfo!.playlistId.isNotEmpty) ...[
                        Text(
                          'ID Playlist: ${_urlInfo!.playlistId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      
                      Text(
                        'URL valide ✓',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildErrorPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'URL YouTube invalide. Vérifiez le format.',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Formats supportés:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Vidéos: youtube.com/watch?v=ID ou youtu.be/ID\\n'
            '• Playlists: youtube.com/playlist?list=ID\\n'
            '• Vidéo dans playlist: youtube.com/watch?v=ID&list=PLAYLIST_ID',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContentTypeIcon() {
    if (_urlInfo == null) return Icons.video_library;
    
    switch (_urlInfo!.contentType) {
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

  void _showUrlDetails() {
    if (_urlInfo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getContentTypeIcon(), color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Détails ${_urlInfo!.displayType}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_urlInfo!.videoId.isNotEmpty) ...[
                const Text('ID Vidéo:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(
                  _urlInfo!.videoId,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
              ],
              
              if (_urlInfo!.playlistId.isNotEmpty) ...[
                const Text('ID Playlist:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(
                  _urlInfo!.playlistId,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
              ],
              
              const Text('URL Originale:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                _urlInfo!.originalUrl,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              
              const Text('URL de visionnage:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                _urlInfo!.watchUrl,
                style: const TextStyle(fontSize: 12),
              ),
              
              if (_urlInfo!.embedUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('URL d\'intégration:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(
                  _urlInfo!.embedUrl,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
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
}