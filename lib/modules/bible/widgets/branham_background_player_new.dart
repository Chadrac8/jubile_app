import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../message/models/branham_sermon_model.dart';
import '../../message/services/admin_branham_sermon_service.dart';
import '../services/branham_audio_manager.dart';
import 'dart:async';

// Primary color for the app theme
const Color _primaryColor = Color(0xFF6B73FF);

/// Lecteur audio Branham simple et professionnel
class BranhamBackgroundPlayerWidget extends StatefulWidget {
  const BranhamBackgroundPlayerWidget({super.key});

  @override
  State<BranhamBackgroundPlayerWidget> createState() => _BranhamBackgroundPlayerWidgetState();
}

class _BranhamBackgroundPlayerWidgetState extends State<BranhamBackgroundPlayerWidget> {
  final BranhamAudioManager _audioManager = BranhamAudioManager();
  
  List<BranhamSermon> _allSermons = [];
  BranhamSermon? _currentSermon;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  
  // Filtres et recherche
  String _searchQuery = '';
  int? _selectedYear;
  final TextEditingController _searchController = TextEditingController();
  
  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAudioService();
    _loadSermons();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _searchController.dispose();
    _audioManager.dispose();
    super.dispose();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioManager.initialize();
      _setupAudioListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du service audio: $e');
      // Continue sans bloquer l'interface - l'utilisateur peut toujours accéder à la liste
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service audio indisponible. La liste des prédications reste accessible.'),
            backgroundColor: AppTheme.warningColor,
            duration: Duration(seconds: 3)));
      }
    }
  }

  void _setupAudioListeners() {
    _positionSubscription = _audioManager.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _durationSubscription = _audioManager.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      }
    });

    _playingSubscription = _audioManager.playingStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });
  }

  Future<void> _loadSermons() async {
    try {
      debugPrint('🔄 Chargement des prédications audio...');
      
      var sermons = await AdminBranhamSermonService.getActiveSermons();
      
      if (sermons.isEmpty) {
        debugPrint('⚠️ Aucune prédication admin trouvée, chargement des données de démonstration...');
        final demoSermons = await _loadDemoSermons();
        sermons = demoSermons;
      }
      
      if (mounted) {
        setState(() {
          _allSermons = sermons;
          
          if (_currentSermon == null && sermons.isNotEmpty) {
            final filteredSermons = _filteredSermons;
            if (filteredSermons.isNotEmpty) {
              _currentSermon = filteredSermons.first;
              debugPrint('📻 Prédication auto-sélectionnée: ${_currentSermon!.title}');
            }
          }
        });
        
        debugPrint('✅ ${sermons.length} prédications chargées avec succès');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des prédications: $e');
    }
  }

  Future<List<BranhamSermon>> _loadDemoSermons() async {
    return [
      BranhamSermon(
        id: 'demo_1',
        title: 'La communion par la rédemption',
        date: '2023-12-25',
        location: 'Jeffersonville, IN',
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        createdAt: DateTime.now()),
    ];
  }

  List<BranhamSermon> get _filteredSermons {
    var filtered = _allSermons.toList();
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((sermon) =>
        sermon.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        sermon.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedYear != null) {
      filtered = filtered.where((sermon) =>
        DateTime.tryParse(sermon.date)?.year == _selectedYear
      ).toList();
    }
    
    return filtered;
  }

  List<int> get _availableYears {
    final years = _allSermons
        .map((sermon) => DateTime.tryParse(sermon.date)?.year)
        .where((year) => year != null)
        .cast<int>()
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _togglePlayPause() {
    if (_currentSermon == null) {
      _showSermonsBottomSheet();
      return;
    }
    
    if (_isPlaying) {
      _audioManager.pause();
    } else {
      _audioManager.playSermon(_currentSermon!);
    }
  }

  void _nextSermon() {
    if (_allSermons.isEmpty) return;
    
    final currentIndex = _allSermons.indexWhere((s) => s.id == _currentSermon?.id);
    if (currentIndex != -1 && currentIndex < _allSermons.length - 1) {
      _selectSermon(_allSermons[currentIndex + 1]);
    } else if (_allSermons.isNotEmpty) {
      _selectSermon(_allSermons.first);
    }
  }

  void _previousSermon() {
    if (_allSermons.isEmpty) return;
    
    final currentIndex = _allSermons.indexWhere((s) => s.id == _currentSermon?.id);
    if (currentIndex > 0) {
      _selectSermon(_allSermons[currentIndex - 1]);
    } else if (_allSermons.isNotEmpty) {
      _selectSermon(_allSermons.last);
    }
  }

  void _selectSermon(BranhamSermon sermon) {
    setState(() {
      _currentSermon = sermon;
    });
    _audioManager.playSermon(sermon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header simple avec bouton liste
            _buildSimpleHeader(),
            
            const SizedBox(height: 30),
            
            // Player central
            Expanded(
              child: _buildSimplePlayer()),
            
            // Controls en bas
            _buildSimpleControls(),
            
            const SizedBox(height: 30),
          ])));
  }

  // Header simple avec bouton pour accéder aux prédications
  Widget _buildSimpleHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'Prédications Branham',
            style: GoogleFonts.inter(
              color: AppTheme.surfaceColor,
              fontSize: 24,
              fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: _showSermonsBottomSheet,
              icon: const Icon(
                Icons.playlist_play,
                color: AppTheme.surfaceColor,
                size: 28),
              tooltip: 'Voir toutes les prédications')),
        ]));
  }

  // Player central simple et efficace
  Widget _buildSimplePlayer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Artwork simple
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withOpacity(0.7)]),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5),
              ]),
            child: Icon(
              Icons.audiotrack,
              size: 100,
              color: AppTheme.surfaceColor.withOpacity(0.9))),
          
          const SizedBox(height: 40),
          
          // Informations de la prédication
          if (_currentSermon != null) ...[
            Text(
              _currentSermon!.title,
              style: GoogleFonts.inter(
                color: AppTheme.surfaceColor,
                fontSize: 20,
                fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.surfaceColor.withOpacity(0.7),
                  size: 16),
                const SizedBox(width: 8),
                Text(
                  _currentSermon!.date,
                  style: GoogleFonts.inter(
                    color: AppTheme.surfaceColor.withOpacity(0.7),
                    fontSize: 14)),
                const SizedBox(width: 20),
                Icon(
                  Icons.location_on,
                  color: AppTheme.surfaceColor.withOpacity(0.7),
                  size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _currentSermon!.location,
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor.withOpacity(0.7),
                      fontSize: 14),
                    overflow: TextOverflow.ellipsis)),
              ]),
          ] else ...[
            Text(
              'Aucune prédication sélectionnée',
              style: GoogleFonts.inter(
                color: AppTheme.surfaceColor.withOpacity(0.7),
                fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showSermonsBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info, color: AppTheme.surfaceColor,
                  const SizedBox(width: 8),
                  Text(
                    'Choisir une prédication',
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor,
                      fontWeight: FontWeight.w600)),
                ])),
          ],
        ]));
  }

  // Controls simples en bas
  Widget _buildSimpleControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Barre de progression
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: GoogleFonts.inter(
                  color: AppTheme.surfaceColor.withOpacity(0.7),
                  fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _totalDuration.inMilliseconds > 0
                      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                      : 0.0,
                  onChanged: (value) {
                    if (_totalDuration.inMilliseconds > 0) {
                      final position = Duration(
                        milliseconds: (value * _totalDuration.inMilliseconds).round());
                      _audioManager.seek(position);
                    }
                  },
                  activeColor: _primaryColor,
                  inactiveColor: AppTheme.surfaceColor.withOpacity(0.3))),
              Text(
                _formatDuration(_totalDuration),
                style: GoogleFonts.inter(
                  color: AppTheme.surfaceColor.withOpacity(0.7),
                  fontSize: 12)),
            ]),
          
          const SizedBox(height: 20),
          
          // Boutons de contrôle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bouton précédent
              IconButton(
                onPressed: _previousSermon,
                icon: const Icon(
                  Icons.skip_previous,
                  color: AppTheme.surfaceColor,
                  size: 40)),
              
              // Bouton play/pause principal
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2),
                  ]),
                child: IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppTheme.surfaceColor,
                    size: 35))),
              
              // Bouton suivant
              IconButton(
                onPressed: _nextSermon,
                icon: const Icon(
                  Icons.skip_next,
                  color: AppTheme.surfaceColor,
                  size: 40)),
            ]),
        ]));
  }

  // Bottom sheet pour sélectionner les prédications
  void _showSermonsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2D1B69).withOpacity(0.95),
                    const Color(0xFF1A0F3A).withOpacity(0.95),
                    const Color(0xFF0A0520).withOpacity(0.95),
                  ]),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30))),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.library_music_rounded,
                          color: _primaryColor,
                          size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Prédications disponibles',
                            style: GoogleFonts.inter(
                              color: AppTheme.surfaceColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700))),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTheme.surfaceColor.withOpacity(0.8),
                              size: 20))),
                      ])),
                  
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.surfaceColor.withOpacity(0.2),
                          width: 1)),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: AppTheme.surfaceColor,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une prédication...',
                          hintStyle: GoogleFonts.inter(
                            color: AppTheme.surfaceColor.withOpacity(0.5)),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppTheme.surfaceColor.withOpacity(0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12)),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        }))),
                  
                  // Filtres par année
                  if (_availableYears.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _buildFilterChip(
                            'Toutes les années',
                            _selectedYear == null,
                            () => setState(() => _selectedYear = null)),
                          const SizedBox(width: 12),
                          ..._availableYears.map((year) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildFilterChip(
                              year.toString(),
                              _selectedYear == year,
                              () => setState(() => _selectedYear = year)))),
                        ])),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Liste des prédications
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filteredSermons.length,
                      itemBuilder: (context, index) {
                        final sermon = _filteredSermons[index];
                        final isCurrentSermon = _currentSermon?.id == sermon.id;
                        
                        return _buildSermonTile(sermon, isCurrentSermon);
                      })),
                ]));
          });
      });
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    _primaryColor,
                    _primaryColor.withOpacity(0.8),
                  ])
              : null,
          color: isSelected ? null : AppTheme.surfaceColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? _primaryColor 
                : AppTheme.surfaceColor.withOpacity(0.3),
            width: 1)),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? AppTheme.surfaceColor : AppTheme.surfaceColor.withOpacity(0.8),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))));
  }

  Widget _buildSermonTile(BranhamSermon sermon, bool isCurrentSermon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isCurrentSermon
            ? LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.2),
                  _primaryColor.withOpacity(0.1),
                ])
            : LinearGradient(
                colors: [
                  AppTheme.surfaceColor.withOpacity(0.1),
                  AppTheme.surfaceColor.withOpacity(0.05),
                ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentSermon 
              ? _primaryColor.withOpacity(0.5)
              : AppTheme.surfaceColor.withOpacity(0.1),
          width: 1)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: isCurrentSermon
                  ? [
                      _primaryColor,
                      _primaryColor.withOpacity(0.7),
                    ]
                  : [
                      AppTheme.surfaceColor.withOpacity(0.2),
                      AppTheme.surfaceColor.withOpacity(0.1),
                    ]),
            shape: BoxShape.circle),
          child: Icon(
            isCurrentSermon && _isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: AppTheme.surfaceColor,
            size: 24)),
        title: Text(
          sermon.title,
          style: GoogleFonts.inter(
            color: AppTheme.surfaceColor,
            fontSize: 16,
            fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.surfaceColor.withOpacity(0.6),
                size: 12),
              const SizedBox(width: 4),
              Text(
                sermon.date,
                style: GoogleFonts.inter(
                  color: AppTheme.surfaceColor.withOpacity(0.7),
                  fontSize: 12)),
              const SizedBox(width: 12),
              Icon(
                Icons.location_on_rounded,
                color: AppTheme.surfaceColor.withOpacity(0.6),
                size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sermon.location,
                  style: GoogleFonts.inter(
                    color: AppTheme.surfaceColor.withOpacity(0.7),
                    fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
            ])),
        onTap: () {
          _selectSermon(sermon);
          Navigator.pop(context);
        }));
  }
}
