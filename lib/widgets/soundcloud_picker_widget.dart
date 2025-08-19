import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/soundcloud_service.dart';
import '../../compatibility/app_theme_bridge.dart';

/// Widget de sélection et validation d'URLs SoundCloud
/// 
/// Fonctionnalités :
/// - Validation temps réel des URLs
/// - Prévisualisation des métadonnées
/// - Support des tracks, playlists et profils utilisateur
/// - Interface moderne avec feedback visuel
/// - Aide contextuelle et exemples
class SoundCloudPickerWidget extends StatefulWidget {
  final String initialUrl;
  final Function(String?) onUrlSelected;
  final bool isRequired;
  final String label;
  final String helperText;
  final bool showPreview;
  final bool showExamples;

  const SoundCloudPickerWidget({
    super.key,
    this.initialUrl = '',
    required this.onUrlSelected,
    this.isRequired = false,
    this.label = 'URL SoundCloud',
    this.helperText = 'Collez l\'URL de la piste, playlist ou profil SoundCloud',
    this.showPreview = true,
    this.showExamples = true,
  });

  @override
  State<SoundCloudPickerWidget> createState() => _SoundCloudPickerWidgetState();
}

class _SoundCloudPickerWidgetState extends State<SoundCloudPickerWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  SoundCloudUrlInfo? _urlInfo;
  bool _isValidating = false;
  String _errorMessage = '';
  bool _showHelp = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialUrl;
    if (widget.initialUrl.isNotEmpty) {
      _validateUrl(widget.initialUrl);
    }
    _controller.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUrlChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() {
        _urlInfo = null;
        _errorMessage = '';
      });
      widget.onUrlSelected(null);
      return;
    }

    _validateUrl(url);
  }

  void _validateUrl(String url) {
    setState(() {
      _isValidating = true;
      _errorMessage = '';
    });

    // Simulation d'un délai de validation pour éviter trop d'appels
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_controller.text.trim() != url) return; // URL a changé entre temps

      final info = SoundCloudService.parseSoundCloudUrl(url);
      
      setState(() {
        _urlInfo = info;
        _isValidating = false;
        
        if (!info.isValid && url.isNotEmpty) {
          _errorMessage = _getErrorMessage(url);
        } else {
          _errorMessage = '';
        }
      });

      widget.onUrlSelected(info.isValid ? url : null);
    });
  }

  String _getErrorMessage(String url) {
    if (!url.contains('soundcloud.com')) {
      return 'L\'URL doit être de SoundCloud (soundcloud.com)';
    }
    
    if (url.contains('soundcloud.com') && url.split('/').length < 4) {
      return 'URL SoundCloud incomplète. Format attendu: soundcloud.com/utilisateur/piste';
    }
    
    return 'URL SoundCloud non valide. Vérifiez le format.';
  }

  void _pasteFromClipboard() async {
    try {
      final clipData = await Clipboard.getData('text/plain');
      if (clipData?.text != null) {
        _controller.text = clipData!.text!;
        _focusNode.requestFocus();
      }
    } catch (e) {
      // Gestion silencieuse des erreurs de presse-papiers
    }
  }

  void _clearUrl() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _insertExampleUrl(String url) {
    _controller.text = url;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ de saisie principal
        _buildUrlInput(),
        
        // Prévisualisation
        if (widget.showPreview && _urlInfo != null) ...[
          const SizedBox(height: 12),
          _buildPreview(),
        ],
        
        // Messages d'erreur
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(),
        ],
        
        // Aide et exemples
        if (widget.showExamples) ...[
          const SizedBox(height: 12),
          _buildHelpSection(),
        ],
      ],
    );
  }

  Widget _buildUrlInput() {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(
          Icons.audiotrack,
          color: _urlInfo?.isValid == true 
              ? Colors.green 
              : Theme.of(context).colorScheme.primaryColor,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de validation
            if (_isValidating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_urlInfo?.isValid == true)
              Icon(Icons.check_circle, color: Colors.green[600], size: 20)
            else if (_errorMessage.isNotEmpty)
              Icon(Icons.error, color: Colors.red[600], size: 20),
            
            const SizedBox(width: 8),
            
            // Bouton coller
            IconButton(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste, size: 20),
              tooltip: 'Coller depuis le presse-papiers',
            ),
            
            // Bouton effacer
            if (_controller.text.isNotEmpty)
              IconButton(
                onPressed: _clearUrl,
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Effacer',
              ),
          ],
        ),
        errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      validator: widget.isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'URL SoundCloud est requise';
              }
              if (_urlInfo?.isValid != true) {
                return 'URL SoundCloud invalide';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildPreview() {
    if (_urlInfo == null || !_urlInfo!.isValid) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getIconForContentType(_urlInfo!.contentType),
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _urlInfo!.displayType,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    Text(
                      _urlInfo!.userName,
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de validation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.green[700], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Valide',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Informations détaillées
          _buildDetailRow('Utilisateur', _urlInfo!.userName),
          
          if (_urlInfo!.contentType == SoundCloudContentType.track)
            _buildDetailRow('Piste', _urlInfo!.trackSlug.replaceAll('-', ' ')),
          
          if (_urlInfo!.contentType == SoundCloudContentType.playlist)
            _buildDetailRow('Playlist', _urlInfo!.playlistSlug.replaceAll('-', ' ')),
          
          const SizedBox(height: 8),
          
          // Bouton d'ouverture
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _launchUrl(_urlInfo!.soundCloudUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ouvrir sur SoundCloud'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.orange[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton d'aide
        TextButton.icon(
          onPressed: () => setState(() => _showHelp = !_showHelp),
          icon: Icon(
            _showHelp ? Icons.help : Icons.help_outline,
            size: 16,
          ),
          label: Text(_showHelp ? 'Masquer l\'aide' : 'Afficher l\'aide'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primaryColor,
          ),
        ),
        
        // Section d'aide dépliable
        if (_showHelp) ...[
          const SizedBox(height: 8),
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
                Text(
                  'Formats d\'URLs SoundCloud supportés :',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Exemples cliquables
                ..._buildExamples(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildExamples() {
    final examples = [
      {
        'type': 'Piste audio',
        'url': 'https://soundcloud.com/artist-name/track-name',
        'description': 'Piste audio individuelle',
      },
      {
        'type': 'Playlist',
        'url': 'https://soundcloud.com/artist-name/sets/playlist-name',
        'description': 'Playlist ou set d\'un artiste',
      },
      {
        'type': 'Profil',
        'url': 'https://soundcloud.com/artist-name',
        'description': 'Profil d\'un utilisateur ou artiste',
      },
    ];

    return examples.map((example) => 
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _insertExampleUrl(example['url']!),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForType(example['type']!),
                      color: Colors.blue[700],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      example['type']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  example['url']!,
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  example['description']!,
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).toList();
  }

  IconData _getIconForContentType(SoundCloudContentType type) {
    switch (type) {
      case SoundCloudContentType.track:
        return Icons.music_note;
      case SoundCloudContentType.playlist:
        return Icons.playlist_play;
      case SoundCloudContentType.user:
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Piste audio':
        return Icons.music_note;
      case 'Playlist':
        return Icons.playlist_play;
      case 'Profil':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  void _launchUrl(String url) {
    // Simule l'ouverture d'URL - dans une vraie app, utiliser url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de: $url'),
        action: SnackBarAction(
          label: 'Copier',
          onPressed: () => Clipboard.setData(ClipboardData(text: url)),
        ),
      ),
    );
  }
}