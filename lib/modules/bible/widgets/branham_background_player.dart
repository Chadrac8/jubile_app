import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../message/models/branham_sermon_model.dart';
import '../../message/services/admin_branham_sermon_service.dart';
import '../services/branham_audio_manager.dart';
import 'dart:async';
import 'dart:math' as math;

// Primary color for the app theme
const Color _primaryColor = Color(0xFF6B73FF);

// Classe pour les particules animées
class Particle {
  double x;
  double y;
  double size;
  double opacity;
  double speed;
  Color color;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.color,
  });
}

/// Lecteur audio Branham simple et professionnel
class BranhamBackgroundPlayerWidget extends StatefulWidget {
  const BranhamBackgroundPlayerWidget({super.key});

  @override
  State<BranhamBackgroundPlayerWidget> createState() => _BranhamBackgroundPlayerWidgetState();
}

class _BranhamBackgroundPlayerWidgetState extends State<BranhamBackgroundPlayerWidget> 
    with TickerProviderStateMixin {
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
  
  // Variables pour les contrôles avancés
  double _playbackSpeed = 1.0;
  bool _isLoopEnabled = false;
  bool _isShuffleEnabled = false;
  double _volume = 1.0;
  bool _showEqualizer = false;
  int _sleepTimerMinutes = 0;
  Timer? _sleepTimer;
  Timer? _speedDebounceTimer;
  
  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;

  // Animation controllers pour l'arrière-plan professionnel
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _titleScrollController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _titleScrollAnimation;
  
  // Variables pour les particules animées
  List<Particle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudioService();
    _loadSermons();
    _createParticles();
  }
  
  void _initializeAnimations() {
    // Contrôleur pour l'arrière-plan gradient animé
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this);
    
    // Contrôleur pour les particules
    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this);
    
    // Contrôleur pour l'effet de pulsation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this);
    
    // Contrôleur pour le défilement du titre
    _titleScrollController = AnimationController(
      duration: const Duration(seconds: 20), // Augmenté de 8 à 20 secondes pour un défilement plus lent
      vsync: this);
    
    // Animations
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut));
    
    _titleScrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0).animate(CurvedAnimation(
      parent: _titleScrollController,
      curve: Curves.linear));
    
    // Démarrer les animations
    _backgroundController.repeat();
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
    _titleScrollController.repeat();
    
    // Timer pour mettre à jour les particules
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateParticles();
    });
  }
  
  void _createParticles() {
    _particles.clear();
    final random = math.Random();
    
    for (int i = 0; i < 25; i++) {
      _particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.6 + 0.1,
        speed: random.nextDouble() * 2 + 0.5,
        color: _primaryColor.withOpacity(random.nextDouble() * 0.3 + 0.1)));
    }
  }
  
  void _updateParticles() {
    if (mounted) {
      setState(() {
        for (var particle in _particles) {
          particle.y -= particle.speed;
          
          // Reset particle when it goes off screen
          if (particle.y < -10) {
            particle.y = 810;
            particle.x = math.Random().nextDouble() * 400;
          }
        }
      });
    }
  }

    @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _searchController.dispose();
    _sleepTimer?.cancel();
    _speedDebounceTimer?.cancel();
    
    // Dispose des animations
    _backgroundController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _titleScrollController.dispose();
    _particleTimer?.cancel();
    
    super.dispose();
  }

  Future<void> _initializeAudioService() async {
    print('🎵 Initializing audio service...');
    try {
      await _audioManager.initialize();
      print('🎵 Audio manager initialized successfully');
      _setupAudioListeners();
      print('🎵 Audio listeners set up');
      debugPrint('✅ Service audio initialisé avec succès pour lecture en arrière-plan');
    } catch (e) {
      print('🎵 ❌ Error initializing audio service: $e');
      debugPrint('❌ Erreur lors de l\'initialisation du service audio: $e');
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
      print('🎵 Audio state changed: isPlaying = $isPlaying');
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
        print('🎵 UI state updated: _isPlaying = $_isPlaying');
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
    print('🎵 _togglePlayPause called - current _isPlaying: $_isPlaying');
    if (_currentSermon == null) {
      print('🎵 No current sermon, showing bottom sheet');
      _showSermonsBottomSheet();
      return;
    }
    
    if (_isPlaying) {
      print('🎵 Calling pause...');
      // Mettre en pause - la position sera automatiquement sauvegardée
      _audioManager.pause().catchError((error) {
        print('🎵 Error during pause: $error');
        _showMessage('Erreur lors de la pause: $error');
      });
    } else {
      print('🎵 Calling play...');
      // Reprendre la lecture - si c'est la même prédication, elle reprendra à la position sauvegardée
      _audioManager.play().catchError((error) {
        print('🎵 Error during play: $error');
        _showMessage('Erreur lors de la lecture: $error');
      });
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
    
    // Vérifier si on a une URL audio valide
    final url = sermon.audioStreamUrl ?? sermon.audioDownloadUrl;
    if (url == null || url.isEmpty) {
      _showMessage('Aucune URL audio disponible pour cette prédication');
      return;
    }
    
    _audioManager.playSermon(sermon).catchError((error) {
      _showMessage('Erreur lors de la lecture: $error');
    });
  }

  // Méthodes pour les contrôles avancés
  void _showAdvancedControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildAdvancedControlsSheet(setModalState)));
  }

  Future<void> _setPlaybackSpeed(double speed, [StateSetter? setModalState]) async {
    setState(() {
      _playbackSpeed = speed;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    try {
      await _audioManager.setSpeed(speed);
    } catch (e) {
      print('Erreur lors du changement de vitesse: $e');
    }
  }

  void _setPlaybackSpeedDebounced(double speed) {
    // Annuler le timer précédent
    _speedDebounceTimer?.cancel();
    
    // Créer un nouveau timer avec un délai de 300ms
    _speedDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        await _audioManager.setSpeed(speed);
      } catch (e) {
        print('Erreur lors du changement de vitesse: $e');
      }
    });
  }

  void _toggleLoop([StateSetter? setModalState]) {
    setState(() {
      _isLoopEnabled = !_isLoopEnabled;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    _showMessage(_isLoopEnabled ? 'Lecture en boucle activée' : 'Lecture en boucle désactivée');
  }

  void _toggleShuffle([StateSetter? setModalState]) {
    setState(() {
      _isShuffleEnabled = !_isShuffleEnabled;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    _showMessage(_isShuffleEnabled ? 'Lecture aléatoire activée' : 'Lecture aléatoire désactivée');
  }

  Future<void> _setVolume(double volume, [StateSetter? setModalState]) async {
    setState(() {
      _volume = volume;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    _showMessage('Volume: ${(volume * 100).round()}%');
  }

  void _toggleEqualizer([StateSetter? setModalState]) {
    setState(() {
      _showEqualizer = !_showEqualizer;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
  }

  void _setSleepTimer(int minutes, [StateSetter? setModalState]) {
    setState(() {
      _sleepTimerMinutes = minutes;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    
    // Annuler le timer précédent
    _sleepTimer?.cancel();
    
    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        _audioManager.pause();
        _showMessage('Minuterie de sommeil activée - Lecture mise en pause');
        setState(() {
          _sleepTimerMinutes = 0;
        });
      });
      _showMessage('Minuterie de sommeil: ${minutes}min');
    }
  }

  Future<void> _fastForward() async {
    print('🎵 _fastForward called');
    try {
      await _audioManager.fastForward();
    } catch (e) {
      print('🎵 Erreur lors de l\'avance rapide: $e');
    }
  }

  Future<void> _rewind() async {
    print('🎵 _rewind called');
    try {
      await _audioManager.rewind();
    } catch (e) {
      print('🎵 Erreur lors du retour rapide: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: _primaryColor));
    }
  }

  void _showBackgroundPlayInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: _primaryColor),
            const SizedBox(width: 12),
            Text(
              'Découvrez votre lecteur',
              style: GoogleFonts.inter(
                color: AppTheme.surfaceColor,
                fontWeight: FontWeight.w600)),
          ]),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Text(
              '🎵 Accès aux prédications :\n\n'
              '• Cliquez sur l\'icône playlist (▶️) en haut à droite\n'
              '• Recherchez par titre ou lieu dans la barre de recherche\n'
              '• Filtrez par année avec les boutons de filtre\n'
              '• Cliquez sur une prédication pour la lancer\n\n'
              '✅ La lecture continue automatiquement :\n\n'
              '• Quand vous fermez l\'application\n'
              '• Quand vous passez à une autre app\n'
              '• Quand vous éteignez l\'écran\n'
              '• Contrôles dans la barre de notification\n'
              '• Contrôles sur l\'écran de verrouillage\n\n'
              '⏯️ Reprise de lecture intelligente :\n\n'
              '• Votre position est sauvegardée automatiquement\n'
              '• Reprend exactement où vous vous êtes arrêté\n'
              '• Même après fermeture de l\'application\n'
              '• Position différente pour chaque prédication\n'
              '• Sauvegarde toutes les 10 secondes\n\n'
              '🎛️ Utilisez les paramètres (⚙️) pour :\n'
              '• Changer la vitesse de lecture\n'
              '• Programmer une minuterie de sommeil\n'
              '• Activer la lecture en boucle\n'
              '• Contrôler le volume\n'
              '• Accès aux contrôles rapides',
              style: GoogleFonts.inter(
                color: AppTheme.surfaceColor.withOpacity(0.9),
                height: 1.4)))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Compris',
              style: GoogleFonts.inter(
                color: _primaryColor,
                fontWeight: FontWeight.w600))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_backgroundAnimation, _particleAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1E1E2E),
                    const Color(0xFF2A1B3D),
                    _backgroundAnimation.value)!,
                  Color.lerp(
                    const Color(0xFF2A1B3D),
                    const Color(0xFF44318D),
                    _backgroundAnimation.value * 0.7)!,
                  Color.lerp(
                    const Color(0xFF1E1E2E),
                    const Color(0xFF6B73FF).withOpacity(0.1),
                    _backgroundAnimation.value * 0.3)!,
                ],
                stops: const [0.0, 0.5, 1.0])),
            child: Stack(
              children: [
                // Particules animées en arrière-plan
                ..._buildAnimatedParticles(),
                
                // Effet de pulsation pour la musique
                if (_isPlaying)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: _pulseAnimation.value * 0.8,
                              colors: [
                                _primaryColor.withOpacity(0.05 * _pulseAnimation.value),
                                Colors.transparent,
                              ]))));
                    }),
                
                // Interface principale
                SafeArea(
                  child: Column(
                    children: [
                      // Header simple avec bouton liste
                      _buildSimpleHeader(),
                      
                      // Player central avec espacement adaptatif
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildSimplePlayer())),
                      
                      // Controls en bas
                      _buildSimpleControls(),
                      
                      const SizedBox(height: 20),
                    ])),
              ]));
        }));
  }
  
  List<Widget> _buildAnimatedParticles() {
    return _particles.map((particle) {
      return Positioned(
        left: particle.x,
        top: particle.y,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: particle.color.withOpacity(0.5),
                blurRadius: particle.size * 2,
                spreadRadius: particle.size * 0.5),
            ])));
    }).toList();
  }

  // Header simple avec titre centré défilant
  Widget _buildSimpleHeader() {
    const String mainTitle = 'Mais qu\'aux jours de la voix du septième ange';
    const String fallbackTitle = 'William Marrion Branham';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 60,
      child: AnimatedBuilder(
        animation: _titleScrollAnimation,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Calculer la largeur du texte principal
              final textPainter = TextPainter(
                text: TextSpan(
                  text: mainTitle,
                  style: GoogleFonts.inter(
                    color: AppTheme.surfaceColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
                textDirection: TextDirection.ltr);
              textPainter.layout();
              
              final textWidth = textPainter.size.width;
              final containerWidth = constraints.maxWidth;
              
              // Si le texte tient dans le conteneur, pas besoin de défiler
              if (textWidth <= containerWidth) {
                return Center(
                  child: Text(
                    mainTitle,
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center));
              }
              
              // Diviser l'animation en phases :
              // 0.0 - 0.05 : Affichage du texte de fallback
              // 0.05 - 0.95 : Défilement du texte principal
              // 0.95 - 1.0 : Affichage du texte de fallback dès que le texte disparaît
              
              if (_titleScrollAnimation.value <= 0.05 || _titleScrollAnimation.value >= 0.95) {
                // Afficher le texte de fallback centré
                return Center(
                  child: Text(
                    fallbackTitle,
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center));
              }
              
              // Phase de défilement (0.05 à 0.95)
              final scrollProgress = (_titleScrollAnimation.value - 0.05) / 0.9; // Normaliser entre 0 et 1
              final totalScrollDistance = textWidth + containerWidth;
              final scrollPosition = scrollProgress * totalScrollDistance - containerWidth;
              
              return ClipRect(
                child: OverflowBox(
                  maxWidth: textWidth,
                  child: Transform.translate(
                    offset: Offset(-scrollPosition, 0),
                    child: Text(
                      mainTitle,
                      style: GoogleFonts.inter(
                        color: AppTheme.surfaceColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.visible))));
            });
        }));
  }

  // Player central simple et efficace
  Widget _buildSimplePlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Artwork avec photo de Branham et effets visuels
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _backgroundAnimation]),
            builder: (context, child) {
              return Container(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercles pulsants en arrière-plan
                    if (_isPlaying) ...[
                      Container(
                        width: 220 * _pulseAnimation.value,
                        height: 220 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3 / _pulseAnimation.value),
                            width: 2))),
                      Container(
                        width: 240 * _pulseAnimation.value,
                        height: 240 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.2 / _pulseAnimation.value),
                            width: 1))),
                      Container(
                        width: 260 * _pulseAnimation.value,
                        height: 260 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.1 / _pulseAnimation.value),
                            width: 0.5))),
                    ],
                    
                    // Image principale avec effets
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(_isPlaying ? 0.4 : 0.3),
                            blurRadius: _isPlaying ? 25 : 20,
                            spreadRadius: _isPlaying ? 8 : 5),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 10)),
                        ]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Image de base
                            Container(
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/branham.jpg'),
                                  fit: BoxFit.cover))),
                            
                            // Overlay gradient animé
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _primaryColor.withOpacity(0.1 * _backgroundAnimation.value),
                                    Colors.transparent,
                                    _primaryColor.withOpacity(0.05 * _backgroundAnimation.value),
                                  ]))),
                            
                            // Effet de brillance si en lecture
                            if (_isPlaying)
                              Positioned(
                                top: -50,
                                left: -50 + (100 * _backgroundAnimation.value),
                                child: Transform.rotate(
                                  angle: math.pi / 4,
                                  child: Container(
                                    width: 100,
                                    height: 400,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppTheme.surfaceColor.withOpacity(0.1),
                                          Colors.transparent,
                                        ]))))),
                          ]))),
                  ]));
            }),
          
          const SizedBox(height: 18),
          
          // Informations de la prédication avec espacement réduit
          if (_currentSermon != null) ...[
            Container(
              constraints: const BoxConstraints(minHeight: 40),
              child: Text(
                _currentSermon!.title,
                style: GoogleFonts.inter(
                  color: AppTheme.surfaceColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.1),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),
            
            const SizedBox(height: 4),
            
            // Informations date et lieu avec wrapping amélioré
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppTheme.surfaceColor.withOpacity(0.7),
                      size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _currentSermon!.date,
                      style: GoogleFonts.inter(
                        color: AppTheme.surfaceColor.withOpacity(0.7),
                        fontSize: 13)),
                  ]),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppTheme.surfaceColor.withOpacity(0.7),
                      size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _currentSermon!.location,
                        style: GoogleFonts.inter(
                          color: AppTheme.surfaceColor.withOpacity(0.7),
                          fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                  ]),
              ]),
          ] else ...[
            Container(
              constraints: const BoxConstraints(minHeight: 50),
              child: Text(
                'Aucune prédication sélectionnée',
                style: GoogleFonts.inter(
                  color: AppTheme.surfaceColor.withOpacity(0.7),
                  fontSize: 16),
                textAlign: TextAlign.center)),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _showSermonsBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, color: AppTheme.surfaceColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Choisir une prédication',
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
                ])),
          ],
        ]));
  }

  // Controls simples en bas avec animations
  Widget _buildSimpleControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.1),
          ])),
      child: Column(
        children: [
          // Barre de progression avec effet lumineux
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: GoogleFonts.inter(
                    color: AppTheme.surfaceColor.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _primaryColor,
                        inactiveTrackColor: AppTheme.surfaceColor.withOpacity(0.2),
                        thumbColor: _primaryColor,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayColor: _primaryColor.withOpacity(0.2),
                        trackHeight: 4),
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
                        })))),
                Text(
                  _formatDuration(_totalDuration),
                  style: GoogleFonts.inter(
                    color: AppTheme.surfaceColor.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
              ])),
          
          const SizedBox(height: 20),
          
          // Boutons de contrôle principal avec animations
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton précédent
                  _buildAnimatedControlButton(
                    icon: Icons.skip_previous,
                    onPressed: _previousSermon,
                    size: 36),
                  
                  // Bouton retour 10s
                  _buildAnimatedControlButton(
                    icon: Icons.replay_10,
                    onPressed: _rewind,
                    size: 32),
                  
                  // Bouton play/pause principal avec pulsation
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _primaryColor,
                          _primaryColor.withOpacity(0.8),
                        ]),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(_isPlaying ? 0.6 : 0.4),
                          blurRadius: _isPlaying ? 25 * _pulseAnimation.value : 20,
                          spreadRadius: _isPlaying ? 5 * _pulseAnimation.value : 2),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5)),
                      ]),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(35),
                        onTap: _togglePlayPause,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surfaceColor.withOpacity(0.2),
                              width: 1)),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppTheme.surfaceColor,
                            size: 35))))),
                  
                  // Bouton avance 30s
                  _buildAnimatedControlButton(
                    icon: Icons.forward_30,
                    onPressed: _fastForward,
                    size: 32),
                  
                  // Bouton suivant
                  _buildAnimatedControlButton(
                    icon: Icons.skip_next,
                    onPressed: _nextSermon,
                    size: 36),
                ]);
            }),
          
          const SizedBox(height: 20),
          
          // Section avec boutons info, paramètres et prédications
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton info à gauche
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showBackgroundPlayInfo,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.info_outline,
                      color: AppTheme.surfaceColor.withOpacity(0.8),
                      size: 26)))),
              
              const SizedBox(width: 20),
              
              // Bouton paramètres au centre
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showAdvancedControls,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.tune,
                      color: _primaryColor,
                      size: 26)))),
              
              const SizedBox(width: 20),
              
              // Bouton prédications à droite
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showSermonsBottomSheet,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.playlist_play,
                      color: _primaryColor,
                      size: 26)))),
            ]),
        ]));
  }
  
  Widget _buildAnimatedControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceColor.withOpacity(0.1),
        border: Border.all(
          color: AppTheme.surfaceColor.withOpacity(0.2),
          width: 1)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Icon(
            icon,
            color: AppTheme.surfaceColor,
            size: size))));
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
                        Expanded(
                          child: Text(
                            'Prédications disponibles',
                            style: GoogleFonts.inter(
                              color: AppTheme.surfaceColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700))),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.library_music_rounded,
                          color: _primaryColor,
                          size: 28),
                        const SizedBox(width: 16),
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

  // Sheet des paramètres avancés (comme YouTube)
  Widget _buildAdvancedControlsSheet(StateSetter setModalState) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  Icons.tune_rounded,
                  color: _primaryColor,
                  size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Paramètres du lecteur',
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor,
                      fontSize: 22,
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
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Vitesse de lecture
                  _buildControlSection(
                    'Vitesse de lecture',
                    Icons.speed_rounded,
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0.5x',
                              style: GoogleFonts.inter(
                                color: AppTheme.surfaceColor.withOpacity(0.7),
                                fontSize: 12)),
                            Text(
                              '${_playbackSpeed.toStringAsFixed(1)}x',
                              style: GoogleFonts.inter(
                                color: _primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                            Text(
                              '2.0x',
                              style: GoogleFonts.inter(
                                color: AppTheme.surfaceColor.withOpacity(0.7),
                                fontSize: 12)),
                          ]),
                        Slider(
                          value: _playbackSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          activeColor: _primaryColor,
                          inactiveColor: AppTheme.surfaceColor.withOpacity(0.2),
                          onChanged: (value) {
                            // Mise à jour immédiate de l'UI
                            setModalState(() {
                              _playbackSpeed = value;
                            });
                            setState(() {
                              _playbackSpeed = value;
                            });
                            // Application de la vitesse avec debouncing
                            _setPlaybackSpeedDebounced(value);
                          }),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                            final isSelected = _playbackSpeed == speed;
                            return GestureDetector(
                              onTap: () {
                                // Mise à jour immédiate de l'UI
                                setModalState(() {
                                  _playbackSpeed = speed;
                                });
                                setState(() {
                                  _playbackSpeed = speed;
                                });
                                // Application de la vitesse avec feedback tactile
                                _setPlaybackSpeedDebounced(speed);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryColor : AppTheme.surfaceColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16)),
                                child: Text(
                                  '${speed}x',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.surfaceColor,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))));
                          }).toList()),
                      ])),
                  
                  const SizedBox(height: 24),
                  
                  // Volume
                  _buildControlSection(
                    'Volume',
                    Icons.volume_up_rounded,
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.volume_mute_rounded,
                              color: AppTheme.surfaceColor.withOpacity(0.7),
                              size: 20),
                            Text(
                              '${(_volume * 100).round()}%',
                              style: GoogleFonts.inter(
                                color: _primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                            Icon(
                              Icons.volume_up_rounded,
                              color: AppTheme.surfaceColor.withOpacity(0.7),
                              size: 20),
                          ]),
                        Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: _primaryColor,
                          inactiveColor: AppTheme.surfaceColor.withOpacity(0.2),
                          onChanged: (value) {
                            // Mise à jour immédiate de l'UI
                            setModalState(() {
                              _volume = value;
                            });
                            setState(() {
                              _volume = value;
                            });
                            // Feedback immédiat sans attendre l'API
                            _showMessage('Volume: ${(value * 100).round()}%');
                          }),
                      ])),
                  
                  const SizedBox(height: 24),
                  
                  // Minuterie de sommeil
                  _buildControlSection(
                    'Minuterie de sommeil',
                    Icons.bedtime_rounded,
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Arrêt automatique',
                              style: GoogleFonts.inter(
                                color: AppTheme.surfaceColor.withOpacity(0.7),
                                fontSize: 14)),
                            Text(
                              _sleepTimerMinutes > 0 ? '${_sleepTimerMinutes}min' : 'Désactivé',
                              style: GoogleFonts.inter(
                                color: _sleepTimerMinutes > 0 ? _primaryColor : AppTheme.surfaceColor.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                          ]),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [0, 5, 10, 15, 30, 45, 60, 90].map((minutes) {
                            final isSelected = _sleepTimerMinutes == minutes;
                            return GestureDetector(
                              onTap: () => _setSleepTimer(minutes, setModalState),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryColor : AppTheme.surfaceColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? _primaryColor : AppTheme.surfaceColor.withOpacity(0.2),
                                    width: 1)),
                                child: Text(
                                  minutes == 0 ? 'Off' : '${minutes}min',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.surfaceColor,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))));
                          }).toList()),
                      ])),
                  
                  const SizedBox(height: 24),
                  
                  // Options de lecture
                  _buildControlSection(
                    'Options de lecture',
                    Icons.loop_rounded,
                    Column(
                      children: [
                        _buildToggleOption(
                          'Lecture en boucle',
                          'Répéter automatiquement la prédication actuelle',
                          Icons.repeat_rounded,
                          _isLoopEnabled,
                          () => _toggleLoop(setModalState)),
                        const SizedBox(height: 16),
                        _buildToggleOption(
                          'Lecture aléatoire',
                          'Choisir aléatoirement la prochaine prédication',
                          Icons.shuffle_rounded,
                          _isShuffleEnabled,
                          () => _toggleShuffle(setModalState)),
                        const SizedBox(height: 16),
                        _buildToggleOption(
                          'Égaliseur visuel',
                          'Afficher les animations de visualisation audio',
                          Icons.graphic_eq_rounded,
                          _showEqualizer,
                          () => _toggleEqualizer(setModalState)),
                      ])),
                  
                  const SizedBox(height: 24),
                  
                  // Contrôles rapides
                  _buildControlSection(
                    'Contrôles rapides',
                    Icons.touch_app_rounded,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          'Retour 10s',
                          Icons.replay_10_rounded,
                          _rewind),
                        _buildQuickActionButton(
                          'Avance 30s',
                          Icons.forward_30_rounded,
                          _fastForward),
                        _buildQuickActionButton(
                          'Aléatoire',
                          Icons.shuffle_rounded,
                          () {
                            if (_allSermons.isNotEmpty) {
                              final random = (_allSermons..shuffle()).first;
                              _selectSermon(random);
                              Navigator.pop(context);
                            }
                          }),
                      ])),
                  
                  const SizedBox(height: 32),
                ]))),
        ]));
  }

  Widget _buildControlSection(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surfaceColor.withOpacity(0.1),
          width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: _primaryColor,
                size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppTheme.surfaceColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
            ]),
          const SizedBox(height: 16),
          content,
        ]));
  }

  Widget _buildToggleOption(String title, String subtitle, IconData icon, bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? _primaryColor.withOpacity(0.1) : AppTheme.surfaceColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? _primaryColor.withOpacity(0.3) : AppTheme.surfaceColor.withOpacity(0.1),
            width: 1)),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? _primaryColor : AppTheme.surfaceColor.withOpacity(0.7),
              size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppTheme.surfaceColor.withOpacity(0.7),
                      fontSize: 12)),
                ])),
            Switch(
              value: value,
              onChanged: (_) => onTap(),
              activeColor: _primaryColor,
              inactiveThumbColor: AppTheme.surfaceColor.withOpacity(0.7),
              inactiveTrackColor: AppTheme.surfaceColor.withOpacity(0.2)),
          ])));
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.surfaceColor.withOpacity(0.2),
            width: 1)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _primaryColor,
              size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.surfaceColor,
                fontSize: 11,
                fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          ])));
  }
}
