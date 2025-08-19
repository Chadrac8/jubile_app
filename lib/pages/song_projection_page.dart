import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song_model.dart';
import '../services/chord_transposer.dart';

/// Page de projection des chants en plein écran
class SongProjectionPage extends StatefulWidget {
  final SongModel song;

  const SongProjectionPage({
    super.key,
    required this.song,
  });

  @override
  State<SongProjectionPage> createState() => _SongProjectionPageState();
}

class _SongProjectionPageState extends State<SongProjectionPage> {
  String _currentKey = '';
  bool _showChords = true;
  int _currentSection = 0;
  List<String> _sections = [];
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.song.originalKey;
    _parseSections();
    
    // Masquer l'interface système
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Garder l'écran allumé
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    // Restaurer l'interface système
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _parseSections() {
    final lyrics = _currentKey == widget.song.originalKey
        ? widget.song.lyrics
        : ChordTransposer.transposeLyrics(
            widget.song.lyrics,
            widget.song.originalKey,
            _currentKey,
          );

    // Diviser les paroles en sections (séparées par des lignes vides)
    final sections = lyrics.split('\n\n');
    _sections = sections.where((section) => section.trim().isNotEmpty).toList();
    
    if (_sections.isEmpty) {
      _sections = [lyrics];
    }
  }

  void _nextSection() {
    if (_currentSection < _sections.length - 1) {
      setState(() {
        _currentSection++;
      });
    }
  }

  void _previousSection() {
    if (_currentSection > 0) {
      setState(() {
        _currentSection--;
      });
    }
  }

  void _transposeKey(String newKey) {
    setState(() {
      _currentKey = newKey;
      _parseSections();
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onPanEnd: (details) {
          // Détecter les gestes de glissement
          if (details.velocity.pixelsPerSecond.dx > 300) {
            _previousSection();
          } else if (details.velocity.pixelsPerSecond.dx < -300) {
            _nextSection();
          }
        },
        child: Stack(
          children: [
            // Contenu principal
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titre du chant
                    Text(
                      widget.song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    if (widget.song.authors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.song.authors,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Section courante
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _sections.isNotEmpty ? _sections[_currentSection] : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    // Indicateur de section
                    if (_sections.length > 1) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_sections.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentSection
                                  ? Colors.white
                                  : Colors.white30,
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Contrôles (affichés/masqués)
            if (_showControls) ...[
              // Barre de contrôle en haut
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Bouton retour
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        
                        const Spacer(),
                        
                        // Sélecteur de tonalité
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _currentKey,
                            onChanged: (newKey) {
                              if (newKey != null) {
                                _transposeKey(newKey);
                              }
                            },
                            dropdownColor: Colors.black87,
                            underline: Container(),
                            style: const TextStyle(color: Colors.white),
                            items: SongModel.availableKeys.map((key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(key),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Bouton afficher/masquer accords
                        IconButton(
                          icon: Icon(
                            _showChords ? Icons.music_note : Icons.music_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _showChords = !_showChords;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Contrôles de navigation en bas
              if (_sections.length > 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bouton précédent
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                            onPressed: _currentSection > 0 ? _previousSection : null,
                          ),
                          
                          // Indicateur de progression
                          Text(
                            '${_currentSection + 1} / ${_sections.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          
                          // Bouton suivant
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                            onPressed: _currentSection < _sections.length - 1 ? _nextSection : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Instructions d'utilisation (affichées temporairement)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Touchez l\'écran pour masquer/afficher les contrôles\n'
                    'Glissez à gauche/droite pour naviguer entre les sections',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            
            // Zones de navigation invisibles (pour les gestes)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 100,
              child: GestureDetector(
                onTap: _previousSection,
                child: Container(color: Colors.transparent),
              ),
            ),
            
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 100,
              child: GestureDetector(
                onTap: _nextSection,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}