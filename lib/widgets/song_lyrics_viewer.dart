import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song_model.dart';
import '../services/chord_transposer.dart';

/// Widget pour afficher les paroles d'un chant avec les accords
class SongLyricsViewer extends StatefulWidget {
  final SongModel song;
  final bool showChords;
  final bool isProjectionMode;
  final VoidCallback? onToggleProjection;

  const SongLyricsViewer({
    super.key,
    required this.song,
    this.showChords = true,
    this.isProjectionMode = false,
    this.onToggleProjection,
  });

  @override
  State<SongLyricsViewer> createState() => _SongLyricsViewerState();
}

class _SongLyricsViewerState extends State<SongLyricsViewer> {
  String _currentKey = '';
  bool _showChords = true;
  double _fontSize = 16.0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.song.originalKey;
    _showChords = widget.showChords;
  }

  String get _displayedLyrics {
    if (_currentKey == widget.song.originalKey) {
      return widget.song.lyrics;
    }
    return ChordTransposer.transposeLyrics(
      widget.song.lyrics,
      widget.song.originalKey,
      _currentKey,
    );
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    // Restaurer l'interface système lors de la fermeture
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenView();
    }

    return Column(
      children: [
        // Barre d'outils
        if (!widget.isProjectionMode) _buildToolbar(),
        
        // Contenu des paroles
        Expanded(
          child: _buildLyricsContent(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sélecteur de tonalité
          DropdownButton<String>(
            value: _currentKey,
            onChanged: (newKey) {
              if (newKey != null) {
                setState(() {
                  _currentKey = newKey;
                });
              }
            },
            items: SongModel.availableKeys.map((key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(key),
              );
            }).toList(),
          ),
          
          const SizedBox(width: 16),
          
          // Bouton afficher/masquer les accords
          IconButton(
            icon: Icon(
              _showChords ? Icons.music_note : Icons.music_off,
              color: _showChords ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              setState(() {
                _showChords = !_showChords;
              });
            },
            tooltip: _showChords ? 'Masquer les accords' : 'Afficher les accords',
          ),
          
          // Contrôle de la taille de police
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: _fontSize > 10 ? () {
              setState(() {
                _fontSize = (_fontSize - 2).clamp(10, 24);
              });
            } : null,
            tooltip: 'Diminuer la taille',
          ),
          
          Text(
            '${_fontSize.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: _fontSize < 24 ? () {
              setState(() {
                _fontSize = (_fontSize + 2).clamp(10, 24);
              });
            } : null,
            tooltip: 'Augmenter la taille',
          ),
          
          const Spacer(),
          
          // Bouton plein écran
          IconButton(
            icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: _toggleFullScreen,
            tooltip: _isFullScreen ? 'Quitter le plein écran' : 'Plein écran',
          ),
          
          // Bouton projection (si disponible)
          if (widget.onToggleProjection != null)
            IconButton(
              icon: const Icon(Icons.present_to_all),
              onPressed: widget.onToggleProjection,
              tooltip: 'Mode projection',
            ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et infos
            if (!widget.isProjectionMode) ...[
              Text(
                widget.song.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: _fontSize + 4,
                ),
              ),
              
              if (widget.song.authors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Par: ${widget.song.authors}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: _fontSize - 2,
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Informations musicales
              Row(
                children: [
                  Text(
                    'Tonalité: $_currentKey',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _fontSize - 2,
                    ),
                  ),
                  if (widget.song.tempo != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      'Tempo: ${widget.song.tempo} BPM',
                      style: TextStyle(fontSize: _fontSize - 2),
                    ),
                  ],
                  const SizedBox(width: 16),
                  Text(
                    widget.song.style,
                    style: TextStyle(fontSize: _fontSize - 2),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Paroles
            _buildFormattedLyrics(),
            
            // Références bibliques
            if (widget.song.bibleReferences.isNotEmpty && !widget.isProjectionMode) ...[
              const SizedBox(height: 24),
              Text(
                'Références bibliques:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _fontSize - 2,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.song.bibleReferences.map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $ref',
                  style: TextStyle(fontSize: _fontSize - 2),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedLyrics() {
    final lines = _displayedLyrics.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: _fontSize / 2));
      } else if (_isChordLine(line)) {
        if (_showChords) {
          widgets.add(_buildChordLine(line));
        }
      } else {
        widgets.add(_buildLyricLine(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  bool _isChordLine(String line) {
    // Une ligne d'accords contient principalement des accords séparés par des espaces
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    
    final parts = trimmed.split(RegExp(r'\s+'));
    int chordCount = 0;
    
    for (final part in parts) {
      if (_isChord(part)) {
        chordCount++;
      }
    }
    
    // Si plus de 60% des éléments sont des accords, c'est une ligne d'accords
    return chordCount / parts.length > 0.6;
  }

  bool _isChord(String text) {
    // Expression régulière pour détecter un accord
    final chordPattern = RegExp(r'^[A-G][#b]?(?:m|maj|min|dim|aug|sus[24]?|add[0-9]|[0-9])*(?:\/[A-G][#b]?)?$');
    return chordPattern.hasMatch(text);
  }

  Widget _buildChordLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        line,
        style: TextStyle(
          fontSize: _fontSize - 2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildLyricLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        line,
        style: TextStyle(
          fontSize: _fontSize,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildFullScreenView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleFullScreen,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Titre en mode projection
              Text(
                widget.song.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Paroles en grand format
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _displayedLyrics,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Indication pour quitter
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Touchez l\'écran pour quitter le mode projection',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}